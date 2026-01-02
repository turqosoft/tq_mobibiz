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
  bool _isSaved = false; // false = not saved, true = saved

  // ✅ Track updated items
  final Set<String> _updatedItems = {};
  void _markUnsaved() {
    if (_isSaved) {
      setState(() {
        _isSaved = false;
      });
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Attach listeners to detect user changes
  //   _supplierController.addListener(_markUnsaved);
  //   _warehouseController.addListener(_markUnsaved);
  //   _rejectedWarehouseController.addListener(_markUnsaved);
  //   _postingDateController.addListener(_markUnsaved);
  //
  //   // Listeners for each item’s controllers
  //   for (var item in widget.items) {
  //     item.acceptedQtyController.addListener(_markUnsaved);
  //     item.rejectedQtyController.addListener(_markUnsaved);
  //     item.wastageQtyController.addListener(_markUnsaved);
  //     item.excessQtyController.addListener(_markUnsaved);
  //   }
  //   _supplierController = TextEditingController(text: widget.supplier);
  //   _warehouseController = TextEditingController(text: widget.warehouse);
  //   _rejectedWarehouseController = TextEditingController();
  // _orderedQuantities = widget.items.map((item) => item.qty).toList();
  //
  //   // ✅ Load saved data via provider if available
  //   _loadSavedData();
  // }
  @override
  void initState() {
    super.initState();

    // 1️⃣ Initialize controllers FIRST
    _supplierController = TextEditingController(text: widget.supplier);
    _warehouseController = TextEditingController(text: widget.warehouse);
    _rejectedWarehouseController = TextEditingController();
    // _postingDateController = TextEditingController();

    // 2️⃣ Now safely add listeners
    _supplierController.addListener(_markUnsaved);
    _warehouseController.addListener(_markUnsaved);
    _rejectedWarehouseController.addListener(_markUnsaved);
    _postingDateController.addListener(_markUnsaved);

    // 3️⃣ Listeners for each item’s controllers
    for (var item in widget.items) {
      item.acceptedQtyController.addListener(_markUnsaved);
      item.rejectedQtyController.addListener(_markUnsaved);
      item.wastageQtyController.addListener(_markUnsaved);
      item.excessQtyController.addListener(_markUnsaved);
    }

    // 4️⃣ Save ordered quantities
    _orderedQuantities = widget.items.map((item) => item.qty).toList();

    // 5️⃣ Load saved data
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

      // Load updated items state BEFORE setState
      final prefs = await SharedPreferences.getInstance();
      List<String>? updatedItems =
      prefs.getStringList('updated_items_${widget.purchaseOrderName}');

      // First restore all saved form fields + items
      setState(() {
        _supplierController.text = savedReceipt.supplier ?? '';
        _warehouseController.text = savedReceipt.warehouse ?? '';
        _rejectedWarehouseController.text = savedReceipt.rejectedWarehouse ?? '';
        _setPostingTime = savedReceipt.setPostingTime == 1;
        _postingDateController.text = savedReceipt.postingDate ?? '';

        widget.items.clear();
        widget.items.addAll(savedReceipt.items ?? []);
// Restore qty into accepted qty controller for each item
        for (var item in widget.items) {
          // Restore Accepted Qty
          item.acceptedQtyController.text = item.qty.toString();

          // Restore Rejected Qty
          if (item.rejectedQty != null) {
            item.rejectedQtyController.text = item.rejectedQty.toString();
          }

          // Restore Wastage Qty
          if (item.wastageQuantity != null) {
            item.wastageQtyController.text = item.wastageQuantity.toString();
          }

          // Restore Excess Qty
          if (item.excessQuantity != null) {
            item.excessQtyController.text = item.excessQuantity.toString();
          }
        }
        _isSaved = true;
        _updatedItems.clear();
        if (updatedItems != null) {
          _updatedItems.addAll(updatedItems);
          debugPrint("🎨 Restored updated items for ${widget.purchaseOrderName}");
        }
      });

      // -------------------------------------------------------------
      // 🔥 RE-FETCH ITEM DETAILS TO RESTORE `hasBatchNo` FLAG
      // -------------------------------------------------------------
      for (var item in widget.items) {
        try {
          if (item.itemCode == null || item.itemCode!.isEmpty) {
            debugPrint("⚠ Skipping item with null itemCode");
            continue;
          }

          final itemDetails =
          await provider.apiService?.fetchItemDetails(item.itemCode!);

          if (itemDetails != null && itemDetails['has_batch_no'] != null) {
            item.hasBatchNo = itemDetails['has_batch_no'] == 1;
            debugPrint("♻ Restored batch flag for ${item.itemCode}: ${item.hasBatchNo}");
          }

        } catch (e) {
          debugPrint("❗ Error restoring batch flag for ${item.itemCode}: $e");
        }
      }


      // Force rebuild AFTER restoring batch flags
      setState(() {});
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

      // ---------------------------------------
      // 1️⃣ Format Posting Date
      // ---------------------------------------
      String formattedPostingDate = "";
      if (_setPostingTime && _postingDateController.text.isNotEmpty) {
        DateTime parsedDate =
        DateFormat('dd-MM-yyyy').parse(_postingDateController.text);
        formattedPostingDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      // ---------------------------------------
      // 2️⃣ Update item values
      // ---------------------------------------
      for (var item in widget.items) {
        item.qty = double.tryParse(item.acceptedQtyController.text) ?? item.qty;
        item.rejectedQty =
            double.tryParse(item.rejectedQtyController.text) ?? item.rejectedQty;
        item.wastageQuantity =
            double.tryParse(item.wastageQtyController.text) ?? item.wastageQuantity;
        item.excessQuantity =
            double.tryParse(item.excessQtyController.text) ?? item.excessQuantity;

        // assign rejected warehouse only when qty > 0
        item.rejectedWarehouseController.text =
        item.rejectedQty > 0 ? item.rejectedWarehouseController.text : "";
      }

      // ---------------------------------------
      // 3️⃣ Build Purchase Receipt data
      // ---------------------------------------
      final receipt = PurchaseReceipt(
        supplier: _supplierController.text,
        warehouse: _warehouseController.text,
        rejectedWarehouse: _rejectedWarehouseController.text,
        items: widget.items,
        setPostingTime: _setPostingTime ? 1 : 0,
        postingDate: formattedPostingDate,
      );

      // ---------------------------------------
      // 4️⃣ Inject PO Name for mapping API
      //     (THIS FIXES YOUR ERROR)
      // ---------------------------------------
      if (widget.purchaseOrderName.isNotEmpty) {
        receipt.purchaseOrder = widget.purchaseOrderName;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❗ Purchase Order Name missing")),
        );
        return; // stop submission
      }

      // ---------------------------------------
      // 5️⃣ Call API
      // ---------------------------------------
      // provider.createPurchaseReceipt(context, receipt).then((result) {
      provider.submitPurchaseReceipt(context, receipt).then((result) {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Purchase Receipt Created")),
          );

          _formKey.currentState!.reset();
          setState(() {
            widget.items.clear();
          });

          _clearSavedData();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseReceiptScreen(),
            ),
          );
        }

        // Error returned as String
        else if (result is String) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❗ $result"),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Unknown fallback
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Failed to create receipt. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
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
  void _saveForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      // format posting date
      String formattedPostingDate = "";
      if (_setPostingTime && _postingDateController.text.isNotEmpty) {
        DateTime parsedDate =
        DateFormat('dd-MM-yyyy').parse(_postingDateController.text);
        formattedPostingDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      // update items
      for (var item in widget.items) {
        item.qty = double.tryParse(item.acceptedQtyController.text) ?? item.qty;
        item.rejectedQty =
            double.tryParse(item.rejectedQtyController.text) ?? item.rejectedQty;

        item.wastageQuantity =
            double.tryParse(item.wastageQtyController.text) ?? item.wastageQuantity;

        item.excessQuantity =
            double.tryParse(item.excessQtyController.text) ?? item.excessQuantity;

        item.rejectedWarehouseController.text =
        item.rejectedQty > 0 ? item.rejectedWarehouseController.text : "";
      }

      // build doc
      final receipt = PurchaseReceipt(
        supplier: _supplierController.text,
        warehouse: _warehouseController.text,
        rejectedWarehouse: _rejectedWarehouseController.text,
        items: widget.items,
        setPostingTime: _setPostingTime ? 1 : 0,
        postingDate: formattedPostingDate,
      );

      // Add po name
      if (widget.purchaseOrderName.isNotEmpty) {
        receipt.purchaseOrder = widget.purchaseOrderName;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❗ Purchase Order Name missing")),
        );
        return;
      }

      // call API as draft
      final result =
      await provider.savePurchaseReceipt(context, receipt);

      if (result == true) {
        setState(() {
          _isSaved = true;   // mark as saved
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("💾 Saved as Draft")),
        );
        return;
      }

      if (result is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to save. Try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,

        // Back button
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Purchase Receipt",
          style: TextStyle(
            // fontWeight: FontWeight.w600,
            // fontSize: 18,
              color: Colors.white
          ),
        ),

        // Save action button
        // actions: [
        //   IconButton(
        //     color: Colors.white,
        //     icon: const Icon(Icons.save),
        //     onPressed: () => _saveForm(context),
        //   ),
        // ],
        actions: [
          // Status Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _isSaved ? Icons.check_circle : Icons.error_outline,
                  color: _isSaved ? Colors.greenAccent : Colors.yellowAccent,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  _isSaved ? "Saved" : "Not Saved",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // Save Button
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.save),
            onPressed: () => _saveForm(context),
          ),
        ],

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

    return Stack(
      children: [
        Card(
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

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Received: ${(item.receivedQty ?? 0.0).toStringAsFixed(2)} ${item.uom ?? ''}",
                              ),
                            ),

                            SizedBox(width: 12),

                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: item.acceptedQtyController,
                                builder: (context, value, _) {
                                  final rawQty = double.tryParse(value.text) ?? 0.0;
                                  final acceptedQty = rawQty < 0 ? 0.0 : rawQty;

                                  return Text(
                                    "Accepted: ${acceptedQty.toStringAsFixed(2)} ${item.uom ?? ''}",
                                    style: const TextStyle(fontSize: 14),
                                  );
                                },
                              ),
                            ),
                          ],
                        )

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
        ),

        // 🔥 BATCH INDICATOR IN TOP RIGHT CORNER
        if (item.hasBatchNo)
          Positioned(
            top: 14,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

      ],
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
                const SizedBox(height: 35),

              ],
            ),

          ),

        ),

      ),

    );
  }
}
