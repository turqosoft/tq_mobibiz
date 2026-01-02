import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
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
  String? _existingQuotationName;
  bool _isEditMode = false;
  String? quotationName;
  double? _quotationTotal;
  bool _isFormDirty = false;
  bool get isFormDirty => _isFormDirty;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();
  final FocusNode _itemSearchFocusNode = FocusNode();



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
    // Clear all text controllers
    _customerSearchController.clear();
    customerController.clear();
    itemController.clear();
    _searchController.clear();
    _itemSearchController.clear();
    quotationName = null;
    _quotationTotal = null;
    _isPrefilled = false;
    _isEditMode = false;
    _existingQuotationName = null;
    // Reset selection flags and names
    _selectedItem = null;
    _selectedCustomer = null;
    _searchCustomerName = null;
    _customerSelected = false;
    _itemSelected = false;
    _currency = null;
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    provider.clearItemSearch();
    provider.clearItem();
    // Reset dates
    transactionDate = DateTime.now();
    validTill = DateTime.now().add(const Duration(days: 1));

    // Rebuild UI
    setState(() {});
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
        "rate": item.rate ?? item.priceListRate ?? 0.0,
        "discount_percentage": item.discountPercentage ?? 0.0,
      };
    }).toList();

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

    if (_isEditMode && _existingQuotationName != null) {
      // ✅ UPDATE existing quotation
      success = await provider.updateQuotation(
        quotationName: _existingQuotationName!,
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
      success = res != null;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Quotation updated successfully!'
              : 'Quotation created successfully!'),
        ),
      );
      FocusScope.of(context).unfocus();

      _formKey.currentState?.reset();
      provider.clearItem();
      clearForm();

      setState(() {
        _isEditMode = false;
        _existingQuotationName = null;
        _isPrefilled = false;
        _isFormDirty = false;
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
      SalesOrderProvider provider, final VoidCallback onCancel) {
    final item = provider.itemsList[index];
    final _rateController = TextEditingController(text: item.rate.toString());
    final _quantityController = TextEditingController(text: item.quantity.toString());
    final _priceListRateController = TextEditingController(text: item.priceListRate?.toString() ?? '');
    final _discountPercentageController = TextEditingController(text: item.discountPercentage?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Item: ${item.name}'),
                TextField(
                  controller: _priceListRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Price List Rate'),
                  readOnly: true,
                ),
                TextField(
                  readOnly: true,
                  controller: _discountPercentageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Discount Percentage'),
                ),
                TextField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Rate'),
                ),



                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newRate = double.tryParse(_rateController.text) ?? 0.0;
                final newQuantity = double.tryParse(_quantityController.text) ?? 0.0;
                final newPriceListRate = double.tryParse(_priceListRateController.text) ?? 0.0;
                final newDiscountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;

                if (newRate <= 0) {
                  Fluttertoast.showToast(msg: "Please enter a valid rate");
                } else if (newQuantity <= 0) {
                  Fluttertoast.showToast(msg: "Please enter a valid quantity");
                } else {
                  final provider = Provider.of<SalesOrderProvider>(context, listen: false);

                  // 🧮 Compute difference
                  final oldAmount = item.rate * item.quantity;
                  final newAmount = newRate * newQuantity;
                  final diff = newAmount - oldAmount;

                  // ✅ Update the item
                  provider.editItem(index, newRate, newQuantity, newPriceListRate, newDiscountPercentage);

                  // ✅ Update total globally
                  if (diff != 0) {
                    if (diff > 0) {
                      provider.addToTotal(diff);
                    } else {
                      provider.subtractFromTotal(diff.abs());
                    }
                  }
                  // 🟡 Mark form dirty after editing
                  setState(() {
                    _isFormDirty = true;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),

            TextButton(
              onPressed: () {
                onCancel();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void prefillQuotationForm(Map<String, dynamic> data) {
    setState(() {
      _isEditMode = true; // ✅ mark as update mode
      _existingQuotationName = data["name"]; // save quotation name for PUT
      quotationName = data["name"];
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
        final itemsList = (data["items"] as List)
            .map((item) => {
          "item_code": item["item_code"],
          "item_name": item["item_name"],
          "qty": item["qty"],
          "price_list_rate": item["price_list_rate"],
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

    // _overlayEntry = OverlayEntry(
    //   builder: (context) => Positioned(
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
                          final fetchedRate = itemDetails['message']['price_list_rate'] ?? 0.0;
                          final fetchedDiscountPercentage =
                              itemDetails['message']['discount_percentage'] ?? 0.0;

                          _showAddItemDialog(
                            itemName: item.itemName ?? "",
                            itemCode: item.itemCode ?? "",
                            rate: fetchedRate,
                            quantity: 1,
                            priceListRate: fetchedRate,
                            discountPercentage: fetchedDiscountPercentage,
                          );
                        } else {
                          Fluttertoast.showToast(msg: "Select Customer first");
                        }
                      } catch (e) {
                        Fluttertoast.showToast(msg: "Error fetching item details: $e");
                      }

                      // 👇 reset and refocus for next entry
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
//             if (_quotationName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quotationName ?? '',
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

            // 👇 Compact search result list
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
                constraints: const BoxConstraints(maxHeight: 115),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 8),
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
                              overflow: TextOverflow.ellipsis, // ⛔ no overflow
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
                              overflow: TextOverflow.ellipsis, // ⛔ no overflow
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
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: TextField(
//                 controller: _itemSearchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search Item',
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon: _itemSearchController.text.isNotEmpty
//                       ? IconButton(
//                     icon: const Icon(Icons.clear),
//                     onPressed: () {
//                       setState(() {
//                         _itemSearchController.clear();
//                         _itemSelected = false;
//                         _selectedItem = null;
//                       });
//                       Provider.of<SalesOrderProvider>(context, listen: false)
//                           .clearItemSearch();
//                     },
//                   )
//                       : null,
//                   border: InputBorder.none,
//                   contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                 ),
//                 onChanged: (content) {
//                   if (content.isEmpty) {
//                     setState(() {
//                       _itemSelected = false;
//                       _selectedItem = null;
//                     });
//                     Provider.of<SalesOrderProvider>(context, listen: false)
//                         .clearItemSearch();
//                   } else {
//                     setState(() {
//                       _itemSelected = false;
//                     });
//                     _searchItemList(_itemSearchController.text);
//                   }
//                 },
//                 onSubmitted: (query) {
//                   if (query.trim().isEmpty) {
//                     setState(() {
//                       _itemSelected = false;
//                       _selectedItem = null;
//                     });
//                     Provider.of<SalesOrderProvider>(context, listen: false)
//                         .clearItemSearch();
//                     return;
//                   }
//
//                   setState(() {
//                     _itemSelected = false;
//                   });
//                   _searchItemList(query.trim());
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
// // 🧭 Item Search Results List
//             if (!_itemSelected && items.isNotEmpty)
//               SizedBox(
//                 height: 115,
//                 child: ListView.builder(
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     final item = items[index];
//                     return RadioListTile<String>(
//                       title: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(item.itemName ?? '',
//                               style: const TextStyle(fontWeight: FontWeight.bold)),
//                           const SizedBox(height: 4),
//                           Text(item.itemCode ?? '', style: const TextStyle(color: Colors.grey)),
//                         ],
//                       ),
//                       value: item.itemName ?? '',
//                       groupValue: _selectedItem,
//                       onChanged: (selected) async {
//
//                         if (selected != null) {
//                           final quotationProvider =
//                           Provider.of<SalesOrderProvider>(context, listen: false);
//
//                           // ✅ Prevent duplicates if not allowed
//                           if (quotationProvider.allowMultipleItems == 0) {
//                             bool alreadyExists = quotationProvider.itemsList.any(
//                                   (i) => i.itemCode == item.itemCode,
//                             );
//
//                             if (alreadyExists) {
//                               Fluttertoast.showToast(
//                                 msg: "This item is already added and duplicates are not allowed.",
//                                 toastLength: Toast.LENGTH_SHORT,
//                                 gravity: ToastGravity.BOTTOM,
//                               );
//                               return; // stop here
//                             }
//                           }
//
//                           setState(() {
//                             _selectedItem = selected;
//                             _itemSelected = true;
//                             _itemSearchController.clear();
//                           });
//
//                           try {
//                             final itemDetails = await quotationProvider.fetchItemDetail(
//                               context: context,
//                               itemCode: item.itemCode ?? '',
//                               currency: _currency ?? '',
//                               quantity: 1.0,
//                               customerName: _selectedCustomer ?? '',
//                             );
//
//                             if (itemDetails != null && itemDetails['message'] != null) {
//                               final fetchedRate = itemDetails['message']['price_list_rate'] ?? 0.0;
//                               final fetchedDiscountPercentage =
//                                   itemDetails['message']['discount_percentage'] ?? 0.0;
//
//                               _showAddItemDialog(
//                                 itemName: item.itemName ?? "",
//                                 itemCode: item.itemCode ?? "",
//                                 rate: fetchedRate,
//                                 quantity: 1,
//                                 priceListRate: fetchedRate,
//                                 discountPercentage: fetchedDiscountPercentage,
//                               );
//                             } else {
//                               Fluttertoast.showToast(msg: "Select Customer first");
//                             }
//                           } catch (e) {
//                             Fluttertoast.showToast(msg: "Error fetching item details: $e");
//                           }
//                         }
//
//
//                       },
//                     );
//                   },
//                 ),
//               ),
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
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  // ❌ remove onTapOutside to prevent unwanted closing
                ),
              ),
            ),


            const SizedBox(height: 10),

// ✅ Added Items List
            Expanded(
              child: Consumer<SalesOrderProvider>(
                builder: (context, itemProvider, child) {
                  final itemList = itemProvider.itemsList;

                  if (itemProvider.isLoadingItem) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (itemList.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: itemList.length,
                    itemBuilder: (context, index) {
                      final item = itemList[index];

                      return InkWell(
                          onTap: () {
                        _showEditDialog(context, index, itemProvider, () {
                          setState(() {
                            _selectedItem = null;
                          });
                          _itemSearchController.clear();
                        });
                      },
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                      '${index + 1}. ',
                      style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      ),
                      ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.name} (${item.itemCode})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Rate: ${item.rate}, Quantity: ${item.quantity}, '
                                        'Amount: ${(item.rate * item.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),

                            // 🗑 Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
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
                                    _isFormDirty = true; // 🟡 Mark dirty after deletion
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
                            ),
                          ],
                        ),
                      ));
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    ));
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
  final Function(double rate, double quantity)? onItemAdded; // ✅ NEW

  const AddItemDialog({
    super.key,
    required this.itemName,
    required this.itemCode,
    required this.onCancel,
    this.rate = 0.0,
    this.quantity = 1.0,
    this.priceListRate = 0.0,
    this.discountPercentage = 0.0,
    this.onItemAdded, // ✅ NEW

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
  double _totalAmount = 0.0;
  late TextEditingController _totalController;
  bool _isUpdatingFromTotal = false;
  late FocusNode _totalFocusNode;
  late FocusNode _rateFocusNode;
  late FocusNode _priceListRateFocusNode;
  late FocusNode _discountFocusNode;


  @override
  void initState() {
    super.initState();

    _rateController = TextEditingController(text: widget.rate.toStringAsFixed(3));
    _quantityController = TextEditingController(text: widget.quantity.toStringAsFixed(2));
    _priceListRateController = TextEditingController(text: widget.priceListRate.toStringAsFixed(3));
    _discountPercentageController = TextEditingController(text: widget.discountPercentage.toStringAsFixed(2));
    _totalController = TextEditingController();

    _quantityFocusNode = FocusNode();
    _rateFocusNode = FocusNode();
    _totalFocusNode = FocusNode();
    _priceListRateFocusNode = FocusNode();
    _discountFocusNode = FocusNode();

    _calculateTotal();

    _rateController.addListener(_calculateTotal);
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
    // Update rate when price list rate is edited
    _priceListRateController.addListener(() {
      if (_priceListRateFocusNode.hasFocus) {
        final priceListRate = double.tryParse(_priceListRateController.text) ?? 0.0;
        _rateController.text = priceListRate.toStringAsFixed(3);
      }
    });

    _discountFocusNode.addListener(() {
      if (_discountFocusNode.hasFocus) {
        _discountPercentageController.selection = TextSelection(baseOffset: 0, extentOffset: _discountPercentageController.text.length);
      }
    });
  }




  void _calculateTotal() {
    if (_isUpdatingFromTotal) return;

    final rate = double.tryParse(_rateController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final total = rate * quantity;

    setState(() {
      _totalAmount = total;
      _totalController.text = total.toStringAsFixed(3);
    });
  }

  void _updateRateFromTotal() {
    if (!_totalFocusNode.hasFocus) return;

    final total = double.tryParse(_totalController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (quantity > 0) {
      final newRate = total / quantity;
      _isUpdatingFromTotal = true;
      _rateController.text = newRate.toStringAsFixed(3);
      _priceListRateController.text = newRate.toStringAsFixed(3);
      _isUpdatingFromTotal = false;
    }
  }



  @override
  void dispose() {
    _rateController.removeListener(_calculateTotal);
    _quantityController.removeListener(_calculateTotal);
    _totalController.removeListener(_updateRateFromTotal);
    _priceListRateController.removeListener(() {});

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.itemName, // ✅ highlighted item name
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // semi-bold for name
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: " (${widget.itemCode})", // ✅ normal item code
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black54, // slightly lighter
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _priceListRateController,
              focusNode: _priceListRateFocusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price List Rate'),
            ),

            TextField(
              controller: _rateController,
              focusNode: _rateFocusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Rate'),
            ),
            TextField(
              readOnly: true,
              controller: _discountPercentageController,
              keyboardType: TextInputType.number,
              focusNode: _discountFocusNode,
              decoration: InputDecoration(labelText: 'Discount Percentage'),
            ),

            TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),

            TextField(
              controller: _totalController,
              focusNode: _totalFocusNode,
              readOnly: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Total'),
            ),


          ],
        ),
      ),
      actions: [

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
              provider.addItem(rate, quantity, widget.itemName, widget.itemCode, priceListRate, discountPercentage);

              // ✅ Notify parent to update global total
              widget.onItemAdded?.call(rate, quantity);

              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),

        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}