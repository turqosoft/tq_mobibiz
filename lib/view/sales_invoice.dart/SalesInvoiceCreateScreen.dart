
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoice.dart';

class SalesInvoiceCreateScreen extends StatefulWidget {
  final void Function(Future<void> Function())? onSave;

  const SalesInvoiceCreateScreen({super.key, this.onSave});

  @override
  State<SalesInvoiceCreateScreen> createState() =>
      _SalesInvoiceCreateScreenState();
}

class _SalesInvoiceCreateScreenState extends State<SalesInvoiceCreateScreen> {
  String? _selectedCustomer;
  String? _searchCustomerName;
  final TextEditingController _searchController = TextEditingController();
  bool _customerSelected = false;
  String? _currency;
  bool isSubmitting = false;

  final TextEditingController _itemSearchController = TextEditingController();
  String? _selectedItem;
  bool _itemSelected = false;

  final TextEditingController customerController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController priceListRateController = TextEditingController();
  final TextEditingController totalController = TextEditingController(); // NEW
  final TextEditingController postingDateController = TextEditingController();
  DateTime? _selectedPostingDate;


  final FocusNode totalFocusNode = FocusNode(); // NEW

  String currency = "INR";

  void _recalculateTotal() {
    final qty = double.tryParse(qtyController.text) ?? 0.0;
    final rate = double.tryParse(rateController.text) ?? 0.0;
    final total = qty * rate;
    totalController.text = total.toStringAsFixed(3);
  }

  void _handleTotalEdit() {
    if (!totalFocusNode.hasFocus) return;

    final total = double.tryParse(totalController.text) ?? 0.0;
    final qty = double.tryParse(qtyController.text) ?? 0.0;
    if (qty > 0) {
      final newRate = total / qty;
      rateController.text = newRate.toStringAsFixed(3);
      priceListRateController.text = newRate.toStringAsFixed(3);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemSearchController.dispose();
    customerController.dispose();
    dueDateController.dispose();
    itemCodeController.dispose();
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    priceListRateController.dispose();
    totalController.dispose(); // dispose new controller
    totalFocusNode.dispose(); // dispose new focus node
    postingDateController.dispose();


    super.dispose();
  }

  Future<void> _handleSave() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    final provider =
    Provider.of<SalesOrderProvider>(context, listen: false);

    final customerName = customerController.text.trim();
    final dueDate = dueDateController.text.trim();
    final items = provider.items;

    if (customerName.isEmpty || dueDate.isEmpty || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and add items.")),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final success = await provider.submitInvoice(
      context,
      customerName,
      _selectedDueDate!,
      _selectedPostingDate!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sales Invoice Created"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesInvoicePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "Unknown error occurred"),
        ),
      );
    }

    setState(() => isSubmitting = false);
  }


    Future<void> _searchCustomer(String customer) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.searchCustomer(customer, context);
    } catch (e) {
      print('Error searching customer: $e');
    }
  }


  Future<void> _searchItemList(String item) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.itemSearchList(item, context, false);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }
  Future<void> _selectPostingDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedPostingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedPostingDate = pickedDate;
        postingDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void resetForm() {
  setState(() {
    _selectedCustomer = null;
    _searchCustomerName = null;
    _searchController.clear();
    _customerSelected = false;

    _selectedItem = null;
    _itemSearchController.clear();
    _itemSelected = false;
    _itemSelected = false;

    customerController.clear();
  _selectedDueDate = DateTime.now();
  dueDateController.text = DateFormat('dd-MM-yyyy').format(_selectedDueDate!);    itemCodeController.clear();
    qtyController.clear();
    rateController.clear();
    discountController.clear();
    priceListRateController.clear();
    _selectedPostingDate = DateTime.now();
    postingDateController.text = DateFormat('dd-MM-yyyy').format(_selectedPostingDate!);

  });

  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  provider.clearItem();
  provider.clearSearchResults(); // You’ll add this next
}



void _showAddItemDialog({
  required String itemName,
  required String itemCode,
  required double rate,
  required double quantity,
  required double priceListRate, // <-- Add this
  required double discountPercentage,
  required VoidCallback onCancel,
  required String itemTaxTemplate,
  required double lastPurchaseRate,

}) {
    // Set rateController to priceListRate as default
  rateController.text = priceListRate.toStringAsFixed(3);

  // Set priceListRateController too for display (if needed)
  priceListRateController.text = priceListRate.toStringAsFixed(3);
  showDialog(
    context: context,
    builder: (context) => AddItemDialog(
      itemName: itemName,
      itemCode: itemCode,
      rate: priceListRate,
      quantity: quantity,
      priceListRate: priceListRate, // <-- Pass it here
      discountPercentage: discountPercentage,
      onCancel: onCancel,
      itemTaxTemplate: itemTaxTemplate,
      lastPurchaseRate: lastPurchaseRate,

    ),
  );
}

  //
  // void _showEditDialog(BuildContext context, int index,
  //     SalesOrderProvider provider, final VoidCallback onCancel) {
  //   final item = provider.itemsList[index];
  //   final _rateController = TextEditingController(text: item.rate.toString());
  //   final _quantityController = TextEditingController(text: item.quantity.toString());
  //   final _priceListRateController = TextEditingController(text: item.priceListRate?.toString() ?? '');
  //   final _discountPercentageController = TextEditingController(text: item.discountPercentage?.toString() ?? '');
  //   final _totalController = TextEditingController(text: (item.rate * item.quantity).toStringAsFixed(3));
  //   final _totalFocusNode = FocusNode();
  //
  //   double totalAmount = item.rate * item.quantity;
  //
  //   void updateTotal() {
  //     if (_totalFocusNode.hasFocus) return;
  //
  //     final rate = double.tryParse(_rateController.text) ?? 0;
  //     final qty = double.tryParse(_quantityController.text) ?? 0;
  //     final discount =
  //         double.tryParse(_discountPercentageController.text) ?? 0;
  //
  //     final effectiveRate =
  //     discount > 0 ? rate * (1 - discount / 100) : rate;
  //
  //     totalAmount = effectiveRate * qty;
  //     _totalController.text = totalAmount.toStringAsFixed(3);
  //   }
  //
  //
  //   void updateRateFromTotal() {
  //     if (!_totalFocusNode.hasFocus) return;
  //
  //     final total = double.tryParse(_totalController.text) ?? 0;
  //     final qty = double.tryParse(_quantityController.text) ?? 0;
  //     if (qty > 0) {
  //       final newRate = total / qty;
  //       _rateController.text = newRate.toStringAsFixed(3);
  //       _priceListRateController.text = newRate.toStringAsFixed(3);
  //     }
  //   }
  //
  //   _rateController.addListener(updateTotal);
  //   _quantityController.addListener(updateTotal);
  //   _totalController.addListener(updateRateFromTotal);
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Edit Item'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text('Item: ${item.name}'),
  //               TextField(
  //                 controller: _priceListRateController,
  //                 keyboardType: TextInputType.number,
  //                 decoration: InputDecoration(labelText: 'Price List Rate'),
  //                 readOnly: true,
  //               ),
  //               TextField(
  //                 controller: _rateController,
  //                 keyboardType: TextInputType.number,
  //                 decoration: InputDecoration(labelText: 'Rate'),
  //               ),
  //               TextField(
  //                 controller: _discountPercentageController,
  //                 keyboardType: TextInputType.number,
  //                 decoration: InputDecoration(labelText: 'Discount Percentage'),
  //               ),
  //               TextField(
  //                 controller: _quantityController,
  //                 keyboardType: TextInputType.number,
  //                 decoration: InputDecoration(labelText: 'Quantity'),
  //               ),
  //               TextField(
  //                 controller: _totalController,
  //                 focusNode: _totalFocusNode,
  //                 keyboardType: TextInputType.number,
  //                 decoration: InputDecoration(labelText: 'Total'),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               final newRate = double.tryParse(_rateController.text) ?? 0.0;
  //               final newQuantity = double.tryParse(_quantityController.text) ?? 0;
  //               final newPriceListRate =
  //                   double.tryParse(_priceListRateController.text) ?? 0.0;
  //               final newDiscountPercentage =
  //                   double.tryParse(_discountPercentageController.text) ?? 0.0;
  //
  //               if (newRate <= 0) {
  //                 Fluttertoast.showToast(
  //                   msg: "Please enter a valid rate",
  //                   toastLength: Toast.LENGTH_SHORT,
  //                   gravity: ToastGravity.BOTTOM,
  //                 );
  //               } else if (newQuantity <= 0) {
  //                 Fluttertoast.showToast(
  //                   msg: "Please enter a valid quantity",
  //                   toastLength: Toast.LENGTH_SHORT,
  //                   gravity: ToastGravity.BOTTOM,
  //                 );
  //               } else {
  //                 provider.editItem(
  //                   index,
  //                   newRate,
  //                   newQuantity,
  //                   newPriceListRate,
  //                   newDiscountPercentage,
  //                 );
  //                 Navigator.of(context).pop();
  //               }
  //             },
  //             child: Text('Save'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               onCancel();
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Cancel'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showEditDialog(BuildContext context, int index,
      SalesOrderProvider provider, final VoidCallback onCancel) async {

    final item = provider.itemsList[index];

    /// 🔥 Fetch full details (IMPORTANT)
    final details = await provider.fetchItemDetail(
      context: context,
      itemCode: item.itemCode,
      currency: _currency ?? '',
      quantity: item.quantity,
      customerName: _selectedCustomer ?? '',
    );

    final message = details?["message"];

    final lastPurchaseRate =
        message?["last_purchase_rate"] ?? item.lastPurchaseRate;

    final itemTaxTemplate =
        message?["item_tax_template"] ?? item.itemTaxTemplate;

    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        itemName: item.name,
        itemCode: item.itemCode,
        rate: item.rate,
        quantity: item.quantity,
        priceListRate: item.priceListRate ?? item.rate,
        discountPercentage: item.discountPercentage ?? 0.0,
        itemTaxTemplate: itemTaxTemplate,
        lastPurchaseRate: lastPurchaseRate,
        isEdit: true,
        editIndex: index,// ✅ IMPORTANT
        onCancel: onCancel,
        onItemAdded: (rate, qty) {
          setState(() {
            // _isFormDirty = true;
          });
        },
      ),
    );
  }

  DateTime? _selectedDueDate;

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (_selectedPostingDate != null && pickedDate.isBefore(_selectedPostingDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Due date cannot be before posting date."),
            backgroundColor: Colors.red,
          ),
        );
        return; // ❌ Do not update if invalid
      }

      setState(() {
        _selectedDueDate = pickedDate;
        dueDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }


@override
void initState() {
  super.initState();
  qtyController.addListener(_recalculateTotal);
  rateController.addListener(_recalculateTotal);
  totalController.addListener(_handleTotalEdit);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    widget.onSave?.call(_handleSave);
    resetForm(); // Ensures context is available
  });
}


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
        final items = provider.itemListModel?.data ?? [];
    TextStyle style =
        const TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
        final customerList = provider.customerSearchModel?.data ?? [];


    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 💰 TOTAL (TOP RIGHT)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildTotalAmount(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// 🔍 SEARCH CUSTOMER (FULL WIDTH)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Customer',
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedCustomer = null;
                              customerController.clear();
                              customerList.clear();
                            });
                          },
                        )
                            : const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _selectedCustomer = null;
                        _searchCustomer(value);
                      },
                    ),
                  ),
                ],
              ),



// List of Matching Customers
              if (customerList.isNotEmpty)

                SizedBox(
    height: 200,
    child: ListView.builder(
      itemCount: customerList.length,
      itemBuilder: (BuildContext context, int index) {
        final customer = customerList[index];

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: RadioListTile<String>(
            title: Text(customer.customerName ?? ''),
            subtitle: Text(
              customer.name ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            value: customer.name ?? '',
            groupValue: _selectedCustomer,
            onChanged: (String? selected) async {
              if (selected == null) return;


              setState(() {
                _selectedCustomer = customer.name;
                _searchController.text = customer.customerName ?? '';
                customerController.text = customer.name ?? '';
                customerList.clear(); // hide list after selection
              });

              try {
                final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                final customerDetails = await provider.fetchCustomerDetails(
                  context,
                  customer.customerName ?? '',
                );

                debugPrint('✅ Fetched Customer Details: $customerDetails');

                if (customerDetails != null && customerDetails['message'] != null) {
                  final message = customerDetails['message'];
                  setState(() {
                    _currency = message['currency'] ?? '';
                  });
                  debugPrint('💱 Currency: $_currency');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to fetch customer details')),
                  );
                }
              } catch (e) {
                debugPrint('❌ Error fetching customer details: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error occurred while fetching customer')),
                );
              }
            },
          ),
        );
      },
    ),
  ),

// Loading Indicator
if (Provider.of<SalesOrderProvider>(context).isLoading)
  const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 12),

const SizedBox(height: 15),

              Row(
                children: [
                  // Posting Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0, bottom: 3),
                          child: Text(
                            "Posting Date",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectPostingDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: postingDateController,
                              hintText: "Select",
                              borderRadius: 10,
                              style: style,
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Due Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0, bottom: 3),
                          child: Text(
                            "Due Date",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectDueDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: dueDateController,
                              hintText: "Select",
                              borderRadius: 10,
                              style: style,
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

                  const Divider(height: 32),
              const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold)),

// Input field styled like reference
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(10.0),
  ),
  child: TextField(
    controller: _itemSearchController,
    decoration: const InputDecoration(
      labelText: 'Search Item',
      suffixIcon: Icon(Icons.search),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
    ),
    onChanged: (content) {
      setState(() {
        _itemSelected = false;
      });
      _searchItemList(content);
    },
    onSubmitted: (query) {
      setState(() {
        _itemSelected = false;
      });
      _searchItemList(query);
    },
  ),
),

// List of matching items
if (!_itemSelected && items.isNotEmpty)
  SizedBox(
    height: 200,
    child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        var item = items[index];
        bool isAlreadySelected = _selectedItem == item.itemName;

        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: RadioListTile<String>(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item.itemCode ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            value: item.itemName ?? '',
            groupValue: _selectedItem,

              onChanged: (String? selected) async {
                if (selected == null) return;

                final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                final customer = customerController.text.trim();

                // 🔐 Check if customer is filled in
                if (customer.isEmpty) {
                  Fluttertoast.showToast(msg: "Please enter/select a customer first.");
                  return;
                }

                // 🔁 Ensure customer details are fetched
                if (provider.invoiceCustomerDetails == null ||
                    provider.invoiceCustomerDetails?["customer_name"] != customer) {
                  try {
                    await provider.fetchCustomer(context, customer);
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Failed to fetch customer details.");
                    return;
                  }
                }

                final customerDetails = provider.invoiceCustomerDetails ??
                    await provider.fetchCustomer(context, customer);

                if (customerDetails == null) {
                  Fluttertoast.showToast(msg: "Failed to load customer details.");
                  return;
                }

                final priceList = provider.sellingPriceList;

                if (priceList == null || priceList.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "Selling Price List is not configured for this customer.",
                  );
                  return;
                }

                try {
                  final item = items[index];

                  // 🚫 Check if item already exists in the list
                  final isDuplicate = provider.itemsList.any(
                        (existingItem) => existingItem.itemCode == item.itemCode,
                  );

                  if (isDuplicate) {
                    Fluttertoast.showToast(msg: "Item '${item.itemName}' already added.");
                    return; // Exit early, don't proceed to fetch or show dialog
                  }

                  // final itemDetails = await provider.fetchItem(
                  //   context: context,
                  //   itemCode: item.itemCode ?? '',
                  //   itemName: item.itemName ?? '',
                  //   quantity: 1.0,
                  //   currency: currency,
                  //   customer: customer,
                  //   priceList: priceList,
                  // );
                  final itemDetails = await provider.fetchItemDetail(
                    context: context,
                    itemCode: item.itemCode ?? '',
                    currency: currency,
                    quantity: 1.0,
                    customerName: customer,
                  );

                  // if (itemDetails != null) {
                  //
                  //   final rate = (itemDetails['rate'] ?? 0).toDouble();
                  //   final priceListRate = (itemDetails['price_list_rate'] ?? 0).toDouble();
                  //   final discount = (itemDetails['discount_percentage'] ?? 0).toDouble();
                  //   final itemTaxTemplate = itemDetails["item_tax_template"] ?? "";
                  if (itemDetails != null && itemDetails['message'] != null) {

                    final message = itemDetails['message'];

                    final rate = (message['rate'] ?? 0).toDouble();
                    final priceListRate = (message['price_list_rate'] ?? 0).toDouble();
                    final discount = (message['discount_percentage'] ?? 0).toDouble();
                    final itemTaxTemplate = message["item_tax_template"] ?? "";

                    /// ✅ NEW
                    final lastPurchaseRate =
                    (message['last_purchase_rate'] ?? 0).toDouble();

                    setState(() {
                      _selectedItem = selected;
                      _itemSelected = true;
                      _itemSearchController.clear();
                    });

                    _showAddItemDialog(
                      itemName: item.itemName ?? "",
                      itemCode: item.itemCode ?? "",
                      rate: rate,
                      quantity: 1,
                      priceListRate: priceListRate,
                      discountPercentage: discount,
                      lastPurchaseRate: lastPurchaseRate,
                      // itemTaxTemplate: message["item_tax_template"] ?? "",
                      itemTaxTemplate: itemTaxTemplate,

                      onCancel: () {
                        setState(() {
                          _selectedItem = null;
                          _itemSelected = false;
                        });
                      },
                    );
                  } else {
                    Fluttertoast.showToast(msg: "Failed to fetch item details.");
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: "Error fetching item: $e");
                }

              }

          ),
        );
      },
    ),
  ),

              if (provider.isLoadingItem)
                const Center(
                  child: CircularProgressIndicator(),
                ),

SizedBox(
  height: 300, // Increased height to fit the total amount text
  child: Consumer<SalesOrderProvider>(
    builder: (context, itemProvider, child) {
      // Calculate grand total of all items
      final grandTotal = itemProvider.itemsList.fold<double>(
        0,
        (sum, item) => sum + ((item.rate ?? 0) * (item.quantity ?? 0)),
      );

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // List of items
    Expanded(
      child: Consumer<SalesOrderProvider>(
        builder: (context, itemProvider, child) {
          final itemList = itemProvider.itemsList;

          /// 🔄 Loading
          if (itemProvider.isLoadingItem) {
            return const Center(child: CircularProgressIndicator());
          }

          /// 📭 Empty state
          if (itemList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No items added yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          /// 📦 Item list
          return ListView.builder(
            itemCount: itemList.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemBuilder: (context, index) {
              final item = itemList[index];

              final double rate = item.rate ?? 0;
              final double qty = item.quantity ?? 0;
              final double discount = item.discountPercentage ?? 0;

              final double effectiveRate =
              discount > 0 ? rate * (1 - discount / 100) : rate;

              final double amount = effectiveRate * qty;
              final double originalAmount = rate * qty;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showEditDialog(context, index, itemProvider, () {
                      setState(() => _selectedItem = null);
                      _itemSearchController.clear();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔢 Serial badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        /// 📄 Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Item name
                              Text(
                                item.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),

                              /// Item code
                              if (item.itemCode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.itemCode!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 4),

                              /// Qty × Rate
                              Text(
                                '${qty.toStringAsFixed(2)} × ₹${rate.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),

                              /// Discount
                              if (discount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Discount: ${discount.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        /// 💰 Amount + Delete
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (discount > 0)
                              Text(
                                '₹${originalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),

                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// 🗑 Delete
                            InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: Colors.redAccent),
                                        SizedBox(width: 8),
                                        Text("Confirm Delete",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    content: Text(
                                      "Are you sure you want to delete '${item.name}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        icon: const Icon(Icons.delete_forever,
                                            size: 18),
                                        label: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  itemProvider.deleteItem(index);
                                  // setState(() => _isFormDirty = true);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "'${item.name}' deleted successfully"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              child: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),


  ],
);

    },
  ),
),

             Consumer<SalesOrderProvider>(
  builder: (context, provider, _) {
    if (provider.item.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Items Added:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...provider.item.map((item) {
return ListTile(
  title: Text("${item["item_code"]} - ${item["item_name"]}"),
  subtitle: Text("Qty: ${item["qty"]}, Rate: ${item["rate"]}"),
);

        }).toList(),
      ],
    );
  },
),

              // const SizedBox(height: 30),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTotalAmount() {
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, _) {
        final total = provider.itemsList.fold<double>(
          0,
              (sum, item) {
            final rate = item.rate ?? 0;
            final qty = item.quantity ?? 0;
            final discount = item.discountPercentage ?? 0;

            final effectiveRate =
            discount > 0 ? rate * (1 - discount / 100) : rate;

            return sum + (effectiveRate * qty);
          },
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '₹ ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        );
      },
    );
  }

}
