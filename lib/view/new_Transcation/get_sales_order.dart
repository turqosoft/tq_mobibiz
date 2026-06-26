// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';

import '../../model/get_sales_order_response.dart';

// class SalesOrderPage extends StatefulWidget {
class SalesOrderPage extends StatefulWidget {
  final Map<String, dynamic>? mappedQuotation;
  final String? initialCustomerName; // 👈 display name
  final String? initialCustomerId;   // 👈 customer.name (ID)

  const SalesOrderPage({
    super.key,
    this.mappedQuotation,
    this.initialCustomerName,
    this.initialCustomerId,
  });

  @override
  _SalesOrderPageState createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage>
    with SingleTickerProviderStateMixin {   // 👈 add this mixin
  late TabController _tabController;

  final GlobalKey<SalesOrderScreenState> _salesOrderKey =
  GlobalKey<SalesOrderScreenState>();
  TabController get tabController => _tabController; // 👈 expose controller
  bool _isSaving = false;
  // SalesOrderPage
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _salesOrderKey.currentState?.hideSearchOverlay();

      if (mounted) setState(() {});
    });

    // ✅ Clear SYNCHRONOUSLY before SalesOrderScreen builds
    if (widget.mappedQuotation == null) {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      provider.clearSelectedSalesOrder();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);

    // return Stack(
    //   children: [
    //     Scaffold(
    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          _salesOrderKey.currentState?.hideSearchOverlay();
        },
        child: Stack(
          children: [
            Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              // 👇 Block back navigation during save/submit
              // onTap: _isSaving ? null : () => Navigator.pop(context),
              onTap: _isSaving
                  ? null
                  : () {
                _salesOrderKey.currentState?.hideSearchOverlay();
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            title: const Text(
              'Sales Order',
              style: TextStyle(color: Colors.white),
            ),
            actions: _tabController.index == 0
                ? [
              // 💾 Save
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                tooltip: "Save Sales Order",
                // 👇 Disable during save/submit
                onPressed: _isSaving
                    ? null
                    : () async {
                  final state = _salesOrderKey.currentState;
                  if (state != null) {
                    await state.handleSave(context);
                  }
                },
              ),

              if (provider.hasActiveOrder) ...[
                // ➕ New Order
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: "New Sales Order",
                  onPressed: _isSaving
                      ? null
                      : () async {
                    final state = _salesOrderKey.currentState;
                    if (state?.isDirty == true) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Discard changes?"),
                          content: const Text(
                              "You have unsaved changes. Continue?"),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Continue"),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const SalesOrderPage(),
                      ),
                    );
                  },
                ),

                // ✅ Submit
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  tooltip: "Submit Sales Order",
                  onPressed: _isSaving
                      ? null
                      : () async {
                    final state = _salesOrderKey.currentState;
                    if (state == null) return;

                    if (state.isDirty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Please save changes before submitting"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final orderName = state.getCurrentOrderName();
                    if (orderName == null || orderName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Please create/save Sales Order before submitting"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Submit Sales Order"),
                        content: const Text(
                            "Are you sure you want to submit?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    // 👇 Show overlay for submit
                    if (mounted) setState(() => _isSaving = true);

                    final provider = Provider.of<SalesOrderProvider>(
                        context,
                        listen: false);
                    final success =
                    await provider.submitSalesOrder(orderName);

                    if (!mounted) return;
                    setState(() => _isSaving = false);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Sales Order submitted successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await Future.delayed(
                          const Duration(milliseconds: 500));
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SalesOrderPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              provider.errorMessage ?? "Submit failed"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ]
                : null,
            bottom: TabBar(
              controller: _tabController,
              // 👇 Block tab switching during save/submit
              onTap: _isSaving ? (_) {} : null,
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
                // 👇 Block swipe during save/submit
                physics: _isSaving
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                children: [
                  SalesOrderScreen(
                    key: _salesOrderKey,
                    salesOrder: provider.selectedSalesOrder,
                    mappedQuotation: widget.mappedQuotation,
                    initialCustomerName: widget.initialCustomerName, // 👈
                    initialCustomerId: widget.initialCustomerId,     // 👈
                    // 👇 Callbacks so child save controls parent overlay
                    onSaveStart: () {
                      if (mounted) setState(() => _isSaving = true);
                    },
                    onSaveEnd: () {
                      if (mounted) setState(() => _isSaving = false);
                    },
                  ),
                  SalesOrderListScreen(),
                ],
              );
            },
          ),
        ),

        // 👇 Full-screen overlay — covers AppBar + TabBar + body
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ));
  }
}

class SalesOrderListScreen extends StatefulWidget {
  @override
  _SalesOrderListScreenState createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen>
    with AutomaticKeepAliveClientMixin {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchCustomerController = TextEditingController();
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchItemController =
  TextEditingController();
  String _searchQuery = '';
  String _searchCustomerQuery = '';
  String _searchCustomerName = '';
  String _fromDate = '';
  String _toDate = '';
  String? _selectedStatus;
  int limitStart = 0;
  int pageLength = 10;
  bool isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _fromDateController = TextEditingController();
    _toDateController = TextEditingController();

    _setTodayAsDefaultDate(); // this already fetches data
  }

  void _setTodayAsDefaultDate({bool fetchImmediately = true}) {
    final today = DateTime.now();

    // UI format
    final displayDate = DateFormat('dd-MM-yyyy').format(today);

    // API format
    final apiDate = DateFormat('yyyy-MM-dd').format(today);

    setState(() {
      _fromDateController.text = displayDate;
      _toDateController.text = displayDate;

      _fromDate = apiDate;
      _toDate = apiDate;
    });

    if (fetchImmediately) {
      _fetchSalesOrders();
    }
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
      customerName: _searchCustomerController.text.isNotEmpty
          ? _searchCustomerController.text
          : null,
      itemSearch: _searchItemController.text.isNotEmpty
          ? _searchItemController.text
          : null,
      status: _selectedStatus,  // ✅

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
    _searchController.clear();
    _searchCustomerController.clear();
    _searchItemController.clear();
    setState(() => _selectedStatus = null);  // ✅

    _setTodayAsDefaultDate();
  }

  // void _showSearchPopup(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Search'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: _searchController,
  //               decoration: InputDecoration(
  //                 hintText: 'Enter Order Id',
  //                 suffixIcon: IconButton(
  //                   icon: Icon(Icons.search),
  //                   onPressed: () {
  //                     setState(() {
  //                       _searchQuery = _searchController.text;
  //                     });
  //                   },
  //                 ),
  //               ),
  //             ),
  //             TextField(
  //               controller: _searchCustomerController,
  //               decoration: const InputDecoration(
  //                 hintText: 'Enter Customer Id or Name',
  //               ),
  //             ),
  //             TextField(
  //               controller: _searchItemController,
  //               decoration: const InputDecoration(
  //                 hintText: 'Enter Item Code or Item Name',
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           Container(
  //             decoration: BoxDecoration(
  //                 color: AppColors.primaryColor,
  //                 borderRadius: BorderRadius.circular(8)),
  //             child: TextButton(
  //               onPressed: () {
  //                 _fetchSalesOrders();
  //                 Navigator.of(context).pop();
  //               },
  //               child: Text(
  //                 'Search',
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void _showSearchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Search'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Order Id',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCustomerController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Customer Id or Name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchItemController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Item Code or Item Name',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Status dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      hintText: 'Select Status',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
                      DropdownMenuItem(value: 'To Pay', child: Text('To Pay')),
                      DropdownMenuItem(value: 'To Deliver and Bill', child: Text('To Deliver and Bill')),
                      DropdownMenuItem(value: 'To Deliver', child: Text('To Deliver')),
                      DropdownMenuItem(value: 'To Bill', child: Text('To Bill')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _selectedStatus = value);
                      setState(() => _selectedStatus = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // ✅ Clear all filters
                    setState(() {
                      _searchController.clear();
                      _searchCustomerController.clear();
                      _searchItemController.clear();
                      _selectedStatus = null;
                    });
                    Navigator.of(context).pop();
                    _fetchSalesOrders();
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _fetchSalesOrders();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  super.build(context);
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
                    // _getSalesOrderList();
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
                        key: const PageStorageKey<String>('orderListScroll'),
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
                                // Show local loader — no provider state change, no list rebuild
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                final order = await salesOrderProvider.fetchSalesOrderDetailsSilent(data.name!);

                                // Dismiss loader
                                if (mounted && Navigator.canPop(context)) Navigator.pop(context);
                                if (!mounted || safeContext == null || order == null) return;

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

                                                _sectionHeader("Items (${items.length})"),
                                                const SizedBox(height: 4),

                                                if (items.isEmpty)
                                                  const Text("No items available."),

                                                ...items.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final item = entry.value;

                                                  final qty = item.qty ?? 0;
                                                  final netRate = item.netRate ?? item.rate ?? 0;
                                                  final amount = item.amount ?? (qty * netRate);

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
                                                        "Qty ${qty.toStringAsFixed(2)} • Net Rt ₹${netRate.toStringAsFixed(2)} • Total ₹${amount.toStringAsFixed(2)}",
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),

                                                    // ---------- DETAILS ----------
                                                  children: [
                                                  Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _itemRow("Code", item.itemCode),
                                                      _itemRow("Qty", qty.toStringAsFixed(2)),
                                                      _itemRow("Delivered Qty", item.deliveredQty?.toStringAsFixed(2) ?? '0.00'),
                                                      _itemRow("Picked Qty", item.pickedQty?.toStringAsFixed(2) ?? '0.00'),
                                                      _itemRow("Unit", item.uom),
                                                      _itemRow("Item Tax Details", item.itemTaxDetails),
                                                      if (item.gstAmount > 0)
                                                        _itemRow("GST Amount", "₹ ${item.gstAmount.toStringAsFixed(2)}"),
                                                      _itemRow(
                                                        "Price List Rate",
                                                        item.priceListRate?.toStringAsFixed(2),
                                                      ),

                                                      if ((item.discountPercentage ?? 0) > 0)
                                                        _itemRow(
                                                          "Discount %",
                                                          "${item.discountPercentage!.toStringAsFixed(2)} %",
                                                        ),

                                                      if ((item.discountAmount ?? 0) > 0)
                                                        _itemRow(
                                                          "Discount Amt",
                                                          "₹ ${item.discountAmount!.toStringAsFixed(2)}",
                                                        ),

                                                      _itemRow(
                                                        "Rate",
                                                        item.rate?.toStringAsFixed(2),
                                                      ),

                                                      _itemRow(
                                                        "Total",
                                                        "₹ ${amount.toStringAsFixed(2)}",
                                                      ),
                                                    ],
                                                  ),
                                                  ),

                                                      /// 🔽 RIGHT-BOTTOM SUMMARY BLOCK
                                                      _rightBottomSummary(
                                                        addlDiscount: item.distributedDiscountAmount,
                                                        netRate: netRate,
                                                        netAmount: item.netAmount,
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

                                // }
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
  Widget _rightBottomSummary({
    double? addlDiscount,
    double? netRate,
    double? netAmount,
  }) {
    final hasAnyValue =
        (addlDiscount ?? 0) > 0 ||
            (netRate ?? 0) > 0 ||
            (netAmount ?? 0) > 0;

    if (!hasAnyValue) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        // margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if ((addlDiscount ?? 0) > 0)
              _summaryRow("Addl. Disc. Amt", addlDiscount!),

            if ((netRate ?? 0) > 0)
              _summaryRow("Net Rate", netRate!),

            if ((netAmount ?? 0) > 0)
              _summaryRow("Net Amount", netAmount!, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label : ₹ ${value.toStringAsFixed(2)}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

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

class SalesOrderCard extends StatelessWidget {
  final dynamic data;

  SalesOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

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
            /// 🔽 HEADER WITH DOWNLOAD ICON
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        data.name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 DOWNLOAD ICON
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  color: Colors.red,
                  onPressed: () async {
                    final provider =
                    Provider.of<SalesOrderProvider>(context, listen: false);

                    try {
                      final formats = await provider.fetchPrintFormats();

                      if (formats.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No print formats found")),
                        );
                        return;
                      }

                      /// 🔥 SHOW DIALOG
                      showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text("Select Print Format"),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: formats.length,
                                itemBuilder: (context, index) {
                                  final format = formats[index];

                                  return ListTile(
                                    title: Text(format),
                                    // onTap: () async {
                                    //   Navigator.pop(context);
                                    //
                                    //   await provider.downloadSalesOrderPdf(
                                    //     data.name,
                                    //     format,
                                    //   );
                                    // },
                                      onTap: () async {
                                        final path = await provider.downloadSalesOrderPdf(data.name, format);

                                        if (path == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Failed to download PDF")),
                                          );
                                          return;
                                        }

                                        final result = await OpenFilex.open(path);

                                        debugPrint("Open result: ${result.message}");

                                        if (result.type != ResultType.done) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("No app found to open PDF")),
                                          );
                                        }
                                      }
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error loading formats")),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 5),
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



