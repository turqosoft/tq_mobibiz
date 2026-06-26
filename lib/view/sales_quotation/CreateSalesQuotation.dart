import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import '../../model/customer_list_model.dart';

class CreateQuotationTab extends StatefulWidget {
  const CreateQuotationTab({super.key});

  @override
  State<CreateQuotationTab> createState() => CreateQuotationTabState();
}

class CreateQuotationTabState extends State<CreateQuotationTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerSearchController = TextEditingController();
  String? _selectedItem;
  final TextEditingController customerController = TextEditingController();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  DateTime? transactionDate;
  DateTime? validTill;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _customerSearchFocusNode = FocusNode();
  bool _customerSelected = false;
  String? _searchCustomerName;
  String? _selectedCustomer;
  final TextEditingController _itemSearchController = TextEditingController();
  bool _itemSelected = false;
  String? _currency;
  bool _isPrefilled = false;
  String? existingQuotationName;
  bool _isEditMode = false;
  // String? quotationName;
  double? _quotationTotal;
  bool _isFormDirty = false;
  bool get isFormDirty => _isFormDirty;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();
  final FocusNode _itemSearchFocusNode = FocusNode();
  bool get isEditMode => _isEditMode;
  String? get quotationName => existingQuotationName;
  bool isUpdating = false;




  @override
  void initState() {
    super.initState();
    transactionDate = DateTime.now();
    validTill = DateTime.now().add(const Duration(days: 1));
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.clearItem();
    clearForm();
  }

  Future<void> _searchCustomer(String customer) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.searchCustomer(customer, context);
    } catch (e) {
      debugPrint('Error searching customer: $e');
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
@override
void dispose() {
_hideOverlay();
  super.dispose();
}
  Future<void> _pickDate(BuildContext context, bool isTransactionDate) async {
    final initialDate = isTransactionDate
        ? (transactionDate ?? DateTime.now())
        : (validTill ?? DateTime.now().add(const Duration(days: 1)));

    final firstDate = isTransactionDate
        ? DateTime(2020)
        : (transactionDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isTransactionDate) {
          // 🟡 Check if the user actually changed the date
          if (transactionDate == null ||
              picked.difference(transactionDate!).inDays != 0) {
            transactionDate = picked;
            _isFormDirty = true; // ✅ Mark form dirty when changed
          }

          // ⏩ Ensure validTill is not before transactionDate
          if (validTill != null && validTill!.isBefore(transactionDate!)) {
            validTill = transactionDate!.add(const Duration(days: 1));
            _isFormDirty = true; // ✅ Also mark dirty if validTill auto-adjusts
          }
        } else {
          if (picked.isBefore(transactionDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Valid Till date cannot be before the Transaction Date."),
              ),
            );
          } else {
            // 🟡 Mark dirty only if user picked a new validTill date
            if (validTill == null ||
                picked.difference(validTill!).inDays != 0) {
              validTill = picked;
              _isFormDirty = true; // ✅ Mark dirty
            }
          }
        }
      });
    }
  }


  void clearForm() {
    _formKey.currentState?.reset();

    _customerSearchController.clear();
    customerController.clear();
    itemController.clear();
    _searchController.clear();
    _itemSearchController.clear();

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.clearItem();
    provider.clearItemSearch();

    setState(() {
      transactionDate = DateTime.now();
      validTill = DateTime.now().add(const Duration(days: 1));

      _selectedItem = null;
      _selectedCustomer = null;
      _searchCustomerName = null;
      _customerSelected = false;
      _itemSelected = false;
      _currency = null;

      _isPrefilled = false;
      _isEditMode = false;
      existingQuotationName = null;
      _quotationTotal = null;
      _isFormDirty = false;
    });
  }


  Future<void> submitQuotation() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    if (transactionDate == null || validTill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both dates')),
      );
      return;
    }

    if (_searchCustomerName == null || _searchCustomerName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (provider.customerDetail == null) {
      await provider.fetchCustomerDetailss(_searchCustomerName!, context);
    }

    final itemsList = provider.itemsList;
    if (itemsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final quotationItems = itemsList.map((item) {
      return {
        "item_code": item.itemCode ?? "",
        "item_name": item.name ?? "",
        "qty": item.quantity ?? 1,
        "price_list_rate": item.priceListRate ?? 0.0,
        "rate": item.rate,
        "discount_percentage": item.discountPercentage ?? 0.0,
      };
    }).toList();
    debugPrint("📦 Quotation Items Sent To API: $quotationItems");
    final fetchedItemDetails = <Map<String, dynamic>>[];
    for (final item in itemsList) {
      final details = await provider.fetchItemDetail(
        context: context,
        itemCode: item.itemCode ?? '',
        currency: provider.customerDetail?["customer_currency"] ?? "INR",
        quantity: item.quantity ?? 1.0,
        customerName: _searchCustomerName!,
      );
      if (details != null && details["message"] != null) {
        fetchedItemDetails.add(details["message"]);
      }
    }

    bool success = false;

    if (_isEditMode && existingQuotationName != null) {
      isUpdating = true;
      // ✅ UPDATE existing quotation
      success = await provider.updateQuotation(
        quotationName: existingQuotationName!,
        partyName: _searchCustomerName!,
        transactionDate: DateFormat('yyyy-MM-dd').format(transactionDate!),
        validTill: DateFormat('yyyy-MM-dd').format(validTill!),
        items: quotationItems,
        context: context,
        customerDetails: provider.customerDetail!,
        itemDetails: fetchedItemDetails,
      );
    } else {
      // ✅ CREATE new quotation
      final res = await provider.createQuotationWithDetails(
        partyName: _searchCustomerName!,
        transactionDate: DateFormat('yyyy-MM-dd').format(transactionDate!),
        validTill: DateFormat('yyyy-MM-dd').format(validTill!),
        items: quotationItems,
        context: context,
        customerDetails: provider.customerDetail!,
        itemDetails: fetchedItemDetails,
      );
      if (res?.data?.name != null) {
        setState(() {
          existingQuotationName = res!.data!.name;
          _isEditMode = true;
          _isFormDirty = false;
        });
        success = true;
      } else {
        success = false;
      }
      // success = res != null;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdating
              ? 'Quotation updated successfully!'
              : 'Quotation created successfully!'),

        ),
      );
      FocusScope.of(context).unfocus();

      setState(() {
        _isFormDirty = false; // mark clean
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.errorMessage ?? 'Failed'}')),
      );
    }
  }


  void _showAddItemDialog({
    required String itemName,
    required String itemCode,
    required double rate,
    required double quantity,
    required double priceListRate,
    required double discountPercentage,
    required String itemTaxTemplate,
    required double lastPurchaseRate, // ✅ NEW
    String uom = '',   // 👇 new
    double availableQty = 0.0,
    VoidCallback? onCa
  }) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        itemName: itemName,
        itemCode: itemCode,
        rate: rate,
        quantity: quantity,
        priceListRate: priceListRate,
        discountPercentage: discountPercentage,
        itemTaxTemplate: itemTaxTemplate,
        lastPurchaseRate: lastPurchaseRate, // ✅ NEW
        uom: uom,           // 👇 pass it down
        availableQty: availableQty,
        onCancel: () {},
        onItemAdded: (addedRate, addedQty) {
          final double addedAmount = addedRate * addedQty;
          Provider.of<SalesOrderProvider>(context, listen: false)
              .addToTotal(addedAmount);
          setState(() {
            _isFormDirty = true;
          });
        },
      ),
    );
  }

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
    final uom = item.uom?.isNotEmpty == true    // 👈 add this
        ? item.uom!
        : (message?["uom"] ?? message?["stock_uom"] ?? '');
    // ✅ Fetch available qty for this item
    final qtyMap = await provider.fetchItemActualQty(item.itemCode);  // or your API service call
    final actualQty = qtyMap['${item.itemCode}__actual'] ?? 0.0;
    final reservedQty = qtyMap['${item.itemCode}__reserved'] ?? 0.0;
    final availableQty = actualQty - reservedQty;
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
        isEdit: true, // ✅ IMPORTANT
        editIndex: index,
        onCancel: onCancel,
        uom: uom,
        availableQty: availableQty,
        onItemAdded: (rate, qty) {
          setState(() {
            _isFormDirty = true;
          });
        },
      ),
    );
  }

  void prefillQuotationForm(Map<String, dynamic> data) {
    setState(() {
      _isEditMode = true; // ✅ mark as update mode
      existingQuotationName = data["name"]; // save quotation name for PUT
      // quotationName = data["name"];
      final num? netTotal = data["net_total"];
      final num? total = data["total"];
      _quotationTotal = (netTotal ?? total ?? 0).toDouble();
      // Existing prefill logic
      final customerName = data["party_name"] ?? '';
      _customerSearchController.text = customerName;
      customerController.text = customerName;
      _searchCustomerName = customerName;
      _selectedCustomer = customerName;
      _customerSelected = true;
      _isPrefilled = true;

      transactionDate = DateTime.tryParse(data["transaction_date"] ?? '') ?? DateTime.now();
      validTill = DateTime.tryParse(data["valid_till"] ?? '') ?? DateTime.now().add(const Duration(days: 1));
      _currency = data["currency"] ?? 'INR';

      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      provider.clearItem();

      if (data["items"] != null) {
        final itemsList = (data["items"] as List).map((item) => {
          "item_code": item["item_code"],
          "item_name": item["item_name"],
          "qty": item["qty"],
          "price_list_rate": item["price_list_rate"],
          "rate": item["rate"],
          "discount_percentage": item["discount_percentage"] ?? 0.0,
          "uom": item["uom"] ?? item["stock_uom"] ?? '',   // 👈 add this

        }).toList();

        provider.setItemsFromQuotation(itemsList);
      }

      FocusScope.of(context).unfocus();
    });
  }
  void _showOverlay(BuildContext context, List items) {
    _hideOverlay(); // remove any old overlay

    if (items.isEmpty) return;

    final RenderBox renderBox =
    _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
      // 👇 This invisible full-screen layer catches outside taps
      Positioned.fill(
      child: GestureDetector(
      behavior: HitTestBehavior.translucent,
        onTap: _hideOverlay, // hide overlay when tapping anywhere else
      ),
    ),

    // 👇 The actual dropdown positioned below the search box
    Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: GestureDetector(
              // 👇 Prevent taps inside overlay from closing it
              behavior: HitTestBehavior.translucent,
              onTap: () {},
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ListTile(
                    title: Text(item.itemName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.itemCode ?? '',
                        style: const TextStyle(color: Colors.grey)),
                    // trailing: Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    //   decoration: BoxDecoration(
                    //     color: (item.actualQty ?? 0) > 0
                    //         ? Colors.green.shade50
                    //         : Colors.red.shade50,
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: (item.actualQty ?? 0) > 0
                    //           ? Colors.green.shade300
                    //           : Colors.red.shade300,
                    //     ),
                    //   ),
                    //   child: Text(
                    //     'Qty: ${(item.actualQty ?? 0).toStringAsFixed(0)}',
                    //     style: TextStyle(
                    //       fontSize: 11,
                    //       fontWeight: FontWeight.w600,
                    //       color: (item.actualQty ?? 0) > 0
                    //           ? Colors.green.shade700
                    //           : Colors.red.shade700,
                    //     ),
                    //   ),
                    // ),
                    trailing: Builder(
                      builder: (context) {
                        final actual = item.actualQty ?? 0;
                        final reserved = item.reservedQty ?? 0;
                        final available = actual - reserved;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Actual Qty badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                'Actual: ${actual.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Available Qty badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: available > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: available > 0 ? Colors.green.shade300 : Colors.red.shade300,
                                ),
                              ),
                              child: Text(
                                'Avail: ${available.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: available > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    onTap: () async {
                      _hideOverlay();

                      final quotationProvider =
                      Provider.of<SalesOrderProvider>(context, listen: false);

                      if (quotationProvider.allowMultipleItems == 0) {
                        bool alreadyExists = quotationProvider.itemsList.any(
                              (i) => i.itemCode == item.itemCode,
                        );
                        if (alreadyExists) {
                          Fluttertoast.showToast(
                            msg: "This item is already added and duplicates are not allowed.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          return;
                        }
                      }

                      setState(() {
                        _selectedItem = item.itemName;
                        _itemSelected = true;
                      });

                      try {
                        final itemDetails = await quotationProvider.fetchItemDetail(
                          context: context,
                          itemCode: item.itemCode ?? '',
                          currency: _currency ?? '',
                          quantity: 1.0,
                          customerName: _selectedCustomer ?? '',
                        );

                        if (itemDetails != null && itemDetails['message'] != null) {
                          final fetchedRate = itemDetails['message']['rate'] ?? 0.0;
                          final fetchedPriceListRate =
                              itemDetails['message']['price_list_rate'] ?? 0.0;
                          final fetchedDiscountPercentage =
                              itemDetails['message']['discount_percentage'] ?? 0.0;
                          final message = itemDetails["message"];
                          final lastPurchaseRate =
                              itemDetails['message']['last_purchase_rate'] ?? 0.0;

                          _showAddItemDialog(
                            itemName: item.itemName ?? "",
                            itemCode: item.itemCode ?? "",
                            rate: fetchedPriceListRate,
                            quantity: 1,
                            priceListRate: fetchedPriceListRate,
                            discountPercentage: fetchedDiscountPercentage,
                            itemTaxTemplate: message["item_tax_template"] ?? "",
                            lastPurchaseRate: lastPurchaseRate,
                            uom: message["uom"] ?? "",   // 👇 new
                            availableQty: (item.actualQty ?? 0) - (item.reservedQty ?? 0),

                          );
                        } else {
                          Fluttertoast.showToast(msg: "Select Customer first");
                        }
                      } catch (e) {
                        Fluttertoast.showToast(msg: "Error fetching item details: $e");
                      }

                      setState(() {
                        _itemSearchController.clear();
                        _itemSelected = false;
                        _selectedItem = null;
                      });

                      await Future.delayed(const Duration(milliseconds: 200));
                      _itemSearchFocusNode.requestFocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ]));

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  void hideSearchOverlay() {
    _hideOverlay();
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<SalesOrderProvider>(context);
    final items = provider.itemListModel?.data ?? [];

    final customerList =
        provider.customerSearchModel?.data ?? []; // ✅ Get customer list safely

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧾 Quotation Header (shows Quotation Name and Live Total)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        existingQuotationName ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer<SalesOrderProvider>(
                      builder: (context, provider, _) {
                        double total = provider.totalItemAmount;
                        return Text(
                          "₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🆕 SOLUTION: Wrap everything in Expanded to prevent overflow
              Expanded(
                child: SingleChildScrollView(
                  // 🆕 Disable scroll when keyboard is open and search results shown
                  physics: (!_customerSelected &&
                      customerList.isNotEmpty &&
                      _customerSearchFocusNode.hasFocus)
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔍 Customer Search
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          focusNode: _customerSearchFocusNode,
                          controller: _customerSearchController,
                          readOnly: _isPrefilled, // ✅ disable editing when prefilled
                          decoration: InputDecoration(
                            hintText: 'Search Customer',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: !_isPrefilled && _customerSearchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _customerSearchController.clear();
                                  _customerSelected = false;
                                  _selectedCustomer = null;
                                  _searchCustomerName = null;
                                });
                                provider.clearCustomerSearch();
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: _isPrefilled
                              ? null // ✅ disable search callback
                              : (content) {
                            if (content.isEmpty) {
                              setState(() {
                                _customerSelected = false;
                                _selectedCustomer = null;
                                _searchCustomerName = null;
                              });
                              provider.clearCustomerSearch();
                            } else {
                              setState(() => _customerSelected = false);
                              _searchCustomer(content);
                            }
                          },
                        ),
                      ),

                      // 👇 Compact search result list - 🆕 FIXED with flexible height
                      if (!_customerSelected &&
                          customerList.isNotEmpty &&
                          _customerSearchFocusNode.hasFocus)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // 🆕 Use flexible constraints based on available space
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.25, // 25% of screen
                            minHeight: 50,
                          ),
                          child: ListView.builder(
                            itemCount: customerList.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final Data customer = customerList[index];
                              return InkWell(
                                onTap: () async {
                                  setState(() {
                                    _selectedCustomer = customer.name;
                                    _searchCustomerName = customer.customerName;
                                    _customerSelected = true;
                                    _customerSearchController.text = customer.customerName ?? '';
                                  });

                                  FocusScope.of(context).unfocus(); // hide keyboard

                                  // ✅ Fetch customer details
                                  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                                  await provider.fetchCustomerDetailss(customer.customerName ?? '', context);
                                  final customerData = provider.customerDetail;
                                  _currency = customerData?["customer_currency"] ?? "INR";
                                  // Optionally, show a confirmation/snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Customer details fetched successfully')),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8),
                                  child: Text(
                                    customer.customerName ?? '',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 10),
                      // 🗓️ Date and Valid Till Row
                      Row(
                        children: [
                          // Transaction Date
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Date: ${DateFormat('dd-MM-yyyy').format(transactionDate!)}",
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Valid Till
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Valid Till: ${DateFormat('dd-MM-yyyy').format(validTill!)}",
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 🧭 Item Search TextField

                      CompositedTransformTarget(
                        link: _layerLink,
                        child: Container(
                          key: _textFieldKey,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            focusNode: _itemSearchFocusNode,
                            controller: _itemSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search Item',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _itemSearchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _itemSearchController.clear();
                                    _itemSelected = false;
                                    _selectedItem = null;
                                  });
                                  _hideOverlay();
                                  Provider.of<SalesOrderProvider>(context, listen: false)
                                      .clearItemSearch();
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (query) async {
                              if (query.isEmpty) {
                                setState(() {
                                  _itemSelected = false;
                                  _selectedItem = null;
                                });
                                _hideOverlay();
                                Provider.of<SalesOrderProvider>(context, listen: false)
                                    .clearItemSearch();
                              } else {
                                await _searchItemList(query);
                                final provider =
                                Provider.of<SalesOrderProvider>(context, listen: false);
                                _showOverlay(context, provider.itemListModel?.data ?? []);
                              }
                            },
                            onEditingComplete: () => _itemSearchFocusNode.unfocus(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ✅ Enhanced Items List (Fixed Overflow)
                      // 🆕 Use ConstrainedBox instead of Expanded inside SingleChildScrollView
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 200,
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: Consumer<SalesOrderProvider>(
                          builder: (context, itemProvider, child) {
                            final itemList = itemProvider.itemsList;

                            if (itemProvider.isLoadingItem) {
                              return const Center(child: CircularProgressIndicator());
                            }

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

                            return ListView.builder(
                              itemCount: itemList.length,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), // 🆕 Disable inner scroll
                              itemBuilder: (context, index) {
                                final item = itemList[index];
                                final double discount = item.discountPercentage ?? 0.0;

                                // ✅ item.rate already contains discounted price
                                final double amount = item.rate * item.quantity;

                                // ✅ original amount before discount
                                final double originalAmount =
                                    (item.priceListRate ?? item.rate) * item.quantity;
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[200]!, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _showEditDialog(context, index, itemProvider, () {
                                        setState(() {
                                          _selectedItem = null;
                                        });
                                        _itemSearchController.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Serial Number Badge
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

                                          // Item Details (Flexible)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Item Name
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),

                                                // Item Code
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    item.itemCode,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // Quantity and Rate
                                                // Text(
                                                //   '${item.quantity} × ₹${item.rate.toStringAsFixed(2)}',
                                                //   style: TextStyle(
                                                //     fontSize: 11,
                                                //     color: Colors.grey[600],
                                                //   ),
                                                // ),
                                                // Quantity and Rate
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${item.quantity} × ₹${item.rate.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    if (item.uom != null && item.uom!.isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue[50],
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          item.uom!,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.blue[700],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
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

                                          // Amount and Delete Button (Fixed width)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Amount
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
                                              const SizedBox(height: 2),

                                              // Delete Button
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
                                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to delete '${item.name}'?",
                                                        style: const TextStyle(fontSize: 15),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text("Cancel",
                                                              style: TextStyle(color: Colors.blueAccent)),
                                                        ),
                                                        ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.redAccent,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          onPressed: () => Navigator.pop(context, true),
                                                          icon: const Icon(Icons.delete_forever, size: 18),
                                                          label: const Text("Delete"),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    final double deletedAmount = item.rate * item.quantity;
                                                    itemProvider.deleteItem(index);
                                                    itemProvider.subtractFromTotal(deletedAmount);
                                                    setState(() {
                                                      _isFormDirty = true;
                                                    });

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "'${item.name}' deleted successfully.",
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                        backgroundColor: Colors.redAccent,
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: Colors.red[400],
                                                  ),
                                                ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class AddItemDialog extends StatefulWidget {
  final String itemName;
  final String itemCode;
  final VoidCallback onCancel;
  final double rate;
  final double quantity;
  final double priceListRate;
  final double discountPercentage;
  final String itemTaxTemplate;
  final Function(double rate, double quantity)? onItemAdded; // ✅ NEW
  final double lastPurchaseRate; // ✅ NEW
  final bool isEdit;
  final int? editIndex;
  final String uom;             // 👇 new
  final double availableQty;

  const AddItemDialog({
    super.key,
    required this.itemName,
    required this.itemCode,
    required this.onCancel,
    required this.itemTaxTemplate,
    this.rate = 0.0,
    this.quantity = 1.0,
    this.priceListRate = 0.0,
    this.discountPercentage = 0.0,
    this.onItemAdded, // ✅ NEW
    this.lastPurchaseRate = 0.0, // ✅ NEW
    this.isEdit = false,
    this.editIndex,
    this.uom = '',              // 👇 new
    this.availableQty = 0.0,

  });

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late TextEditingController _rateController;
  late TextEditingController _quantityController;
  late TextEditingController _priceListRateController;
  late TextEditingController _discountPercentageController;
  late FocusNode _quantityFocusNode;
  late TextEditingController _itemTaxTemplateController;
  double _totalAmount = 0.0;
  late TextEditingController _totalController;
  bool _isUpdatingFromTotal = false;
  late FocusNode _totalFocusNode;
  late FocusNode _rateFocusNode;
  late FocusNode _priceListRateFocusNode;
  late FocusNode _discountFocusNode;
  double _baseRate = 0.0;
  bool _isUpdatingDiscount = false;
  bool _qtyExceedsAvailable = false;

  @override
  void initState() {
    super.initState();
    _baseRate = widget.priceListRate > 0
        ? widget.priceListRate
        : widget.rate;
    _rateController = TextEditingController(text: widget.rate.toStringAsFixed(3));
    _quantityController = TextEditingController(text: widget.quantity.toStringAsFixed(2));
    _priceListRateController = TextEditingController(text: widget.priceListRate.toStringAsFixed(3));
    _discountPercentageController = TextEditingController(text: widget.discountPercentage.toStringAsFixed(2));
    _totalController = TextEditingController();
    _itemTaxTemplateController =
        TextEditingController(text: widget.itemTaxTemplate);
    _quantityFocusNode = FocusNode();
    _rateFocusNode = FocusNode();
    _totalFocusNode = FocusNode();
    _priceListRateFocusNode = FocusNode();
    _discountFocusNode = FocusNode();

    _calculateTotal();
    _quantityController.addListener(_calculateTotal);

    _discountPercentageController.addListener(() {
      _applyDiscountCalculation();
    });

    _priceListRateController.addListener(() {
      if (_priceListRateFocusNode.hasFocus) {

        _baseRate =
            double.tryParse(_priceListRateController.text) ?? 0.0;

        _applyDiscountCalculation();
      }
    });
    // _rateController.addListener(_calculateTotal);
    _quantityController.addListener(_calculateTotal);
    _totalController.addListener(_updateRateFromTotal);

    // Add listeners for focus auto-selection
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        _quantityController.selection = TextSelection(baseOffset: 0, extentOffset: _quantityController.text.length);
      }
    });
// Auto-select text on focus
    _priceListRateFocusNode.addListener(() {
      if (_priceListRateFocusNode.hasFocus) {
        _priceListRateController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _priceListRateController.text.length,
        );
      }
    });
    _rateFocusNode.addListener(() {
      if (_rateFocusNode.hasFocus) {
        _rateController.selection = TextSelection(baseOffset: 0, extentOffset: _rateController.text.length);
      }
    });

    _totalFocusNode.addListener(() {
      if (_totalFocusNode.hasFocus) {
        _totalController.selection = TextSelection(baseOffset: 0, extentOffset: _totalController.text.length);
      }
    });
    _discountFocusNode.addListener(() {
      if (_discountFocusNode.hasFocus) {
        _discountPercentageController.selection = TextSelection(baseOffset: 0, extentOffset: _discountPercentageController.text.length);
      }
    });
  }
  void _applyDiscountCalculation() {
    if (_isUpdatingDiscount) return;

    final discount =
        double.tryParse(_discountPercentageController.text) ?? 0.0;

    final discountedRate =
        _baseRate - ((_baseRate * discount) / 100);

    _isUpdatingDiscount = true;

    /// Prevent cursor jump while typing rate
    if (!_rateFocusNode.hasFocus) {
      _rateController.text =
          discountedRate.toStringAsFixed(3);
    }

    _isUpdatingDiscount = false;

    _calculateTotal();
  }

  void _calculateTotal() {
    if (_isUpdatingFromTotal) return;

    final rate =
        double.tryParse(_rateController.text) ?? 0;

    final quantity =
        double.tryParse(_quantityController.text) ?? 0;

    final total = rate * quantity;

    setState(() {
      _totalAmount = total;
      _totalController.text = total.toStringAsFixed(3);
      _qtyExceedsAvailable = quantity > widget.availableQty;
    });
  }
  void _updateRateFromTotal() {
    if (!_totalFocusNode.hasFocus) return;

    final total = double.tryParse(_totalController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final discount =
        double.tryParse(_discountPercentageController.text) ?? 0;

    if (quantity <= 0) return;

    double effectiveRate = total / quantity;

    if (discount > 0) {
      effectiveRate = effectiveRate / (1 - discount / 100);
    }

    _isUpdatingFromTotal = true;
    _rateController.text = effectiveRate.toStringAsFixed(3);
    _priceListRateController.text = effectiveRate.toStringAsFixed(3);
    _isUpdatingFromTotal = false;
  }



  @override
  void dispose() {
    _rateController.removeListener(_calculateTotal);
    _quantityController.removeListener(_calculateTotal);
    _totalController.removeListener(_updateRateFromTotal);
    _priceListRateController.removeListener(() {});
    _itemTaxTemplateController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    _priceListRateController.dispose();
    _discountPercentageController.dispose();
    _totalController.dispose();

    _quantityFocusNode.dispose();
    _rateFocusNode.dispose();
    _totalFocusNode.dispose();
    _discountFocusNode.dispose();
    _priceListRateFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.itemName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: " (${widget.itemCode})",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
            if (widget.uom.isNotEmpty)
              TextSpan(
                text: " · ${widget.uom}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Read-only info chips ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _infoChip(
                    label: 'Tax Template',
                    value: widget.itemTaxTemplate.isNotEmpty
                        ? widget.itemTaxTemplate
                        : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoChip(
                    label: 'Last Purchase Rate',
                    value: '₹${widget.lastPurchaseRate.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Price List Rate + Discount ──────────────────────
            Row(
              children: [
                Expanded(
                  child: _compactField(
                    controller: _priceListRateController,
                    focusNode: _priceListRateFocusNode,
                    label: 'Price List Rate',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactField(
                    controller: _discountPercentageController,
                    focusNode: _discountFocusNode,
                    label: 'Discount %',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Rate + Quantity ─────────────────────────────────
            // Row(
            //   children: [
            //     Expanded(
            //       child: _compactField(
            //         controller: _rateController,
            //         focusNode: _rateFocusNode,
            //         label: 'Rate',
            //       ),
            //     ),
            //     const SizedBox(width: 8),
            //     Expanded(
            //       child: _compactField(
            //         controller: _quantityController,
            //         focusNode: _quantityFocusNode,
            //         label: 'Quantity',
            //       ),
            //     ),
            //   ],
            // ),
            Row(
              children: [
                Expanded(
                  child: _compactField(
                    controller: _rateController,
                    focusNode: _rateFocusNode,
                    label: 'Rate',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(                              // ✅ wrap in Column
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _compactField(
                        controller: _quantityController,
                        focusNode: _quantityFocusNode,
                        label: 'Quantity',
                      ),
                      if (_qtyExceedsAvailable)              // ✅ warning row
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 13, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Exceeds available (${widget.availableQty.toStringAsFixed(0)})',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Total (full width) ──────────────────────────────
            _compactField(
              controller: _totalController,
              focusNode: _totalFocusNode,
              label: 'Total',
              readOnly: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final rate = double.tryParse(_rateController.text) ?? 0.0;
            final quantity = double.tryParse(_quantityController.text) ?? 0;
            final priceListRate = double.tryParse(_priceListRateController.text) ?? 0.0;
            final discountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;

            if (rate <= 0) {
              Fluttertoast.showToast(msg: "Please enter a valid rate");
            } else if (quantity <= 0) {
              Fluttertoast.showToast(msg: "Please enter a valid quantity");
            } else {
              final provider = Provider.of<SalesOrderProvider>(context, listen: false);
              if (widget.isEdit && widget.editIndex != null) {
                provider.editItem(
                  widget.editIndex!,
                  rate,
                  quantity,
                  priceListRate,
                  discountPercentage,
                );
              } else {
                provider.addItem(
                  rate,
                  quantity,
                  widget.itemName,
                  widget.itemCode,
                  priceListRate,
                  discountPercentage,
                  widget.itemTaxTemplate,
                  widget.lastPurchaseRate,
                  uom: widget.uom,
                );
              }
              widget.onItemAdded?.call(rate, quantity);
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

// ── Helpers ────────────────────────────────────────────────────

  Widget _infoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _compactField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}