// purchase_receipt_create_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/model/purchase_receipt_model.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/purchase_receipt/ItemDetailScreen.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/view/purchase_receipt/PurchaseReceipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseReceiptCreateScreen extends StatefulWidget {
  final String? supplier;
  final String? warehouse;
  final String? rejectedWarehouse;
  final List<PurchaseItem> items;
  final String purchaseOrderName; // ✅ Add this


  PurchaseReceiptCreateScreen({
    required this.supplier,
    required this.warehouse,
    this.rejectedWarehouse,
    required this.items,
    required this.purchaseOrderName, // ✅ Add to constructor

  });

  @override
  _PurchaseReceiptCreateScreenState createState() => _PurchaseReceiptCreateScreenState();
}

class _PurchaseReceiptCreateScreenState
    extends State<PurchaseReceiptCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _postingDateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );

  late TextEditingController _supplierController;
  late TextEditingController _warehouseController;
  late TextEditingController _rejectedWarehouseController;
  bool _setPostingTime = false;
late List<double> _orderedQuantities;

  // ✅ Track updated items
  final Set<String> _updatedItems = {};

  @override
  void initState() {
    super.initState();
    _supplierController = TextEditingController(text: widget.supplier);
    _warehouseController = TextEditingController(text: widget.warehouse);
    _rejectedWarehouseController = TextEditingController();
  _orderedQuantities = widget.items.map((item) => item.qty).toList();

    // ✅ Load saved data via provider if available
    _loadSavedData();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _warehouseController.dispose();
    _rejectedWarehouseController.dispose();
    
    super.dispose();
  }

Future<void> _setPendingStatus(String purchaseOrderName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('pending_status_$purchaseOrderName', true);
  debugPrint("⚡️ Pending status set for $purchaseOrderName");
}


// ✅ Load Saved Data Using Provider
Future<void> _loadSavedData() async {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  final savedReceipt =
      await provider.loadSavedPurchaseReceipt(widget.purchaseOrderName);

  if (savedReceipt != null) {
    // ✅ Restore Updated Items State BEFORE setState
    final prefs = await SharedPreferences.getInstance();
    List<String>? updatedItems =
        prefs.getStringList('updated_items_${widget.purchaseOrderName}');

    setState(() {
      _supplierController.text = savedReceipt.supplier ?? '';
      _warehouseController.text = savedReceipt.warehouse ?? '';
      _rejectedWarehouseController.text =
          savedReceipt.rejectedWarehouse ?? '';
      _setPostingTime = savedReceipt.setPostingTime == 1;
      _postingDateController.text = savedReceipt.postingDate ?? '';

      // ✅ Correctly modify items by clearing and adding updated items
      widget.items.clear();
      widget.items.addAll(savedReceipt.items ?? []);

      // ✅ Restore Updated Items State in setState
      _updatedItems.clear();
      if (updatedItems != null) {
        _updatedItems.addAll(updatedItems);
        debugPrint("🎨 Restored updated items for ${widget.purchaseOrderName}");
      }
    });
  }
}

  // ✅ Save Updated Items to SharedPreferences
Future<void> _saveUpdatedItems() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'updated_items_${widget.purchaseOrderName}',
    _updatedItems.toList(),
  );
  debugPrint("💾 Updated items saved for ${widget.purchaseOrderName}");
}


  // ✅ Save Data Using Provider
  Future<void> _saveData() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    final receipt = PurchaseReceipt(
      supplier: _supplierController.text,
      warehouse: _warehouseController.text,
      rejectedWarehouse: _rejectedWarehouseController.text,
      items: widget.items,
      setPostingTime: _setPostingTime ? 1 : 0,
      postingDate: _postingDateController.text,
    );

    await provider.savePurchaseReceiptData(widget.purchaseOrderName, receipt);
  }


// ✅ Clear Saved Data Using Provider
Future<void> _clearSavedData() async {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  await provider.clearSavedPurchaseReceipt(widget.purchaseOrderName);

  // 🧹 Clear updated items state after submission
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('updated_items_${widget.purchaseOrderName}');
  _updatedItems.clear();

  // ✅ Clear pending status after submission
  await prefs.remove('pending_status_${widget.purchaseOrderName}');
  debugPrint(
      "🧹 Cleared saved purchase receipt, updated items, and pending status for ${widget.purchaseOrderName}");
}


void _navigateToItemScreen(PurchaseItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PurchaseReceiptItemsScreen(
        supplier: widget.supplier ?? '',
        warehouse: widget.warehouse ?? '',
        rejectedWarehouse: _rejectedWarehouseController.text,
        selectedItem: item,
        onSave: (updatedItem) {
          setState(() {
            int index = widget.items
                .indexWhere((i) => i.itemCode == updatedItem.itemCode);
            if (index != -1) {
              widget.items[index] = updatedItem;
              _updatedItems.add(updatedItem.itemCode ?? "");
            }
          });

          _saveData();
          _saveUpdatedItems();
          _setPendingStatus(widget.purchaseOrderName); // ✅ Mark as pending
        },
      ),
    ),
  );
}


// ✅ Card Color Logic: Change Color for Updated Items
Color _getCardColor(PurchaseItem item) {
  if (_updatedItems.contains(item.itemCode)) {
    return const Color.fromARGB(255, 215, 252, 250); // 🟢 Light Green if updated
  }
  return Colors.white; // ⚪️ Default color if not updated
}

// ✅ Submit Purchase Receipt
void _submitForm(BuildContext context) {
  if (_formKey.currentState!.validate()) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // ✅ Convert date format before sending
    String formattedPostingDate = "";
    if (_setPostingTime && _postingDateController.text.isNotEmpty) {
      DateTime parsedDate =
          DateFormat('dd-MM-yyyy').parse(_postingDateController.text);
      formattedPostingDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    }

    // ✅ Update item values before sending
    for (var item in widget.items) {
      item.qty = double.tryParse(item.acceptedQtyController.text) ?? item.qty;
      item.rejectedQty =
          double.tryParse(item.rejectedQtyController.text) ?? item.rejectedQty;
      item.wastageQuantity =
          double.tryParse(item.wastageQtyController.text) ?? item.wastageQuantity;
      item.excessQuantity =
          double.tryParse(item.excessQtyController.text) ?? item.excessQuantity;

      // ✅ Assign rejected warehouse if applicable
      item.rejectedWarehouseController.text =
          item.rejectedQty > 0 ? item.rejectedWarehouseController.text : "";
    }

    // ✅ Mandatory field check for purchase_order and purchase_order_item
    for (var item in widget.items) {
      if (item.purchaseOrder == null || item.purchaseOrder!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "⚠️ Purchase Order is missing for item: ${item.itemName ?? 'Unknown'}"),
          ),
        );
        debugPrint(
            "⚠️ Missing purchase_order for item: ${item.itemName ?? 'Unknown'}");
        return; // Prevent submission if missing
      }

      if (item.purchaseOrderItem == null || item.purchaseOrderItem!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "⚠️ Purchase Order Item is missing for item: ${item.itemName ?? 'Unknown'}"),
          ),
        );
        debugPrint(
            "⚠️ Missing purchase_order_item for item: ${item.itemName ?? 'Unknown'}");
        return; // Prevent submission if missing
      }
    }

    // ✅ Create PurchaseReceipt object with validated data
    final receipt = PurchaseReceipt(
      supplier: _supplierController.text,
      warehouse: _warehouseController.text,
      rejectedWarehouse: _rejectedWarehouseController.text,
      items: widget.items, // Items now have updated and validated values
      setPostingTime: _setPostingTime ? 1 : 0,
      postingDate: formattedPostingDate,
    );

    // ✅ Submit the purchase receipt and handle error messages
    provider.createPurchaseReceipt(context, receipt).then((result) {
      if (result == true) {
        // ✅ Success: Purchase receipt created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Purchase Receipt Created")),
        );

        _formKey.currentState!.reset();
        setState(() {
          widget.items.clear(); // Clear items after success
        });

        // 🧹 Clear saved data after successful submission
        _clearSavedData();

        // ✅ Navigate to PurchaseReceiptScreen after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PurchaseReceiptScreen(),
          ),
        );
      }

      // 🚨 Handle custom error messages
      else if (result is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❗ $result",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint("❗ API Error: $result");
      }

      // ❌ General error fallback
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to create receipt. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint("❌ Unknown error while creating receipt.");
      }
    });
  }
}
  void _confirmDeleteItem(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        widget.items.removeAt(index);
                      _orderedQuantities.removeAt(index); // 🧹 Keep it in sync

      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Purchase Receipt",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier Field (Read-Only)
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(labelText: "Supplier"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter Supplier" : null,
                  readOnly: true,
                ),

Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<String>.empty();
    }
    try {
      final warehouseList = await Provider.of<SalesOrderProvider>(
        context,
        listen: false,
      ).fetchWarehouseCodes(textEditingValue.text);

      return warehouseList;
    } catch (e) {
      debugPrint("❗ Error fetching warehouse list: $e");
      return const Iterable<String>.empty();
    }
  },
  onSelected: (String selection) {
    setState(() {
      _warehouseController.text = selection; // ✅ Auto-select warehouse
    });
  },
  fieldViewBuilder:
      (context, controller, focusNode, onFieldSubmitted) {
    controller.text = _warehouseController.text;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: "Accepted Warehouse",
        prefixIcon: const Icon(Icons.warehouse),
        suffixIcon: const Icon(Icons.search),
      ),
      validator: (value) => value!.isEmpty ? "Enter Warehouse" : null,
      onChanged: (value) {
        setState(() {
          _warehouseController.text = value;
        });
      },
      // ✅ Automatically select the text when the field gains focus
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
    );
  },
  optionsViewBuilder: (context, onSelected, options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);
              return ListTile(
                title: Text(option),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  },
),



                // Rejected Warehouse Autocomplete
                SizedBox(height: 20),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    try {
                      final warehouseList =
                          await Provider.of<SalesOrderProvider>(
                        context,
                        listen: false,
                      ).fetchWarehouse(textEditingValue.text);

                      return warehouseList;
                    } catch (e) {
                      print("Error fetching warehouse list: $e");
                      return const Iterable<String>.empty();
                    }
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _rejectedWarehouseController.text = selection;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.text = _rejectedWarehouseController.text;

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Rejected Warehouse",
                        prefixIcon: Icon(Icons.warehouse),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _rejectedWarehouseController.text = value;
                        });
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),

                // Set Posting Time Checkbox
                SwitchListTile(
                  title: Text("Set Posting Date"),
                  value: _setPostingTime,
                  onChanged: (value) {
                    setState(() {
                      _setPostingTime = value;
                    });
                  },
                ),

                if (_setPostingTime)
                  TextFormField(
                    controller: _postingDateController,
                    decoration: InputDecoration(labelText: "Posting Date"),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _postingDateController.text =
                              DateFormat('dd-MM-yyyy').format(pickedDate);
                        });
                      }
                    },
                  ),

                SizedBox(height: 20),

                // **Item List Preview**
                Text(
                  "Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: widget.items.length,
  itemBuilder: (context, index) {
    final item = widget.items[index];
    final orderedQty = _orderedQuantities[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      color: _getCardColor(item), // ✅ Dynamic Card Color
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content (item info)
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToItemScreen(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.itemName ?? 'Unknown Item'} (${item.itemCode ?? 'N/A'})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Ordered: ${orderedQty.toStringAsFixed(2)} ${item.uom ?? ''}",
                    ),
                    const SizedBox(height: 8),

                    // ✅ Row for Recd Qty and Received Qty
                    Row(
                      children: [
Text(
  "Received: ${(item.receivedQty ?? 0.0).toStringAsFixed(2)} ${item.uom ?? ''}",
),

                        const SizedBox(width: 12),

                        // Received Qty (Read-only)
// Text(
//   "Accepted: ${max(0, (orderedQty - (item.receivedQty ?? 0.0))).toStringAsFixed(2)} ${item.uom ?? ''}",
//   style: const TextStyle(fontSize: 14),
// ),
// Text(
//   "Accepted: ${item.defaultAcceptedQty.toStringAsFixed(2)} ${item.uom ?? ''}",
//   style: const TextStyle(fontSize: 14),
// ),

// ValueListenableBuilder<TextEditingValue>(
//   valueListenable: item.acceptedQtyController,
//   builder: (context, value, _) {
//     final acceptedQty = double.tryParse(value.text) ?? 0.0;
//     return Text(
//       "Accepted: ${acceptedQty.toStringAsFixed(2)} ${item.uom ?? ''}",
//       style: const TextStyle(fontSize: 14),
//     );
//   },
// ),

ValueListenableBuilder<TextEditingValue>(
  valueListenable: item.acceptedQtyController,
  builder: (context, value, _) {
    final rawQty = double.tryParse(value.text) ?? 0.0;
    final acceptedQty = rawQty < 0 ? 0.0 : rawQty; // Clamp to zero

    return Text(
      "Accepted: ${acceptedQty.toStringAsFixed(2)} ${item.uom ?? ''}",
      style: const TextStyle(fontSize: 14),
    );
  },
),



                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteItem(index),
            ),
          ],
        ),
      ),
    );
  },
),

                SizedBox(height: 20),

                ElevatedButton(
  onPressed: () async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Submission"),
        content: const Text("Are you sure you want to submit this Purchase Receipt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      _submitForm(context);
    }
  },
  child: const Text("Submit Purchase Receipt"),
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
