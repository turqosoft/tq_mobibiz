import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import '../../service/apiservices.dart';
import '../../utils/sharedpreference.dart';
import '../new_Transcation/get_sales_order.dart';
import '../sales_invoice.dart/SalesInvoice.dart';
import 'add_customer.dart';
import 'ledger_pdf_builder.dart';
import 'map_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  _CustomersListScreenState createState() => _CustomersListScreenState();
}


class _CustomersListScreenState extends State<CustomersListScreen> {
  String? _selectedFilter;
  List<String> _filters = [];
  bool _isMyCustomers = false; // 👈 NEW
  final TextEditingController _searchController = TextEditingController();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final ScrollController _scrollController = ScrollController();
  bool _isFilterBarOpen = false; // 👈 collapsed by default (compact)
  bool _showUnpaidOnly = false;
  final ValueNotifier<bool> _showBackToTop = ValueNotifier(false);
  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController.addListener(_onScroll);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     // ✅ Only fetch if not already loaded
  //     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //     if (provider.customerListModel == null ||
  //         provider.customerListModel?.data == null ||
  //         provider.customerListModel!.data!.isEmpty) {
  //       _fetchCustomerList();
  //     }
  //     _fetchCustomerGroupList();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 👇 NEW: Read toggle from SharedPreferences as default
      final savedValue =
      await _sharedPrefService.getCustomerFilterBySalesPerson();
      setState(() {
        _isMyCustomers = savedValue;
        // _isFilterBarOpen = savedValue;

      });

      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);
      if (provider.customerListModel == null ||
          provider.customerListModel?.data == null ||
          provider.customerListModel!.data!.isEmpty) {
        _fetchCustomerList();
      }
      _fetchCustomerGroupList();
    });
  }
  @override
  void dispose() {
    _showBackToTop.dispose();
    // _debounce?.cancel();
    // _hasSearchText.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // void _onScroll() {
  //   if (_scrollController.position.pixels >=
  //       _scrollController.position.maxScrollExtent - 200) {
  //     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //     if (!provider.isLoadingMore && provider.hasMoreData) {
  //       provider.loadMoreCustomers(context);
  //     }
  //   }
  // }
  void _onScroll() {
    // ✅ Show/hide back to top button
    _showBackToTop.value = _scrollController.position.pixels > 400;

    // existing load more logic
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMoreData) {
        provider.loadMoreCustomers(context);
      }
    }
  }

  // Future<void> _fetchCustomerList() async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   try {
  //     await provider.customerList(context);
  //   } catch (e) {
  //     print('Error fetching customer details: $e');
  //   }
  // }
  Future<void> _fetchCustomerList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      // 👇 Pass the local toggle state instead of always reading SharedPrefs
      await provider.customerList(context, filterOverride: _isMyCustomers);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }
  Future<void> _fetchCustomerGroupList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      final customerGroupList = await provider.customerGroupList(context);
      setState(() {
        _filters =
            customerGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
      });
    } catch (e) {
      print('Error fetching customer groups: $e');
    }
  }
  Future<Position?> _getDeviceLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied.")),
      );
      return null;
    }

    // ✅ Get device position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  Future<void> _fetchCustomerGroupFilter(
      String customerGroup, BuildContext content) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.applyCustomerGroupFilter(customerGroup, content);
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }
  Future<void> saveAndOpenPdf(List<int> pdfBytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName.pdf");
    await file.writeAsBytes(pdfBytes, flush: true);
    await OpenFilex.open(file.path);
  }

  // Future<void> _fetchCustomerNameSearch(
  //     String customerName, BuildContext content) async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   try {
  //     await provider.customerNameSearch(customerName, content);
  //   } catch (e) {
  //     print('Error fetching customer details: $e');
  //   }
  // }
  Future<void> _fetchCustomerNameSearch(
      String customerName, BuildContext context) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      if (provider.showOnlyUnpaid) {
        // 👇 Search within unpaid customers locally first
        provider.searchWithinUnpaid(customerName);
      } else {
        await provider.customerNameSearch(customerName, context);
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  DateTime safeSubtractOneMonth(DateTime date) {
    // Move back one month, keeping the year correct
    int year = date.year;
    int month = date.month - 1;

    if (month == 0) {
      month = 12;
      year -= 1;
    }

    // Find the last day of the new month
    int lastDayOfPrevMonth = DateTime(year, month + 1, 0).day;

    // Clamp the day (e.g., 31 -> 28/29 if February)
    int day = date.day > lastDayOfPrevMonth ? lastDayOfPrevMonth : date.day;

    return DateTime(year, month, day);
  }
  Future<void> _showInvoiceDialog(
      BuildContext context,
      String customerName,
      double totalUnpaid,
      ) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // Show dialog immediately with a loading state
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _InvoiceListDialog(
        customerName: customerName,
        totalUnpaid: totalUnpaid,
        apiService: provider.apiService,
      ),
    );
  }

  void _showFilterDialog() {
    bool likedOnly =
        Provider.of<SalesOrderProvider>(context, listen: false).showOnlyLiked;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Items'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Customer Group Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Customer Group',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                    ),
                    value: _selectedFilter,
                    items: _filters.map((String filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        _selectedFilter = newValue;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  /// ⭐ Liked Customers Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: likedOnly,
                        onChanged: (value) {
                          setStateDialog(() {
                            likedOnly = value ?? false;
                          });
                        },
                      ),
                      const Text("Show Liked Customers Only"),
                    ],
                  ),
                ],
              ),
              actions: [

                /// Apply button
                TextButton(
                  child: const Text("Apply"),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    final provider =
                    Provider.of<SalesOrderProvider>(context, listen: false);
                    provider.toggleLikedFilter(likedOnly);

                    if (_selectedFilter != null) {
                      await _fetchCustomerGroupFilter(_selectedFilter!, context);
                    } else {
                      await provider.customerList(context);
                    }
                  },
                ),

                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // prevent closing
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }



  String formatDateForDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String formatDateForApi(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
  Widget _buildFilterBar() {
    final activeCount = (_isMyCustomers ? 1 : 0); // extend if you add more chips

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FILTERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // ── My Customers chip ──────────────────────────
              FilterChip(
                label: const Text('My customers'),
                selected: _isMyCustomers,
                avatar: Icon(
                  Icons.person_outline,
                  size: 16,
                  color: _isMyCustomers
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
                onSelected: (selected) async {
                  setState(() => _isMyCustomers = selected);
                  await _sharedPrefService
                      .saveCustomerFilterBySalesPerson(selected);
                  // _fetchCustomerList();
                  final provider =
                  Provider.of<SalesOrderProvider>(context, listen: false);

                  if (_showUnpaidOnly) {
                    // Both filters active — re-fetch unpaid with new salesPerson scope
                    await provider.setUnpaidFilter(
                      enabled: true,
                      context: context,
                      filterBySalesPerson: selected,
                    );
                  } else {
                    _fetchCustomerList();
                  }
                },
                selectedColor:
                Theme.of(context).primaryColor.withOpacity(0.12),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: _isMyCustomers
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                  fontWeight: _isMyCustomers
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _isMyCustomers
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
// ── Has unpaid chip ────────────────────────────────
              FilterChip(
                label: const Text('Has unpaid'),
                selected: _showUnpaidOnly,
                avatar: Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: _showUnpaidOnly ? Colors.red.shade700 : Colors.grey.shade600,
                ),
                onSelected: (selected) async {
                  setState(() => _showUnpaidOnly = selected);

                  final provider =
                  Provider.of<SalesOrderProvider>(context, listen: false);
                  if (!selected) {
                    _searchController.clear(); // 👈 clear search on filter off
                  }
                  await provider.setUnpaidFilter(
                    enabled: selected,
                    context: context,
                    // Pass current "My Customers" state so it respects both filters
                    filterBySalesPerson: _isMyCustomers,
                  );                },
                selectedColor: Colors.red.withOpacity(0.10),
                checkmarkColor: Colors.red.shade700,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: _showUnpaidOnly ? Colors.red.shade700 : Colors.black87,
                  fontWeight:
                  _showUnpaidOnly ? FontWeight.w500 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _showUnpaidOnly ? Colors.red.shade400 : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Add more FilterChips here as needed
              // e.g. Liked, Retail, Wholesale group chips...
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFilterTogglePill() {
    // final activeCount = (_isMyCustomers ? 1 : 0);
    final activeCount = (_isMyCustomers ? 1 : 0) + (_showUnpaidOnly ? 1 : 0);

    return InkWell(
      onTap: () => setState(() => _isFilterBarOpen = !_isFilterBarOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: _isFilterBarOpen ? -0.5 : 0, // chevron flips
              duration: const Duration(milliseconds: 260),
              child: const Icon(Icons.expand_more,
                  size: 16, color: Colors.grey),
            ),
            const SizedBox(width: 4),
            Text(
              _isFilterBarOpen ? 'Hide filters' : 'Show filters',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customers',
        onBackTap: () {
          Navigator.pop(context);
        },
        actions: Row(
          children: [
            // ➕ ADD NEW CUSTOMER BUTTON
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                ).then((_) {
                  _fetchCustomerList();   // Refresh after adding customer
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: () async {
                _searchController.clear();

                final provider =
                Provider.of<SalesOrderProvider>(context, listen: false);

                // ⭐ Reset liked filter
                provider.resetLikedFilter();

                setState(() {
                  _selectedFilter = null;
                  _showUnpaidOnly = false;
                });

                await _fetchCustomerList();
              },
            ),
            // 👇 Filter icon with active indicator
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: Colors.white,
              ),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
      ),


        // body: Consumer<SalesOrderProvider>(
        // body: Column(
        //     children: [
      body: Stack(
          children: [

      // ── Your existing Column body ──────────────────────────────
      Column(
      children: [
              // ── Expandable filter bar ──────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                height: _isFilterBarOpen ? null : 0,     // shrink to 0 when collapsed
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),       // required for clipBehavior
                child: _buildFilterBar(),
              ),

              // ── Collapse toggle pill ───────────────────────────────
              _buildFilterTogglePill(),


    // 👇 Your existing Consumer body, now wrapped in Expanded
    Expanded(
    child: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {

          // 👇 Use unpaid list when filter is active, else normal list
          final customerList = provider.showOnlyUnpaid
              ? provider.unpaidCustomerList
              : provider.customerListModel?.data ?? [];

          final isSearch = provider.activeSearch != null;

          // Show shimmer/loading while fetching all for unpaid
          if (provider.isLoading ||
              (provider.isFetchingAllForUnpaid &&
                  provider.unpaidCustomerList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customerList.isEmpty) {
            return Center(
              child: provider.isFetchingAllForUnpaid
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading customers with unpaid…'),
                ],
              )
                  : const Text('No customers found'),
            );
          }
      // final customerList = provider.customerListModel?.data ?? [];
          final rawList = provider.customerListModel?.data ?? [];

      if (provider.isLoading) {
        return Center(child: CircularProgressIndicator());
      } else if (provider.customerListModel == null ||
          provider.customerListModel!.data == null ||
          provider.customerListModel!.data!.isEmpty) {
        return Center(child: Text('No current customer available.'));
      }

      return SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
          padding: const EdgeInsets.all(15.0),
    child: Column(
    children: [
    // Search field
    Container(
    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
    decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(10.0),
    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search name',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              _fetchCustomerNameSearch(_searchController.text, context);
                            } else {
                              // Show message if search is empty
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a customer name to search'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          _fetchCustomerNameSearch(query, context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a customer name to search'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),


                  ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Consumer<SalesOrderProvider>(
          builder: (context, provider, _) {
            return Align(
              alignment: Alignment.center,
              child: provider.showOnlyUnpaid
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.isFetchingAllForUnpaid
                        ? 'Found ${provider.unpaidCustomerList.length} so far…'
                        : 'Customers with unpaid: ${provider.unpaidCustomerList.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  if (!provider.isFetchingAllForUnpaid) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Total unpaid: ₹${provider.totalUnpaidSum.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              )
                  : Text(
                isSearch
                    ? 'Found ${provider.customerCount} customers'
                    : 'Total customers: ${provider.customerCount}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      // 👇 Progress banner — shows while background batches are still loading
      if (provider.isFetchingAllForUnpaid)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          color: Colors.orange.withOpacity(0.08),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(        // 👈 wrap Text in Expanded
                child: Text(
                  'Loading customers with unpaid '
                      '(${provider.unpaidCustomerList.length} found so far)',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                  overflow: TextOverflow.ellipsis,  // 👈 safety fallback
                ),
              ),
            ],
          ),
        ),
                  customerList.isNotEmpty

      ?ListView.builder(
        itemCount: customerList.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final customer = customerList[index];
          final slNo = index + 1;

          // fetch details only once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final provider = Provider.of<SalesOrderProvider>(context, listen: false);
            provider.apiService!.fetchCustomerDetailss(customer, context);
          });

          // return Stack(
          return GestureDetector(
              onTap: () => _showPaymentCollectionDialog(context, customer), // ✅ tap to open dialog
          child: Stack(
              children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Serial Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$slNo",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Customer Name + Sales Person + Favorite Icon
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and Sales Person
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name ?? "N/A",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (customer.salesPersons.isNotEmpty)
                                    Text(
                                      "Sales Person: ${customer.salesPersons.join(", ")}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),

                            // ✅ Favorite Icon aligned to the right of name/sales person
                            GestureDetector(
                              onTap: () {
                                Provider.of<SalesOrderProvider>(context, listen: false)
                                    .toggleCustomerFavorite(context, customer);
                              },
                              child: Icon(
                                customer.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: customer.isLiked ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Compact Info Grid (2 columns)
                  _buildInfoGrid(context,customer),

                  // Financial Info (if available)
                  if ((customer.billingThisYear != null && customer.billingThisYear! > 0) ||
                      (customer.totalUnpaid != null && customer.totalUnpaid! > 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          if (customer.billingThisYear != null && customer.billingThisYear! > 0)
                            Expanded(
                              child: _buildFinancialChip(
                                "Billing",
                                customer.billingThisYear!,
                                Colors.green,
                              ),
                            ),
                          if (customer.billingThisYear != null &&
                              customer.billingThisYear! > 0 &&
                              customer.totalUnpaid != null &&
                              customer.totalUnpaid! > 0)
                            const SizedBox(width: 6),

                          if (customer.totalUnpaid != null && customer.totalUnpaid! > 0)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showInvoiceDialog(
                                  context,
                                  customer.name ?? '',
                                  customer.totalUnpaid!,
                                ),
                                child: _buildFinancialChip(
                                  "Unpaid",
                                  customer.totalUnpaid!,
                                  Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const Divider(thickness: 0.5, height: 16),

                  // Compact Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactActionButton(
                        icon: Icons.file_download,
                        label: "GL",
                        color: Colors.orangeAccent,
                        onPressed: () async {
                          final api = Provider.of<SalesOrderProvider>(context, listen: false);

                          final DateTime? fromDate = await showDatePicker(
                            context: context,
                            locale: const Locale('en', 'GB'),
                            initialDate: DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            helpText: "Select From Date",
                          );

                          if (fromDate == null) return;

                          final DateTime? toDate = await showDatePicker(
                            context: context,
                            locale: const Locale('en', 'GB'),
                            initialDate: DateTime.now(),
                            firstDate: fromDate,
                            lastDate: DateTime.now(),
                            helpText: "Select To Date",
                          );

                          if (toDate == null) return;

                          String formatDate(DateTime date) =>
                              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                          final fromDateStr = formatDate(fromDate);
                          final toDateStr = formatDate(toDate);

                          final ledgerJson = await api.apiService!.FetchGeneralLedger(
                            context,
                            customer.name!,
                            fromDateStr,
                            toDateStr,
                          );

                          if (ledgerJson != null) {
                            final html = BuildLedgerHtml(
                              ledgerJson,
                              fromDateStr,
                              toDateStr,
                              fallbackCustomerName: customer.name,
                            );

                            final pdfBytes = await api.apiService!.generatePdfFromHtml(context, html);

                            if (pdfBytes != null) {
                              await saveAndOpenPdf(
                                pdfBytes as List<int>,
                                "General_Ledger_${customer.name}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("PDF Downloaded Successfully")),
                              );
                            }
                          }
                        },
                      ),

                      _buildCompactActionButton(
                        icon: Icons.picture_as_pdf,
                        label: "AR",
                        color: Colors.red,
                        // onPressed: () async {
                        //   final result = await showReceivableFilterDialog(context);
                        //   if (result == null) return;
                        //
                        //   final minOverdueDays = result.daysBefore;
                        //   final postingDate = formatDateForApi(DateTime.now());
                        //
                        //   showLoadingDialog(context);
                        //
                        //   final fullName = await _sharedPrefService.getFullName() ?? "";
                        //   try {
                        //     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                        //     final api = provider.apiService!;
                        //     final company = await _sharedPrefService.getCompany();
                        //     final party = customer.name!;
                        //
                        //     final report = await api.fetchAccountsReceivable(
                        //       context,
                        //       company!,
                        //       postingDate,
                        //       party,
                        //       result.range,
                        //     );
                        //
                        //     if (report == null) return;
                        //
                        //     final List<dynamic> originalRows = report["data"] as List<dynamic>;
                        //     final filteredRows = originalRows.where((row) {
                        //       final age = (row["age"] ?? 0).toInt();
                        //       return age >= minOverdueDays;
                        //     }).toList();
                        //     report["data"] = filteredRows;
                        //
                        //     final rangeLabel = buildRangeLabel(result.range);
                        //     final letterheadContent = await api.fetchLetterHeadContent(context);
                        //
                        //     final html = buildAccountsReceivableHtml(
                        //       report,
                        //       party,
                        //       postingDate,
                        //       rangeLabel,
                        //       company,
                        //       fullName,
                        //       letterheadContent,
                        //       // provider.domain,
                        //       provider.baseHost,
                        //     );
                        //
                        //     final pdfBytes = await api.generatePdfFromHtml(context, html);
                        //
                        //     if (pdfBytes != null) {
                        //       await saveAndOpenPdf(
                        //         pdfBytes,
                        //         "Accounts_Receivable_${party}_$postingDate.pdf",
                        //       );
                        //     }
                        //   } finally {
                        //     Navigator.pop(context);
                        //   }
                        // },
                        onPressed: () async {
                          final result = await showReceivableFilterDialog(context);
                          if (result == null) return;

                          final minOverdueDays = result.daysBefore;
                          final postingDate = formatDateForApi(DateTime.now());

                          showLoadingDialog(context);

                          final fullName =
                              await _sharedPrefService.getFullName() ?? "";

                          try {
                            final provider =
                            Provider.of<SalesOrderProvider>(context, listen: false);
                            final api = provider.apiService!;
                            final company = await _sharedPrefService.getCompany();
                            final party = customer.name!;

                            final report = await api.fetchAccountsReceivable(
                              context,
                              company!,
                              postingDate,
                              party,
                              result.range,
                            );

                            if (report == null) return;

                            final List<dynamic> originalRows =
                            report["data"] as List<dynamic>;
                            final filteredRows = originalRows.where((row) {
                              final age = (row["age"] ?? 0).toInt();
                              return minOverdueDays <= 0 || age >= minOverdueDays;
                            }).toList();

                            final rangeLabel = buildRangeLabel(result.range);
                            final letterheadContent =
                            await api.fetchLetterHeadContent(context);

                            // 👇 Close loading dialog before showing preview
                            Navigator.pop(context);

                            // 👇 Show preview dialog
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => AccountsReceivablePreviewDialog(
                                party: party,
                                company: company,
                                postingDate: postingDate,
                                rangeLabel: rangeLabel,
                                rows: filteredRows,
                                fullName: fullName,
                                onDownload: () async {
                                  // 👇 PDF generation happens only when user taps Download
                                  report["data"] = filteredRows;
                                  final html = buildAccountsReceivableHtml(
                                    report,
                                    party,
                                    postingDate,
                                    rangeLabel,
                                    company,
                                    fullName,
                                    letterheadContent,
                                    provider.baseHost,
                                  );
                                  final pdfBytes =
                                  await api.generatePdfFromHtml(context, html);
                                  if (pdfBytes != null) {
                                    await saveAndOpenPdf(
                                      pdfBytes,
                                      "Accounts_Receivable_${party}_$postingDate.pdf",
                                    );
                                  }
                                },
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(context); // close loading on error
                            debugPrint('AR error: $e');
                          }
                        },
                      ),
                      // 👇 NEW: Sales Order button
                      _buildCompactActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: "SO",
                        color: Colors.green,
                        onPressed: () {
                          // 👇 fallback to customer.name if customerName is null
                          final displayName = (customer.customerName != null &&
                              customer.customerName!.isNotEmpty)
                              ? customer.customerName!
                              : customer.name ?? '';

                          debugPrint('SO button tapped');
                          debugPrint('customer.name: ${customer.name}');
                          debugPrint('customer.customerName: ${customer.customerName}');
                          debugPrint('displayName resolved to: $displayName');

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalesOrderPage(
                                initialCustomerName: displayName,  // 👈 never null now
                                initialCustomerId: customer.name,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildCompactActionButton(
                        icon: Icons.location_on,
                        label: "Map",
                        color: Colors.blue,
                        onPressed: () async {
                          final api = Provider.of<SalesOrderProvider>(context, listen: false);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final customerDetails = await api.apiService!.fetchCustomerLocation(customer.name!, context);

                            double? lat = customerDetails?["latitude"]?.toDouble();
                            double? lng = customerDetails?["longitude"]?.toDouble();

                            Navigator.pop(context);

                            if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
                              final shouldFetch = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Location Not Found"),
                                  content: const Text("No location found. Do you want to fetch from this device?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldFetch == true) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                                );

                                final position = await _getDeviceLocation(context);
                                Navigator.pop(context);
                                if (position != null) {
                                  lat = position.latitude;
                                  lng = position.longitude;
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Location not available.")),
                                );
                                return;
                              }
                            }

                            if (lat != null && lng != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => CustomerMapScreen(
                                    latitude: lat!,
                                    longitude: lng!,
                                    customerName: customer.name!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No location data available.")),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )]));
        },
      )

                      : Center(
                          child: provider.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('No customers found'),
                        ),

      // Loading indicator at bottom
      if (provider.isLoadingMore)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),

      // End of list message
      if (!provider.hasMoreData && customerList.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No more customers to load',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
    ],
    ),
          ),
      );
        },
        ),
    ),
    ]
      ),
    // ── Back to Top Button ─────────────────────────────────────
    Positioned(
      bottom: 24 + MediaQuery.of(context).padding.bottom,
    right: 16,
    child: ValueListenableBuilder<bool>(
    valueListenable: _showBackToTop,
    builder: (context, show, _) {
    return AnimatedSlide(
    offset: show ? Offset.zero : const Offset(0, 2),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    child: AnimatedOpacity(
    opacity: show ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 300),
    child: show
    ? GestureDetector(
    onTap: () {
    _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    );
    },
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
    color: AppColors.primaryColor,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
    BoxShadow(
    color: AppColors.primaryColor.withOpacity(0.35),
    blurRadius: 10,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.keyboard_arrow_up_rounded,
    color: Colors.white, size: 18),
    SizedBox(width: 4),
    // Text(
    // "Top",
    // style: TextStyle(
    // color: Colors.white,
    // fontSize: 12,
    // fontWeight: FontWeight.w600,
    // ),
    // ),
    ],
    ),
    ),
    )
        : const SizedBox.shrink(),
    ),
    );
    },
    ),
    ),
    ],
    ),
    );
  }
}
Future<void> saveAndOpenPdf(List<int> pdfBytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File("${dir.path}/$fileName.pdf");
  await file.writeAsBytes(pdfBytes, flush: true);
  await OpenFilex.open(file.path);
}

void _showPaymentCollectionDialog(BuildContext context, customer) {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController chequeNoController = TextEditingController();
  final TextEditingController beingController = TextEditingController();
  final TextEditingController drawnOnController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime? chequeDate;
  String? selectedModeOfPayment;
  bool isSettled = false;
  bool isSubmitting = false;
  List<String> paymentModes = [];
  bool isLoadingModes = true;
  int selectedTab = 0; // 0 = New Payment, 1 = History
  List<Map<String, dynamic>> paymentHistory = [];
  bool isLoadingHistory = false;
  bool _historyFetchInitiated = false;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setStateSheet) {
          if (isLoadingModes && paymentModes.isEmpty) {
            Provider.of<SalesOrderProvider>(context, listen: false)
                .apiService!
                .fetchModeOfPayments()
                .then((modes) {
              setStateSheet(() {
                paymentModes = modes;
                selectedModeOfPayment = modes.isNotEmpty ? modes.first : null;
                isLoadingModes = false;
              });
            });
          }
// ✅ Only trigger once, not on every rebuild
          if (selectedTab == 1 && !_historyFetchInitiated) {
            _historyFetchInitiated = true;
            isLoadingHistory = true;

            Future.microtask(() {
              Provider.of<SalesOrderProvider>(context, listen: false)
                  .apiService!
                  .fetchPaymentCollections(customerName: customer.name ?? '')
                  .then((list) {
                setStateSheet(() {
                  paymentHistory = list;
                  isLoadingHistory = false;
                });
              }).catchError((_) {
                setStateSheet(() => isLoadingHistory = false);
              });
            });
          }
          final displayDate = DateFormat('dd MMM yyyy').format(selectedDate);
          final apiDate = DateFormat('yyyy-MM-dd').format(selectedDate);
          final displayChequeDate = chequeDate != null
              ? DateFormat('dd MMM yyyy').format(chequeDate!)
              : "Select Date";
          final apiChequeDate = chequeDate != null
              ? DateFormat('yyyy-MM-dd').format(chequeDate!)
              : null;

// ✅ Show extra fields for any mode except Cash
          final isCash = selectedModeOfPayment?.toLowerCase().trim() == 'cash';
          final showExtraFields = selectedModeOfPayment != null && !isCash;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Drag handle ──────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 2),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.payments_rounded,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Payment Collection",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              Text(
                                customer.name ?? "",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Date chip — tappable
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: ColorScheme.light(
                                      primary: AppColors.primaryColor),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setStateSheet(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_calendar_outlined,
                                    size: 13, color: AppColors.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  displayDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Divider(height: 1, thickness: 0.8),
                  ),
// ── Tab Bar ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _buildTab(
                            label: "New Payment",
                            icon: Icons.add_circle_outline_rounded,
                            selected: selectedTab == 0,
                            onTap: () => setStateSheet(() => selectedTab = 0),
                          ),
                          _buildTab(
                            label: "History",
                            icon: Icons.history_rounded,
                            selected: selectedTab == 1,
                            onTap: () => setStateSheet(() => selectedTab = 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Scrollable form ──────────────────────────────────
                  Flexible(
                    child: selectedTab == 0

                    // ── your existing form — completely unchanged ─────────
                        ? SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Mode of Payment
                          _buildCompactLabel("Mode of Payment"),
                          const SizedBox(height: 5),
                          isLoadingModes
                              ? _buildLoadingField()
                              : _buildDropdownField(
                            value: selectedModeOfPayment,
                            items: paymentModes,
                            icon: Icons.account_balance_wallet_outlined,
                            onChanged: (v) => setStateSheet(
                                    () => selectedModeOfPayment = v),
                          ),

                          const SizedBox(height: 12),

                          // Amount
                          _buildCompactLabel("Amount"),
                          const SizedBox(height: 5),
                          _buildInputField(
                            controller: amountController,
                            hint: "0.00",
                            icon: Icons.currency_rupee_rounded,
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 12),

                          // Being
                          _buildCompactLabel("Being"),
                          const SizedBox(height: 5),
                          _buildInputField(
                            controller: beingController,
                            hint: "Purpose of payment...",
                            icon: Icons.description_outlined,
                          ),

                          const SizedBox(height: 12),

                          // // ✅ Cheque fields — shown only for cheque mode
                          // if (isChequeMode) ...[
                          //
                          //   // Cheque No
                          //   _buildCompactLabel("Cheque No"),
                          //   const SizedBox(height: 5),
                          //   _buildInputField(
                          //     controller: chequeNoController,
                          //     hint: "Enter cheque number",
                          //     icon: Icons.confirmation_number_outlined,
                          //     keyboardType: TextInputType.number,
                          //   ),
                          //
                          //   const SizedBox(height: 12),
                          //
                          //   // Cheque Date
                          //   _buildCompactLabel("Cheque Date"),
                          //   const SizedBox(height: 5),
                          //   GestureDetector(
                          //     onTap: () async {
                          //       final picked = await showDatePicker(
                          //         context: context,
                          //         initialDate: chequeDate ?? DateTime.now(),
                          //         firstDate: DateTime(2020),
                          //         lastDate: DateTime(2100),
                          //         builder: (ctx, child) => Theme(
                          //           data: Theme.of(ctx).copyWith(
                          //             colorScheme: ColorScheme.light(
                          //                 primary: AppColors.primaryColor),
                          //           ),
                          //           child: child!,
                          //         ),
                          //       );
                          //       if (picked != null) {
                          //         setStateSheet(() => chequeDate = picked);
                          //       }
                          //     },
                          //     child: Container(
                          //       padding: const EdgeInsets.symmetric(
                          //           horizontal: 12, vertical: 13),
                          //       decoration: BoxDecoration(
                          //         color: Colors.grey[50],
                          //         borderRadius: BorderRadius.circular(10),
                          //         border:
                          //         Border.all(color: Colors.grey.shade200),
                          //       ),
                          //       child: Row(
                          //         children: [
                          //           Icon(Icons.calendar_month_outlined,
                          //               size: 18, color: Colors.grey[500]),
                          //           const SizedBox(width: 10),
                          //           Text(
                          //             displayChequeDate,
                          //             style: TextStyle(
                          //               fontSize: 13,
                          //               color: chequeDate != null
                          //                   ? Colors.black87
                          //                   : Colors.grey[400],
                          //             ),
                          //           ),
                          //           const Spacer(),
                          //           Icon(Icons.edit_outlined,
                          //               size: 14, color: Colors.grey[400]),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          //
                          //   const SizedBox(height: 12),
                          //
                          //   // Drawn On (Bank name)
                          //   _buildCompactLabel("Drawn On"),
                          //   const SizedBox(height: 5),
                          //   _buildInputField(
                          //     controller: drawnOnController,
                          //     hint: "Bank name...",
                          //     icon: Icons.account_balance_outlined,
                          //   ),
                          //
                          //   const SizedBox(height: 12),
                          // ],
// ✅ Cheque/Other payment fields — hidden only for Cash
                          if (showExtraFields) ...[

                            // Cheque/Reference No
                            _buildCompactLabel("Cheque/Reference No"),
                            const SizedBox(height: 5),
                            _buildInputField(
                              controller: chequeNoController,
                              hint: "Enter cheque/reference number",
                              icon: Icons.confirmation_number_outlined,
                              keyboardType: TextInputType.text,
                            ),

                            const SizedBox(height: 12),

                            // Cheque/Transaction Date
                            _buildCompactLabel("Cheque/Transaction Date"),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: chequeDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: AppColors.primaryColor),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setStateSheet(() => chequeDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month_outlined,
                                        size: 18, color: Colors.grey[500]),
                                    const SizedBox(width: 10),
                                    Text(
                                      displayChequeDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: chequeDate != null
                                            ? Colors.black87
                                            : Colors.grey[400],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.edit_outlined,
                                        size: 14, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Drawn On (Bank name)
                            _buildCompactLabel("Drawn On"),
                            const SizedBox(height: 5),
                            _buildInputField(
                              controller: drawnOnController,
                              hint: "Bank name...",
                              icon: Icons.account_balance_outlined,
                            ),

                            const SizedBox(height: 12),
                          ],
                          // Remarks
                          _buildCompactLabel("Remarks (Optional)"),
                          const SizedBox(height: 5),
                          _buildInputField(
                            controller: remarksController,
                            hint: "Add a note...",
                            icon: Icons.notes_rounded,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 16),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    side:
                                    BorderSide(color: Colors.grey.shade300),
                                  ),
                                  child: const Text("Cancel",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  // onPressed: isSubmitting
                                  //     ? null
                                  //     : () async {
                                  //   final amount = double.tryParse(
                                  //       amountController.text);
                                  //   if (amount == null || amount <= 0) {
                                  //     Fluttertoast.showToast(
                                  //         msg: "Enter a valid amount");
                                  //     return;
                                  //   }
                                  //   if (selectedModeOfPayment == null) {
                                  //     Fluttertoast.showToast(
                                  //         msg: "Select payment mode");
                                  //     return;
                                  //   }
                                  //   // ✅ Validate cheque fields if cheque mode
                                  //   if (isChequeMode &&
                                  //       chequeNoController.text
                                  //           .trim()
                                  //           .isEmpty) {
                                  //     Fluttertoast.showToast(
                                  //         msg: "Enter cheque number");
                                  //     return;
                                  //   }
                                  //
                                  //   setStateSheet(
                                  //           () => isSubmitting = true);
                                  //
                                  //   final provider =
                                  //   Provider.of<SalesOrderProvider>(
                                  //       context,
                                  //       listen: false);
                                  //
                                  //   // ✅ Build payload with conditional cheque fields
                                  //   final payload = {
                                  //     "docstatus": 1,
                                  //     "customer": customer.name,
                                  //     "mode_of_payment":
                                  //     selectedModeOfPayment,
                                  //     "date": apiDate,
                                  //     "amount": amount,
                                  //     "is_settled": isSettled ? 1 : 0,
                                  //     "remarks":
                                  //     remarksController.text.trim(),
                                  //     "being": beingController.text.trim(),
                                  //     if (isChequeMode) ...{
                                  //       "cash_cheque_no":
                                  //       chequeNoController.text.trim(),
                                  //       if (apiChequeDate != null)
                                  //         "cheque_date": apiChequeDate,
                                  //       "drawn_on":
                                  //       drawnOnController.text.trim(),
                                  //     },
                                  //   };
                                  //
                                  //   final docName = await provider
                                  //       .createPaymentCollection(
                                  //       payload, context);
                                  // onPressed: isSubmitting
                                  //     ? null
                                  //     : () async {
                                  //   final amount = double.tryParse(amountController.text);
                                  //   if (amount == null || amount <= 0) {
                                  //     Fluttertoast.showToast(msg: "Enter a valid amount");
                                  //     return;
                                  //   }
                                  //   if (selectedModeOfPayment == null) {
                                  //     Fluttertoast.showToast(msg: "Select payment mode");
                                  //     return;
                                  //   }
                                  //   // ✅ Validate extra fields if not cash
                                  //   if (showExtraFields &&
                                  //       chequeNoController.text.trim().isEmpty) {
                                  //     Fluttertoast.showToast(msg: "Enter cheque/reference number");
                                  //     return;
                                  //   }
                                  //
                                  //   setStateSheet(() => isSubmitting = true);
                                  //
                                  //   final provider = Provider.of<SalesOrderProvider>(
                                  //       context, listen: false);
                                  //
                                  //   // ✅ Build payload — extra fields only when not cash
                                  //   final payload = {
                                  //     "docstatus": 1,
                                  //     "customer": customer.name,
                                  //     "mode_of_payment": selectedModeOfPayment,
                                  //     "date": apiDate,
                                  //     "amount": amount,
                                  //     "is_settled": isSettled ? 1 : 0,
                                  //     "remarks": remarksController.text.trim(),
                                  //     "being": beingController.text.trim(),
                                  //     if (showExtraFields) ...{
                                  //       "cash_cheque_no": chequeNoController.text.trim(),
                                  //       if (apiChequeDate != null) "cheque_date": apiChequeDate,
                                  //       "drawn_on": drawnOnController.text.trim(),
                                  //     },
                                  //   };
                                  //
                                  //   final docName = await provider.createPaymentCollection(payload, context);
                                  //
                                  //   setStateSheet(
                                  //           () => isSubmitting = false);
                                  //   Navigator.of(sheetContext).pop();
                                  //
                                  //   if (docName != null) {
                                  //     Fluttertoast.showToast(
                                  //         msg:
                                  //         "Payment collected! Downloading PDF...");
                                  //
                                  //     final pdfBytes = await provider
                                  //         .apiService!
                                  //         .downloadPaymentCollectionPdf(
                                  //       docName: docName,
                                  //       context: context,
                                  //     );
                                  //
                                  //     if (pdfBytes != null) {
                                  //       try {
                                  //         final dir =
                                  //         await getApplicationDocumentsDirectory();
                                  //         final safeFileName =
                                  //             "Payment_Collection_${docName.replaceAll('/', '_')}.pdf";
                                  //         final file = File(
                                  //             "${dir.path}/$safeFileName");
                                  //         await file.writeAsBytes(pdfBytes,
                                  //             flush: true);
                                  //         await OpenFilex.open(file.path);
                                  //       } catch (e) {
                                  //         debugPrint(
                                  //             "Error saving PDF: $e");
                                  //         Fluttertoast.showToast(
                                  //             msg: "Failed to open PDF");
                                  //       }
                                  //     } else {
                                  //       Fluttertoast.showToast(
                                  //           msg:
                                  //           "Failed to download PDF");
                                  //     }
                                  //   } else {
                                  //     Fluttertoast.showToast(
                                  //         msg:
                                  //         "Failed to create payment");
                                  //   }
                                  // },
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                    final amount = double.tryParse(amountController.text);
                                    if (amount == null || amount <= 0) {
                                      Fluttertoast.showToast(msg: "Enter a valid amount");
                                      return;
                                    }
                                    if (selectedModeOfPayment == null) {
                                      Fluttertoast.showToast(msg: "Select payment mode");
                                      return;
                                    }
                                    // ✅ Validate extra fields if not cash
                                    if (showExtraFields &&
                                        chequeNoController.text.trim().isEmpty) {
                                      Fluttertoast.showToast(msg: "Enter cheque/reference number");
                                      return;
                                    }

                                    setStateSheet(() => isSubmitting = true);

                                    final provider = Provider.of<SalesOrderProvider>(
                                        context, listen: false);

                                    // ✅ Build payload — extra fields only when not cash
                                    final payload = {
                                      "docstatus": 1,
                                      "customer": customer.name,
                                      "mode_of_payment": selectedModeOfPayment,
                                      "date": apiDate,
                                      "amount": amount,
                                      "is_settled": isSettled ? 1 : 0,
                                      "remarks": remarksController.text.trim(),
                                      "being": beingController.text.trim(),
                                      if (showExtraFields) ...{
                                        "cash_cheque_no": chequeNoController.text.trim(),
                                        if (apiChequeDate != null) "cheque_date": apiChequeDate,
                                        "drawn_on": drawnOnController.text.trim(),
                                      },
                                    };

                                    final docName = await provider.createPaymentCollection(payload, context);

                                    setStateSheet(() => isSubmitting = false);
                                    Navigator.of(sheetContext).pop();

                                    // ✅ Simple success/failure message — no PDF download
                                    Fluttertoast.showToast(
                                      msg: docName != null
                                          ? "Payment collection created successfully"
                                          : "Failed to create payment",
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                      : const Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 5),
                                      Text("Submit",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),)
                    // ── History tab ──────────────────────────────────────
                        : isLoadingHistory
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : paymentHistory.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              "No payment collections found",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      itemCount: paymentHistory.length,
                      itemBuilder: (context, index) {
                        final payment = paymentHistory[index];
                        final date = payment['date'] ?? '';
                        final amount = payment['amount'] ?? 0.0;
                        final mode = payment['mode_of_payment'] ?? '';
                        final name = payment['name'] ?? '';
                        final docStatus = (payment['docstatus'] ?? 0) as int;                        final remarks = payment['remarks'] ?? '';
                        final being = payment['being'] ?? '';

                        String displayPaymentDate = date;
                        try {
                          displayPaymentDate = DateFormat('dd MMM yyyy')
                              .format(DateTime.parse(date));
                        } catch (_) {}

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + settled badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getDocStatusColor(docStatus).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getDocStatusLabel(docStatus),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _getDocStatusColor(docStatus),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Amount + mode + date
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Amount
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.currency_rupee_rounded,
                                          size: 13, color: Colors.green[600]),
                                      Text(
                                        amount.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Mode
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getPaymentModeIcon(mode),
                                          size: 13, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        mode,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  // Date
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 12, color: Colors.grey[400]),
                                      const SizedBox(width: 3),
                                      Text(
                                        displayPaymentDate,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (being.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(being,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis),
                              ],
                              if (remarks.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(remarks,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),


                ],
              ),
            ),
          );
        },
      );
    },
  );
}
String _getDocStatusLabel(int docStatus) {
  switch (docStatus) {
    case 1:
      return "Submitted";
    case 2:
      return "Cancelled";
    default:
      return "Draft";
  }
}

Color _getDocStatusColor(int docStatus) {
  switch (docStatus) {
    case 1:
      return Colors.green;
    case 2:
      return Colors.red;
    default:
      return Colors.orange;
  }
}
Widget _buildTab({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.primaryColor : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildCompactLabel(String label) {
  return Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.black54,
      letterSpacing: 0.2,
    ),
  );
}

Widget _buildLoadingField() {
  return Container(
    height: 46,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: TextField(
      controller: controller,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType, // ✅ multiline keyboard
      maxLines: null,        // ✅ unlimited lines — grows with content
      minLines: maxLines,    // ✅ starts at the specified height
      textInputAction: maxLines > 1
          ? TextInputAction.newline  // ✅ Enter key adds new line instead of submitting
          : TextInputAction.done,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20 : 0), // ✅ align icon to top for multiline
          child: Icon(icon, size: 18, color: Colors.grey[500]),
        ),
        border: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      ),
    ),
  );
}

// Widget _buildDropdownField({
//   required String? value,
//   required List<String> items,
//   required IconData icon,
//   required ValueChanged<String?> onChanged,
// }) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(10),
//       border: Border.all(color: Colors.grey.shade200),
//     ),
//     child: DropdownButtonHideUnderline(
//       child: DropdownButton<String>(
//         value: value,
//         isExpanded: true,
//         icon: Icon(Icons.keyboard_arrow_down_rounded,
//             color: AppColors.primaryColor, size: 20),
//         style: const TextStyle(fontSize: 13, color: Colors.black87),
//         items: items.map((mode) {
//           return DropdownMenuItem(
//             value: mode,
//             child: Row(
//               children: [
//                 Icon(_getPaymentModeIcon(mode),
//                     size: 16, color: AppColors.primaryColor),
//                 const SizedBox(width: 8),
//                 Text(mode),
//               ],
//             ),
//           );
//         }).toList(),
//         onChanged: onChanged,
//       ),
//     ),
//   );
// }
Widget _buildDropdownField({
  required String? value,
  required List<String> items,
  required IconData icon,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10), // ✅ reduced from 14 to give more room
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryColor, size: 20),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        // ✅ selectedItemBuilder controls what shows in the closed field
        selectedItemBuilder: (context) {
          return items.map((mode) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPaymentModeIcon(mode),
                      size: 16, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      mode,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        items: items.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Row(
              mainAxisSize: MainAxisSize.min, // ✅ prevent row from expanding beyond content
              children: [
                Icon(_getPaymentModeIcon(mode),
                    size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Flexible(  // ✅ allow text to shrink instead of overflowing
                  child: Text(
                    mode,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
IconData _getPaymentModeIcon(String mode) {
  switch (mode.toLowerCase()) {
    case 'cash':
      return Icons.money_rounded;
    case 'cheque':
      return Icons.receipt_long_rounded;
    case 'upi':
      return Icons.phone_android_rounded;
    case 'neft/imps':
    case 'bank transfer':
      return Icons.account_balance_rounded;
    case 'credit card':
      return Icons.credit_card_rounded;
    case 'debit card':
      return Icons.credit_card_rounded;
    default:
      return Icons.payment_rounded;
  }
}
  String buildRangeLabel(String range) {
    final values = range.split(',').map(int.parse).toList();
    final labels = <String>[];

    int start = 0;
    for (final v in values) {
      labels.add("$start–$v");
      start = v + 1;
    }
    labels.add("${start}-Above");

    return labels.join(", ");
  }

  Future<ReceivableFilterResult?> showReceivableFilterDialog(
      BuildContext context,
      ) async {
    final daysController = TextEditingController(text: "0");
    final rangeController = TextEditingController(text: "30,60,90,120");

    return showDialog<ReceivableFilterResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Accounts Receivable Filter"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Days Before Field
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Overdue ≥ Days",
                  border: OutlineInputBorder(),
                ),

                onTap: () {
                  daysController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: daysController.text.length,
                  );
                },
              ),


              const SizedBox(height: 16),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final days = int.tryParse(daysController.text.trim()) ?? 0;
                final range = rangeController.text.trim();
                if (range.isEmpty) return;

                Navigator.pop(
                  context,
                  ReceivableFilterResult(
                    daysBefore: days,
                    range: range,
                  ),
                );
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

// Helper method to build info grid
Widget _buildInfoGrid(BuildContext context, customer) {
  final List<Map<String, String?>> infoItems = [
    if (customer.gstin != null) {"label": "GSTIN", "value": customer.gstin},
    if (customer.territory != null) {"label": "Territory", "value": customer.territory},
    if (customer.customerPrimaryContact != null)
      {"label": "Contact", "value": customer.customerPrimaryContact},
    if (customer.mobileNo != null) {"label": "Mobile", "value": customer.mobileNo},
    if (customer.taxCategory != null) {"label": "Tax Cat.", "value": customer.taxCategory},
    if (customer.customerGroup != null) {"label": "Group", "value": customer.customerGroup},
  ];

  return Wrap(
    spacing: 8,
    runSpacing: 6,
    children: infoItems.map((item) {
      return Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.42,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${item['label']}: ",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: Text(
                item['value'] ?? "",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

// Helper method for financial chips
Widget _buildFinancialChip(String label, double amount, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label == "Billing" ? Icons.trending_up : Icons.warning_amber_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            "$label: ₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// Helper method for compact action buttons
Widget _buildCompactActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
class ReceivableFilterResult {
  final int daysBefore;
  final String range;

  ReceivableFilterResult({
    required this.daysBefore,
    required this.range,
  });
}


class BuildCustomerDetail extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  const BuildCustomerDetail(
      {super.key, required this.label, this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class BuildCustomerTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  //final Widget iconWidget;
  const BuildCustomerTile({
    super.key,
    required this.label,
    this.value,
    required this.icon,
    //required this.iconWidget
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // iconWidget
        ],
      ),
    );
  }
}

class BuildItemDetail extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Function onTapAdd;
  final Function onTapClose;
  const BuildItemDetail(
      {super.key,
      required this.label,
      this.value,
      required this.icon,
      required this.onTapAdd,
      required this.onTapClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              onTapAdd.call();
            },
            child: Icon(Icons.add),
          ),
          GestureDetector(
            onTap: () {
              onTapClose.call();

            },
            child: Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class BuildItemListTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Function onTapAdd;
  final Function onTapClose;
  final int qty;
  const BuildItemListTile(
      {super.key,
      required this.label,
      this.value,
      required this.icon,
      required this.onTapAdd,
      required this.onTapClose,
      required this.qty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: GestureDetector(
              onTap: () {
                onTapAdd.call();
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.add),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('$qty'),
          ),
          GestureDetector(
            onTap: () {
              onTapClose.call();
            },
            child: Icon(Icons.minimize),
          ),
        ],
      ),
    );
  }
}
class _InvoiceListDialog extends StatefulWidget {
  final String customerName;
  final double totalUnpaid;
  final ApiService? apiService;
  const _InvoiceListDialog({
    required this.customerName,
    required this.totalUnpaid,
    required this.apiService,
  });

  @override
  State<_InvoiceListDialog> createState() => _InvoiceListDialogState();
}

class _InvoiceListDialogState extends State<_InvoiceListDialog> {
  List<Map<String, dynamic>> _invoices = []; // 👈 was List<String>
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }
  // Date formatter helper
  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return '—';
    try {
      final parsed = DateTime.parse(date.toString());
      return "${parsed.day.toString().padLeft(2, '0')}-"
          "${parsed.month.toString().padLeft(2, '0')}-"
          "${parsed.year}";
    } catch (_) {
      return date.toString();
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Status color helper
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'overdue':
        return Colors.orange;
      case 'partly paid':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }
  Future<void> _loadInvoices() async {
    if (widget.apiService == null) {
      setState(() {
        _error = 'Service unavailable';
        _isLoading = false;
      });
      return;
    }

    try {
      final invoices = await widget.apiService!.fetchCustomerSalesInvoices(
        customerName: widget.customerName,
        context: context,
      );
      if (mounted) {
        setState(() {
          _invoices = invoices; // 👈 now List<Map<String, dynamic>>
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load invoices';
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          // Container(
          //   padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
          //   decoration: BoxDecoration(
          //     color: Colors.red.withOpacity(0.06),
          //     borderRadius:
          //     const BorderRadius.vertical(top: Radius.circular(14)),
          //     border: Border(
          //       bottom: BorderSide(
          //         color: Colors.red.withOpacity(0.15),
          //       ),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.receipt_long, color: Colors.red, size: 20),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const Text(
          //               'Unpaid Invoices',
          //               style: TextStyle(
          //                 fontSize: 15,
          //                 fontWeight: FontWeight.w600,
          //                 color: Colors.red,
          //               ),
          //             ),
          //             Text(
          //               widget.customerName,
          //               style: TextStyle(
          //                 fontSize: 12,
          //                 color: Colors.grey.shade600,
          //               ),
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //           ],
          //         ),
          //       ),
          //       IconButton(
          //         icon: const Icon(Icons.close, size: 20),
          //         onPressed: () => Navigator.pop(context),
          //         color: Colors.grey.shade600,
          //         padding: EdgeInsets.zero,
          //         constraints: const BoxConstraints(),
          //       ),
          //     ],
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(color: Colors.red.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unpaid Invoices',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.customerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 👇 Total unpaid amount
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Total unpaid: ₹${widget.totalUnpaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _buildBody(),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isLoading && _invoices.isNotEmpty)
                  Text(
                    '${_invoices.length} invoice${_invoices.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
              SizedBox(height: 12),
              Text(
                'Loading invoices…',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 36),
              const SizedBox(height: 8),
              Text(
                _error!,
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadInvoices();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green.shade400, size: 36),
              const SizedBox(height: 8),
              Text(
                'No unpaid invoices found',
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Invoice list
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _invoices.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        final name = invoice['name']?.toString() ?? '—';
        final customer = invoice['customer']?.toString() ?? '—';
        final postingDate = _formatDate(invoice['posting_date']);
        final dueDate = _formatDate(invoice['due_date']);
        final status = invoice['status']?.toString();
        // final total = _toDouble(invoice['rounded_total'] ?? invoice['grand_total']);
        final rounded = _toDouble(invoice['rounded_total']);
        final grand = _toDouble(invoice['grand_total']);

        final total = rounded > 0 ? rounded : grand;
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalesInvoicePage(initialInvoice: name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice number + status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusColor(status).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Dates row
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Posted: $postingDate',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.event, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Due: $dueDate',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      customer,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AccountsReceivablePreviewDialog extends StatefulWidget {
  final String party;
  final String company;
  final String postingDate;
  final String rangeLabel;
  final List<dynamic> rows;
  final String fullName;
  final Future<void> Function() onDownload;

  const AccountsReceivablePreviewDialog({
    super.key,
    required this.party,
    required this.company,
    required this.postingDate,
    required this.rangeLabel,
    required this.rows,
    required this.fullName,
    required this.onDownload,
  });

  @override
  State<AccountsReceivablePreviewDialog> createState() =>
      _AccountsReceivablePreviewDialogState();
}

class _AccountsReceivablePreviewDialogState
    extends State<AccountsReceivablePreviewDialog> {
  bool _isDownloading = false;

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatCurrency(dynamic value) {
    return '₹${_toDouble(value).toStringAsFixed(2)}';
  }

  Color _ageColor(int age) {
    if (age <= 30) return Colors.green;
    if (age <= 60) return Colors.orange;
    if (age <= 90) return Colors.deepOrange;
    return Colors.red;
  }
  String _formatDate(String date) {
    if (date.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(date);
      return "${parsed.day.toString().padLeft(2, '0')}-"
          "${parsed.month.toString().padLeft(2, '0')}-"
          "${parsed.year}";
    } catch (_) {
      return date;
    }
  }
  @override
  Widget build(BuildContext context) {
    final total = widget.rows.fold<double>(
      0.0,
          (sum, row) => sum + _toDouble(
        row['outstanding_amount'] ?? row['outstanding'] ?? 0,
      ),
    );
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom:
                BorderSide(color: Colors.red.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accounts Receivable',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.party,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Summary chips row
                      Row(
                        children: [
                          _buildHeaderChip(
                            'Date: ${_formatDate(widget.postingDate)}', // 👈 wrap with _formatDate
                            Icons.calendar_today,
                          ),
                          const SizedBox(width: 6),
                          _buildHeaderChip(
                            '${widget.rows.length} invoice${widget.rows.length == 1 ? '' : 's'}',
                            Icons.receipt_long,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Invoice rows ─────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.50,
            ),
            child: widget.rows.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade400, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No outstanding invoices',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: widget.rows.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final row = widget.rows[index];
                final age = (row['age'] ?? 0).toInt();
                final voucher =
                    row['voucher_no']?.toString() ?? '—';
                final outstanding =
                _toDouble(row['outstanding_amount'] ?? row['outstanding'] ?? 0);

                final invoiceDate = _formatDate(row['posting_date']?.toString() ?? '');
                final dueDate = _formatDate(row['due_date']?.toString() ?? '');

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice number + age badge
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                  Icons.description_outlined,
                                  color: Colors.red,
                                  size: 15),
                              const SizedBox(width: 6),
                              Text(
                                voucher,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Age badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ageColor(age)
                                  .withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                color: _ageColor(age)
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '$age days',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _ageColor(age),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Dates row
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Invoiced: $invoiceDate',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.event,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Due: $dueDate',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Outstanding amount
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatCurrency(outstanding),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Total + actions ──────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Total outstanding
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total outstanding',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () async {
                          setState(
                                  () => _isDownloading = true);
                          try {
                            await widget.onDownload();
                            if (mounted) Navigator.pop(context);
                          } finally {
                            if (mounted) {
                              setState(() =>
                              _isDownloading = false);
                            }
                          }
                        },
                        icon: _isDownloading
                            ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.download, size: 16),
                        label: Text(
                            _isDownloading ? 'Generating…' : 'Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String label, IconData icon) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}