import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/stock_updates/AddStockReconciliation.dart';
import 'package:sales_ordering_app/view/stock_updates/StockStatusScreen.dart';

// class StockReconciliationScreen extends StatefulWidget {
//   @override
//   _StockReconciliationScreenState createState() =>
//       _StockReconciliationScreenState();
// }
//
// class _StockReconciliationScreenState extends State<StockReconciliationScreen> {
//   late Future<void> _fetchDataFuture = Future.value();
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       setState(() {
//         _fetchDataFuture = _fetchData();
//       });
//     });
//   }
//
//
//   Future<void> _fetchData() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//     await Future.wait([
//       provider.fetchStockReconciliations(context),
//       provider.fetchBinStock(context),
//     ]);
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           leading: GestureDetector(
//             onTap: () {
//               Navigator.pop(context);
//             },
//             child: Icon(
//               Icons.arrow_back,
//               color: Colors.white,
//             ),
//           ),
//           backgroundColor: AppColors.primaryColor,
//           title: Text(
//             'Stock Update',
//             style: TextStyle(color: Colors.white),
//           ),
//           bottom: TabBar(
//             tabs: [
//               Tab(text: 'Currant Stock'),
//               Tab(text: 'Stock Updates'),
//             ],
//           ),
//         ),
//         body: FutureBuilder<void>(
//           future: _fetchDataFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               return Center(
//                 child: Text('An error occurred: ${snapshot.error}'),
//               );
//             }
//             return TabBarView(
//               children: [
//                 StockLedgerScreen(),
//                 StockReconciliationListScreen(),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

class StockReconciliationScreen extends StatefulWidget {
  @override
  _StockReconciliationScreenState createState() => _StockReconciliationScreenState();
}

class _StockReconciliationScreenState extends State<StockReconciliationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _fetchDataFuture = Future.value();
  final List<Map<String, dynamic>> selectedItems = [];

  final GlobalKey<StockLedgerScreenState> _ledgerScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {}); // Rebuild to update AppBar button visibility
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fetchDataFuture = _fetchData();
      });
    });
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    await Future.wait([
      provider.fetchStockReconciliations(context),
      provider.fetchBinStock(context),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onUpdateStockPressed() {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    if (provider.selectedItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one item before updating stock."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _ledgerScreenKey.currentState?.showSelectedItemsPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        title: const Text('Stock Update', style: TextStyle(color: Colors.white)),
        actions: [
          if (_tabController.index == 0)
            // TextButton.icon(
            //   onPressed: _onUpdateStockPressed,
            //   icon: const Icon(Icons.check, color: Colors.white),
            //   label: const Text("Update Stock", style: TextStyle(color: Colors.white)),
            // ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0), // Move it left by adding right padding
              child: Consumer<SalesOrderProvider>(
                builder: (context, provider, child) {
                  return TextButton(
                    onPressed: _onUpdateStockPressed,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_shopping_cart_outlined, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          "${provider.selectedItemCount}",
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),




        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Currant Stock'),
            Tab(text: 'Stock Updates'),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              StockLedgerScreen(key: _ledgerScreenKey), // pass GlobalKey here
               StockReconciliationListScreen(),
            ],
          );
        },
      ),
    );
  }
}
