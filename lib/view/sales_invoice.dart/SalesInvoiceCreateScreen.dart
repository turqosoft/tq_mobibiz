
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
// 👇 Add these to the widget's constructor
  final VoidCallback? onSubmitStart;
  final VoidCallback? onSubmitEnd;

  // const SalesInvoiceCreateScreen({super.key, this.onSave});
  const SalesInvoiceCreateScreen({
    super.key,
    required this.onSave,
    this.onSubmitStart,
    this.onSubmitEnd,
  });

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
  final FocusNode _itemSearchFocusNode = FocusNode();
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

  bool _isDiscountExpanded = false;
  String _applyDiscountOn = 'Net Total';
  final TextEditingController _discountPercentageController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
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
    _itemSearchFocusNode.dispose();
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
    _discountPercentageController.dispose();
    _discountAmountController.dispose();

    super.dispose();
  }

  // Future<void> _handleSave() async {
  //   if (isSubmitting) return;
  //
  //   setState(() => isSubmitting = true);
  //
  //   final provider =
  //   Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //   final customerName = customerController.text.trim();
  //   final dueDate = dueDateController.text.trim();
  //   final items = provider.items;
  //
  //   if (customerName.isEmpty || dueDate.isEmpty || items.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Please fill all fields and add items.")),
  //     );
  //     setState(() => isSubmitting = false);
  //     return;
  //   }
  //
  //   final success = await provider.submitInvoice(
  //     context,
  //     customerName,
  //     _selectedDueDate!,
  //     _selectedPostingDate!,
  //   );
  //
  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Sales Invoice Created"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const SalesInvoicePage()),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(provider.errorMessage ?? "Unknown error occurred"),
  //       ),
  //     );
  //   }
  //
  //   setState(() => isSubmitting = false);
  // }
  Future<void> _handleSave() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);
    widget.onSubmitStart?.call(); // 👇 tell parent to show overlay

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final customerName = customerController.text.trim();
    final dueDate = dueDateController.text.trim();
    final items = provider.items;

    if (customerName.isEmpty || dueDate.isEmpty || items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields and add items.")),
        );
      }
      setState(() => isSubmitting = false);
      widget.onSubmitEnd?.call(); // 👇 tell parent to hide overlay
      return;
    }

    final double discountPercentage = provider.isDiscountEnabled
        ? (double.tryParse(_discountPercentageController.text.trim()) ?? 0.0)
        : 0.0;
    final double discountAmount = provider.isDiscountEnabled
        ? (double.tryParse(_discountAmountController.text.trim()) ?? 0.0)
        : 0.0;
    final String applyDiscountOn =
    provider.isDiscountEnabled ? _applyDiscountOn : 'Grand Total';

    final success = await provider.submitInvoice(
      context,
      customerName,
      _selectedDueDate!,
      _selectedPostingDate!,
      applyDiscountOn: applyDiscountOn,
      additionalDiscountPercentage: discountPercentage,
      discountAmount: discountAmount,
    );

    if (!mounted) return;

    if (success) {
      widget.onSubmitEnd?.call(); // 👇 hide overlay before navigating
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
      setState(() => isSubmitting = false);
      widget.onSubmitEnd?.call(); // 👇 hide overlay on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "Unknown error occurred"),
        ),
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
  String uom = '',   // 👇 new
  VoidCallback? onCa

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
      uom: uom,           // 👇 pass it down

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
        uom: uom,              // ✅ use the resolved variable, not item.uom
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
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.fetchDiscountSettings(context);
    widget.onSave?.call(_handleSave);
    resetForm(); // Ensures context is available
  });
}


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);
    final items = provider.itemListModel?.data ?? [];
    final customerList = provider.customerSearchModel?.data ?? [];
    TextStyle labelStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.bold);

    // 👇 Get bottom inset (navigation bar height)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
        bottom: false,
        child: Padding(
        padding: const EdgeInsets.all(12.0),
    child: SingleChildScrollView(
    padding: EdgeInsets.only(
    bottom: bottomPadding + bottomInset + 16,
    ),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
              /// 🔍 CUSTOMER SEARCH + TOTAL (SAME ROW)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Search Customer',
                          labelStyle: const TextStyle(fontSize: 13),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            iconSize: 18,
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
                              : const Icon(Icons.search, size: 18),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) {
                          _selectedCustomer = null;
                          _searchCustomer(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTotalAmount(),
                ],
              ),

              /// 📋 CUSTOMER DROPDOWN LIST
              if (customerList.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: customerList.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final customer = customerList[index];
                      final isSelected = _selectedCustomer == customer.name;
                      return InkWell(
                        onTap: () async {
                          if (customer.name == null) return;
                          setState(() {
                            _selectedCustomer = customer.name;
                            _searchController.text = customer.customerName ?? '';
                            customerController.text = customer.name ?? '';
                            customerList.clear();
                          });
                          try {
                            final p = Provider.of<SalesOrderProvider>(context, listen: false);
                            final details = await p.fetchCustomerDetails(context, customer.customerName ?? '');
                            if (details?['message'] != null) {
                              setState(() => _currency = details!['message']['currency'] ?? '');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to fetch customer details')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error fetching customer')),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(Icons.check_circle, size: 16, color: AppColors.primaryColor),
                              if (isSelected) const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.customerName ?? '',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(customer.name ?? '',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (Provider.of<SalesOrderProvider>(context).isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),

              const SizedBox(height: 10),

              /// 📅 POSTING DATE + DUE DATE
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text("Posting Date", style: labelStyle),
                        ),
                        GestureDetector(
                          onTap: () => _selectPostingDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: postingDateController,
                              hintText: "Select",
                              borderRadius: 8,
                              style: const TextStyle(fontSize: 13),
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text("Due Date", style: labelStyle),
                        ),
                        GestureDetector(
                          onTap: () => _selectDueDate(context),
                          child: AbsorbPointer(
                            child: CommonTextField(
                              controller: dueDateController,
                              hintText: "Select",
                              borderRadius: 8,
                              style: const TextStyle(fontSize: 13),
                              obscureText: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              /// ➕ ADD ITEM SECTION
              const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
    TapRegion(
    onTapOutside: (_) {
    setState(() {
    _itemSelected = true;
    });

    _itemSearchFocusNode.unfocus();
    },
    child: Column(
    children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  focusNode: _itemSearchFocusNode,
                  controller: _itemSearchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Search Item',
                    labelStyle: TextStyle(fontSize: 13),
                    suffixIcon: Icon(Icons.search, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (content) {
                    setState(() => _itemSelected = false);
                    _searchItemList(content);
                  },
                  onSubmitted: (query) {
                    setState(() => _itemSelected = false);
                    _searchItemList(query);
                  },
                ),
              ),

              /// 📋 ITEM DROPDOWN LIST
              if (!_itemSelected && items.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: () async {
                          final p = Provider.of<SalesOrderProvider>(context, listen: false);
                          final customer = customerController.text.trim();

                          if (customer.isEmpty) {
                            Fluttertoast.showToast(msg: "Please select a customer first.");
                            return;
                          }

                          if (p.invoiceCustomerDetails == null ||
                              p.invoiceCustomerDetails?["customer_name"] != customer) {
                            try {
                              await p.fetchCustomer(context, customer);
                            } catch (_) {
                              Fluttertoast.showToast(msg: "Failed to fetch customer details.");
                              return;
                            }
                          }

                          final customerDetails = p.invoiceCustomerDetails ??
                              await p.fetchCustomer(context, customer);
                          if (customerDetails == null) {
                            Fluttertoast.showToast(msg: "Failed to load customer details.");
                            return;
                          }

                          final priceList = p.sellingPriceList;
                          if (priceList == null || priceList.isEmpty) {
                            Fluttertoast.showToast(msg: "Selling Price List not configured.");
                            return;
                          }

                          final isDuplicate = p.itemsList.any((e) => e.itemCode == item.itemCode);
                          if (isDuplicate) {
                            Fluttertoast.showToast(msg: "'${item.itemName}' already added.");
                            return;
                          }

                          try {
                            final itemDetails = await p.fetchItemDetail(
                              context: context,
                              itemCode: item.itemCode ?? '',
                              currency: currency,
                              quantity: 1.0,
                              customerName: customer,
                            );

                            if (itemDetails?['message'] != null) {
                              final msg = itemDetails!['message'];
                              setState(() {
                                _selectedItem = item.itemName;
                                _itemSelected = true;
                                _itemSearchController.clear();
                              });
                              _showAddItemDialog(
                                itemName: item.itemName ?? "",
                                itemCode: item.itemCode ?? "",
                                rate: (msg['rate'] ?? 0).toDouble(),
                                quantity: 1,
                                priceListRate: (msg['price_list_rate'] ?? 0).toDouble(),
                                discountPercentage: (msg['discount_percentage'] ?? 0).toDouble(),
                                lastPurchaseRate: (msg['last_purchase_rate'] ?? 0).toDouble(),
                                itemTaxTemplate: msg["item_tax_template"] ?? "",
                                uom: msg?["uom"] ?? msg?["stock_uom"] ?? '',  // 👈 add this
                                onCancel: () => setState(() {
                                  _selectedItem = null;
                                  _itemSelected = false;
                                }),
                              );
                            } else {
                              Fluttertoast.showToast(msg: "Failed to fetch item details.");
                            }
                          } catch (e) {
                            Fluttertoast.showToast(msg: "Error fetching item: $e");
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName ?? '',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(item.itemCode ?? '',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    ],
    ),
    ),

              const SizedBox(height: 8),

              /// 📦 ITEM LIST
              Consumer<SalesOrderProvider>(
                builder: (context, itemProvider, child) {
                  final itemList = itemProvider.itemsList;

                  if (itemProvider.isLoadingItem) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }

                  if (itemList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('No items added yet',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: List.generate(itemList.length, (index) {
                      final item = itemList[index];
                      final double rate = item.rate ?? 0;
                      final double qty = item.quantity ?? 0;
                      final double discount = item.discountPercentage ?? 0;
                      final double effectiveRate = discount > 0 ? rate * (1 - discount / 100) : rate;
                      final double amount = effectiveRate * qty;
                      final double originalAmount = rate * qty;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _showEditDialog(context, index, itemProvider,
                                    () => setState(() => _selectedItem = null));
                            _itemSearchController.clear();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                /// Serial badge
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${index + 1}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AppColors.primaryColor)),
                                ),
                                const SizedBox(width: 8),

                                /// Item info — Expanded forces it to take only remaining space
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name ?? '',
                                        maxLines: 2,              // allow wrap instead of overflow
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      // Wrap(                        // Wrap instead of Row so it never overflows
                                      //   spacing: 6,
                                      //   runSpacing: 2,
                                      //   children: [
                                      //     if (item.itemCode != null)
                                      //       Container(
                                      //         padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      //         decoration: BoxDecoration(
                                      //           color: Colors.grey[100],
                                      //           borderRadius: BorderRadius.circular(3),
                                      //         ),
                                      //         child: Text(item.itemCode!,
                                      //             style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      //       ),
                                      //     Text(
                                      //       '${qty.toStringAsFixed(0)} × ₹${rate.toStringAsFixed(2)}',
                                      //       style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      //     ),
                                      //     if (discount > 0)
                                      //       Text(
                                      //         '-${discount.toStringAsFixed(0)}%',
                                      //         style: TextStyle(
                                      //             fontSize: 10,
                                      //             color: Colors.orange[600],
                                      //             fontWeight: FontWeight.w600),
                                      //       ),
                                      //   ],
                                      // ),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        children: [
                                          if (item.itemCode != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(item.itemCode!,
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                            ),
                                          Text(
                                            '${qty.toStringAsFixed(0)} × ₹${rate.toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                          if (item.uom != null && item.uom!.isNotEmpty)   // 👈 add this
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(3),
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
                                          if (discount > 0)
                                            Text(
                                              '-${discount.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange[600],
                                                  fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                /// Amount + delete — intrinsic width, never grows
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,     // ← don't stretch vertically
                                  children: [
                                    if (discount > 0)
                                      Text(
                                        '₹${originalAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[400],
                                            decoration: TextDecoration.lineThrough),
                                      ),
                                    Text(
                                      '₹${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.green[700]),
                                    ),
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: () async { /* your existing delete logic */ },
                                      child: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
      Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          // Still loading — show a subtle placeholder so layout doesn't jump
          if (!provider.isDiscountEnabled) return const SizedBox.shrink();
          return _buildAdditionalDiscountSection();
        },
      ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
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

  Widget _buildAdditionalDiscountSection() {
    final List<String> discountOnOptions = ['Grand Total', 'Net Total'];

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          /// Header / Toggle
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isDiscountExpanded = !_isDiscountExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.local_offer_outlined,
                        size: 16, color: Colors.orange[700]),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Additional Discount',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  /// Show summary when collapsed and values exist
                  if (!_isDiscountExpanded)
                    _buildDiscountSummaryBadge(),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isDiscountExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          /// Expandable body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDiscountFields(discountOnOptions),
            crossFadeState: _isDiscountExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSummaryBadge() {
    final pct = _discountPercentageController.text.trim();
    final amt = _discountAmountController.text.trim();

    if (pct.isEmpty && amt.isEmpty) return const SizedBox.shrink();

    String label = '';
    if (pct.isNotEmpty && pct != '0') label = '$pct%';
    if (amt.isNotEmpty && amt != '0') {
      label = label.isEmpty ? '₹$amt' : '$label · ₹$amt';
    }
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            color: Colors.orange[800],
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDiscountFields(List<String> discountOnOptions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 10),

          /// Apply Discount On
          const Text('Apply Discount On',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _applyDiscountOn,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                icon: Icon(Icons.unfold_more, size: 18, color: Colors.grey[500]),
                onChanged: (val) {
                  if (val != null) setState(() => _applyDiscountOn = val);
                },
                items: discountOnOptions
                    .map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// Percentage + Amount side by side
          Row(
            children: [
              /// Discount Percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discount %',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _discountPercentageController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          suffixText: '%',
                          suffixStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) {
                          setState(() {}); // refresh badge
                          /// Optional: auto-calculate discount amount from grand total
                          // final total = _calculateGrandTotal();
                          // final pct = double.tryParse(val) ?? 0;
                          // _discountAmountController.text =
                          //     (total * pct / 100).toStringAsFixed(2);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// Discount Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discount Amount',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _discountAmountController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          prefixText: '₹',
                          prefixStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onChanged: (val) => setState(() {}), // refresh badge
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
