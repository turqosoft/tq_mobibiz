import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/provider/provider.dart';
// import 'package:sales_ordering_app/view/home/home.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sales_ordering_app/view/new_Transcation/get_sales_order.dart';

import '../../model/get_sales_order_response.dart';
import '../Home/home.dart';

class SalesOrderScreen extends StatefulWidget {
  final SalesOrderDetails? salesOrder;
  final String? salesOrderName;
  final Map<String, dynamic>? mappedQuotation;

  const SalesOrderScreen({
    super.key,
    this.salesOrder,
    this.salesOrderName,
    this.mappedQuotation, // 👈 ADD THIS
  });
  @override
  SalesOrderScreenState createState() => SalesOrderScreenState();
}

// NOTE: public (no leading underscore)
class SalesOrderScreenState extends State<SalesOrderScreen> {
  // keep your existing private fields, controllers, etc.
  String? _selectedFilter;
  List<String> _filters = [];
  List<String> _customerNames = [];
  String? _selectedCustomer;
  String? _searchCustomerName;
  String? _selectedItem;
  List<String> _selectedItems = [];
  String? _currency;
  bool _isEditMode = false;
  final FocusNode _customerSearchFocusNode = FocusNode();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  SalesOrderProvider? _salesOrderProvider;
  bool _customerSelected = false;
  bool _itemSelected = false;
  bool _isSaving = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();
  final FocusNode _itemSearchFocusNode = FocusNode();
  String? _sourceQuotation;
  String? _createdSalesOrderName;
  bool _isDirty = false;
  bool get isDirty => _isDirty;
  bool get isEditMode => _isEditMode;
  bool _warehouseExpanded = false;
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // ✅ Determine mode FIRST
    if (widget.salesOrder != null) {
      _isEditMode = true;
      _createdSalesOrderName = widget.salesOrder!.name;
    } else {
      _isEditMode = false;
      _createdSalesOrderName = null; // only null if truly new
    }

    provider.setSelectedSalesOrderName(null);
    provider.setSelectedSalesOrderTotal(null);
    provider.clearItem();
    provider.clearWarehouse();
    provider.clearSalesOrderModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCustomerGroupList();
      if (widget.mappedQuotation != null) {
        _prefillFromMappedQuotation(widget.mappedQuotation!);
      }
      if (widget.salesOrder != null) {
        _prefillFromOrder(widget.salesOrder!);
      }
    });

    _customerSearchFocusNode.addListener(() {
      if (!_customerSearchFocusNode.hasFocus) {
        setState(() => _customerSelected = false);
      }
    });

    _deliveryDateController.text =
        DateFormat('dd-MM-yyyy').format(DateTime.now());

    final salesOrderProvider =
    Provider.of<SalesOrderProvider>(context, listen: false);
    salesOrderProvider.loadAllowMultipleItems(context);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  String? getCurrentOrderName() {
    return _createdSalesOrderName ?? widget.salesOrder?.name;
  }
  bool get canSubmit {
    return (_createdSalesOrderName != null && _createdSalesOrderName!.isNotEmpty)
        || (widget.salesOrder?.name != null && widget.salesOrder!.name!.isNotEmpty);
  }

  @override
  void didUpdateWidget(covariant SalesOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.salesOrder != null &&
        widget.salesOrder != oldWidget.salesOrder) {
      _isEditMode = true;
      _createdSalesOrderName = widget.salesOrder!.name;
      _prefillFromOrder(widget.salesOrder!);
    } else if (widget.salesOrder == null) {
      // ✅ Only reset if we don't already have a locally created order
      if (_createdSalesOrderName == null) {
        _isEditMode = false;
      }
    }
  }
  void _prefillFromMappedQuotation(Map<String, dynamic> data) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    _sourceQuotation = data['name']; // ✅ IMPORTANT

    setState(() {
      _selectedCustomer = data['customer'];
      _searchCustomerName = data['customer_name'];
      _customerSelected = true;

      // 🔥 THIS LINE FIXES YOUR ISSUE
      _searchController.text = data['customer_name'] ?? '';
    });
    /// ✅ Fetch customer details
    try {
      final customerDetails =
      await provider.fetchCustomerDetails(context, data['customer']);

      if (customerDetails != null && customerDetails['message'] != null) {
        final message = customerDetails['message'];

        setState(() {
          _currency = message['currency'] ?? 'INR';
        });

        provider.setSelectedCustomerDetails(message);
      }
    } catch (e) {
      debugPrint("❌ Error fetching customer: $e");
    }

    /// ✅ Set Items
    final items = (data['items'] ?? []) as List;

    provider.setItems(
      items.map((e) {
        return Item(
          rowName: e['name'],
          name: e['item_name'] ?? '',
          itemCode: e['item_code'] ?? '',
          quantity: (e['qty'] ?? 1).toDouble(),
          rate: (e['rate'] ?? 0).toDouble(),
          priceListRate: (e['price_list_rate'] ?? 0).toDouble(),
          discountPercentage: (e['discount_percentage'] ?? 0).toDouble(),
          itemTaxTemplate: e['item_tax_template'] ?? "",
          lastPurchaseRate: 0.0, // optional
          quotationItem: e['quotation_item'],
          prevdocDocname: e['prevdoc_docname'],
        );
      }).toList(),
    );
  }

  void _prefillFromOrder(SalesOrderDetails order) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    setState(() {
      _selectedCustomer = order.customer;
      _searchCustomerName = order.customerName;
      _customerSelected = true;
      _deliveryDateController.text =
          DateFormat('dd-MM-yyyy').format(DateTime.parse(order.deliveryDate!));
    });

    /// ✅ 🔥 SET WAREHOUSE (MAIN FIX)
    if (order.setWarehouse != null && order.setWarehouse!.isNotEmpty) {
      provider.setWarehousee(order.setWarehouse!);
    } else if (order.items != null && order.items!.isNotEmpty) {

    }

    try {
      final customerDetails =
      await provider.fetchCustomerDetails(context, order.customer ?? "");

      if (customerDetails != null && customerDetails['message'] != null) {
        final message = customerDetails['message'];

        setState(() {
          _currency = message['currency'] ?? 'INR';
        });

        provider.setSelectedCustomerDetails(message);
      }
    } catch (e) {
      print("Error fetching customer details on prefill: $e");
    }

    provider.setItems(
      order.items!.map((e) => Item(
        rowName: e.rowName,
        name: e.itemName ?? '',
        itemCode: e.itemCode ?? '',
        quantity: e.qty ?? 1,
        rate: e.rate ?? 0,
        priceListRate: e.priceListRate ?? 0,
        discountPercentage: e.discountPercentage ?? 0,
        quotationItem: e.quotationItem,
        prevdocDocname: e.prevdocDocname,
      )).toList(),
    );
  }
  /// 🔹 Method that AppBar Save button will call
  Future<void> handleSave(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final itemList = provider.itemsList;

    if (itemList.isEmpty) {
      Fluttertoast.showToast(msg: "Please add items to the order");
      setState(() => _isSaving = false);
      return;
    }

    final formattedItems = itemList.map((item) {
      final discount = item.discountPercentage ?? 0.0;
      return {
        "item_code": item.itemCode,
        "qty": item.quantity.toDouble(),

        /// REQUIRED for discount
        "price_list_rate": item.priceListRate,
        "rate": item.rate,
        if (item.prevdocDocname != null)
          "prevdoc_docname": item.prevdocDocname,

        if (item.quotationItem != null)
          "quotation_item": item.quotationItem,
        /// ONLY if > 0
        if (discount > 0)
          "discount_percentage": discount,
      };
    }).toList();

    if (_isEditMode) {
      // Update existing order
      // final orderId = widget.salesOrder!.name!;
      final orderId = _createdSalesOrderName ?? widget.salesOrder?.name;

      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order not found. Please save again."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
      final customerDetailsResponse =
      await provider.fetchCustomerDetails(context, _selectedCustomer ?? '');
      final customerDetails = customerDetailsResponse?['message'] ?? {};

      final detailedItems = provider.itemsList.map((item) {
        final discount = item.discountPercentage ?? 0.0;

        return {
          "name": item.rowName,
          "item_code": item.itemCode,
          "qty": item.quantity.toDouble(),
          "price_list_rate": item.priceListRate ?? item.rate,
          "rate": item.rate,

          // ✅ ADD THESE — preserve quotation linkage on update
          if (item.prevdocDocname != null)
            "prevdoc_docname": item.prevdocDocname,

          if (item.quotationItem != null)
            "quotation_item": item.quotationItem,

          if (discount > 0)
            "discount_percentage": discount,
        };
      }).toList();
      String formattedDeliveryDate = '';
      try {
        DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(_deliveryDateController.text);
        formattedDeliveryDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (_) {
        formattedDeliveryDate = widget.salesOrder?.deliveryDate ?? '';
      }

      final result = await provider.updateSalesOrder(
        orderId,
        _selectedCustomer ?? '',
        formattedDeliveryDate,
        provider.setWarehouse,
        detailedItems,
        context,
        customerDetails: customerDetails,
      );
      if (result != null) {
        final updatedName = result.data?.name;
        // final updatedTotal = result.data?.grandTotal ?? result.data?.total;

        debugPrint("✅ UPDATED SALES ORDER: $updatedName");

        provider.setSelectedSalesOrderName(updatedName);
        // if (updatedTotal != null) {
        //   provider.setSelectedSalesOrderTotal(updatedTotal.toString());
        // }
        setState(() {
          _createdSalesOrderName = updatedName;
          _isEditMode = true;
          _isDirty = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sales Order updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );

      }
      else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Create new order
      String formattedDeliveryDate = '';
      try {
        DateTime parsedDate =
        DateFormat('dd-MM-yyyy').parse(_deliveryDateController.text);
        formattedDeliveryDate =
            DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (_) {}
      debugPrint("📤 FINAL SALES ORDER ITEMS:");
      for (var item in formattedItems) {
        debugPrint(item.toString());
      }
      await _salesOrder(
        _selectedCustomer ?? '',
        formattedDeliveryDate,
        formattedItems,
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _fetchCustomerGroupList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final customerGroupList = await provider.customerGroupList(context);
      setState(() {
        _filters =
            customerGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
      });
    } catch (e) {
      print('Error fetching customer groups: $e');
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

  Future<void> _salesOrder(
      String customerName, String deliveryDate, List items) async {
    if (_selectedCustomer != null && _deliveryDateController.text.isNotEmpty) {
      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);
      try {
        final customerDetailsResponse =
        await provider.fetchCustomerDetails(context, customerName);
        final customerDetails = customerDetailsResponse?['message'] ?? {};
        final quotationName =
            _sourceQuotation ?? widget.mappedQuotation?['name'];
        await provider.salesOrder(
          customerName,
          deliveryDate,
          items,
          context,
          customerDetails: customerDetails,
          setWarehouse: provider.setWarehouse,
        );

        if (provider.salesOrderModel != null) {
          final createdName = provider.salesOrderModel?.data?.name;
          // final createdTotal = provider.salesOrderModel?.data?.grandTotal
          //     ?? provider.salesOrderModel?.data?.total;
          debugPrint("✅ CREATED SALES ORDER: $createdName");

          // 🔥 CRITICAL FIX — UPDATE PROVIDER
          provider.setSelectedSalesOrderName(createdName);
          // if (createdTotal != null) {
          //   provider.setSelectedSalesOrderTotal(createdTotal.toString());
          // }
          setState(() {
            _createdSalesOrderName = createdName;
            _isEditMode = true;
            _isDirty = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sales Order created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        else if (provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error creating sales order: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer and delivery date')),
      );
    }
  }

  Future<void> _searchCustomer(String customer) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.searchCustomer(customer, context);
    } catch (e) {
      print('Error searching customer: $e');
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _deliveryDateController.text =
            DateFormat('dd-MM-yyyy').format(pickedDate);
      });
      _markDirty();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _salesOrderProvider =
        Provider.of<SalesOrderProvider>(context, listen: false);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _salesOrderProvider?.clearCustomerList();
      _salesOrderProvider?.clearItemList();
      _customerSearchFocusNode.dispose();

      _salesOrderProvider?.clearItem();
      _salesOrderProvider?.setSelectedSalesOrderName(null);
      _salesOrderProvider?.clearTransactionDate(); // ✅ added line

    });
    super.dispose();
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
                          // return ListTile(
                          //   title: Text(item.itemName ?? '',
                          //       style: const TextStyle(fontWeight: FontWeight.bold)),
                          //   subtitle: Text(item.itemCode ?? '',
                          //       style: const TextStyle(color: Colors.grey)),
                          //   onTap: () async {
                          //     _hideOverlay();
                          //
                          //     final quotationProvider =
                          //     Provider.of<SalesOrderProvider>(context, listen: false);
                          //
                          //     if (quotationProvider.allowMultipleItems == 0) {
                          //       bool alreadyExists = quotationProvider.itemsList.any(
                          //             (i) => i.itemCode == item.itemCode,
                          //       );
                          //       if (alreadyExists) {
                          //         Fluttertoast.showToast(
                          //           msg: "This item is already added and duplicates are not allowed.",
                          //           toastLength: Toast.LENGTH_SHORT,
                          //           gravity: ToastGravity.BOTTOM,
                          //         );
                          //         return;
                          //       }
                          //     }
                          //
                          //     setState(() {
                          //       _selectedItem = item.itemName;
                          //       _itemSelected = true;
                          //     });
                          //
                          //     try {
                          //       final itemDetails = await quotationProvider.fetchItemDetail(
                          //         context: context,
                          //         itemCode: item.itemCode ?? '',
                          //         currency: _currency ?? '',
                          //         quantity: 1.0,
                          //         customerName: _selectedCustomer ?? '',
                          //       );
                          //
                          //       if (itemDetails != null && itemDetails['message'] != null) {
                          //         final fetchedRate = itemDetails['message']['price_list_rate'] ?? 0.0;
                          //         final fetchedDiscountPercentage =
                          //             itemDetails['message']['discount_percentage'] ?? 0.0;
                          //         final message = itemDetails["message"];
                          //         final lastPurchaseRate = itemDetails['message']['last_purchase_rate'] ?? 0.0; // ✅ NEW
                          //
                          //         _showAddItemDialog(
                          //           itemName: item.itemName ?? "",
                          //           itemCode: item.itemCode ?? "",
                          //           rate: fetchedRate,
                          //           quantity: 1,
                          //           priceListRate: fetchedRate,
                          //           discountPercentage: fetchedDiscountPercentage,
                          //           itemTaxTemplate: message["item_tax_template"] ?? "",
                          //           lastPurchaseRate: lastPurchaseRate, // ✅ NEW
                          //
                          //         );
                          //       } else {
                          //         Fluttertoast.showToast(msg: "Select Customer first");
                          //       }
                          //     } catch (e) {
                          //       Fluttertoast.showToast(msg: "Error fetching item details: $e");
                          //     }
                          //
                          //     // 👇 reset and refocus for next entry
                          //     setState(() {
                          //       _itemSearchController.clear();
                          //       _itemSelected = false;
                          //       _selectedItem = null;
                          //     });
                          //
                          //     await Future.delayed(const Duration(milliseconds: 200));
                          //     _itemSearchFocusNode.requestFocus();
                          //   },
                          //
                          // );
                          return ListTile(
                            title: Text(item.itemName ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item.itemCode ?? '',
                                style: const TextStyle(color: Colors.grey)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (item.actualQty ?? 0) > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (item.actualQty ?? 0) > 0
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                ),
                              ),
                              child: Text(
                                'Qty: ${(item.actualQty ?? 0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (item.actualQty ?? 0) > 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
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
                                  final fetchedRate = itemDetails['message']['price_list_rate'] ?? 0.0;
                                  final fetchedDiscountPercentage =
                                      itemDetails['message']['discount_percentage'] ?? 0.0;
                                  final message = itemDetails["message"];
                                  final lastPurchaseRate =
                                      itemDetails['message']['last_purchase_rate'] ?? 0.0;

                                  _showAddItemDialog(
                                    itemName: item.itemName ?? "",
                                    itemCode: item.itemCode ?? "",
                                    rate: fetchedRate,
                                    quantity: 1,
                                    priceListRate: fetchedRate,
                                    discountPercentage: fetchedDiscountPercentage,
                                    itemTaxTemplate: message["item_tax_template"] ?? "",
                                    lastPurchaseRate: lastPurchaseRate,
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
  void _setWarehouseAndMarkDirty(String warehouse) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    provider.setWarehousee(warehouse);

    _markDirty(); // ✅ THIS IS THE KEY
  }
  // void _showWarehouseDialog(BuildContext context) {
  //   final provider =
  //   Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //   String? selectedWarehouse = provider.setWarehouse;
  //
  //   showDialog(
  //     context: context,
  //     builder: (_) {
  //       return AlertDialog(
  //         title: const Text('Set Warehouse'),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: Autocomplete<String>(
  //             initialValue: TextEditingValue(
  //               text: selectedWarehouse ?? '',
  //             ),
  //             optionsBuilder: (TextEditingValue textEditingValue) async {
  //               if (textEditingValue.text.isEmpty) {
  //                 return const Iterable<String>.empty();
  //               }
  //               return await provider.fetchWarehouse(
  //                 textEditingValue.text,
  //               );
  //             },
  //             displayStringForOption: (option) => option,
  //             onSelected: (String selection) {
  //               selectedWarehouse = selection;
  //             },
  //             fieldViewBuilder:
  //                 (context, controller, focusNode, onEditingComplete) {
  //               return TextField(
  //                 controller: controller,
  //                 focusNode: focusNode,
  //                 decoration: const InputDecoration(
  //                   hintText: 'Search Warehouse',
  //                   prefixIcon: Icon(Icons.search),
  //                 ),
  //               );
  //             },
  //             optionsViewBuilder:
  //                 (context, onSelected, Iterable<String> options) {
  //               return Align(
  //                 alignment: Alignment.topLeft,
  //                 child: Material(
  //                   elevation: 4,
  //                   child: ListView.builder(
  //                     padding: EdgeInsets.zero,
  //                     shrinkWrap: true,
  //                     itemCount: options.length,
  //                     itemBuilder: (context, index) {
  //                       final option = options.elementAt(index);
  //                       return ListTile(
  //                         title: Text(option),
  //                         onTap: () => onSelected(option),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (selectedWarehouse != null &&
  //                   selectedWarehouse!.isNotEmpty) {
  //                 // provider.setWarehousee(selectedWarehouse!);
  //                 _setWarehouseAndMarkDirty(selectedWarehouse!);
  //               }
  //               Navigator.pop(context);
  //             },
  //             child: const Text('Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  bool isAdd = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
    final items = provider.itemListModel?.data ?? [];
    final customerList = provider.customerSearchModel?.data ?? [];
    final formattedItemTotal = NumberFormat('#,##0.00').format(provider.totalItemAmount);

    final formattedTotal = provider.selectedSalesOrderTotal != null

        ? NumberFormat('#,##0.00').format(double.tryParse(provider.selectedSalesOrderTotal!) ?? 0)
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏬 Warehouse Selector (TOP)
            // GestureDetector(
            //   onTap: () => _showWarehouseDialog(context),
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            //     margin: const EdgeInsets.only(bottom: 8),
            //     decoration: BoxDecoration(
            //       color: Colors.grey[100],
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: Colors.grey.shade300),
            //     ),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.warehouse, size: 18, color: Colors.grey),
            //         const SizedBox(width: 8),
            //
            //         Expanded(
            //           child: Consumer<SalesOrderProvider>(
            //             builder: (_, provider, __) {
            //               return Text(
            //                 provider.setWarehouse ?? "Select Warehouse",
            //                 style: TextStyle(
            //                   fontSize: 14,
            //                   fontWeight: FontWeight.w500,
            //                   color: provider.setWarehouse == null
            //                       ? Colors.grey
            //                       : Colors.black,
            //                 ),
            //               );
            //             },
            //           ),
            //         ),
            //
            //         const Icon(Icons.arrow_drop_down, color: Colors.grey),
            //       ],
            //     ),
            //   ),
            // ),
            // Replace the GestureDetector + _showWarehouseDialog with this widget
            Consumer<SalesOrderProvider>(
              builder: (_, provider, __) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact trigger row
                    GestureDetector(
                      onTap: () => setState(() => _warehouseExpanded = !_warehouseExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _warehouseExpanded
                                ? AppColors.primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warehouse, size: 16,
                                color: _warehouseExpanded
                                    ? AppColors.primaryColor
                                    : Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.setWarehouse ?? "Source Warehouse",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: provider.setWarehouse == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                            Icon(
                              _warehouseExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Inline expandable search
                    if (_warehouseExpanded)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.4)),
                        ),
                        child: Autocomplete<String>(
                          initialValue: TextEditingValue(text: provider.setWarehouse ?? ''),
                          optionsBuilder: (TextEditingValue value) async {
                            if (value.text.isEmpty) return const Iterable<String>.empty();
                            return await provider.fetchWarehouse(value.text);
                          },
                          onSelected: (String selection) {
                            _setWarehouseAndMarkDirty(selection);
                            setState(() => _warehouseExpanded = false); // ✅ auto-close
                          },
                          fieldViewBuilder: (context, controller, focusNode, _) {
                            // Auto-focus when expanded
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_warehouseExpanded) focusNode.requestFocus();
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search warehouse...',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 16),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    controller.clear();
                                    _setWarehouseAndMarkDirty('');
                                  },
                                )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.warehouse_outlined, size: 16),
                                        title: Text(option,
                                            style: const TextStyle(fontSize: 13)),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          if (provider.selectedSalesOrderName != null) ...[
      Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Order #${provider.selectedSalesOrderName!}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        if (formattedTotal != null)
          Text(
            "Total: ₹$formattedTotal",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
          ),
      ],
    ),
    ],

            const SizedBox(height: 5),

// ✅ Show total when adding new items

            if (provider.selectedSalesOrderName == null &&
                provider.itemsList.isNotEmpty)...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // ✅ Right align
                  children: [
                    Text(
                      "Total: ₹$formattedItemTotal",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            ],

// ✅ Customer Field (Compact)
            _isEditMode
                ? Row(

            children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _searchCustomerName ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.lock, size: 16, color: Colors.grey),
              ],
            )
            :Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                focusNode: _customerSearchFocusNode, // ✅ attach FocusNode
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Customer',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _customerSelected = false;
                        _selectedCustomer = null;
                        _searchCustomerName = null;
                      });
                      provider.clearCustomerSearch();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (content) {
                  _markDirty();
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

// ✅ Compact Customer List
            if (!_isEditMode &&
                !_customerSelected &&
                customerList.isNotEmpty &&
                _customerSearchFocusNode.hasFocus) // 👈 show only if focused
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 135),
                child: ListView.builder(
                  itemCount: customerList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final customer = customerList[index];
                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedCustomer = customer.name;
                          _searchCustomerName = customer.customerName;
                          _customerSelected = true;
                          _searchController.text = customer.customerName ?? '';
                        });
                        FocusScope.of(context).unfocus(); // 👈 hide keyboard & list
                        try {
                          final details = await provider.fetchCustomerDetails(
                            context,
                            // customer.customerName ?? '',
                            customer.name ?? '',   // ← change this

                          );
                          if (details?['message'] != null) {
                            setState(() {
                              _currency = details?['message']['currency'] ?? '';
                            });
                          }
                        } catch (e) {
                          print('Error fetching customer details: $e');
                        }
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


            if (provider.isLoading)
              const Center(child: CircularProgressIndicator()),

// ✅ Delivery Date + Transaction Date (in same row)
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  "Delivery:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(

                    onTap: () => _selectDeliveryDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _deliveryDateController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Select Delivery Date',
                          border: InputBorder.none,

                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ Transaction Date Display
                if (provider.selectedTransactionDate != null)
                  Text(
                    "Order: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(provider.selectedTransactionDate!))}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),


                              // ✅ Item Search (Compact)

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
                    _markDirty();
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

// ✅ Item search results
            const SizedBox(height: 10),

            // Expanded(
            //   child: Consumer<SalesOrderProvider>(
            SizedBox(
              height: 400,
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
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey[300]),
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
                    itemBuilder: (context, index) {
                      final item = itemList[index];

                      final double discount = item.discountPercentage ?? 0.0;
                      final double effectiveRate =
                      discount > 0 ? item.rate * (1 - discount / 100) : item.rate;

                      final double amount = effectiveRate * item.quantity;

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
                              setState(() {
                                _selectedItem = null;
                              });
                              _itemSearchController.clear();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔢 Serial badge
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

                                // 📦 Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
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

                                      Text(
                                        '${item.quantity} × ₹${item.rate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
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

                                // 💰 Amount + delete
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (discount > 0)
                                      Text(
                                        '₹${(item.rate * item.quantity).toStringAsFixed(2)}',
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
                                              style: const TextStyle(fontSize: 15),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text("Cancel",
                                                    style: TextStyle(
                                                        color: Colors.blueAccent)),
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
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
                                          _markDirty();
                                          setState(() {
                                            // _isFormDirty = true;
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "'${item.name}' deleted successfully.",
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                              duration:
                                              const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
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
    );
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

        onCancel: () {},
        onItemAdded: (addedRate, addedQty) {
          final double addedAmount = addedRate * addedQty;
          Provider.of<SalesOrderProvider>(context, listen: false)
              .addToTotal(addedAmount);
        },
      ),
    );
  }



// void _showEditDialog(BuildContext context, int index,
//     SalesOrderProvider provider, final VoidCallback onCancel) {
//   final item = provider.itemsList[index];
//   final _rateController = TextEditingController(text: item.rate.toString());
//   final _quantityController = TextEditingController(text: item.quantity.toString());
//   final _priceListRateController = TextEditingController(text: item.priceListRate?.toString() ?? '');
//   final _discountPercentageController = TextEditingController(text: item.discountPercentage?.toString() ?? '');
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
//                             TextField(
//                 controller: _priceListRateController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: 'Price List Rate'),
//                 readOnly: true,
//               ),
//                             TextField(
//                               // readOnly: true,
//                 controller: _discountPercentageController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: 'Discount Percentage'),
//               ),
//               TextField(
//                 controller: _rateController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: 'Rate'),
//               ),
//
//
//
//                             TextField(
//                 controller: _quantityController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(labelText: 'Quantity'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               final newRate = double.tryParse(_rateController.text) ?? 0.0;
//               final newQuantity = double.tryParse(_quantityController.text) ?? 0.0;
//               final newPriceListRate = double.tryParse(_priceListRateController.text) ?? 0.0;
//               final newDiscountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;
//
//               if (newRate <= 0) {
//                 Fluttertoast.showToast(msg: "Please enter a valid rate");
//               } else if (newQuantity <= 0) {
//                 Fluttertoast.showToast(msg: "Please enter a valid quantity");
//               } else {
//                 final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//                 // 🧮 Compute difference
//                 final oldAmount = item.rate * item.quantity;
//                 final newAmount = newRate * newQuantity;
//                 final diff = newAmount - oldAmount;
//
//                 // ✅ Update the item
//                 provider.editItem(index, newRate, newQuantity, newPriceListRate, newDiscountPercentage);
//
//                 // ✅ Update total globally
//                 if (diff != 0) {
//                   if (diff > 0) {
//                     provider.addToTotal(diff);
//                   } else {
//                     provider.subtractFromTotal(diff.abs());
//                   }
//                 }
//
//                 Navigator.of(context).pop();
//               }
//             },
//             child: const Text('Save'),
//           ),
//
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
        // onItemAdded: (rate, qty) {
        //   setState(() {
        //     // _isFormDirty = true;
        //   });
        // },
        onItemAdded: (rate, qty) {
          _markDirty(); // ✅ THIS FIXES YOUR MAIN ISSUE
        },
      ),
    );
  }
}

class Data {
  final String? itemCode;
  final String? itemName;
  int qty;
  final double? rate;
  final double? priceListRate;
  final double? discountPercentage;

  Data({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    this.priceListRate,
    this.discountPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'qty': qty,
      'rate': rate,
      'price_list_rate': priceListRate,
      'discount_percentage': discountPercentage,
    };
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
    required this.itemTaxTemplate,
    this.lastPurchaseRate = 0.0, // ✅ NEW
    this.isEdit = false,
    this.editIndex,
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
  late TextEditingController _itemTaxTemplateController;


  @override
  void initState() {
    super.initState();

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
              controller: _itemTaxTemplateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Item Tax Template',
              ),
            ),
            TextField(
              controller: TextEditingController(
                text: widget.lastPurchaseRate.toStringAsFixed(3),
              ),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Last Purchase Rate',
              ),
            ),
            TextField(
              controller: _priceListRateController,
              focusNode: _priceListRateFocusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price List Rate'),
            ),
            TextField(
              // readOnly: true,
              controller: _discountPercentageController,
              keyboardType: TextInputType.number,
              focusNode: _discountFocusNode,
              decoration: InputDecoration(labelText: 'Discount Percentage'),
            ),
            TextField(
              controller: _rateController,
              focusNode: _rateFocusNode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Rate'),
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
              // provider.addItem(rate, quantity, widget.itemName, widget.itemCode, priceListRate, discountPercentage,                   widget.itemTaxTemplate,
              //   widget.lastPurchaseRate,);
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
                );
              }

              // ✅ Notify parent to update global total
              widget.onItemAdded?.call(rate, quantity);

              Navigator.of(context).pop();
            }
          },
          // child: const Text('Add'),
          child: Text(widget.isEdit ? 'Save' : 'Add'),
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


class Item {
  String? rowName;
  final double rate;
  final double quantity;
  final String name;
  final String itemCode;
  final double? priceListRate;
  final double? discountPercentage;
  final String itemTaxTemplate;
  final double lastPurchaseRate;
  final String? quotationItem;
  final String? prevdocDocname;

  Item(
      {required this.rate, this.rowName,
      required this.quantity,
      required this.name,
      required this.itemCode,
      this.priceListRate,
      this.discountPercentage,
      this.itemTaxTemplate = "",
        this.quotationItem,
        this.prevdocDocname,
        this.lastPurchaseRate = 0.0,});
}
