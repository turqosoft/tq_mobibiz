import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/customer_list_model.dart';
import '../../model/item_list_model.dart';
import '../../model/pos_invoice_model.dart';
import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import '../home/widgets/settings_screen.dart';

class PosInvoiceScreen extends StatefulWidget {
  final String userEmail;
  final String? invoiceName;   // 👈 new
  final bool isSubmittedView;  // 👈 new
  // const PosInvoiceScreen({Key? key, required this.userEmail}) : super(key: key);
  const PosInvoiceScreen({
    Key? key,
    required this.userEmail,
    this.invoiceName,
    this.isSubmittedView = false,
  }) : super(key: key);



  @override
  State<PosInvoiceScreen> createState() => _PosInvoiceScreenState();
}

class _PosInvoiceScreenState extends State<PosInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late BuildContext _rootContext; // ✅ Keep root context

  // Controllers
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _currencyController =
  TextEditingController(text: "INR");
  final FocusNode _itemSearchFocusNode = FocusNode();

  final TextEditingController _priceListController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _discountPercent = 0.0;
  double getGrandTotal() {
    double total = _items.fold(0.0, (sum, item) => sum + (item.qty * item.rate));
    if (_discountPercent > 0) {
      total = total - (total * (_discountPercent / 100));
    }
    return total;
  }

  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _uomController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<ItemData> _itemSuggestions = [];
  bool _itemSelected = false;
  String? _submittedInvoiceName;
  String? _submittedInvoiceStatus;
  bool _isSearchingItem = false;
  List<Data> _customerList = [];
  String? _selectedCustomer;
  String? _searchCustomerName;
  bool _customerSelected = false;
  bool _isSubmitting = false;
  List<Items> _items = [];
  bool _showUpdateButton = false;
  String? _lastInvoiceName;
  bool get _isReadOnly => _submittedInvoiceName != null;
  double getDiscountAmount() {
    double total = _items.fold(0.0, (sum, item) => sum + (item.qty * item.rate));
    return total * (_discountPercent / 100);
  }
  double getRoundedGrandTotal() {
    return getGrandTotal().roundToDouble();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   provider.fetchPosProfile();  // fetch profile → then payments
  // }
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.fetchPosProfile();

    // 👇 If opened from invoice list → fetch details
    if (widget.invoiceName != null && widget.isSubmittedView) {
      _loadSubmittedInvoice(widget.invoiceName!);
    }
  }

  Future<void> _loadSubmittedInvoice(String invoiceName) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final invoiceData = await provider.fetchInvoiceDetails(invoiceName);

    if (invoiceData != null) {
      setState(() {
        // 🔹 Basic invoice info
        _submittedInvoiceName = invoiceData["name"];
        _submittedInvoiceStatus = invoiceData["status"];
        _lastInvoiceName = invoiceData["name"];
        _showUpdateButton = false; // lock updates for submitted invoice

        // 🔹 Customer details
        _selectedCustomer = invoiceData["customer"];
        _searchCustomerName = invoiceData["customer_name"];
        _customerController.text = invoiceData["customer"] ?? "";
        _searchController.text =
        "${invoiceData["customer_name"] ?? ''} (${invoiceData["customer"] ?? ''})";

        // 🔹 Currency, Price List, Company if returned by API
        _currencyController.text = invoiceData["currency"] ?? "";
        _priceListController.text = invoiceData["selling_price_list"] ?? "";
        _companyController.text = invoiceData["company"] ?? "";
        // 🔹 Discount %
        _discountPercent = (invoiceData["additional_discount_percentage"] ?? 0).toDouble();
        _discountController.text = _discountPercent.toStringAsFixed(2);
        // 🔹 Items (map JSON → your ItemData model)
        if (invoiceData["items"] != null) {
          _items = (invoiceData["items"] as List)
              .map((it) => Items(
            itemCode: it["item_code"],
            itemName: it["item_name"],
            qty: (it["qty"] as num).toDouble(),
            rate: (it["rate"] as num).toDouble(),
            uom: it["uom"],
              priceListRate: it["price_list_rate"],
              warehouse: it["warehouse"]
          ))
              .toList();
        }

      });
    }
  }

  void _resetForm() {
    setState(() {
      // Clear all controllers
      _customerController.clear();
      _companyController.clear();
      _currencyController.text = "INR"; // reset default
      _priceListController.clear();
      _discountController.clear();
      _itemCodeController.clear();
      _itemNameController.clear();
      _qtyController.clear();
      _uomController.clear();
      _rateController.clear();
      _warehouseController.clear();
      _searchController.clear();

      // Reset other states
      _items.clear();
      _itemSuggestions.clear();
      _customerList.clear();
      _selectedCustomer = null;
      _searchCustomerName = null;
      _customerSelected = false;
      _itemSelected = false;
      _discountPercent = 0.0;
    });
  }

  Future<void> _searchCustomer(String query) async {
    if (query.isEmpty) return;
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final result = await provider.searchCustomer(query, context);
    setState(() {
      _customerList = result?.data ?? [];
      // _customerSelected = false;
    });
  }

  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      setState(() => _itemSuggestions = []);
      return;
    }

    setState(() => _isSearchingItem = true);
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    final result = await provider.itemSearchLists(query, context, false);

    if (result != null) {
      setState(() {
        _itemSuggestions = result; // ✅ now a List<ItemData>
      });
    } else {
      setState(() => _itemSuggestions = []);
    }

    setState(() => _isSearchingItem = false);
  }


  void _showItemDialog({
    required BuildContext context,
    Items? existingItem, // if not null → edit mode
    Map<String, dynamic>? itemDetails, // passed in add mode
    int? editIndex,
  }) async {
    // 🔎 If editing, fetch latest item details
    Map<String, dynamic>? details = itemDetails;
    if (existingItem != null && details == null) {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      details = await provider.fetchItemsDetails(
        existingItem.itemCode,
        provider.posProfile?["name"] ?? "",
        _customerController.text,
      );
    }

    final qtyController = TextEditingController(
      text: existingItem != null ? existingItem.qty.toString() : "",
    );

    final availableQty = (details?["available_qty"] ?? 0).toDouble();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existingItem != null
              ? "Edit ${existingItem.itemName}"
              : details?["item_name"] ?? "Add Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Item Code: ${existingItem?.itemCode ?? details?["item_code"] ?? ""}"),
              Text("UOM: ${existingItem?.uom ?? details?["uom"] ?? ""}"),
              Text("Rate: ${existingItem?.rate ?? details?["price_list_rate"] ?? "0"}"),
              Text("Available Qty: $availableQty"), // ✅ Always show
              const SizedBox(height: 10),
              TextField(
                controller: qtyController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: Text(existingItem != null ? "Update" : "Add Item"),
              onPressed: () {
                if (qtyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter quantity")),
                  );
                  return;
                }

                final enteredQty = double.tryParse(qtyController.text) ?? 0;

                if (enteredQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠ Quantity must be greater than 0")),
                  );
                  return;
                }

                if (enteredQty > availableQty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("⚠ Only $availableQty available in stock")),
                  );
                  return;
                }

                setState(() {
                  if (existingItem != null && editIndex != null) {
                    // ✏ Update existing item
                    _items[editIndex] = Items(
                      itemCode: existingItem.itemCode,
                      itemName: existingItem.itemName,
                      qty: enteredQty,
                      uom: existingItem.uom,
                      rate: existingItem.rate,
                      priceListRate: existingItem.priceListRate,
                      warehouse: existingItem.warehouse,
                    );
                  } else if (details != null) {
                    // ➕ Add new item
                    _items.add(
                      Items(
                        itemCode: details["item_code"] ?? "",
                        itemName: details["item_name"] ?? "",
                        qty: enteredQty,
                        uom: details["uom"] ?? "",
                        rate: double.tryParse(details["price_list_rate"].toString()) ?? 0,
                        priceListRate: double.tryParse(details["price_list_rate"].toString()) ?? 0,
                        warehouse: details["warehouse"] ?? "",
                      ),
                    );
                  }
                });

                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<bool?> showPaymentDialog(
      BuildContext context, SalesOrderProvider provider, double invoiceAmount) async {
    final controllers = provider.paymentEntries
        .map((p) => TextEditingController(text: p.amount.toString()))
        .toList();

    double getPaidAmount() =>
        provider.paymentEntries.fold(0.0, (sum, p) => sum + p.amount);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Payment Modes"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...provider.paymentEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payment = entry.value;
                    return Row(
                      children: [
                        Expanded(child: Text(payment.modeOfPayment)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controllers[index],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Amount",
                            ),
                            onTap: () {
                              // ✅ select all text when user taps
                              controllers[index].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: controllers[index].text.length,
                              );
                            },
                            onChanged: (val) {
                              setState(() {
                                double entered = double.tryParse(val) ?? 0.0;

                                // Temporarily update
                                payment.amount = entered;

                                double total = getPaidAmount();

                              });
                            },

                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  // ✅ Summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text("Grand Total: ₹${invoiceAmount.toStringAsFixed(2)}")),
                      Expanded(child: Text("Paid: ₹${getPaidAmount().toStringAsFixed(2)}")),
                      Expanded(child: Text("Change: ₹${(getPaidAmount() - invoiceAmount).toStringAsFixed(2)}")),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    double total = getPaidAmount();


                    for (var i = 0; i < controllers.length; i++) {
                      provider.paymentEntries[i].amount =
                          double.tryParse(controllers[i].text) ?? 0.0;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text("Confirm"),
                ),

              ],
            );
          },
        );
      },
    );

    return result; // ✅ true / false
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
    _rootContext = context;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "POS Invoice",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          _isSubmitting || provider.isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
              : _showUpdateButton
              ? IconButton(
            icon: const Icon(Icons.update, color: Colors.green),
            tooltip: "Update Invoice",
            onPressed: () async {
              // 🔄 your existing update logic unchanged...
                    final provider = Provider.of<SalesOrderProvider>(
                        context, listen: false);

                    setState(() => _isSubmitting = true);

                    // 🔄 Update invoice with items
                    final success =
                    await provider.updateInvoiceItems(
                        _lastInvoiceName!,
                        _items,
                      additionalDiscountPercentage: _discountPercent
                    );

                    setState(() => _isSubmitting = false);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("✅ Invoice updated, please confirm payment")),
                      );

                      // 🔁 Fetch updated grand total
                      final invoiceData =
                      await provider.fetchInvoiceDetails(_lastInvoiceName!);

                      final double grandTotal =
                      (invoiceData?['rounded_total'] ?? 0) > 0
                          ? (invoiceData?['rounded_total'] as double)
                          : (invoiceData?['grand_total'] ?? 0.0) as double;

                      await provider.fetchModesOfPayments(
                          provider.posProfile?["name"],
                          invoiceAmount: grandTotal);

                      final confirmed =
                      await showPaymentDialog(context, provider, grandTotal);

                      if (confirmed == true) {
                        final submitSuccess = await provider
                            .confirmAndSubmitInvoice(_lastInvoiceName!);
                        if (submitSuccess) {
                          final submittedInvoice =
                          await provider.fetchInvoiceDetails(_lastInvoiceName!);

                          setState(() {
                            _submittedInvoiceName = submittedInvoice?["name"];
                            _submittedInvoiceStatus = submittedInvoice?["status"];
                            _showUpdateButton = false;
                            // don’t null _lastInvoiceName immediately, keep it for reference
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("✅ Invoice submitted successfully")),
                          );
                          setState(() {
                            _showUpdateButton = false; // reset for next invoice
                            _lastInvoiceName = null;
                          });
                          // _resetForm();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("❌ Failed to submit invoice")),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("❌ Failed to update invoice items")),
                      );
                    }
                  },
                )
        : Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    IconButton(
    icon: _submittedInvoiceName != null
    ? const Icon(Icons.add, color: Colors.white)
        : const Icon(Icons.currency_rupee_sharp,
    color: Colors.white),
    tooltip: _submittedInvoiceName != null
    ? "New Invoice"
        : "Create Invoice",
    onPressed: () async {
    if (_submittedInvoiceName != null) {
    // 👇 Reset when plus is pressed
    _resetForm();
    setState(() {
    _submittedInvoiceName = null;
    _submittedInvoiceStatus = null;
    _lastInvoiceName = null;
    _showUpdateButton = false;
    });
    return;
    }


    // 👇 your existing create invoice logic unchanged...
              if (_formKey.currentState!.validate()) {
                setState(() => _isSubmitting = true);

                final invoice = PosInvoice(
                  docstatus: 0,
                  customer: _customerController.text,
                  company: _companyController.text,
                  currency: _currencyController.text,
                  sellingPriceList: _priceListController.text,
                  payments: [],
                  items: _items,
                  additionalDiscountPercentage: _discountPercent,
                );

                final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                final invoiceName = await provider.submitInvoices(
                  context,
                  invoice,
                  getGrandTotal(), // 👈 add this
                );


                setState(() => _isSubmitting = false);

                if (invoiceName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("❌ Failed to Create Invoice")),
                  );
                  return;
                }

                // 💾 store invoice name for future update
                setState(() {
                  _lastInvoiceName = invoiceName;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                      Text("✅ POS Invoice Created: $invoiceName")),
                );

                final invoiceData =
                await provider.fetchInvoiceDetails(invoiceName);

                final double grandTotal =
                (invoiceData?['rounded_total'] ?? 0) > 0
                    ? (invoiceData?['rounded_total'] as double)
                    : (invoiceData?['grand_total'] ?? 0.0) as double;

                await provider.fetchModesOfPayments(provider.posProfile?["name"],
                    invoiceAmount: grandTotal);

                final confirmed =
                await showPaymentDialog(context, provider, grandTotal);

                if (confirmed == true) {
                  final success =
                  await provider.confirmAndSubmitInvoice(invoiceName);

                  if (success) {
                    // ✅ Fetch final invoice details (name + status)
                    final submittedInvoice =
                    await provider.fetchInvoiceDetails(invoiceName);
                    setState(() {
                      _submittedInvoiceName = submittedInvoice?["name"];
                      _submittedInvoiceStatus =
                      submittedInvoice?["status"];
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "✅ Invoice submitted successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("❌ Failed to submit invoice")),
                    );
                  }
                } else if (confirmed == false) {
                  // 👇 Switch UI to update mode
                  setState(() {
                    _showUpdateButton = true;
                  });
                }
              }
            },
          ),

      if (_submittedInvoiceName != null)
        IconButton(
          icon: const Icon(Icons.print, color: Colors.white),
          tooltip: "Print Invoice",
          onPressed: () async {
            final sharedPref = provider.sharedPrefService;
            final savedPrinter = await sharedPref.getPrinterAddress();

            if (savedPrinter == null || savedPrinter.isEmpty) {
              // Show dialog if no printer configured
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("No Printer Selected"),
                  content: const Text(
                      "You haven’t selected a printer. Please configure one to continue."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Go to Settings"),
                    ),
                  ],
                ),
              );

              if (shouldOpenSettings == true) {
                // Navigate to settings
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );

                // Re-check printer after settings
                final newPrinter = await sharedPref.getPrinterAddress();
                if (newPrinter != null && newPrinter.isNotEmpty) {
                  // Retry printing the same invoice
                  final success = await provider.printInvoiceReceipt(
                    _submittedInvoiceName!,
                    context,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "✅ Invoice sent to printer"
                            : "⚠️ Failed to print invoice",
                      ),
                    ),
                  );
                }
              }
            } else {
              // Printer already exists → print directly
              final success = await provider.printInvoiceReceipt(
                _submittedInvoiceName!,
                context,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? "✅ Invoice sent to printer"
                        : "⚠️ Failed to print invoice",
                  ),
                ),
              );
            }
          },
        ),



    ],
          ),

        ],

      ),
      // body: Form(
      //   key: _formKey,
      //   child: Column(
      //       children: [
      //         // 👇 Submitted invoice card (only visible if not null)
      //         if (_submittedInvoiceName != null)
      //           Card(
      //             color: Colors.green[50],
      //             margin: const EdgeInsets.all(12),
      //             child: Padding(
      //               padding: const EdgeInsets.all(16.0),
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   const Text(
      //                     "Invoice Submitted ✅",
      //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      //                   ),
      //                   const SizedBox(height: 8),
      //                   Text("Name: $_submittedInvoiceName"),
      //                   Text("Status: $_submittedInvoiceStatus"),
      //                 ],
      //               ),
      //             ),
      //           ),
      //   Expanded(
      //   child: SingleChildScrollView(
      //   padding: const EdgeInsets.all(12),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //
      //       const Text("Customer", style: TextStyle(fontWeight: FontWeight.bold)),
      //       Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      //         decoration: BoxDecoration(
      //           color: Colors.grey[200],
      //           borderRadius: BorderRadius.circular(10.0),
      //         ),
      //         child: TextField(
      //           enabled: !_isReadOnly,   // disable editing
      //           controller: _searchController,
      //           readOnly: _showUpdateButton, // 👈 Make field read-only in update mode
      //           decoration: InputDecoration(
      //             labelText: 'Search Customer',
      //             suffixIcon: _showUpdateButton
      //                 ? null // 👈 hide search icon when locked
      //                 : const Icon(Icons.search),
      //             border: InputBorder.none,
      //             contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      //           ),
      //           onChanged: _showUpdateButton
      //               ? null // 👈 disable searching
      //               : (content) {
      //             setState(() {
      //               _customerSelected = false;
      //             });
      //             _searchCustomer(content);
      //           },
      //           onSubmitted: _showUpdateButton
      //               ? null
      //               : (query) {
      //             setState(() {
      //               _customerSelected = false;
      //             });
      //             _searchCustomer(query);
      //           },
      //         ),
      //       ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 👇 Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👇 Submitted invoice card (only visible if not null)
                    if (_submittedInvoiceName != null)
                      Card(
                        color: Colors.green[50],
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Invoice Submitted ✅",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text("Name: $_submittedInvoiceName"),
                              Text("Status: $_submittedInvoiceStatus"),
                            ],
                          ),
                        ),
                      ),

                    // 🔎 Customer search field
                    const Text("Customer",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: TextField(
                        enabled: !_isReadOnly,
                        controller: _searchController,
                        readOnly: _showUpdateButton,
                        decoration: InputDecoration(
                          labelText: 'Search Customer',
                          suffixIcon: _showUpdateButton
                              ? null
                              : const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        onChanged: _showUpdateButton
                            ? null
                            : (content) {
                          setState(() {
                            _customerSelected = false;
                          });
                          _searchCustomer(content);
                        },
                        onSubmitted: _showUpdateButton
                            ? null
                            : (query) {
                          setState(() {
                            _customerSelected = false;
                          });
                          _searchCustomer(query);
                        },
                      ),
                    ),

// 🔎 Customer Suggestions
            if (!_customerSelected && _customerList.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _customerList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final customer = _customerList[index];
                    return ListTile(
                      title: Text(customer.customerName ?? ''),
                      subtitle: Text(customer.name ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      onTap: () async {
                        // ✅ Set selected customer directly into search bar
                        setState(() {
                          _selectedCustomer = customer.name ?? '';
                          _searchCustomerName = customer.customerName;
                          _customerSelected = true;

                          // Show name in search field
                          _searchController.text =
                          "${customer.customerName} (${customer.name})";

                          _customerController.text = customer.name ?? '';
                        });

                        // ✅ Close keyboard
                        FocusScope.of(context).unfocus();

                        try {
                          final customerDetails =
                          await provider.fetchCustomersDetails(customer.customerName ?? '');
                          if (customerDetails != null) {
                            setState(() {
                              _currencyController.text =
                                  customerDetails['currency'] ?? '';
                              _priceListController.text =
                                  customerDetails['selling_price_list'] ?? '';
                              _companyController.text =
                                  customerDetails['company'] ?? '';
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to fetch customer details')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Error occurred while fetching customer')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),


// Show Selected Customer Details
            if (_selectedCustomer != null)

            // Loading Indicator
              if (provider.isLoading) const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 20),
              //
              // const SizedBox(height: 100),

              const Text("Item", style: TextStyle(fontWeight: FontWeight.bold)),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                enabled: !_isReadOnly,
                focusNode: _itemSearchFocusNode,
                controller: _itemCodeController,
                decoration: const InputDecoration(
                  labelText: 'Search Item',
                  suffixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                onChanged: (value) async {
                  setState(() {
                    _itemSelected = false;
                  });
                  await _searchItems(value);
                },
                onSubmitted: (query) async {
                  setState(() {
                    _itemSelected = false;
                  });
                  await _searchItems(query);
                },
              ),
            ),

// 🔄 Loading indicator
            if (_isSearchingItem)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              )

            else if (_itemSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _itemSuggestions.length,
                  itemBuilder: (context, index) {
                    final item = _itemSuggestions[index]; // 👈 ItemData
                    return ListTile(
                      leading: item.image != null
                          ? Image.network(
                        item.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.inventory_2),
                      title: Text(item.itemName ?? ""),
                      subtitle: Text("Code: ${item.itemCode ?? ""}"),
                      onTap: () async {
                        _itemSearchFocusNode.unfocus();
                        _itemCodeController.clear();
                        setState(() => _itemSuggestions = []);

                        final itemDetails = await provider.fetchItemsDetails(
                          item.itemCode ?? "",
                          provider.posProfile?["name"] ?? "",
                          _customerController.text,
                        );

                        if (!mounted) return;

                        if (itemDetails != null) {
                          final availableQty = (itemDetails["available_qty"] ?? 0).toDouble();

                          if (availableQty <= 0) {
                            ScaffoldMessenger.of(_rootContext).showSnackBar(
                              SnackBar(content: Text("❌ ${itemDetails["item_name"]} is out of stock")),
                            );
                            return;
                          }

                          _showItemDialog(
                            context: _rootContext,
                            itemDetails: itemDetails,
                          );
                        } else {
                          ScaffoldMessenger.of(_rootContext).showSnackBar(
                            const SnackBar(content: Text("❌ Failed to fetch item details")),
                          );
                        }
                      },
                    );
                  },
                ),
              ),


             SizedBox(height: 20),
              // 📝 Show added items
              if (_items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
    const Text(
    "Added Items",
    style: TextStyle(fontWeight: FontWeight.bold),
    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final it = _items[index];
                        final amount = (it.qty * it.rate); // ✅ calculate amount here

                        return ListTile(
                          title: Text(
                            "${it.itemName ?? ''} (${it.itemCode ?? ''})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 First row: labels
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Expanded(child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                              // 🔹 Second row: values
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text("${it.qty} ${it.uom}")),
                                  Expanded(child: Text("₹${it.rate.toStringAsFixed(2)}")),
                                  Expanded(child: Text("₹${(it.qty * it.rate).toStringAsFixed(2)}")),
                                ],
                              ),
                            ],
                          ),

                          trailing: !_isReadOnly
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showItemDialog(
                                    context: context,
                                    existingItem: it,
                                    editIndex: index,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          )
                              : null,
                        );
                      },
                    )



                  ],),
    ],
    ),
    ),
    ),

      // bottomNavigationBar: Container(
      //   padding: const EdgeInsets.all(12),
      //   decoration: const BoxDecoration(
      //     color: Colors.white60,
      //     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      //   ),
      //   child: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Row(
      //         children: [
      //           const Text(
      //             "Discount %: ",
      //             style: TextStyle(fontWeight: FontWeight.bold),
      //           ),
      //           Expanded(
      //             child: GestureDetector(
      //               onTap: _isReadOnly || !provider.allowDiscountChange
      //                   ? null
      //                   : () async {
      //                 final newDiscount = await showDialog<double>(
      //                   context: context,
      //                   builder: (ctx) {
      //                     final controller = TextEditingController(
      //                       text: _discountPercent.toString(),
      //                     );
      //                     controller.selection = TextSelection(
      //                       baseOffset: 0,
      //                       extentOffset: controller.text.length,
      //                     );
      //
      //                     return AlertDialog(
      //                       title: const Text("Enter Discount %"),
      //                       content: TextField(
      //                         controller: controller,
      //                         autofocus: true,
      //                         keyboardType: TextInputType.number,
      //                         decoration: const InputDecoration(
      //                           hintText: "Enter discount %",
      //                           border: OutlineInputBorder(),
      //                         ),
      //                         onSubmitted: (val) {
      //                           final value = double.tryParse(val) ?? 0.0;
      //                           Navigator.pop(ctx, value);
      //                         },
      //                       ),
      //                       actions: [
      //                         TextButton(
      //                           onPressed: () => Navigator.pop(ctx),
      //                           child: const Text("Cancel"),
      //                         ),
      //                         ElevatedButton(
      //                           onPressed: () {
      //                             final value = double.tryParse(controller.text) ?? 0.0;
      //                             Navigator.pop(ctx, value);
      //                           },
      //                           child: const Text("OK"),
      //                         ),
      //                       ],
      //                     );
      //                   },
      //                 );
      //
      //                 if (newDiscount != null) {
      //                   setState(() {
      //                     _discountPercent = newDiscount;
      //                     _discountController.text = newDiscount.toString();
      //                   });
      //                 }
      //               },
      //               child: AbsorbPointer(
      //                 child: TextField(
      //                   controller: _discountController,
      //                   readOnly: true,
      //                   enabled: !_isReadOnly && provider.allowDiscountChange,
      //                   decoration: InputDecoration(
      //                     hintText: provider.allowDiscountChange
      //                         ? "Tap to enter discount %"
      //                         : "Discount not allowed",
      //                     border: const OutlineInputBorder(),
      //                     isDense: true,
      //                     contentPadding: const EdgeInsets.all(8),
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //           const SizedBox(width: 10),
      //           // 👉 Show discount amount
      //           Text(
      //             "₹${getDiscountAmount().toStringAsFixed(2)}",
      //             style: const TextStyle(
      //               fontWeight: FontWeight.bold,
      //               color: Colors.red,
      //             ),
      //           ),
      //         ],
      //       ),
      //
      //
      //       SizedBox(height: 10),
      //       Align(
      //         alignment: Alignment.centerRight,
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.end,
      //           children: [
      //             Text(
      //               "Grand Total: ₹${getGrandTotal().toStringAsFixed(2)}",
      //               style: const TextStyle(
      //                 fontWeight: FontWeight.bold,
      //                 fontSize: 18,
      //                 color: Colors.black,
      //               ),
      //             ),
      //             const SizedBox(height: 4),
      //             Text(
      //               "Rounded Total: ₹${getRoundedGrandTotal().toStringAsFixed(2)}",
      //               style: const TextStyle(
      //                 fontWeight: FontWeight.w600,
      //                 fontSize: 16,
      //                 color: Colors.green,
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
      //
      //
      //       const SizedBox(height: 50),
      //     ],
      //   ),
      // ),
      Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
      color: Colors.white60,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
      Row(
      children: [
      const Text(
      "Discount %: ",
      style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Expanded(
      child: GestureDetector(
      onTap: _isReadOnly || !provider.allowDiscountChange
      ? null
          : () async {
    final newDiscount = await showDialog<double>(
    context: context,
    builder: (ctx) {
    final controller = TextEditingController(
    text: _discountPercent.toString(),
    );
    controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
    );

    return AlertDialog(
    title: const Text("Enter Discount %"),
    content: TextField(
    controller: controller,
    autofocus: true,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
    hintText: "Enter discount %",
    border: OutlineInputBorder(),
    ),
    onSubmitted: (val) {
    final value =
    double.tryParse(val) ?? 0.0;
    Navigator.pop(ctx, value);
    },
    ),
    actions: [
    TextButton(
    onPressed: () =>
    Navigator.pop(ctx),
    child: const Text("Cancel"),
    ),
    ElevatedButton(
    onPressed: () {
    final value = double.tryParse(
    controller.text) ??
    0.0;
    Navigator.pop(ctx, value);
    },
    child: const Text("OK"),
    ),
    ],
    );
    },
    );

    if (newDiscount != null) {
    setState(() {
    _discountPercent = newDiscount;
    _discountController.text =
    newDiscount.toString();
    });
    }
    },
    child: AbsorbPointer(
    child: TextField(
    controller: _discountController,
    readOnly: true,
    enabled: !_isReadOnly &&
    provider.allowDiscountChange,
    decoration: InputDecoration(
    hintText: provider.allowDiscountChange
    ? "Tap to enter discount %"
        : "Discount not allowed",
    border: const OutlineInputBorder(),
    isDense: true,
    contentPadding: const EdgeInsets.all(8),
    ),
    ),
    ),
    ),
    ),
    const SizedBox(width: 10),
    Text(
    "₹${getDiscountAmount().toStringAsFixed(2)}",
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.red,
    ),
    ),
    ],
    ),
    const SizedBox(height: 10),
    Align(
    alignment: Alignment.centerRight,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Text(
    "Grand Total: ₹${getGrandTotal().toStringAsFixed(2)}",
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: Colors.black,
    ),
    ),
    const SizedBox(height: 4),
    Text(
    "Rounded Total: ₹${getRoundedGrandTotal().toStringAsFixed(2)}",
    style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.green,
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 50),
    ],
    ),
    ),
    ],
    ),
    ),


    );
  }
}