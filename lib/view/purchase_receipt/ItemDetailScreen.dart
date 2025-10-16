// purchase_receipt_items_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sales_ordering_app/model/purchase_receipt_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';



class PurchaseReceiptItemsScreen extends StatefulWidget {
  final String supplier;
  final String warehouse;
  final String rejectedWarehouse; // New field for default rejected warehouse
  final PurchaseItem selectedItem;
  final Function(PurchaseItem) onSave;

  PurchaseReceiptItemsScreen({
    required this.supplier,
    required this.warehouse,
    required this.rejectedWarehouse, // Pass the rejected warehouse from parent
    required this.selectedItem,
    required this.onSave,
    
  });

  @override
  _PurchaseReceiptItemsScreenState createState() => _PurchaseReceiptItemsScreenState();
}

class _PurchaseReceiptItemsScreenState extends State<PurchaseReceiptItemsScreen> {
  late FocusNode _acceptedQtyFocusNode;
  late FocusNode _rejectedQtyFocusNode;
  late FocusNode _wastageQtyFocusNode;
  late FocusNode _excessQtyFocusNode;

  @override
  void initState() {
    super.initState();

    // Auto-fill rejected warehouse if empty
    if (widget.selectedItem.rejectedWarehouseController.text.isEmpty) {
      widget.selectedItem.rejectedWarehouseController.text = widget.rejectedWarehouse;
    }

    // Initialize focus nodes
    _acceptedQtyFocusNode = FocusNode();
    _rejectedQtyFocusNode = FocusNode();
    _wastageQtyFocusNode = FocusNode();
    _excessQtyFocusNode = FocusNode();

    // Attach listeners to auto-select text on focus
    _acceptedQtyFocusNode.addListener(() {
      if (_acceptedQtyFocusNode.hasFocus) {
        widget.selectedItem.acceptedQtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.selectedItem.acceptedQtyController.text.length,
        );
      }
    });

    _rejectedQtyFocusNode.addListener(() {
      if (_rejectedQtyFocusNode.hasFocus) {
        widget.selectedItem.rejectedQtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.selectedItem.rejectedQtyController.text.length,
        );
      }
    });

    _wastageQtyFocusNode.addListener(() {
      if (_wastageQtyFocusNode.hasFocus) {
        widget.selectedItem.wastageQtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.selectedItem.wastageQtyController.text.length,
        );
      }
    });

    _excessQtyFocusNode.addListener(() {
      if (_excessQtyFocusNode.hasFocus) {
        widget.selectedItem.excessQtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.selectedItem.excessQtyController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    // Clean up the focus nodes to avoid memory leaks
    _acceptedQtyFocusNode.dispose();
    _rejectedQtyFocusNode.dispose();
    _wastageQtyFocusNode.dispose();
    _excessQtyFocusNode.dispose();
    super.dispose();
  }

  void _saveAndReturn() {
    final rejectedQty = double.tryParse(widget.selectedItem.rejectedQtyController.text) ?? 0.0;
    final rejectedWarehouse = widget.selectedItem.rejectedWarehouseController.text.trim();

    // Validation: If rejectedQty > 0, rejectedWarehouse must not be empty
    if (rejectedQty > 0 && rejectedWarehouse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rejected Warehouse is required when Rejected Quantity is entered."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop execution if validation fails
    }
widget.selectedItem.finalReceivedQty =
    double.tryParse(widget.selectedItem.acceptedQtyController.text) ?? 0.0;

    // widget.selectedItem.receivedQty = double.tryParse(widget.selectedItem.acceptedQtyController.text) ?? 0.0;
    widget.selectedItem.rejectedQty = rejectedQty;
    widget.selectedItem.wastageQuantity = double.tryParse(widget.selectedItem.wastageQtyController.text) ?? 0.0;
    widget.selectedItem.excessQuantity = double.tryParse(widget.selectedItem.excessQtyController.text) ?? 0.0;

    widget.onSave(widget.selectedItem); // Update item in parent screen

    Navigator.pop(context); // Go back to PurchaseReceiptCreateScreen
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.selectedItem;

    return Scaffold(
      appBar: CommonAppBar(
        title: "Enter Item Details",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: SingleChildScrollView(
        // ✅ Fix Overflow by enabling scrolling
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item.itemName ?? 'Unknown Item'} (${item.itemCode ?? 'N/A'})",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text("Ordered Quantity: ${item.qty.toStringAsFixed(2)} ${item.uom ?? ''}"),
                    ],
                  ),
                ),
              ),

Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    // Accepted Quantity Field
    Expanded(
      child: TextFormField(
        controller: item.acceptedQtyController,
        focusNode: _acceptedQtyFocusNode,
        decoration: const InputDecoration(labelText: "Accepted Quantity"),
        keyboardType: TextInputType.number,
      ),
    ),
    const SizedBox(width: 12),

ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        // ✅ Initialize controllers with existing values if available
        List<int> existingQuantities = [];
        if (item.itemPackDetails != null && item.itemPackDetails!.isNotEmpty) {
          existingQuantities = item.itemPackDetails!
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .toList();
        }

        List<TextEditingController> packControllers = existingQuantities.isNotEmpty
            ? existingQuantities.map((qty) => TextEditingController(text: qty.toString())).toList()
            : [TextEditingController()];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Enter Pack Quantities"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(packControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: TextFormField(
                          controller: packControllers[index],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Pack ${index + 1} Quantity",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: "Add another pack",
                        onPressed: () {
                          setState(() {
                            packControllers.add(TextEditingController());
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final quantities = packControllers
                        .map((c) => int.tryParse(c.text.trim()) ?? 0)
                        .toList();

                    final totalAcceptedQty =
                        quantities.fold(0, (sum, qty) => sum + qty);

                    // ✅ Save accepted quantity and CSV string
                    item.acceptedQtyController.text =
                        totalAcceptedQty.toString();
                    item.itemPackDetails = quantities.join(","); // ✅ Save as CSV

                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  },
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: const Text("Details"),
),

  ],
),



              // ✅ Rejected Quantity Field
              TextFormField(
                controller: item.rejectedQtyController,
                focusNode: _rejectedQtyFocusNode,
                decoration: InputDecoration(labelText: "Rejected Quantity"),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {}); // Update UI dynamically
                },
              ),

              // ✅ Show "Rejected Warehouse" with Scrollable Autocomplete only if rejected qty > 0
              if (item.rejectedQtyController.text.isNotEmpty &&
                  (double.tryParse(item.rejectedQtyController.text) ?? 0) > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text("Rejected Warehouse", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
 Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<String>.empty();
    }

    try {
      // ✅ Fetch warehouse list dynamically
      final warehouseList = await Provider.of<SalesOrderProvider>(
        context,
        listen: false,
      ).fetchWarehouse(textEditingValue.text);

      return warehouseList; // ✅ Return the list or empty if no results
    } catch (e) {
      debugPrint("❗ Error fetching warehouse list: $e");
      return const Iterable<String>.empty();
    }
  },
  onSelected: (String selection) {
    setState(() {
      item.rejectedWarehouseController.text = selection; // ✅ Auto-select warehouse
    });
  },
  fieldViewBuilder:
      (context, controller, focusNode, onFieldSubmitted) {
    controller.text = item.rejectedWarehouseController.text;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: "Select Warehouse",
        prefixIcon: const Icon(Icons.warehouse),
        suffixIcon: const Icon(Icons.search),
      ),
      // ✅ Auto-select text when the field is tapped
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
      onChanged: (value) {
        setState(() {
          item.rejectedWarehouseController.text = value;
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
          constraints: const BoxConstraints(maxHeight: 200), // ✅ Limit dropdown height
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


                  ],
                ),

              // ✅ Wastage Quantity Field
              TextFormField(
                controller: item.wastageQtyController,
                focusNode: _wastageQtyFocusNode,
                decoration: InputDecoration(labelText: "Wastage Quantity"),
                keyboardType: TextInputType.number,
              ),

              // ✅ Excess Quantity Field
              TextFormField(
                controller: item.excessQtyController,
                focusNode: _excessQtyFocusNode,
                decoration: InputDecoration(labelText: "Excess Quantity"),
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAndReturn,
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
