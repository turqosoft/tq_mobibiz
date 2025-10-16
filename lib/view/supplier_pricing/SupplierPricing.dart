import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/supplier_pricing_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';

class SupplierPricingScreen extends StatelessWidget {
  final TextEditingController _searchController =
      TextEditingController(); // Add controller

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.itemPrices == null || provider.itemPrices!.isEmpty) {
        provider.fetchItemPrices(context);
      }
    });

// void _showAddItemPriceDialog(BuildContext context, [Map<String, dynamic>? item]) async {
//   final _priceListController = TextEditingController();
//   final _priceListRateController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final TextEditingController _uomController = TextEditingController();
//   String? selectedItemCode;

//   if (item != null) {
//     _priceListRateController.text = item['price_list_rate']?.toString() ?? '';
//     _descriptionController.text = item['item_name_local'] ?? ''; // Prefill description
//     _uomController.text = item['uom'] ?? ''; // Prefill UOM
//     selectedItemCode = item['item_code'];
//   }

//   try {
//     final priceList = await Provider.of<SalesOrderProvider>(context, listen: false)
//         .apiService!
//         .fetchPriceList();

//     if (priceList == null || priceList.isEmpty) {
//       throw Exception('No price list found for the logged-in user');
//     }

//     _priceListController.text = item?['price_list'] ?? priceList;
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: Text(item == null ? 'Add Item Price' : 'Edit Item Price'),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (item == null) ...[
//                   Consumer<SalesOrderProvider>(
//                     builder: (context, provider, child) {
//                       return Autocomplete<Map<String, dynamic>>(
//                         optionsBuilder: (TextEditingValue textEditingValue) {
//                           final query = textEditingValue.text.trim();
//                           if (query.isEmpty) {
//                             return const Iterable<Map<String, dynamic>>.empty();
//                           }

//                           provider.fetchItemSuggestions(context, query);

//                           return provider.itemSuggestions.where((option) {
//                             final itemName = option['item_name']?.toString().toLowerCase() ?? '';
//                             final itemCode = option['item_code']?.toString().toLowerCase() ?? '';
//                             return itemName.contains(query.toLowerCase()) || itemCode.contains(query.toLowerCase());
//                           });
//                         },
//                         displayStringForOption: (option) => '${option['item_name']} (${option['item_code']})\nUOM: ${option['uom']}',
//                         fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
//                           return TextField(
//                             controller: controller,
//                             focusNode: focusNode,
//                             decoration: const InputDecoration(
//                               labelText: 'Item Name or Code',
//                             ),
//                             onChanged: (value) {
//                               provider.fetchItemSuggestions(context, value);
//                             },
//                           );
//                         },
//                         onSelected: (option) {
//                           selectedItemCode = option['item_code'];
//                           _descriptionController.text = option['item_name_local'] ?? ''; 
//                           _uomController.text = option['uom'] ?? 'N/A'; 
//                         },
//                       );
//                     },
//                   ),
//                 ] else ...[
//                   TextField(
//                     readOnly: true,
//                     decoration: const InputDecoration(labelText: 'Item Name'),
//                     controller: TextEditingController(
//                       text: '${item['item_name']} (${item['item_code']})',
//                     ),
//                   ),
//                 ],
//                 TextField(
//                   controller: _descriptionController,
//                   readOnly: true, 
//                   decoration: const InputDecoration(labelText: ''),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: _uomController,
//                   readOnly: true, 
//                   decoration: const InputDecoration(labelText: 'UOM'),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: _priceListController,
//                   readOnly: true,
//                   decoration: const InputDecoration(labelText: 'Price List'),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: _priceListRateController,
//                   decoration: const InputDecoration(labelText: 'Price List Rate'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Provider.of<SalesOrderProvider>(context, listen: false).clearSuggestions();
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             ElevatedButton(
//               child: Text(item == null ? 'Add' : 'Update'),
//               onPressed: () {
//                 final priceList = _priceListController.text.trim();
//                 final priceListRate = double.tryParse(_priceListRateController.text.trim());
//                 final description = _descriptionController.text.trim();

//                 if (selectedItemCode == null || selectedItemCode!.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Please select a valid item')),
//                   );
//                   return;
//                 }

//                 if (priceList.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Price List is required')),
//                   );
//                   return;
//                 }

//                 if (priceListRate == null || priceListRate <= 0) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Enter a valid Price List Rate')),
//                   );
//                   return;
//                 }

//                 final newItemPrice = ItemPrice(
//                   itemCode: selectedItemCode!,
//                   itemName: '',
//                   priceList: priceList,
//                   priceListRate: priceListRate,
//                   description: description, 
//                 );

//                 final salesOrderProvider = Provider.of<SalesOrderProvider>(context, listen: false);

//                 salesOrderProvider.addItemPrice(context, newItemPrice).then((success) {
//                   if (success) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(item == null ? 'Item Price added successfully' : 'Item Price updated successfully')),
//                     );
//                     salesOrderProvider.refreshItemPrices(context);
//                   }
//                 }).catchError((e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Failed to update Item Price: $e')),
//                   );
//                 });

//                 salesOrderProvider.clearSuggestions();
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to prefill price list: $e')),
//     );
//   }
// }
void _showAddItemPriceDialog(BuildContext context, [Map<String, dynamic>? item]) async {
  final _priceListController = TextEditingController();
  final _priceListRateController = TextEditingController();
  final _descriptionController = TextEditingController(); // For item_name_local
  final TextEditingController _uomController = TextEditingController();
  String? selectedItemCode;

  if (item != null) {
    _priceListRateController.text = item['price_list_rate']?.toString() ?? '';
    _descriptionController.text = item['item_name_local'] ?? ''; // Prefill local item name
    _uomController.text = item['uom'] ?? ''; // Prefill UOM
    selectedItemCode = item['item_code'];

    // ✅ Fetch item_name_local if not available
    if (item['item_name_local'] == null || item['item_name_local'].toString().trim().isEmpty) {
      try {
        final localName = await Provider.of<SalesOrderProvider>(context, listen: false)
            .apiService!
            .fetchItemNameLocal(context, selectedItemCode!);
        if (localName != null) {
          _descriptionController.text = localName;
        }
      } catch (e) {
        debugPrint('Failed to fetch item_name_local: $e');
      }
    }
  }

  try {
    final priceList = await Provider.of<SalesOrderProvider>(context, listen: false)
        .apiService!
        .fetchPriceList();

    if (priceList == null || priceList.isEmpty) {
      throw Exception('No price list found for the logged-in user');
    }

    _priceListController.text = item?['price_list'] ?? priceList;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(item == null ? 'Add Item Price' : 'Edit Item Price'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item == null) ...[
                  Consumer<SalesOrderProvider>(
                    builder: (context, provider, child) {
                      return Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.trim();
                          if (query.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }

                          provider.fetchItemSuggestions(context, query);

                          return provider.itemSuggestions.where((option) {
                            final itemName = option['item_name']?.toString().toLowerCase() ?? '';
                            final itemCode = option['item_code']?.toString().toLowerCase() ?? '';
                            return itemName.contains(query.toLowerCase()) || itemCode.contains(query.toLowerCase());
                          });
                        },
                        displayStringForOption: (option) => '${option['item_name']} (${option['item_code']})\nUOM: ${option['uom']}',
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Item Name or Code',
                            ),
                            onChanged: (value) {
                              provider.fetchItemSuggestions(context, value);
                            },
                          );
                        },
                        onSelected: (option) async {
                          selectedItemCode = option['item_code'];
                          _descriptionController.text = option['item_name_local'] ?? 'Fetching...';
                          _uomController.text = option['uom'] ?? 'N/A';

                          // ✅ Fetch item_name_local if not provided
                          if (option['item_name_local'] == null || option['item_name_local'].toString().trim().isEmpty) {
                            try {
                              final localName = await Provider.of<SalesOrderProvider>(context, listen: false)
                                  .apiService!
                                  .fetchItemNameLocal(context, selectedItemCode!);
                              if (localName != null) {
                                _descriptionController.text = localName;
                              } else {
                                _descriptionController.text = '';
                              }
                            } catch (e) {
                              debugPrint('Failed to fetch item_name_local: $e');
                              _descriptionController.text = '';
                            }
                          }
                        },
                      );
                    },
                  ),
                ] else ...[
                  TextField(
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    controller: TextEditingController(
                      text: '${item['item_name']} (${item['item_code']})',
                    ),
                  ),
                ],
                TextField(
                  controller: _descriptionController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Local Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _uomController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'UOM'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceListController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Price List'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceListRateController,
                  decoration: const InputDecoration(labelText: 'Price List Rate'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Provider.of<SalesOrderProvider>(context, listen: false).clearSuggestions();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text(item == null ? 'Add' : 'Update'),
              onPressed: () {
                final priceList = _priceListController.text.trim();
                final priceListRate = double.tryParse(_priceListRateController.text.trim());
                final description = _descriptionController.text.trim();

                if (selectedItemCode == null || selectedItemCode!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a valid item')),
                  );
                  return;
                }

                if (priceList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price List is required')),
                  );
                  return;
                }

                if (priceListRate == null || priceListRate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid Price List Rate')),
                  );
                  return;
                }

                final newItemPrice = ItemPrice(
                  itemCode: selectedItemCode!,
                  itemName: '',
                  priceList: priceList,
                  priceListRate: priceListRate,
                  description: description,
                );

                final salesOrderProvider = Provider.of<SalesOrderProvider>(context, listen: false);

                salesOrderProvider.addItemPrice(context, newItemPrice).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(item == null ? 'Item Price added successfully' : 'Item Price updated successfully')),
                    );
                    salesOrderProvider.refreshItemPrices(context);
                  }
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update Item Price: $e')),
                  );
                });

                salesOrderProvider.clearSuggestions();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to prefill price list: $e')),
    );
  }
}



    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Item Price List",
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        iconTheme:
            IconThemeData(color: Colors.white), // Set icon color to white
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddItemPriceDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController, // Assign controller to TextField
              decoration: InputDecoration(
                labelText: 'Search by Item Name or Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (query) {
                provider.searchItems(
                    query); // Call the search function in the provider
              },
            ),
          ),
          Consumer<SalesOrderProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Items: ${provider.itemPriceCount}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<SalesOrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.itemPrices!.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!provider.isLoading &&
                    (provider.itemPrices == null ||
                        provider.itemPrices!.isEmpty)) {
                  return Center(
                    child: Text(
                      "No item prices available",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.itemPrices!.length +
                      (provider.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.itemPrices!.length) {
                      Future.delayed(Duration.zero, () {
                        if (!provider.isLoading && provider.hasMoreData) {
                          provider.fetchItemPrices(context);
                        }
                      });

                      return Center(child: CircularProgressIndicator());
                    }

                    final item = provider.itemPrices![index];
                    final cardColors = [
                      const Color.fromARGB(255, 205, 227, 225),
                      const Color.fromARGB(255, 205, 213, 221),
                    ];
                    final cardColor = cardColors[index % cardColors.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 6.0),
//                       child: Card(
//                         color: cardColor,
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [

//                               Row(
//   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   children: [
//     Expanded(  
//       child: Text(
//         item['item_name'],
//         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         overflow: TextOverflow.ellipsis,  
//       ),
//     ),
//     IconButton(
//       icon: const Icon(Icons.edit, color: Colors.blue),
//       onPressed: () {
//         _showAddItemPriceDialog(context, item);
//       },
//     ),
//   ],
// ),

//                               const SizedBox(height: 8),
//                               Text('Code: ${item['item_code']}',
//                                   style: TextStyle(
//                                       fontSize: 14, color: Colors.grey[600])),
//                               const SizedBox(height: 8),
//                               Text('Price: ₹${item['price_list_rate']}',
//                                   style: const TextStyle(
//                                       fontSize: 16, color: Colors.black)),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Valid From: ${item['valid_from'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(item['valid_from'])) : 'N/A'}',
//                                 style: TextStyle(
//                                     fontSize: 14, color: Colors.grey[800]),
//                               ),
//                               const SizedBox(height: 8),
//                               // Add the UOM field
//                               Text('UOM: ${item['uom'] ?? 'N/A'}',
//                                   style: const TextStyle(
//                                       fontSize: 14, color: Colors.black)),
//                             ],
//                           ),
//                         ),
//                       ),
child: Card(
  color: cardColor,
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item['item_name'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                _showAddItemPriceDialog(context, item);
              },
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ✅ Display `item_name_local`, fallback to "Not Available" if missing
   // Only display `item_name_local` if it's not empty
if (item['item_name_local'] != null && item['item_name_local'].toString().trim().isNotEmpty)
  Text(
    item['item_name_local'],
    style: const TextStyle(fontSize: 14, color: Colors.black),
  ),


        const SizedBox(height: 8),
        Text('Code: ${item['item_code']}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),

        const SizedBox(height: 8),
        Text('Price: ₹${item['price_list_rate']}',
            style: const TextStyle(fontSize: 16, color: Colors.black)),

        const SizedBox(height: 8),
        Text(
          'Valid From: ${item['valid_from'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(item['valid_from'])) : 'N/A'}',
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),

        const SizedBox(height: 8),
        // ✅ Display UOM
        Text('UOM: ${item['uom'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 14, color: Colors.black)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _searchController.clear(); // Clear the search field
          FocusScope.of(context).unfocus(); // Hide the keyboard
          provider.searchItems(''); // Reset the filtered list
          provider.refreshItemPrices(context); // Refresh item prices
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
