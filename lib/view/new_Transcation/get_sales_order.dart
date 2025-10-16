// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';

class SalesOrderPage extends StatefulWidget {
  @override
  _SalesOrderPageState createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage>
    with SingleTickerProviderStateMixin {   // 👈 add this mixin
  late TabController _tabController;

  final GlobalKey<SalesOrderScreenState> _salesOrderKey =
  GlobalKey<SalesOrderScreenState>();
  TabController get tabController => _tabController; // 👈 expose controller

  @override
  void initState() {
    super.initState();
    // 👇 now we can use `this` as vsync safely
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // rebuild AppBar when tab changes
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Sales Order', style: TextStyle(color: Colors.white)),

        actions: _tabController.index == 0
            ? [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              final state = _salesOrderKey.currentState;
              if (state != null) {
                await state.handleSave(context);
              }
            },
          ),
        ]
            : null,

        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales Order'),
            Tab(text: 'Sales Order List'),
          ],
        ),
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              SalesOrderScreen(
                key: _salesOrderKey,
                salesOrder: provider.selectedSalesOrder,
              ),
              SalesOrderListScreen(),
            ],
          );
        },
      ),
    );
  }
}

class SalesOrderListScreen extends StatefulWidget {
  @override
  _SalesOrderListScreenState createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchCustomerController = TextEditingController();
  TextEditingController _searchCustomerNameController = TextEditingController();
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _searchCustomerQuery = '';
  String _searchCustomerName = '';
  String _fromDate = '';
  String _toDate = '';

  int limitStart = 0;
  int pageLength = 10;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _getSalesOrderList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getSalesOrderList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getSalesOrder(context, limitStart, pageLength);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _getSearchSalesList(
      String? salesId, String? customerId, String? customerName) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getSearchSalesOrder(
          context, salesId!, customerId!, customerName!);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }

  Future<void> _getSalesDateFilterList(String startDate, String endDate) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getSalesOrderDateFilter(context, startDate, endDate);
    } catch (e) {
      print('Error fetching item details: $e');
    }
  }


  Future<void> _loadMoreItems({bool next = true}) async {
    if (!isLoadingMore) {
      setState(() {
        isLoadingMore = true;
        if (next) {
          limitStart += pageLength;
        } else {
          if (limitStart > 0) {
            limitStart -= pageLength;
          }
        }
      });

      await _getSalesOrderList();

      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );
    if (picked != null) {
      setState(() {
        // Display date in dd-MM-yyyy format
        String displayDate = DateFormat('dd-MM-yyyy').format(picked);
        controller.text = displayDate;

        // Keep the date in yyyy-MM-dd format for API calls
        String apiDate = DateFormat('yyyy-MM-dd').format(picked);
        if (isFromDate) {
          _fromDate = apiDate; // Pass this to API
        } else {
          _toDate = apiDate; // Pass this to API
          _getSalesDateFilterList(_fromDate, _toDate);
        }
      });
    }
  }
  void _resetFilters() {
    setState(() {
      // Clear date controllers
      _fromDateController.clear();
      _toDateController.clear();
      _fromDate = "";
      _toDate = "";

      // Clear search controllers
      _searchController.clear();
      _searchCustomerController.clear();
      _searchCustomerNameController.clear();

      // Reset search query variables
      _searchQuery = "";
      _searchCustomerQuery = "";
      _searchCustomerName = "";
    });
  }
  void _showSearchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter Order Id',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _searchQuery = _searchController.text;
                      });
                    },
                  ),
                ),
              ),
              TextField(
                controller: _searchCustomerController,
                decoration: InputDecoration(
                  hintText: 'Enter Customer Id',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _searchCustomerQuery = _searchCustomerController.text;
                      });

                    },
                  ),
                ),
              ),
              TextField(
                controller: _searchCustomerNameController,
                decoration: InputDecoration(
                  hintText: 'Enter Customer Name',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _searchCustomerName =
                            _searchCustomerNameController.text;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8)),
              child: TextButton(
                onPressed: () {
                  _getSearchSalesList(
                      _searchController.text,
                      _searchCustomerController.text,
                      _searchCustomerNameController.text);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Search',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey, // ✅ Add this line

    backgroundColor: Colors.transparent, // If you want background to show
    body: Column(
      children: [
        // Date Filters Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'From Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, _fromDateController, true),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _toDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'To Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () {
                        _selectDate(context, _toDateController, false);
                        // _getSalesDateFilterList(_fromDate, _toDate);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search and Refresh Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _showSearchPopup(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    _resetFilters();
                    _getSalesOrderList();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<SalesOrderProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && limitStart == 0) {
                return const Center(child: CircularProgressIndicator());
              } else if (provider.errorMessage != null) {
                return Center(child: Text('Error: ${provider.errorMessage}'));
              } else if (provider.getSalesOrderList == null ||
                  provider.getSalesOrderList!.data!.isEmpty) {
                return const Center(child: Text('No data available'));
              } else {
                return SafeArea(
                  child: Stack(
                    children: [
                      // ✅ Scrollable list underneath
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        itemCount: provider.getSalesOrderList!.data!.length,
                        itemBuilder: (context, index) {
                          final data = provider.getSalesOrderList!.data![index];
                          return GestureDetector(
                            onTap: () async {
                              final salesOrderProvider = context.read<SalesOrderProvider>();
                              final tabController = context
                                  .findAncestorStateOfType<_SalesOrderPageState>()
                                  ?.tabController;

                              // ✅ Use the Scaffold’s context (stable)
                              final safeContext = _scaffoldKey.currentContext;

                              if (data.status == "Draft") {
                                salesOrderProvider.setSelectedSalesOrderName(data.name);
                                salesOrderProvider.setSelectedTransactionDate(data.transactionDate);
                                tabController?.animateTo(0);
                                await salesOrderProvider.fetchSalesOrderDetails(data.name!);
                              } else {
                                await salesOrderProvider.fetchSalesOrderDetails(data.name!);
                                final order = salesOrderProvider.selectedSalesOrder;

                                // ✅ Only continue if still mounted AND scaffold context is valid
                                if (!mounted || safeContext == null) return;

                                if (order != null) {
                                  final items = order.items ?? [];

                                  showDialog(
                                    context: safeContext,
                                    builder: (_) {
                                      String _formatDate(String? date) {
                                        if (date == null) return 'N/A';
                                        try {
                                          final parsed = DateTime.parse(date);
                                          return DateFormat('dd/MM/yyyy').format(parsed);
                                        } catch (_) {
                                          return date;
                                        }
                                      }

                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                                        scrollable: true,
                                        content: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 🧾 Header (Order name + Customer)
                                            Text(
                                              order.name ?? 'Sales Order',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              order.customer ?? order.customerName ?? 'Unknown Customer',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black54,
                                              ),
                                            ),

                                            const SizedBox(height: 12),
                                            const Divider(thickness: 1),

                                            // ⚠️ Draft note
                                            if (order.status != "Draft")
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                                child: Text(
                                                  "Only Draft orders can be edited",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),

                                            const SizedBox(height: 6),

                                            // 📅 Order Info
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  _buildInfoRow("Order Date", _formatDate(order.transactionDate)),
                                                  _buildInfoRow("Delivery Date", _formatDate(order.deliveryDate)),
                                                  _buildInfoRow("Status", order.status ?? 'N/A'),
                                                  _buildInfoRow(
                                                    "Total",
                                                    (order.netTotal != null && order.netTotal != 0)
                                                        ? order.netTotal!.toStringAsFixed(2)
                                                        : (order.total?.toStringAsFixed(2) ?? '0.00'),
                                                  ),
                                                  _buildInfoRow(
                                                    "Grand Total",
                                                    (order.roundedTotal != null && order.roundedTotal != 0)
                                                        ? order.roundedTotal!.toStringAsFixed(2)
                                                        : (order.grandTotal?.toStringAsFixed(2) ?? '0.00'),
                                                  ),

                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 18),

                                            const Text(
                                              "Items",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (items.isEmpty)
                                              const Text("No items available."),
                                            ...items.asMap().entries.map((entry) {
                                              final index = entry.key + 1;
                                              final item = entry.value;

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // 🟦 Index + Item Name
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // 🔹 Index Badge
                                                        Container(
                                                          width: 26,
                                                          height: 26,
                                                          margin: const EdgeInsets.only(right: 10, top: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blueAccent.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            "$index",
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blueAccent,
                                                            ),
                                                          ),
                                                        ),

                                                        // 🧾 Item name and details
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              // Item name
                                                              Text(
                                                                "${item.itemCode ?? ''} ${item.itemName ?? ''}",
                                                                style: const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.black,
                                                                ),
                                                              ),

                                                              const SizedBox(height: 4),

                                                              // 📦 Details (Qty, Rate, Amt)
                                                              Wrap(
                                                                spacing: 16,
                                                                runSpacing: 4,
                                                                children: [
                                                                  Text(
                                                                    "Qty: ${item.qty?.toStringAsFixed(2) ?? '0'}",
                                                                    style: TextStyle(color: Colors.grey.shade800),
                                                                  ),
                                                                  Text(
                                                                    "Rate: ${item.rate?.toStringAsFixed(2) ?? '0'}",
                                                                    style: TextStyle(color: Colors.grey.shade800),
                                                                  ),
                                                                  Text(
                                                                    "Amt: ${item.amount?.toStringAsFixed(2) ?? '0'}",
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.w600,
                                                                      color: Colors.black87,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Divider between items (optional)
                                                    if (index != items.length)
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 36, top: 8),
                                                        child: Divider(
                                                          height: 1,
                                                          color: Colors.grey.shade300,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }),


                                          ],
                                        ),
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          TextButton.icon(
                                            onPressed: () => Navigator.pop(safeContext),
                                            icon: const Icon(Icons.close, color: Colors.blueAccent),
                                            label: const Text(
                                              "Close",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                }
                              }
                            },

                            child: SalesOrderCard(data: data),
                          );
                        },
                      ),
                      // ✅ Floating pagination buttons
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: limitStart > 0
                            ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => _loadMoreItems(next: false),
                          child: const Text('Previous'),
                        )
                            : const SizedBox.shrink(),
                      ),

                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: provider.getSalesOrderList!.data!.length >= pageLength
                            ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => _loadMoreItems(next: true),
                          child: const Text('Next'),
                        )
                            : const SizedBox.shrink(),
                      ),

                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
  );
}

}
Widget _buildInfoRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class SalesOrderCard extends StatelessWidget {
  final dynamic data;

  SalesOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        // Add a container with height constraints
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints:
            BoxConstraints(minHeight: 100), // Set a min height if needed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildRow('Order', data.name, Icons.receipt_long),
            // _buildRow('Customer Name', data.customerName, Icons.person),
            _buildRow('Customer', data.customer, Icons.person),
            _buildRow('Order Date', _formatDate(data.transactionDate),
                Icons.date_range),
            _buildRow('Delivery Date', _formatDate(data.deliveryDate),
                Icons.date_range),
            _buildRow('Status', data.status, Icons.info_outline),
          ],
        ),
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      // Assuming your date is in the format 'yyyy-MM-dd'
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


