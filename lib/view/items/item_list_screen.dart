// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sales_ordering_app/provider/provider.dart';
// import 'package:sales_ordering_app/utils/app_colors.dart';
// import 'package:sales_ordering_app/utils/common/common_widgets.dart';

// class ItemListScreen extends StatefulWidget {
//   const ItemListScreen({super.key});

//   @override
//   _ItemListScreenState createState() => _ItemListScreenState();
// }

// class _ItemListScreenState extends State<ItemListScreen> {
//   String? _selectedBrand;
//   String? _selectedCategory;
//   String? _selectedItem;
//   final TextEditingController _itemSearchController = TextEditingController();

//   List<String> _brands = [];
//   List<String> _categories = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchBrandList();
//     _categoryList();
//     _itemList();
//   }

//   Future<void> _fetchBrandList() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//     try {
//       Future.microtask(() async {
//         final brandGroupList = await provider.brandList();
//         setState(() {
//           _brands =
//               brandGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
//         });
//       });
//     } catch (e) {
//       print('Error fetching customer groups: $e');
//     }
//   }

//   Future<void> _categoryList() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//     try {
//       Future.microtask(() async {
//         final categoryGroupList = await provider.categoryGroupList();
//         setState(() {
//           _categories =
//               categoryGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
//         });
//       });
//     } catch (e) {
//       print('Error fetching category groups: $e');
//     }
//   }

//   Future<void> _itemList() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//     try {
//       Future.microtask(() async {
//         await provider.itemGroupList();
//         ;
//       });
//     } catch (e) {
//       print('Error fetching item details: $e');
//     }
//   }

//   Future<void> _itemBrandList(String brandname) async {
//     print("test brand 1");
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//     try {
//       Future.microtask(() async {
//         await provider.itemByBrandList(brandname);
//         ;
//       });
//     } catch (e) {
//       print('Error fetching item details: $e');
//     }
//   }

//   Future<void> _itemNameSearchList(String itemName) async {
//     print("test brand 1");
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//     try {
//       Future.microtask(() async {
//         await provider.itemSearchList(itemName);
//       });
//     } catch (e) {
//       print('Error fetching item details: $e');
//     }
//   }

//   // Future<void> _categoryFilterList(String category) async {
//   //   print("test brand 1");
//   //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//   //   try {
//   //     Future.microtask(() async {
//   //       await provider.itemByCategoryList(category);
//   //       ;
//   //     });
//   //   } catch (e) {
//   //     print('Error fetching item details: $e');
//   //   }
//   // }

//   Future<void> _categoryBrandList(String brand, String category) async {
//     print("test brand 1");
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//     try {
//       Future.microtask(() async {
//         await provider.categoryAndBrandList(brand, category);
//         ;
//       });
//     } catch (e) {
//       print('Error fetching item details: $e');
//     }
//   }

//   Future<void> _categoryFilterList(String category) async {
//     print("test brand 1");
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);

//     try {
//       Future.microtask(() async {
//         await provider.itemByCategoryList(category);
//         ;
//       });
//     } catch (e) {
//       print('Error fetching item details: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: 'Items',
//         onBackTap: () {
//           Navigator.pop(context);
//         },
//         backgroundColor: AppColors.primaryColor,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [AppColors.primaryColor.withOpacity(0.3), Colors.white],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Consumer<SalesOrderProvider>(
//           builder: (context, provider, child) {
//             if (provider.isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             } else if (provider.errorMessage != null) {
//               return Center(child: Text(provider.errorMessage!));
//             } else if (provider.itemListModel == null ||
//                 provider.itemListModel!.data == null ||
//                 provider.itemListModel!.data!.isEmpty) {
//               return const Center(child: Text('No items available'));
//             } else {
//               final items = provider.itemListModel!.data!;

//               return SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(15.0),
//                   child: Column(
//                     children: [
//                       LayoutBuilder(
//                         builder: (context, constraints) {
//                           return Column(
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 10.0, vertical: 8.0),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[200],
//                                   borderRadius: BorderRadius.circular(10.0),
//                                 ),
//                                 child: TextField(
//                                   controller: _itemSearchController,
//                                   decoration: InputDecoration(
//                                     labelText: 'Search Item',
//                                     suffixIcon: Icon(Icons.search),
//                                     border: InputBorder.none,
//                                     contentPadding:
//                                         EdgeInsets.symmetric(horizontal: 16.0),
//                                   ),
//                                   onSubmitted: (query) {
//                                     _itemNameSearchList(
//                                         _itemSearchController.text);
//                                   },
//                                 ),
//                               ),
//                               SizedBox(
//                                 height: 15,
//                               ),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: DropdownButtonFormField<String>(
//                                       decoration: InputDecoration(
//                                         labelText: 'Select Brand',
//                                         border: OutlineInputBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(10.0),
//                                           borderSide: BorderSide(
//                                               color: AppColors.primaryColor),
//                                         ),
//                                         contentPadding: EdgeInsets.symmetric(
//                                             horizontal: 20.0, vertical: 15.0),
//                                       ),
//                                       value: _selectedBrand,
//                                       items: _brands.map((String filter) {
//                                         return DropdownMenuItem<String>(
//                                           value: filter,
//                                           child: Text(filter),
//                                         );
//                                       }).toList(),
//                                       onChanged: (String? newValue) {
//                                         setState(() {
//                                           _selectedBrand = newValue;
//                                         });
//                                         _itemBrandList(_selectedBrand!);
//                                       },
//                                       icon: Icon(Icons.arrow_drop_down,
//                                           color: AppColors.primaryColor),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               DropdownButtonFormField<String>(
//                                 decoration: InputDecoration(
//                                   labelText: 'Select Category',
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                     borderSide: BorderSide(
//                                         color: AppColors.primaryColor),
//                                   ),
//                                   contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 20.0, vertical: 15.0),
//                                 ),
//                                 value: _selectedCategory,
//                                 items: _categories.map((String category) {
//                                   return DropdownMenuItem<String>(
//                                     value: category,
//                                     child: Text(category),
//                                   );
//                                 }).toList(),
//                                 onChanged: (String? newValue) {
//                                   setState(() {
//                                     _selectedCategory = newValue;
//                                   });
//                                   // if (_selectedBrand != null ||
//                                   //     _selectedBrand!.isNotEmpty) {
//                                   //   print("brand also selected::::::::::");
//                                   // _categoryBrandList(
//                                   //     _selectedBrand!, _selectedCategory!);
//                                   // } else {
//                                   //   print("category  selected::::::::::");

//                                   _categoryFilterList(_selectedCategory!);
//                                   // }
//                                 },
//                                 icon: Icon(Icons.arrow_drop_down,
//                                     color: AppColors.primaryColor),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       // ListView.separated(
//                       //   separatorBuilder: (context, index) => const Divider(),
//                       //   itemCount: items.length,
//                       //   shrinkWrap: true,
//                       //   physics: const NeverScrollableScrollPhysics(),
//                       //   itemBuilder: (BuildContext context, int index) {
//                       //     final item = items[index];
//                       //     return GestureDetector(
//                       //       onTap: () {},
//                       //       child: Container(
//                       //         margin:
//                       //             const EdgeInsets.symmetric(vertical: 10.0),
//                       //         decoration: BoxDecoration(
//                       //           color: Colors.white,
//                       //           borderRadius: BorderRadius.circular(20.0),
//                       //           boxShadow: [
//                       //             BoxShadow(
//                       //               color: Colors.black.withOpacity(0.1),
//                       //               blurRadius: 10.0,
//                       //               offset: const Offset(0, 5),
//                       //             ),
//                       //           ],
//                       //         ),
//                       //         child: Padding(
//                       //           padding: const EdgeInsets.all(15.0),
//                       //           child: Column(
//                       //             crossAxisAlignment: CrossAxisAlignment.start,
//                       //             children: [
//                       //               item.itemName != null?Text(
//                       //                 "Name : ${item.itemName}",
//                       //                 style: const TextStyle(
//                       //                     fontSize: 16,
//                       //                     fontWeight: FontWeight.bold,
//                       //                     color: Colors.black),
//                       //               ):SizedBox.shrink(),
//                       //               Row(
//                       //                 // mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       //                 children: [
//                       //                 item.itemCode != null?  Text(
//                       //                     "Code : ${item.itemCode}",
//                       //                     style: TextStyle(
//                       //                         fontSize: 16,
//                       //                         fontWeight: FontWeight.bold,
//                       //                         color: Colors.black),
//                       //                   ):SizedBox.shrink(),
//                       //                   SizedBox(
//                       //                     width: 15,
//                       //                   ),
//                       //                   item.valuationRate != null?Text(
//                       //                     "Rate : ${item.valuationRate?.toString()}",
//                       //                     style: TextStyle(
//                       //                         fontSize: 16,
//                       //                         fontWeight: FontWeight.bold,
//                       //                         color: Colors.black),
//                       //                   ):SizedBox.shrink(),
//                       //                 ],
//                       //               ),
//                       //                item.brand != null?Text(
//                       //                 "Brand : ${item.brand}",
//                       //                 style: const TextStyle(
//                       //                     fontSize: 16,
//                       //                     fontWeight: FontWeight.bold,
//                       //                     color: Colors.black),
//                       //               ):SizedBox.shrink(),
//                       //               item.itemGroup != null?Text(
//                       //                 "Category : ${item.itemGroup}",
//                       //                 style: const TextStyle(
//                       //                     fontSize: 16,
//                       //                     fontWeight: FontWeight.bold,
//                       //                     color: Colors.black),
//                       //               ):SizedBox.shrink(),
//                       //               // _buildItemDetail(
//                       //               //     'Item Code', item.itemCode, Icons.code),
//                       //               // _buildItemDetail('Item Name', item.itemName,
//                       //               //     Icons.label),
//                       //               // _buildItemDetail(
//                       //               //     'Rate',
//                       //               //     item.valuationRate?.toString(),
//                       //               //     Icons.attach_money),
//                       //               // _buildItemDetail(
//                       //               //     'Brand',
//                       //               //     item.brand?.toString(),
//                       //               //     Icons.branding_watermark),
//                       //               // _buildItemDetail(
//                       //               //     'Category',
//                       //               //     item.itemGroup?.toString(),
//                       //               //     Icons.category),
//                       //             ],
//                       //           ),
//                       //         ),
//                       //       ),
//                       //     );
//                       //   },
//                       // ),
//                       ListView.separated(
//   separatorBuilder: (context, index) => const Divider(),
//   itemCount: items.length,
//   shrinkWrap: true,
//   physics: const NeverScrollableScrollPhysics(),
//   itemBuilder: (BuildContext context, int index) {
//     final item = items[index];
//     return GestureDetector(
//       onTap: () {},
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 10.0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20.0),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10.0,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(15.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (item.itemName != null)
//                 Text(
//                   "Name : ${item.itemName}",
//                   style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                 ),
//               Row(
//                 children: [
//                   if (item.itemCode != null)
//                     Flexible(
//                       child: Text(
//                         "Code : ${item.itemCode}",
//                         style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black),
//                       ),
//                     ),
//                   const SizedBox(width: 15),
//                   if (item.valuationRate != null)
//                     Flexible(
//                       child: Text(
//                         "Rate : ${item.valuationRate?.toString()}",
//                         style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black),
//                       ),
//                     ),
//                 ],
//               ),
//               if (item.brand != null)
//                 Text(
//                   "Brand : ${item.brand}",
//                   style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                 ),
//               if (item.itemGroup != null)
//                 Text(
//                   "Category : ${item.itemGroup}",
//                   style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   },
// ),

//                     ],
//                   ),
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildItemDetail(String label, String? value, IconData icon) {
//     if (value == null || value.isEmpty) {
//       return const SizedBox.shrink();
//     }
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(
//             backgroundColor: AppColors.primaryColor.withOpacity(0.1),
//             child: Icon(icon, color: AppColors.primaryColor, size: 20),
//             radius: 15,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               "$label: $value",
//               style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  String? _selectedBrand;
  String? _selectedCategory;
  //final TextEditingController _itemSearchController = TextEditingController();
  SalesOrderProvider? _salesOrderProvider;

  List<String> _brands = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchBrandList();
    _categoryList();
    _itemList();
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
    });
    super.dispose();
  }

  Future<void> _fetchBrandList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async {
        final brandGroupList = await provider.brandList(context);
        setState(() {
          _brands =
              brandGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
        });
      });
    } catch (e) {
      print('Error fetching customer groups: $e');
    }
  }

  Future<void> _categoryList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async {
        final categoryGroupList = await provider.categoryGroupList(context);
        setState(() {
          _categories =
              categoryGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
        });
      });
    } catch (e) {
      print('Error fetching category groups: $e');
    }
  }

  Future<void> _itemList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      Future.microtask(() async {
        await provider.itemGroupList(context);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _itemBrandList(String brandname) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      Future.microtask(() async {
        await provider.itemByBrandList(brandname, context);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _itemNameSearchList(String itemName) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      Future.microtask(() async {
        await provider.itemSearchList(itemName, context, true);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _categoryBrandList(String brand, String category) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      Future.microtask(() async {
        await provider.categoryAndBrandList(brand, category, context);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _categoryFilterList(String category) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      Future.microtask(() async {
        await provider.itemByCategoryList(category, context);
      });
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Brand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                value: _selectedBrand,
                items: _brands.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(
                      filter,
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBrand = newValue;
                  });
                  _itemBrandList(_selectedBrand!);
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _categoryFilterList(_selectedCategory!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
          title: 'Items',
          onBackTap: () {
            Navigator.pop(context);
          },
          backgroundColor: AppColors.primaryColor,
          actions: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ItemSearchDelegate(
                      onItemSelected: _itemNameSearchList,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                onPressed: _itemList,
              ),
            ],
          )),
      body: Container(
        child: Consumer<SalesOrderProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            } else if (provider.itemListModel == null ||
                provider.itemListModel!.data == null ||
                provider.itemListModel!.data!.isEmpty) {
              return const Center(child: Text('No items available'));
            } else {
              final items = provider.itemListModel!.data!;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(),
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          final item = items[index];
                          return GestureDetector(
                            onTap: () {},
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.itemName != null)
                                      Text(
                                        "Name : ${item.itemName}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                    Row(
                                      children: [
                                        if (item.itemCode != null)
                                          Flexible(
                                            child: Text(
                                              "Code : ${item.itemCode}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                            ),
                                          ),
                                        const SizedBox(width: 15),
                                        if (item.valuationRate != null)
                                          Flexible(
                                            child: Text(
                                              "Rate : ${item.valuationRate?.toString()}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (item.brand != null)
                                      Text(
                                        "Brand : ${item.brand}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                    if (item.itemGroup != null)
                                      Text(
                                        "Category : ${item.itemGroup}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class ItemSearchDelegate extends SearchDelegate<String> {
  final Function(String) onItemSelected;

  ItemSearchDelegate({required this.onItemSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onItemSelected(query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
