import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import '../../utils/sharedpreference.dart';


class PickListDetailsPage extends StatefulWidget {
  final String pickListName;

  const PickListDetailsPage({required this.pickListName});

  @override
  _PickListDetailsPageState createState() => _PickListDetailsPageState();
}

class _PickListDetailsPageState extends State<PickListDetailsPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  Map<String, TextEditingController> _availControllers = {};
  final Map<String, FocusNode> _availFocusNodes = {};
  Map<String, bool> _lessQtyWarning = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, FocusNode> _priceFocusNodes = {};
  Map<String, bool> _isQtyMatched = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<SalesOrderProvider>(context, listen: false)
        .fetchPickListDetails(context, widget.pickListName));

  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text("Pick List Details",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryColor,
          // Makes back button icon WHITE
          iconTheme: const IconThemeData(color: Colors.white),

          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: "Update All",
              // onPressed: () async {
              //   final provider =
              //   Provider.of<SalesOrderProvider>(context, listen: false);
              //
              //   final List<dynamic> locations =
              //       provider.pickListDetails!["locations"] ?? [];
              //
              //   List<Map<String, dynamic>> updatedLocations =
              //   locations.map<Map<String, dynamic>>((item) {
              //     String itemKey = item["name"];
              //
              //     double newPickedQty =
              //         double.tryParse(_controllers[itemKey]?.text ?? "") ??
              //             item["picked_qty"];
              //
              //     double newAvailQty =
              //         double.tryParse(_availControllers[itemKey]?.text ?? "") ??
              //             item["qty"];
              //     double newRate =
              //         double.tryParse(_priceControllers[itemKey]?.text ?? "") ??
              //             item["mrp"];
              //
              //
              //     return {
              //       "name": itemKey,
              //       "item_code": item["item_code"],
              //       "item_name": item["item_name"],
              //       "warehouse": item["warehouse"],
              //       "qty": newAvailQty,
              //       "stock_qty": newAvailQty,
              //       "picked_qty": newPickedQty,
              //       "uom": item["uom"],
              //       "original_qty": item["qty"],
              //       "mrp": newRate,
              //     };
              //   }).toList();
              //
              //   // --------------------------------------------------------
              //   // 🔥 STEP A — CHECK IF ANY ITEM HAS picked_qty == 0 OR EMPTY
              //   // --------------------------------------------------------
              //   bool hasZeroPicked = false;
              //
              //   for (var item in updatedLocations) {
              //     double picked = item["picked_qty"] ?? 0;
              //
              //     if (picked == 0) {
              //       hasZeroPicked = true;
              //       break;
              //     }
              //   }
              //
              //   if (hasZeroPicked) {
              //     bool? confirmZero = await showDialog(
              //       context: context,
              //       builder: (ctx) => AlertDialog(
              //         title: const Text("Confirm"),
              //         content: const Text(
              //             "Some items have 0 picked quantity.\nAre you sure you want to continue?"),
              //         actions: [
              //           TextButton(
              //             onPressed: () => Navigator.pop(ctx, false),
              //             child: const Text("Cancel"),
              //           ),
              //           ElevatedButton(
              //             onPressed: () => Navigator.pop(ctx, true),
              //             child: const Text("Continue"),
              //           ),
              //         ],
              //       ),
              //     );
              //
              //     if (confirmZero != true) return; // user cancelled
              //   }
              //
              //   // --------------------------------------------------------
              //   // 🔥 STEP B — PROCEED WITH UPDATE
              //   // --------------------------------------------------------
              //   final result = await provider.updatePickedQtyList(
              //     context,
              //     widget.pickListName,
              //     updatedLocations,
              //   );
              //
              //   final msg = result["success"] == true
              //       ? "Updated successfully"
              //       : "Update failed: ${result["message"]}";
              //
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(content: Text(msg)),
              //   );
              //
              //   if (result["success"] == true) {
              //     await Future.delayed(const Duration(milliseconds: 500));
              //     Navigator.pop(context);
              //   }
              // },
              onPressed: () async {
                final provider =
                Provider.of<SalesOrderProvider>(context, listen: false);

                final List<dynamic> locations =
                    provider.pickListDetails!["locations"] ?? [];

                final autoSubmit = await SharedPrefService().getAutoSubmitPickList();

                // -------------------------------------------
                // 🔥 STEP 0 — SHOW AUTO-SUBMIT CONFIRMATION
                // -------------------------------------------
                if (autoSubmit == true) {
                  bool? confirmSubmit = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Submit Pick List?"),
                      content: const Text(
                          "Submitting will finalize this Pick List.\nDo you want to continue?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  );

                  if (confirmSubmit != true) return;   // user cancelled submit
                }

                // -------------------------------------------
                // 🔥 STEP 1 — BUILD UPDATED ITEMS
                // -------------------------------------------
                List<Map<String, dynamic>> updatedLocations =
                locations.map<Map<String, dynamic>>((item) {
                  String itemKey = item["name"];

                  double newPickedQty =
                      double.tryParse(_controllers[itemKey]?.text ?? "") ??
                          item["picked_qty"];

                  double newAvailQty =
                      double.tryParse(_availControllers[itemKey]?.text ?? "") ??
                          item["qty"];

                  double newRate =
                      double.tryParse(_priceControllers[itemKey]?.text ?? "") ??
                          item["mrp"];

                  return {
                    "name": itemKey,
                    "item_code": item["item_code"],
                    "item_name": item["item_name"],
                    "warehouse": item["warehouse"],
                    "qty": newAvailQty,
                    "stock_qty": newAvailQty,
                    "picked_qty": newPickedQty,
                    "uom": item["uom"],
                    "original_qty": item["qty"],
                    "mrp": newRate,
                  };
                }).toList();

                // --------------------------------------------------------
                // 🔥 STEP 2 — CHECK IF ANY ITEM HAS picked_qty == 0
                // --------------------------------------------------------
                bool hasZeroPicked = updatedLocations.any(
                        (item) => (item["picked_qty"] ?? 0) == 0);

                if (hasZeroPicked) {
                  bool? confirmZero = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text(
                          "Some items have 0 picked quantity.\nAre you sure you want to continue?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Continue"),
                        ),
                      ],
                    ),
                  );

                  if (confirmZero != true) return;
                }

                // --------------------------------------------------------
                // 🔥 STEP 3 — UPDATE PICKLIST
                // --------------------------------------------------------
                final result = await provider.updatePickedQtyList(
                  context,
                  widget.pickListName,
                  updatedLocations,
                );

                final msg = result["success"] == true
                    ? "Updated successfully"
                    : "Update failed: ${result["message"]}";

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );

                if (result["success"] == true) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  Navigator.pop(context);
                }
              },



            ),
          ],
        ),

      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.hasDetailsError) {
            return Center(child: Text(provider.detailsErrorMessage ?? "Error"));
          } else if (provider.pickListDetails == null) {
            return const Center(child: Text("No details"));
          }

          final details = provider.pickListDetails!;
          final List<dynamic> locations = details["locations"] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ----------------- COMPACT HEADER -----------------
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _headerRow(Icons.list_alt, "Name", details["name"]),
                      _headerRow(Icons.person, "Customer", details["customer"]),
                      _headerRow(Icons.info_outline, "Purpose", details["purpose"]),
                    ],
                  ),
                ),
              ),

          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: const [
                    Icon(Icons.inventory_2, size: 20, color: Colors.black54),
                    SizedBox(width: 6),
                    Text("Items",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

// ----------------- COMPACT ITEMS LIST -----------------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom > 0
                        ? MediaQuery.of(context).viewPadding.bottom + 10
                        : 10, // add minimal padding when no nav bar
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final item = locations[index];
                      final String itemKey = item["name"];

                      if (!_controllers.containsKey(itemKey)) {
                        _controllers[itemKey] =
                            TextEditingController(text: item["picked_qty"].toString());
                      }
                      if (!_focusNodes.containsKey(itemKey)) {
                        _focusNodes[itemKey] = FocusNode();
                      }
                      if (!_availControllers.containsKey(itemKey)) {
                        _availControllers[itemKey] = TextEditingController(
                          text: item["qty"].toString(),   // default = qty
                        );
                      }
                      if (!_availFocusNodes.containsKey(itemKey)) {
                        _availFocusNodes[itemKey] = FocusNode();
                      }
                      if (!_priceControllers.containsKey(itemKey)) {
                        _priceControllers[itemKey] =
                            TextEditingController(text: item["mrp"]?.toString() ?? "0");
                      }
                      if (!_priceFocusNodes.containsKey(itemKey)) {
                        _priceFocusNodes[itemKey] = FocusNode();
                      }


                      return _itemCard(item, itemKey);
                    },
                  ),
                ),
              ),


            ],
          );
        },
      ));
  }

// ----------------- COMPACT HEADER ROW -----------------
  Widget _headerRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text("$label:", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// ----------------- COMPACT ITEM CARD -----------------
  Widget _itemCard(dynamic item, String itemKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // /// ITEM TITLE
          // Text(
          //   "${item["item_name"]} (${item["item_code"]})",
          //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          // ),
          //
          // if (item["item_name_local"] != null)
          //   Text(
          //     item["item_name_local"],
          //     style: const TextStyle(fontSize: 12, color: Colors.black54),
          //   ),
          /// TITLE + THUMBS UP
          Row(
            children: [
              Expanded(   // <-- FIX: prevents overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item["item_name"]} (${item["item_code"]})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    if (item["item_name_local"] != null)
                      Text(
                        item["item_name_local"],
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
              ),

              /// ⭐ THUMBS UP ICON
              if (_isQtyMatched[itemKey] == true)
                const Icon(Icons.thumb_up, color: Colors.green, size: 26),
            ],
          ),


          const SizedBox(height: 6),

          /// REQUIRED QTY ROW
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),

              Text(
                "Required: ${item["qty"]} ${item["uom"]}",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔥 SINGLE ROW: PICKED | AVAIL | RATE
          Row(
            children: [
              // /// REQUIRED QTY (READ ONLY)
              // SizedBox(
              //   width: 80,
              //   height: 34,
              //   child: TextField(
              //     enabled: false,
              //     controller: TextEditingController(text: item["qty"].toString()),
              //     decoration: InputDecoration(
              //       labelText: "Req",
              //       labelStyle: const TextStyle(fontSize: 11),
              //       contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              //       filled: true,
              //       fillColor: const Color(0xFFE8ECF1), // light grey
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(6),
              //       ),
              //     ),
              //     style: const TextStyle(fontSize: 13, color: Colors.black87),
              //   ),
              // ),
              // const SizedBox(width: 10),

              /// PICKED QTY
              SizedBox(
                width: 80,
                height: 34,
                child: TextField(
                  controller: _controllers[itemKey],
                  focusNode: _focusNodes[itemKey],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    double picked = double.tryParse(value) ?? 0;
                    double original = item["qty"] ?? 0;

                    setState(() {
                      _lessQtyWarning[itemKey] = picked < original;
                      _isQtyMatched[itemKey] = picked == original;   // ⭐ NEW LINE

                    });
                  },
                  onTap: () {
                    _controllers[itemKey]!.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[itemKey]!.text.length,
                    );
                  },
                  decoration: InputDecoration(
                    labelText: "Picked",
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),

              /// RATE
              SizedBox(
                width: 90,
                height: 34,
                child: TextField(
                  controller: _priceControllers[itemKey],
                  focusNode: _priceFocusNodes[itemKey],
                  keyboardType: TextInputType.number,
                  onTap: () {
                    _priceControllers[itemKey]!.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _priceControllers[itemKey]!.text.length,
                    );
                  },
                  decoration: InputDecoration(
                    labelText: "MRP",
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),

              /// AVAIL QTY
              SizedBox(
                width: 80,
                height: 34,
                child: TextField(
                  controller: _availControllers[itemKey],
                  focusNode: _availFocusNodes[itemKey],
                  keyboardType: TextInputType.number,
                  onTap: () {
                    _availControllers[itemKey]!.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _availControllers[itemKey]!.text.length,
                    );
                  },
                  decoration: InputDecoration(
                    labelText: "Avail",
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: const Color(0xFFFAD4D4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),


            ],
          ),

          /// WARNING (if picked < required)
          if (_lessQtyWarning[itemKey] == true) ...[
            const SizedBox(height: 6),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Text(
                  "Picked qty is less than planned!",
                  style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
