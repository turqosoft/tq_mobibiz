import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:intl/intl.dart';

class StockReconciliationListScreen extends StatefulWidget {
  @override
  _StockReconciliationListScreenState createState() =>
      _StockReconciliationListScreenState();

}

class _StockReconciliationListScreenState
    extends State<StockReconciliationListScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
  }

String _formatDate(String dateString) {
  try {
    DateTime parsedDate = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy').format(parsedDate);
  } catch (e) {
    return 'Invalid Date'; // Handle errors gracefully
  }
}


  void _fetchInitialData() {
  Provider.of<SalesOrderProvider>(context, listen: false)
      .refreshStockReconciliations(context);
  }


void _onScroll() {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
      !provider.isLoading &&
      provider.hasMoreData) {
    debugPrint("🔽 Scroll triggered: fetching more data...");
    provider.fetchStockReconciliations(context);
  }
}



  // **Pull-to-refresh function**
  Future<void> _refreshData() async {
    await Provider.of<SalesOrderProvider>(context, listen: false)
        .refreshStockReconciliations(context);
  }

  void _showStockReconciliationDetails(BuildContext context, String reconciliationName) {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);

  // Fetch stock reconciliation details
  provider.fetchStockReconciliationDetails(context, reconciliationName).then((_) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<SalesOrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingDetails) {
              return AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            if (provider.hasErrorDetails) {
              return AlertDialog(
                title: Text('Error'),
                content: Text(provider.errorMessageDetails ?? "Failed to load details"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              );
            }

            if (provider.stockReconciliationDetails == null) {
              return AlertDialog(
                title: Text('No Details Found'),
                content: Text('Stock reconciliation details are unavailable.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              );
            }

            final details = provider.stockReconciliationDetails!;
            final List<dynamic> items = details['items'] ?? []; // Assuming items is a list

            return AlertDialog(
              title: Text('Stock Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final itemCode = item['item_code'];
                    final binActualQty = provider.actualQtyMap[itemCode] ?? 'N/A';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item['item_name'] ?? 'N/A'} (${itemCode ?? 'N/A'})",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Wastage Qty: ${item['qty'] ?? 'N/A'}"),
                        // Text("Reconciliation Qty: ${item['actual_qty'] ?? 'N/A'}"),
                        Text("Actual Qty: $binActualQty"), // 👈 Added line
                        Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            );

          },
        );
      },
    );
  });
}


void _confirmDelete(BuildContext context, String docName) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Confirm Deletion"),
      content: Text("Are you sure you want to delete $docName?"),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        TextButton(
          child: Text("Delete", style: TextStyle(color: Colors.red)),
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await Provider.of<SalesOrderProvider>(context, listen: false)
                  .deleteStockReconciliationByName(context, docName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleted successfully")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to delete: $e")),
              );
            }
          },
        ),
      ],
    ),
  );
}

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> reconciliation) async {
    final yourProvider = Provider.of<SalesOrderProvider>(context, listen: false);
    final fullEntry = await yourProvider.fetchStockReconciliationByName(reconciliation['name']);
    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(fullEntry['items'] ?? []);

    final List<TextEditingController> controllers = List.generate(
      items.length,
          (index) => TextEditingController(text: items[index]['qty']?.toString() ?? ''),
    );

    // Create focus nodes for each text field
    final List<FocusNode> focusNodes = List.generate(
      items.length,
          (index) => FocusNode(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Stock Entry Quantities'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final controller = controllers[index];
                      final focusNode = focusNodes[index];
                      final binQty = yourProvider.actualQtyMap[item['item_code']] ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item_name'] ?? item['item_code'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("Actual Qty: $binQty"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              onTap: () {
                                // Select all text only when user taps the field
                                controller.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: controller.text.length,
                                );
                              },
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && mounted) {
                                  setState(() {
                                    item['qty'] = parsed;
                                  });
                                }
                              },
                            ),
                            const Divider(height: 24),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await yourProvider.updateStockEntryByName(
                        context,
                        reconciliation['name'],
                        items,
                      );
                      if (mounted) {
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stock Updated Successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update Stock Entry: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dispose all focus nodes when dialog is closed
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
  }
  // Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> reconciliation) async {
  //   final yourProvider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   final fullEntry = await yourProvider.fetchStockReconciliationByName(reconciliation['name']);
  //   List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(fullEntry['items'] ?? []);
  //
  //   final List<TextEditingController> controllers = List.generate(
  //     items.length,
  //         (index) => TextEditingController(text: items[index]['qty']?.toString() ?? ''),
  //   );
  //
  //   await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: const Text('Edit Stock Entry Quantities'),
  //             content: SizedBox(
  //               width: double.maxFinite,
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   children: List.generate(items.length, (index) {
  //                     final item = items[index];
  //                     final controller = controllers[index];
  //                     final binQty = yourProvider.actualQtyMap[item['item_code']] ?? 0.0;
  //
  //                     return Padding(
  //                       padding: const EdgeInsets.symmetric(vertical: 10.0),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             item['item_name'] ?? item['item_code'],
  //                             style: const TextStyle(fontWeight: FontWeight.bold),
  //                           ),
  //                           const SizedBox(height: 4),
  //                           Text("Actual Qty: $binQty"),
  //                           const SizedBox(height: 8),
  //                           TextField(
  //                             controller: controller,
  //                             keyboardType: TextInputType.number,
  //                             decoration: const InputDecoration(
  //                               labelText: 'Quantity',
  //                               border: OutlineInputBorder(),
  //                             ),
  //                             onChanged: (val) {
  //                               final parsed = double.tryParse(val);
  //                               if (parsed != null && mounted) {
  //                                 setState(() {
  //                                   item['qty'] = parsed;
  //                                 });
  //                               }
  //                             },
  //                           ),
  //                           const Divider(height: 24),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ),
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.of(context).pop(false),
  //                 child: const Text('Cancel'),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   try {
  //                     await yourProvider.updateStockEntryByName(
  //                       context,
  //                       reconciliation['name'],
  //                       items,
  //                     );
  //                     if (mounted) {
  //                       Navigator.of(context).pop(true);
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                           content: Text('Stock Updated Successfully'),
  //                           backgroundColor: Colors.green,
  //                         ),
  //                       );
  //                     }
  //                   } catch (e) {
  //                     if (mounted) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(
  //                           content: Text('Failed to update Stock Entry: $e'),
  //                           backgroundColor: Colors.red,
  //                         ),
  //                       );
  //                     }
  //                   }
  //                 },
  //                 child: const Text('Save'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          // if (provider.isLoading && provider.stockReconciliations!.isEmpty) 
          if (provider.isLoading && (provider.stockReconciliations?.isEmpty ?? true))

          {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Text(provider.errorMessage ?? 'An error occurred'),
            );
          }

          if (provider.stockReconciliations!.isEmpty) {
            return Center(child: Text('No Stock Update found.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshData, // **Trigger refresh on swipe-down**
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.stockReconciliations!.length +
                  (provider.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < provider.stockReconciliations!.length) {
                  final reconciliation = provider.stockReconciliations![index];
                  final cardColors = [
                    const Color.fromARGB(255, 205, 227, 225), // Light teal
                    const Color.fromARGB(255, 205, 213, 221), // Light blue-grey
                  ];
                  final cardColor =
                      cardColors[index % cardColors.length]; // Alternating colors

                  // Define the status label and color based on `docstatus`
                  String statusText;
                  Color statusColor;
                  switch (reconciliation['docstatus']) {
                    case 0:
                      statusText = 'Draft';
                      statusColor = Colors.orange;
                      break;
                    case 1:
                      statusText = 'Submitted';
                      statusColor = Colors.green;
                      break;
                    case 2:
                      statusText = 'Cancelled';
                      statusColor = Colors.red;
                      break;
                    default:
                      statusText = 'Unknown';
                      statusColor = Colors.grey;
                  }


return Card(
  color: cardColor,
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    title: Text(
      reconciliation['name'],
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Text('Date: ${_formatDate(reconciliation['posting_date'])}'),
        SizedBox(height: 4),
        Row(
          children: [
            Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(statusText, style: TextStyle(color: statusColor)),
          ],
        ),
      ],
    ),
  


trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: Icon(Icons.remove_red_eye_rounded, color: Colors.black),
      onPressed: () {
        _showStockReconciliationDetails(context, reconciliation['name']);
      },
    ),
    if (reconciliation['docstatus'] == 0) ...[
//       IconButton(
//         icon: Icon(Icons.edit, color: Colors.blue),
// onPressed: () async {
//   final result = await _showEditDialog(context, reconciliation);
//
//   if (result == true) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Stock Updated Successfully')),
//       );
//     });
//   }
// },
//
//
//       ),
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: () async {
          try {
            await _showEditDialog(context, reconciliation);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
      IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          _confirmDelete(context, reconciliation['name']);
        },
      ),
    ],
  ],
),


  ),
);

                } else if (provider.hasMoreData && provider.isLoading) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Center(child: CircularProgressIndicator()),
  );
} else {
  return SizedBox.shrink(); // Don't render anything if no more data
}

              },
            ),

          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
