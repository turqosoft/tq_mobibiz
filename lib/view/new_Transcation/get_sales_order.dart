// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';

import '../../model/get_sales_order_response.dart';

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

  void _showWarehouseDialog(BuildContext context) {
    final provider =
    Provider.of<SalesOrderProvider>(context, listen: false);

    String? selectedWarehouse = provider.setWarehouse;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Set Warehouse'),
          content: SizedBox(
            width: double.maxFinite,
            child: Autocomplete<String>(
              initialValue: TextEditingValue(
                text: selectedWarehouse ?? '',
              ),
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return await provider.fetchWarehouse(
                  textEditingValue.text,
                );
              },
              displayStringForOption: (option) => option,
              onSelected: (String selection) {
                selectedWarehouse = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search Warehouse',
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
              optionsViewBuilder:
                  (context, onSelected, Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedWarehouse != null &&
                    selectedWarehouse!.isNotEmpty) {
                  provider.setWarehousee(selectedWarehouse!);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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

        // actions: _tabController.index == 0
        //     ? [
        //   IconButton(
        //     icon: const Icon(Icons.save, color: Colors.white),
        //     onPressed: () async {
        //       final state = _salesOrderKey.currentState;
        //       if (state != null) {
        //         await state.handleSave(context);
        //       }
        //     },
        //   ),
        // ]
        //     : null,

        actions: _tabController.index == 0
            ? [
          IconButton(
            icon: const Icon(Icons.warehouse, color: Colors.white),
            tooltip: 'Set Warehouse',
            onPressed: () => _showWarehouseDialog(context),
          ),
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

    _fromDateController = TextEditingController();
    _toDateController = TextEditingController();

    _setTodayAsDefaultDate(); // this already fetches data
  }

  void _setTodayAsDefaultDate() {
    final today = DateTime.now();

    // UI format
    final displayDate = DateFormat('dd-MM-yyyy').format(today);

    // API format
    final apiDate = DateFormat('yyyy-MM-dd').format(today);

    _fromDateController.text = displayDate;
    _toDateController.text = displayDate;

    _fromDate = apiDate;
    _toDate = apiDate;

    // Fetch today's Sales Orders by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSalesOrders();
    });

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

  Future<void> _fetchSalesOrders() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    await provider.getSalesOrdersWithFilters(
      context,
      startDate: _fromDate.isNotEmpty ? _fromDate : null,
      endDate: _toDate.isNotEmpty ? _toDate : null,
      salesId: _searchController.text.isNotEmpty
          ? _searchController.text
          : null,
      customerId: _searchCustomerController.text.isNotEmpty
          ? _searchCustomerController.text
          : null,
      customerName: _searchCustomerNameController.text.isNotEmpty
          ? _searchCustomerNameController.text
          : null,
    );
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

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      bool isFromDate,
      ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );

    if (picked != null) {
      final displayDate = DateFormat('dd-MM-yyyy').format(picked);
      final apiDate = DateFormat('yyyy-MM-dd').format(picked);

      setState(() {
        controller.text = displayDate;

        if (isFromDate) {
          _fromDate = apiDate;
        } else {
          _toDate = apiDate;
        }
      });

      _fetchSalesOrders(); // 🔥 always unified
    }

  }

  void _resetFilters() {
    setState(() {
      _fromDateController.clear();
      _toDateController.clear();
      _fromDate = "";
      _toDate = "";

      _searchController.clear();
      _searchCustomerController.clear();
      _searchCustomerNameController.clear();
    });

    // 🔥 Fetch ALL sales orders
    _getSalesOrderList();
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
                  // _getSearchSalesList(
                  //     _searchController.text,
                  //     _searchCustomerController.text,
                  //     _searchCustomerNameController.text);
                  _fetchSalesOrders();
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
                                        if (date == null) return '-';
                                        try {
                                          final parsed = DateTime.parse(date);
                                          return DateFormat('dd/MM/yyyy').format(parsed);
                                        } catch (_) {
                                          return date;
                                        }
                                      }

                                      double _toDouble(dynamic value) {
                                        if (value == null) return 0.0;
                                        if (value is num) return value.toDouble();
                                        return double.tryParse(value.toString()) ?? 0.0;
                                      }

                                      return AlertDialog(
                                        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        backgroundColor: Colors.white,
                                        elevation: 6,

                                        // ---------- HEADER ----------
                                        titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                        title: Row(
                                          children: [
                                            const Icon(Icons.receipt_long, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                order.name ?? 'Sales Order',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(order.transactionDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ---------- CONTENT ----------
                                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                        content: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(safeContext).size.height * 0.75,
                                            maxWidth: MediaQuery.of(safeContext).size.width * 0.90,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _dialogRow("Customer", order.customer ?? order.customerName),

                                                const Divider(height: 16),

                                                _sectionHeader("Financials"),
                                                _financialGrid(order),

                                                const Divider(height: 16),

                                                // _sectionHeader("Items (${items.length})"),
                                                // const SizedBox(height: 4),
                                                //
                                                // if (items.isEmpty)
                                                //   const Text("No items available."),
                                                //
                                                // ...items.asMap().entries.map((entry) {
                                                //   final index = entry.key;
                                                //   final item = entry.value;
                                                //
                                                //   return ExpansionTile(
                                                //     tilePadding: EdgeInsets.zero,
                                                //     childrenPadding:
                                                //     const EdgeInsets.symmetric(vertical: 6),
                                                //     title: Row(
                                                //       children: [
                                                //         SizedBox(
                                                //           width: 24,
                                                //           child: Text(
                                                //             "${index + 1}.",
                                                //             style: const TextStyle(
                                                //               fontWeight: FontWeight.w600,
                                                //               fontSize: 13,
                                                //             ),
                                                //           ),
                                                //         ),
                                                //         Expanded(
                                                //           child: Text(
                                                //             "${item.itemCode ?? ''} ${item.itemName ?? ''}",
                                                //             style: const TextStyle(
                                                //               fontWeight: FontWeight.w600,
                                                //               fontSize: 13,
                                                //             ),
                                                //           ),
                                                //         ),
                                                //       ],
                                                //     ),
                                                //     subtitle: Padding(
                                                //       padding: const EdgeInsets.only(left: 24),
                                                //       child: Text(
                                                //         "Qty ${item.qty?.toStringAsFixed(2)} • ₹${item.amount?.toStringAsFixed(2)}",
                                                //         style: const TextStyle(fontSize: 12),
                                                //       ),
                                                //     ),
                                                //     children: [
                                                //       _itemRow("Qty", item.qty?.toString()),
                                                //       _itemRow("Rate", item.rate?.toStringAsFixed(2)),
                                                //       _itemRow("Amount", item.amount?.toStringAsFixed(2)),
                                                //     ],
                                                //   );
                                                // }).toList(),
                                                _sectionHeader("Items (${items.length})"),
                                                const SizedBox(height: 4),

                                                if (items.isEmpty)
                                                  const Text("No items available."),

                                                ...items.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final item = entry.value;

                                                  final qty = item.qty ?? 0;
                                                  final netRate = item.netRate ?? item.rate ?? 0;

                                                  return ExpansionTile(
                                                    tilePadding: EdgeInsets.zero,
                                                    childrenPadding: const EdgeInsets.symmetric(vertical: 6),

                                                    title: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 24,
                                                          child: Text(
                                                            "${index + 1}.",
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "${item.itemCode ?? ''} ${item.itemName ?? ''}",
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // ---------- SUBTITLE ----------
                                                    subtitle: Padding(
                                                      padding: const EdgeInsets.only(left: 24),
                                                      child: Text(
                                                        "Qty ${qty.toStringAsFixed(2)} • Net Rt ₹${netRate.toStringAsFixed(2)}",
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),

                                                    // ---------- DETAILS ----------
                                                    children: [
                                                      _itemRow("Code", item.itemCode),
                                                      _itemRow("Qty", qty.toStringAsFixed(2)),
                                                      _itemRow("Unit", item.uom),
                                                      _itemRow(
                                                        "Price List Rate",
                                                        item.priceListRate?.toStringAsFixed(2),
                                                      ),

                                                      /// ✅ Discount % (only if > 0)
                                                      if ((item.discountPercentage ?? 0) > 0)
                                                        _itemRow(
                                                          "Discount %",
                                                          "${item.discountPercentage!.toStringAsFixed(2)} %",
                                                        ),

                                                      _itemRow(
                                                        "Rate",
                                                        item.rate?.toStringAsFixed(2),
                                                      ),

                                                      /// ✅ Additional Discount Amount
                                                      if ((item.distributedDiscountAmount ?? 0) > 0)
                                                        _itemRow(
                                                          "Addl.Disc.Amt",
                                                          item.distributedDiscountAmount!.toStringAsFixed(2),
                                                        ),

                                                      _itemRow(
                                                        "Net Rate",
                                                        "₹ ${netRate.toStringAsFixed(2)}",
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),

                                              ],
                                            ),
                                          ),
                                        ),

                                        // ---------- ACTIONS ----------
                                        actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          TextButton.icon(
                                            onPressed: () => Navigator.pop(safeContext),
                                            icon: const Icon(Icons.close),
                                            label: const Text("Close"),
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
  // Widget _financialGrid(order) {
  //   Widget cell(String label, String value) {
  //     return SizedBox(
  //       width: 140,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(label,
  //               style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //           const SizedBox(height: 2),
  //           Text(value,
  //               style: const TextStyle(
  //                   fontWeight: FontWeight.w600, fontSize: 13)),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   final total = (order.roundedTotal != null && order.roundedTotal != 0)
  //       ? order.roundedTotal
  //       : order.grandTotal;
  //
  //   return Wrap(
  //     spacing: 16,
  //     runSpacing: 12,
  //     children: [
  //       cell(
  //         "Net Total",
  //         order.netTotal?.toStringAsFixed(2) ?? "0.00",
  //       ),
  //       cell(
  //         "Grand Total",
  //         total?.toStringAsFixed(2) ?? "0.00",
  //       ),
  //     ],
  //   );
  // }
  Widget _financialGrid(SalesOrderDetails order) {
    const TextStyle labelStyle =
    TextStyle(fontSize: 12, color: Colors.grey);
    const TextStyle valueStyle =
    TextStyle(fontWeight: FontWeight.w600, fontSize: 13);

    Widget cell(String label, String value) {
      return SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 2),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    List<Widget> cells = [
      cell(
        "Net Total",
        (order.netTotal ?? order.total ?? 0).toStringAsFixed(2),
      ),
      cell(
        "Taxes",
        (order.totalTaxesAndCharges ?? 0).toStringAsFixed(2),
      ),
      cell(
        "Total",
        order.displayTotal.toStringAsFixed(2),
      ),
    ];

    /// ✅ Discount Amount (only if available)
    if ((order.discountAmount ?? 0) > 0) {
      cells.add(
        cell(
          "Discount Amount",
          order.discountAmount!.toStringAsFixed(2),
        ),
      );
    }

    /// ✅ Additional Discount % (only if available)
    if ((order.additionalDiscountPercentage ?? 0) > 0) {
      cells.add(
        cell(
          "Additional Discount %",
          "${order.additionalDiscountPercentage!.toStringAsFixed(2)} %",
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: cells,
    );
  }

  Widget _dialogRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? "-",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _itemRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
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
            _buildRow(
              'Total',
              '₹ ${data.displayTotal.toStringAsFixed(2)}',
              Icons.currency_rupee,
            ),

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



