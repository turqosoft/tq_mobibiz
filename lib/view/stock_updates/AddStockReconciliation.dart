import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';


class StockLedgerScreen extends StatefulWidget {
  const StockLedgerScreen({Key? key}) : super(key: key);

  @override
  StockLedgerScreenState createState() => StockLedgerScreenState();
}

class StockLedgerScreenState extends State<StockLedgerScreen> {
  bool _isSubmitting = false;

  // void showSelectedItemsPreview() {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   if (provider.selectedItems.isEmpty) return;
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Review Selected Items"),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             children: provider.selectedItems.map((item) {
  //               return ListTile(
  //                 title: Text(item['item_name']),
  //                 subtitle: Text("Quantity: ${item['entered_qty']}"),
  //                 trailing: IconButton(
  //                   icon: const Icon(Icons.remove_circle),
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     provider.removeSelectedItem(item);
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(content: Text("${item['item_name']} removed")),
  //                     );
  //                     Future.delayed(const Duration(milliseconds: 200), () {
  //                       if (mounted) showSelectedItemsPreview();
  //                     });
  //                   },
  //                 ),
  //               );
  //             }).toList(),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               setState(() => _isSubmitting = true);
  //
  //               showDialog(
  //                 context: context,
  //                 barrierDismissible: false,
  //                 builder: (BuildContext context) {
  //                   return const Center(child: CircularProgressIndicator());
  //                 },
  //               );
  //
  //               await _submitMultipleItems();
  //
  //               if (mounted) {
  //                 Navigator.pop(context); // close loading
  //                 Navigator.pop(context); // close dialog
  //               }
  //
  //               setState(() => _isSubmitting = false);
  //             },
  //             child: _isSubmitting
  //                 ? const SizedBox(
  //               height: 20,
  //               width: 20,
  //               child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
  //             )
  //                 : const Text("Save"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void showSelectedItemsPreview() {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    if (provider.selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _isSubmitting = true);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(child: CircularProgressIndicator());
                        },
                      );

                      await _submitMultipleItems();

                      if (mounted) {
                        Navigator.pop(context); // close loading
                        Navigator.pop(context); // close dialog
                      }

                      setState(() => _isSubmitting = false);
                    },
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                        : const Text("Submit"),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              const Divider(),

              // Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Review Selected Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8.0),

              // Items list
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: provider.selectedItems.map((item) {
                      return ListTile(
                        title: Text(item['item_name']),
                        subtitle: Text("Quantity: ${item['entered_qty']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () {
                            Navigator.pop(context);
                            provider.removeSelectedItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${item['item_name']} removed")),
                            );
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (mounted) showSelectedItemsPreview();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _submitMultipleItems() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.removeZeroQtyItems();
    await provider.createMaterialTransfer(context, provider.selectedItems);
    provider.clearSelectedItems();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      await provider.fetchBinStock(context);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stockLedgerEntries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.stockLedgerEntries.isEmpty) {
            return const Center(child: Text("No Stock Data Available"));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchBinStock(context, clearData: true);
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!provider.isLoading &&
                          provider.hasMoreData &&
                          scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        provider.fetchBinStock(context, isPagination: true);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.stockLedgerEntries.length + (provider.hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.stockLedgerEntries.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final entry = provider.stockLedgerEntries[index];
                        final isDisabled = (entry['actual_qty'] ?? 0.0) == 0.0;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(
                              "${entry['item_name'] ?? 'Unknown Item'} (${entry['item_code'] ?? 'N/A'})",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDisabled ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Warehouse: ${entry['warehouse'] ?? 'N/A'}"),
                                Text(
                                  "Qty: ${entry['actual_qty'] ?? 'N/A'} ${entry['stock_uom'] ?? ''}",
                                  style: TextStyle(
                                    color: isDisabled ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            onTap: isDisabled
                                ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cannot enter wastage for items with 0 quantity."),
                                ),
                              );
                            }
                                : () => _showQuantityPopup(context, entry),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
// class StockLedgerScreen extends StatefulWidget {
//   const StockLedgerScreen({Key? key}) : super(key: key);
//
//   @override
//   StockLedgerScreenState createState() => StockLedgerScreenState();
// }
//
// class StockLedgerScreenState extends State<StockLedgerScreen> {
//   final List<Map<String, dynamic>> selectedItems = [];
//   bool _isSubmitting = false;
//
//   void showSelectedItemsPreview() {
//     if (selectedItems.isEmpty) return;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Review Selected Items"),
//           content: SingleChildScrollView(
//             child: Column(
//               children: selectedItems.map((item) {
//                 return ListTile(
//                   title: Text(item['item_name']),
//                   subtitle: Text("Quantity: ${item['entered_qty']}"),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.remove_circle),
//                     onPressed: () {
//                       Navigator.pop(context);
//                       setState(() {
//                         selectedItems.remove(item);
//                       });
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text("${item['item_name']} removed")),
//                       );
//                       Future.delayed(const Duration(milliseconds: 200), () {
//                         if (mounted) showSelectedItemsPreview();
//                       });
//                     },
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 setState(() => _isSubmitting = true);
//
//                 // Show loading dialog
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (BuildContext context) {
//                     return const Center(child: CircularProgressIndicator());
//                   },
//                 );
//
//                 await _submitMultipleItems();
//
//                 if (mounted) {
//                   Navigator.pop(context); // Close loading dialog
//                   Navigator.pop(context); // Close alert dialog
//                 }
//
//                 setState(() => _isSubmitting = false);
//               },
//               child: _isSubmitting
//                   ? const SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
//               )
//                   : const Text("Confirm Submission"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _submitMultipleItems() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//     // Remove zero quantity items
//     selectedItems.removeWhere((item) => item['entered_qty'] == 0.0);
//
//     await provider.createMaterialTransfer(context, selectedItems);
//
//     if (mounted) {
//       setState(() {
//         selectedItems.clear();
//       });
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//       await provider.fetchBinStock(context);
//       setState(() {}); // Optional: refresh the UI if needed
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Consumer<SalesOrderProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading && provider.stockLedgerEntries.isEmpty) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (provider.hasError) {
//             return Center(child: Text('Error: ${provider.errorMessage}'));
//           }
//
//           if (provider.stockLedgerEntries.isEmpty) {
//             return const Center(child: Text("No Stock Data Available"));
//           }
//
//           return Column(
//             children: [
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     await provider.fetchBinStock(context, clearData: true); // Refresh logic
//                   },
//                   child: NotificationListener<ScrollNotification>(
//                     onNotification: (scrollInfo) {
//                       if (!provider.isLoading &&
//                           provider.hasMoreData &&
//                           scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
//                         provider.fetchBinStock(context, isPagination: true);
//                       }
//                       return false;
//                     },
//                     child: ListView.builder(
//                       physics: const AlwaysScrollableScrollPhysics(), // Ensure pull even if content is short
//                       itemCount: provider.stockLedgerEntries.length + (provider.hasMoreData ? 1 : 0),
//                       itemBuilder: (context, index) {
//                         if (index == provider.stockLedgerEntries.length) {
//                           return const Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Center(child: CircularProgressIndicator()),
//                           );
//                         }
//
//                         final entry = provider.stockLedgerEntries[index];
//                         debugPrint('Displaying item: ${entry['item_code']} → ${entry['item_name']}');
//
//                         bool isDisabled = (entry['actual_qty'] ?? 0.0) == 0.0;
//
//                         return Card(
//                           elevation: 3,
//                           margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                           child: ListTile(
//                             title: Text(
//                               "${entry['item_name'] ?? 'Unknown Item'} (${entry['item_code'] ?? 'N/A'})",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: isDisabled ? Colors.grey : Colors.black,
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text("Warehouse: ${entry['warehouse'] ?? 'N/A'}"),
//                                 Text(
//                                   "Qty: ${entry['actual_qty'] ?? 'N/A'} ${entry['stock_uom'] ?? ''}",
//                                   style: TextStyle(
//                                     color: isDisabled ? Colors.grey : Colors.black,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             onTap: isDisabled
//                                 ? () {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text("Cannot enter wastage for items with 0 quantity."),
//                                 ),
//                               );
//                             }
//                                 : () => _showQuantityPopup(context, entry),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               // ElevatedButton(
//               //   onPressed: selectedItems.isEmpty ? null : _showSelectedItemsPreview,
//               //   child: Text("Update Stock for ${selectedItems.length} items"),
//               // ),
//             ],
//           );
//         },
//       ),
//     );
//   }

  // void _showQuantityPopup(BuildContext context, Map<String, dynamic> entry) {
  //   TextEditingController qtyController = TextEditingController();
  //   FocusNode focusNode = FocusNode();
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       Future.delayed(Duration(milliseconds: 100), () {
  //         if (mounted) FocusScope.of(context).requestFocus(focusNode);
  //       });
  //
  //       return AlertDialog(
  //         title: Text("Enter Wastage Quantity for ${entry['item_name']}"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             if (entry['actual_qty'] != null)
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 12.0),
  //                 child: Text(
  //                   "Actual Qty: ${entry['actual_qty']}",
  //                   style: const TextStyle(fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //             TextField(
  //               controller: qtyController,
  //               focusNode: focusNode,
  //               keyboardType: TextInputType.number,
  //               decoration: const InputDecoration(labelText: "Quantity"),
  //               textInputAction: TextInputAction.done,
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               double enteredQty = double.tryParse(qtyController.text) ?? 0.0;
  //
  //               if (enteredQty <= 0) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text("Please enter a valid quantity")),
  //                 );
  //                 return;
  //               }
  //
  //               // ✅ Duplicate item_code check
  //               bool isDuplicate = selectedItems.any((item) =>
  //               item['item_code'] == entry['item_code']);
  //
  //               if (isDuplicate) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text("${entry['item_name']} is already added.")),
  //                 );
  //                 Navigator.pop(context);
  //                 return;
  //               }
  //
  //               setState(() {
  //                 selectedItems.add({
  //                   'item_code': entry['item_code'],
  //                   'warehouse': entry['warehouse'],
  //                   'entered_qty': enteredQty,
  //                   'item_name': entry['item_name'],
  //                 });
  //               });
  //               Navigator.pop(context);
  //             },
  //             child: const Text("Add Item"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void _showQuantityPopup(BuildContext context, Map<String, dynamic> entry) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    TextEditingController qtyController = TextEditingController();
    FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) FocusScope.of(context).requestFocus(focusNode);
        });

        return AlertDialog(
          title: Text("Enter Wastage Quantity for ${entry['item_name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry['actual_qty'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "Actual Qty: ${entry['actual_qty']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              TextField(
                controller: qtyController,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                double enteredQty = double.tryParse(qtyController.text) ?? 0.0;

                if (enteredQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid quantity")),
                  );
                  return;
                }

                bool isDuplicate = provider.selectedItems.any(
                      (item) => item['item_code'] == entry['item_code'],
                );

                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${entry['item_name']} is already added.")),
                  );
                  Navigator.pop(context);
                  return;
                }

                provider.addSelectedItem({
                  'item_code': entry['item_code'],
                  'warehouse': entry['warehouse'],
                  'entered_qty': enteredQty,
                  'item_name': entry['item_name'],
                });

                Navigator.pop(context);
              },
              child: const Text("Add Item"),
            ),
          ],
        );
      },
    );
  }



//   bool _isSubmitting = false;
//
//   void _showSelectedItemsPreview() {
//     if (selectedItems.isEmpty) {
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(content: Text("Please select at least one item")),
//       // );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Review Selected Items"),
//           content: SingleChildScrollView(
//             child: Column(
//               children: selectedItems.map((item) {
//                 return ListTile(
//                   title: Text(item['item_name']),
//                   subtitle: Text("Quantity: ${item['entered_qty']}"),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.remove_circle),
//                     onPressed: () {
//                       Navigator.pop(context);
//
//                       setState(() {
//                         selectedItems.remove(item);
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text("${item['item_name']} removed")),
//                       );
//
//                       Future.delayed(Duration(milliseconds: 200), () {
//                         if (mounted) _showSelectedItemsPreview();
//                       });
//                     },
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//
// ElevatedButton(
// onPressed: () async {
//   // Show loading dialog
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     },
//   );
//
//   await _submitMultipleItems();
//
//   if (mounted) {
//     Navigator.pop(context); // Close the loading dialog
//     Navigator.pop(context); // Close the bottom sheet/dialog if needed
//   }
// },
//
//   child: _isSubmitting
//       ? const SizedBox(
//           height: 20,
//           width: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2.5,
//             color: Colors.white,
//           ),
//         )
//       : const Text("Confirm Submission"),
// ),
//
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _submitMultipleItems() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//     // Remove items with actual_qty == 0 before submission
//     selectedItems.removeWhere((item) => item['entered_qty'] == 0.0);
//
//     await provider.createMaterialTransfer(context, selectedItems);
//
//     if (mounted) {
//       setState(() {
//         selectedItems.clear();
//       });
//     }
//   }
}
