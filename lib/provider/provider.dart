import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:dio/dio.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart' hide CapabilityProfile, Generator, PaperSize;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart' hide CapabilityProfile, Generator, PaperSize;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:intl/intl.dart';
import 'package:sales_ordering_app/model/attendance_model.dart';
import 'package:sales_ordering_app/model/brand_list_response.dart';
import 'package:sales_ordering_app/model/category_list_model.dart';
import 'package:sales_ordering_app/model/checkin_checkout_model.dart';
import 'package:sales_ordering_app/model/class_group_list_model.dart';
import 'package:sales_ordering_app/model/current_stock_response.dart';
import 'package:sales_ordering_app/model/customer_details.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer_models;
import 'package:sales_ordering_app/model/employee_details.dart';
import 'package:sales_ordering_app/model/get_payement_receipt_model.dart';
import 'package:sales_ordering_app/model/get_sales_invoice_response.dart';
import 'package:sales_ordering_app/model/get_sales_order_response.dart';
import 'package:sales_ordering_app/model/home_tile_response.dart';
import 'package:sales_ordering_app/model/item_list_model.dart';
import 'package:sales_ordering_app/model/login_model.dart';
import 'package:sales_ordering_app/model/material_demand_model.dart';
import 'package:sales_ordering_app/model/material_request_model.dart';
import 'package:sales_ordering_app/model/mode_of_payement.dart';
import 'package:sales_ordering_app/model/payment_type_paid_to_response.dart';
import 'package:sales_ordering_app/model/purchase_receipt_model.dart';
import 'package:sales_ordering_app/model/recipet_model.dart';
import 'package:sales_ordering_app/model/sales_order_response.dart' hide Items;
import 'package:sales_ordering_app/model/supplier_pricing_model.dart';
import 'package:sales_ordering_app/model/user_details_model.dart';
import 'package:sales_ordering_app/service/apiservices.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/new_Transcation/sales_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/create_quotation_response.dart';
import '../model/get_quotation_response.dart';
import '../model/payment_entry.dart';
import '../model/pos_invoice_model.dart';

// import 'dart:typed_data';

import '../utils/invoice_formatter.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer;
import 'package:image_picker/image_picker.dart';

import '../view/sales_manager/performance/performanceReportBuilder.dart';


enum PerformanceReportState { idle, loading, success, error }

class SalesOrderProvider extends ChangeNotifier {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String _domain = '';
  ApiService? _apiService;

  ApiService? get apiService => _apiService;

  Future<void> initialize() async {
    final pref = await _sharedPrefService.getLoginDetails();
    _domain = pref['domain'] ?? '';
    _apiService = ApiService(baseUrl: 'https://$_domain.frappe.cloud/api');
    // _apiService = ApiService(baseUrl: 'http://$_domain/api');
    await loadOpenedPickLists();
    await loadSeenPicklists();
    notifyListeners();
  }

  String get domain => _domain;

  void setDomain(String domain) {
    _domain = domain;
    _apiService = ApiService(baseUrl: 'https://$_domain.frappe.cloud/api');
    // _apiService = ApiService(baseUrl: 'http://$_domain/api');
    notifyListeners();
  }

  Future<List<String>> fetchCompanies() {
    return _apiService!.fetchCompanyList();
  }

  Future<void> changeCompanyLocally(String company) async {
    await _sharedPrefService.saveCompany(company);

    notifyListeners();
  }

  //https://demov15.turqosoft.com/api

  // Login

  LoginModel? _loginModel;
  bool _isLoading = false;
  String? _errorMessage;

  LoginModel? get loginModel => _loginModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> login(String username, String password, String domain) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loginModel = await _apiService!.login(username, password, domain);
      if (_loginModel != null) {
        // Fetch and save company right after login
        final company = await _apiService!.fetchAndSaveDefaultCompany();
        debugPrint("Fetched company: $company");
    }} catch (e) {
      _loginModel = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(String username, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loginModel = await _apiService!.logoutService(username, context);
    } catch (e) {
      _loginModel = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

//profile

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  Future<void> loadLoggedInUserProfile(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = await _apiService!.getLoggedInUserIdentifier();

      if (email == null) {
        throw Exception("Unable to determine logged-in user");
      }

      _userProfile = await _apiService!.fetchUserDetails(email);
    } catch (e) {
      _errorMessage = e.toString();
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  //profile
//Customer Details

  CustomerDetails? _customerModel;

  CustomerDetails? get customerModel => _customerModel;

  Future<CustomerDetails?> customerDetails(String email, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerModel = await _apiService!.customerDetails(email, context);
      return _customerModel;
    } catch (e) {
      _customerModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Customer list

  Future<dynamic> createNewCustomer(Map<String, dynamic> data, BuildContext context) async {
    try {
      return await _apiService!.createCustomer(data, context);
    } catch (e) {
      debugPrint("Provider create error: $e");
      return "Failed to create customer";
    }
  }

  Future<dynamic> createAddressForCustomer(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      return await _apiService!.createAddress(data, context);
    } catch (e) {
      debugPrint("Provider address error: $e");
      return "Failed to create address";
    }
  }
  Future<bool> customerAlreadyExists(String name, BuildContext context) async {
    if (_apiService == null) return false;

    return await _apiService!.checkCustomerExists(name, context);
  }
  Future<String> getSalesPersonWithCache() async {
    return await _apiService!.getSalesPersonWithCache();
  }

  CustomerList? _customerListModel;
  bool _isLoadingMore = false;
  // bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  CustomerList? get customerListModel => _customerListModel;
  bool get isLoadingMore => _isLoadingMore;
  // bool get hasMoreData => _hasMoreData;
  int _customerCount = 0;
  int get customerCount => _customerCount;
  String? _activeSearch;
  String? get activeSearch => _activeSearch;


// Initial load

  Future<CustomerList?> customerList(
      BuildContext context, {
        bool? filterOverride, // 👈 NEW optional param
      }) async {
    _isLoading = true;
    _activeSearch = null;
    _currentPage = 0;
    _hasMoreData = true;
    _showOnlyUnpaid = false;    // 👈 reset unpaid when doing a fresh fetch
    _unpaidCustomerList = [];
    notifyListeners();
    try {
      // 👇 Use override if provided, otherwise fall back to SharedPrefs
      final filterBySalesPerson = filterOverride ??
          await _sharedPrefService.getCustomerFilterBySalesPerson();

      // // Read toggle from settings
      // final filterBySalesPerson =
      // await _sharedPrefService.getCustomerFilterBySalesPerson();

      String? salesPerson;

      // Only fetch Sales Person if toggle is ON
      if (filterBySalesPerson) {
        salesPerson = await _apiService!.getSalesPersonWithCache();
      }

      // Get logged user BEFORE API call (needed for liked filter)
      final loggedUser = await _apiService!.getLoggedInUserIdentifier();

      // Fetch count + customers in parallel
      final results = await Future.wait([
        _apiService!.fetchCustomerCount(
          context: context,
          salesPerson: salesPerson,
          filterBySalesPerson: filterBySalesPerson,
        ),
        _apiService!.customerList(
          context,
          salesPerson,
          filterBySalesPerson: filterBySalesPerson,
          pageLength: _pageSize,
          start: 0,
          onlyLiked: _showOnlyLiked,
          loggedUser: loggedUser,
        ),
      ]);

      _customerCount = results[0] as int;
      _customerListModel = results[1] as CustomerList?;

      // Fetch customer details in parallel
      if (_customerListModel?.data != null &&
          _customerListModel!.data!.isNotEmpty) {
        await Future.wait(
          _customerListModel!.data!.map(
                (customer) =>
                _apiService!.fetchCustomerDetailss(customer, context),
          ),
          eagerError: false,
        );
      }

      // Set favorite status locally
      if (_customerListModel?.data != null && loggedUser != null) {
        for (var customer in _customerListModel!.data!) {
          final likedRaw = customer.likedByRaw ?? "[]";

          try {
            final List likedList = jsonDecode(likedRaw);
            customer.isLiked = likedList.contains(loggedUser);
          } catch (e) {
            customer.isLiked = false;
          }
        }
      }

      if ((_customerListModel?.data?.length ?? 0) < _pageSize) {
        _hasMoreData = false;
      }

      return _customerListModel;
    } catch (e) {
      debugPrint('Error in customerList: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> toggleCustomerFavorite(
      BuildContext context,
      customer.Data customerItem,
      ) async {
    final add = !customerItem.isLiked;

    final success = await _apiService!.toggleCustomerLike(
      context: context,
      customerName: customerItem.name!,
      add: add,
    );

    if (success) {
      customerItem.isLiked = add;
      notifyListeners();
    }
  }
// Load more customers
//   Future<void> loadMoreCustomers(BuildContext context) async {
//     if (_isLoadingMore || !_hasMoreData) return;
  Future<void> loadMoreCustomers(BuildContext context) async {
    // No pagination when showing unpaid — all already loaded
    if (_showOnlyUnpaid) return;

    if (_isLoadingMore || !_hasMoreData) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      // ✅ Read toggle from settings
      final filterBySalesPerson =
      await _sharedPrefService.getCustomerFilterBySalesPerson();

      String? salesPerson;

      // ✅ Only fetch sales person when filter is ON
      if (filterBySalesPerson) {
        salesPerson = await _apiService!.getSalesPersonWithCache();
      }

      _currentPage++;
      final start = _currentPage * _pageSize;

      CustomerList? nextBatch;

      // 🔍 SEARCH PAGINATION
      if (_activeSearch != null && _activeSearch!.isNotEmpty) {
        nextBatch = await _apiService!.customerSearchPaged(
          context: context,
          salesPerson: salesPerson,
          filterBySalesPerson: filterBySalesPerson,
          search: _activeSearch!,
          pageLength: _pageSize,
          start: start,
        );
      }
      // 📋 NORMAL PAGINATION
      else {
        nextBatch = await _apiService!.customerList(
          context,
          salesPerson,
          filterBySalesPerson: filterBySalesPerson,
          pageLength: _pageSize,
          start: start,
          onlyLiked: _showOnlyLiked,
          loggedUser: loggedUser,
        );
      }

      if (nextBatch != null &&
          nextBatch.data != null &&
          nextBatch.data!.isNotEmpty) {

        // ✅ Fetch details in parallel (faster than sequential)
        await Future.wait(
          nextBatch.data!.map(
                (customer) => _apiService!.fetchCustomerDetailss(customer, context),
          ),
          eagerError: false,
        );

        _customerListModel?.data?.addAll(nextBatch.data!);

        if (nextBatch.data!.length < _pageSize) {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }

    } catch (e) {
      debugPrint("Load More Error: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

//   bool _showOnlyUnpaid = false;
//   bool get showOnlyUnpaid => _showOnlyUnpaid;
//
//   bool _isFetchingAllForUnpaid = false;
//   bool get isFetchingAllForUnpaid => _isFetchingAllForUnpaid;
//
// // Holds full unpaid-filtered list separately
// // State variables
//   List<customer_models.Data> _unpaidCustomerList = [];
//   List<customer_models.Data> get unpaidCustomerList => _unpaidCustomerList;
//
// // Track salesPerson for loadMore to reuse
//   String? _activeSalesPerson;
//   bool _activeFilterBySalesPerson = false;
//   Future<void> setUnpaidFilter({
//     required bool enabled,
//     required BuildContext context,
//     bool? filterBySalesPerson,
//     String? salesPerson,
//   }) async {
//     _showOnlyUnpaid = enabled;
//
//     if (!enabled) {
//       // Restore normal paginated list
//       _unpaidCustomerList = [];
//       _isFetchingAllForUnpaid = false;  // 👈 always reset the flag on disable
//       notifyListeners();
//       return;
//     }
//
//     // Fetch ALL customers and filter for unpaid
//     _isFetchingAllForUnpaid = true;
//     _unpaidCustomerList = [];
//     notifyListeners();
//
//     try {
//       final filterBy = filterBySalesPerson ??
//           await _sharedPrefService.getCustomerFilterBySalesPerson();
//
//       String? sp = salesPerson;
//       if (filterBy && sp == null) {
//         sp = await _apiService!.getSalesPersonWithCache();
//       }
//
//       _activeSalesPerson = sp;
//       _activeFilterBySalesPerson = filterBy;
//
//       const int batchSize = 50; // fetch 50 at a time
//       int start = 0;
//       bool hasMore = true;
//
//       while (hasMore) {
//         final batch = await _apiService!.customerList(
//           context,
//           sp,
//           filterBySalesPerson: filterBy,
//           pageLength: batchSize,
//           start: start,
//           onlyLiked: _showOnlyLiked,
//           loggedUser: loggedUser,
//         );
//
//         if (batch?.data == null || batch!.data!.isEmpty) {
//           hasMore = false;
//           break;
//         }
//
//         // Fetch details in parallel for this batch
//         await Future.wait(
//           batch.data!.map(
//                 (c) => _apiService!.fetchCustomerDetailss(c, context),
//           ),
//           eagerError: false,
//         );
//
//         // Set liked status
//         if (loggedUser != null) {
//           for (var customer in batch.data!) {
//             final likedRaw = customer.likedByRaw ?? "[]";
//             try {
//               final List likedList = jsonDecode(likedRaw);
//               customer.isLiked = likedList.contains(loggedUser);
//             } catch (_) {
//               customer.isLiked = false;
//             }
//           }
//         }
//
//         final List<customer_models.Data> unpaidInBatch = batch.data!
//             .where((c) => (c.totalUnpaid ?? 0) > 0)
//             .toList();
//         _unpaidCustomerList.addAll(unpaidInBatch);
//
//         // Stream results into UI after each batch
//         notifyListeners();
//
//         if (batch.data!.length < batchSize) {
//           hasMore = false;
//         } else {
//           start += batchSize;
//         }
//       }
//     } catch (e) {
//       debugPrint('Error fetching all for unpaid filter: $e');
//     } finally {
//       _isFetchingAllForUnpaid = false;
//       notifyListeners();
//     }
//   }
  bool _showOnlyUnpaid = false;
  bool get showOnlyUnpaid => _showOnlyUnpaid;

  bool _isFetchingAllForUnpaid = false;
  bool get isFetchingAllForUnpaid => _isFetchingAllForUnpaid;

  List<customer_models.Data> _unpaidCustomerList = [];
  List<customer_models.Data> get unpaidCustomerList => _unpaidCustomerList;

  String? _activeSalesPerson;
  bool _activeFilterBySalesPerson = false;

  Future<void> setUnpaidFilter({
    required bool enabled,
    required BuildContext context,
    bool? filterBySalesPerson,
    String? salesPerson,
  }) async {
    _showOnlyUnpaid = enabled;

    if (!enabled) {
      _unpaidCustomerList = [];
      _allUnpaidCustomerList = []; // 👈 clear backup too
      _isFetchingAllForUnpaid = false;
      _activeSearch = null;        // 👈 clear any active search
      notifyListeners();
      return;
    }

    _isFetchingAllForUnpaid = true;
    _unpaidCustomerList = [];
    _allUnpaidCustomerList = []; // 👈 clear backup
    notifyListeners();

    try {
      final filterBy = filterBySalesPerson ??
          await _sharedPrefService.getCustomerFilterBySalesPerson();

      String? sp = salesPerson;
      if (filterBy && sp == null) {
        sp = await _apiService!.getSalesPersonWithCache();
      }

      _activeSalesPerson = sp;
      _activeFilterBySalesPerson = filterBy;

      const int batchSize = 100;
      const int parallelBatches = 3;

      // Get total count so we know how many pages to fetch
      final totalCount = await _apiService!.fetchCustomerCount(
        context: context,
        salesPerson: sp,
        filterBySalesPerson: filterBy,
      );

      if (totalCount == 0) {
        _isFetchingAllForUnpaid = false;
        notifyListeners();
        return;
      }

      final totalPages = (totalCount / batchSize).ceil();

      // Process pages in parallel windows of 3
      for (int pageWindow = 0;
      pageWindow < totalPages;
      pageWindow += parallelBatches) {

        // Stop if filter was turned off mid-fetch
        if (!_showOnlyUnpaid) break;

        final pageFutures = <Future<void>>[];

        for (int i = 0;
        i < parallelBatches && (pageWindow + i) < totalPages;
        i++) {
          final start = (pageWindow + i) * batchSize;
          pageFutures.add(_fetchAndFilterBatch(
            context: context,
            sp: sp,
            filterBy: filterBy,
            start: start,
            batchSize: batchSize,
          ));
        }

        // Run this window of pages in parallel
        await Future.wait(pageFutures, eagerError: false);

        // Paint results to UI after each window
        notifyListeners();
        await Future.delayed(Duration.zero);
      }

    } catch (e) {
      debugPrint('Error fetching all for unpaid filter: $e');
    } finally {
      _isFetchingAllForUnpaid = false;
      notifyListeners();
    }
  }
// Returns sum of all totalUnpaid in the unpaid list
  double get totalUnpaidSum => _unpaidCustomerList.fold(
    0.0,
        (sum, customer) => sum + (customer.totalUnpaid ?? 0.0),
  );
  Future<void> _fetchAndFilterBatch({
    required BuildContext context,
    required String? sp,
    required bool filterBy,
    required int start,
    required int batchSize,
  }) async {
    // Bail out if filter was turned off mid-fetch
    if (!_showOnlyUnpaid) return;

    try {
      final batch = await _apiService!.customerList(
        context,
        sp,
        filterBySalesPerson: filterBy,
        pageLength: batchSize,
        start: start,
        onlyLiked: _showOnlyLiked,
        loggedUser: loggedUser,
      );

      if (batch?.data == null || batch!.data!.isEmpty) return;

      // 👇 Fire all balance checks in parallel — one lightweight call per customer
      final balanceResults = await Future.wait(
        batch.data!.map((customer) =>
            _apiService!.fetchCustomerOutstandingBalance(
              customerName: customer.name ?? '',
              context: context,
            )),
        eagerError: false,
      );

      // 👇 Zip customers with their balance, keep only those with unpaid > 0
      final List<customer_models.Data> unpaidInBatch = [];

      for (int i = 0; i < batch.data!.length; i++) {
        final balance = balanceResults[i];
        if (balance > 0) {
          batch.data![i].totalUnpaid = balance; // store for display in card
          unpaidInBatch.add(batch.data![i]);
        }
      }
      // 👇 Fetch full details (billingThisYear etc.) only for unpaid customers
      // This is a much smaller set so it's fast
      if (unpaidInBatch.isNotEmpty) {
        await Future.wait(
          unpaidInBatch.map(
                (customer) => _apiService!.fetchCustomerDetailss(customer, context),
          ),
          eagerError: false,
        );

        // fetchCustomerDetailss overwrites totalUnpaid from dashboard_info
        // so restore the accurate balance we got from get_balance_on
        for (int i = 0; i < unpaidInBatch.length; i++) {
          final balance = balanceResults[
          batch.data!.indexOf(unpaidInBatch[i])];
          unpaidInBatch[i].totalUnpaid = balance;
        }
      }
      // Set liked status for unpaid customers only
      if (loggedUser != null) {
        for (var customer in unpaidInBatch) {
          final likedRaw = customer.likedByRaw ?? "[]";
          try {
            final List likedList = jsonDecode(likedRaw);
            customer.isLiked = likedList.contains(loggedUser);
          } catch (_) {
            customer.isLiked = false;
          }
        }
      }

      _unpaidCustomerList.addAll(unpaidInBatch);
      _allUnpaidCustomerList.addAll(unpaidInBatch); // 👈 keep backup in sync


    } catch (e) {
      debugPrint('Batch fetch error at start=$start: $e');
    }
  }
  void clearCustomerList() {
    _customerSearchModel = null;
    notifyListeners();
  }

  void clearItemList() {
    _itemListModel = null;
    notifyListeners();
  }


  // filter by customer group

  String? _activeCustomerGroup;
  String? get activeCustomerGroup => _activeCustomerGroup;
  Future<CustomerList?> applyCustomerGroupFilter(
      String customerGroup,
      BuildContext context,
      ) async {
    _isLoading = true;
    _activeCustomerGroup = customerGroup;
    _activeSearch = null; // group overrides search
    _currentPage = 0;
    _hasMoreData = true;
    notifyListeners();

    try {
      loggedUser = await _apiService!.getLoggedInUserIdentifier();
      final firstName = await _apiService!.fetchUserFirstName(loggedUser!);
      final employeeId = await _apiService!.fetchEmployeeByFirstName(firstName!);
      final salesPerson =
      await _apiService!.fetchSalesPersonByEmployee(employeeId!);

      if (salesPerson == null) {
        throw Exception("Could not get sales person");
      }

      _customerListModel = await _apiService!.customerGroupPaged(
        context: context,
        salesPerson: salesPerson,
        customerGroup: customerGroup,
        pageLength: _pageSize,
        start: 0,
        onlyLiked: _showOnlyLiked,
        loggedUser: loggedUser,
      );

      // ⭐ APPLY FAVORITE STATUS
      if (_customerListModel?.data != null && loggedUser != null) {
        for (var customer in _customerListModel!.data!) {
          final likedRaw = customer.likedByRaw ?? "[]";

          try {
            final List likedList = jsonDecode(likedRaw);
            customer.isLiked = likedList.contains(loggedUser);
          } catch (e) {
            customer.isLiked = false;
          }
        }
      }

      // fetch customer details
      for (final customer in _customerListModel?.data ?? []) {
        await _apiService!.fetchCustomerDetailss(customer, context);
      }

      if ((_customerListModel?.data?.length ?? 0) < _pageSize) {
        _hasMoreData = false;
      }

      return _customerListModel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  bool _showOnlyLiked = false;
  bool get showOnlyLiked => _showOnlyLiked;
  void toggleLikedFilter(bool value) {
    _showOnlyLiked = value;
    notifyListeners();
  }
  void resetLikedFilter() {
    _showOnlyLiked = false;
    notifyListeners();
  }
  // Holds the full unfiltered unpaid list for search restore
  List<customer_models.Data> _allUnpaidCustomerList = [];

  void searchWithinUnpaid(String query) {
    if (query.isEmpty) {
      // Restore full unpaid list
      _unpaidCustomerList = List.from(_allUnpaidCustomerList);
      _activeSearch = null;
      notifyListeners();
      return;
    }

    _activeSearch = query;
    final lowerQuery = query.toLowerCase();

    _unpaidCustomerList = _allUnpaidCustomerList.where((customer) {
      final name = (customer.customerName ?? '').toLowerCase();
      final id = (customer.name ?? '').toLowerCase();
      return name.contains(lowerQuery) || id.contains(lowerQuery);
    }).toList();

    notifyListeners();
  }
// search by customer name
  Future<CustomerList?> customerNameSearch(
      String customerName,
      BuildContext context,
      ) async {
    _isLoading = true;
    _activeSearch = customerName;
    _currentPage = 0;
    _hasMoreData = true;
    notifyListeners();

    try {
      final filterBySalesPerson =
      await _sharedPrefService.getCustomerFilterBySalesPerson();

      String? salesPerson;

      if (filterBySalesPerson) {
        salesPerson = await _apiService!.getSalesPersonWithCache();
      }

      // fetch count
      _customerCount = await _apiService!.fetchCustomerCount(
        context: context,
        salesPerson: salesPerson,
        filterBySalesPerson: filterBySalesPerson,
        search: customerName,
      );

      // fetch search list
      _customerListModel =
      await _apiService!.customerSearch(customerName, context);

      // ⭐ GET LOGGED USER
      final loggedUser = await _apiService!.getLoggedInUserIdentifier();

      // ⭐ DETERMINE LIKE STATUS
      if (_customerListModel?.data != null && loggedUser != null) {
        for (var customer in _customerListModel!.data!) {
          final likedRaw = customer.likedByRaw ?? "[]";

          try {
            final List likedList = jsonDecode(likedRaw);
            customer.isLiked = likedList.contains(loggedUser);
          } catch (e) {
            customer.isLiked = false;
          }
        }
      }

      // fetch details
      await Future.wait(
        _customerListModel?.data?.map(
              (customer) =>
              _apiService!.fetchCustomerDetailss(customer, context),
        ) ??
            [],
      );

      if ((_customerListModel?.data?.length ?? 0) < _pageSize) {
        _hasMoreData = false;
      }

      return _customerListModel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //Customer list

  CustomerGroupList? _customerGroupListModel;

  CustomerGroupList? get customerGroupListModel => _customerGroupListModel;

  Future<CustomerGroupList?> customerGroupList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerGroupListModel = await _apiService!.customerGroupList(context);
      return _customerGroupListModel;

    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPaymentCollection(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      return await _apiService!.createPaymentCollection(data, context);
    } catch (e) {
      debugPrint("Provider payment collection error: $e");
      return false;
    }
  }


// Material request
  bool _hasError = false;
  bool get hasError => _hasError;

  List<dynamic>? _materialRequests = [];
  bool _isMaterialRequestsLoading = false;



  List<dynamic>? get materialRequests => _materialRequests ??= [];
  bool get isMaterialRequestsLoading => _isMaterialRequestsLoading;


int _totalMaterialRequests = 0;
int get totalMaterialRequests => _totalMaterialRequests;


Future<void> fetchMaterialRequests(
    BuildContext context, {String? fromDate, String? toDate}) async {
  if (_isMaterialRequestsLoading) return;

  _isMaterialRequestsLoading = true;
  notifyListeners();

  try {
    _hasError = false;
    _errorMessage = null;

    final email = await _sharedPrefService.getEmailId();
    if (email != null) {
      Map<String, dynamic>? response = await _apiService!.fetchMaterialRequests(
        context,
        email,
        _limitStart,
        _limitPageLength,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response != null) {
        List<dynamic>? newRequests = response['data'];
        int totalCount = response['total_count'];

        if (_limitStart == 0) {
          _materialRequests = [];
        }
        if (newRequests != null) {
          _materialRequests!.addAll(newRequests);
          _limitStart += _limitPageLength;
        }

        _totalMaterialRequests = totalCount; // Update total count
      }
    } else {
      throw Exception('No logged-in user email found');
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
    _materialRequests = null;
    _totalMaterialRequests = 0; // Reset total count on error
  } finally {
    _isMaterialRequestsLoading = false;
    notifyListeners();
  }
}

Future<void> refreshMaterialRequestsWithDateRange(
    BuildContext context, String fromDate, String toDate) async {
  _limitStart = 0; // Reset pagination, but don't clear data immediately
  await fetchMaterialRequests(context, fromDate: fromDate, toDate: toDate);
}

Future<void> refreshMaterialRequests(BuildContext context) async {
  _limitStart = 0;
  await fetchMaterialRequests(context);
}


// Material request


// Material request detail
  Future<Map<String, dynamic>?> getMaterialRequestDetails(
      BuildContext context, String requestName) async {
    try {
      return await _apiService!.fetchMaterialRequestDetails(
          context, requestName);
    } catch (e) {
      debugPrint('Error fetching material request details: $e');
      return null;
    }
  }
// Material request detail


//mtq put
Future<bool> updateMaterialRequest(
    BuildContext context, String requestName, Map<String, dynamic> updatedData) async {
  try {
    return await _apiService!.updateMaterialRequest(context, requestName, updatedData);
  } catch (e) {
    debugPrint('Error updating material request: $e');
    return false;
  }
}

//mtq put
//mtq form

  Future<void> createMaterialRequest(BuildContext context, MaterialRequest request) async {
    try {
      await _apiService!.createMaterialRequest(context, request);
      await fetchMaterialRequests(context); // Refresh the list after creating a new request
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

//mtq search

Future<List<Map<String, String>>> fetchItems(String query) async {
  if (_apiService == null) {
    throw Exception('API service not initialized');
  }
  return await _apiService!.fetchItems(query);
}


//mtq search

//mtq wh search
Future<List<String>> fetchWarehouseCodes(String query) async {
  if (_apiService == null) {
    throw Exception('API service not initialized');
  }
  return await _apiService!.fetchWarehouseCodes(query);
}
//mtq wh search
Future<String?> getEmployeeName(BuildContext context, String employeeId) async {
  return await _apiService!.fetchEmployeeName(context, employeeId);
}


//job card list

List<dynamic>? _jobCards = [];
bool _isJobCardsLoading = false;
bool _hasMoreJobCards = true; // Flag to indicate if there is more data to load

List<dynamic>? get jobCards => _jobCards;
bool get isJobCardsLoading => _isJobCardsLoading;
bool get hasMoreJobCards => _hasMoreJobCards;

Future<void> fetchJobCards(BuildContext context) async {
  if (_isJobCardsLoading || !_hasMoreJobCards) return;

  _isJobCardsLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    List<dynamic>? newJobCards = await _apiService!.fetchJobCards(
      context,
      _limitStart,
      _limitPageLength,
    );

    if (newJobCards != null && newJobCards.isNotEmpty) {
      _jobCards!.addAll(newJobCards);
      _limitStart += _limitPageLength;
    } else {
      _hasMoreJobCards = false; // No more data to load
    }
  } catch (e) {
    _hasError = true; // Only set error for network or API issues
    _errorMessage = e.toString();
  } finally {
    _isJobCardsLoading = false;
    notifyListeners();
  }
}

Future<void> refreshJobCards(BuildContext context) async {
  _jobCards = [];
  _limitStart = 0;
  _hasMoreJobCards = true; // Reset pagination control
  await fetchJobCards(context);
}

//job card list

//job card detail

Future<Map<String, dynamic>?> getJobCardDetails(
    BuildContext context, String jobCardName) async {
  try {
    return await _apiService!.fetchJobCardDetails(context, jobCardName);
  } catch (e) {
    debugPrint('Error fetching job card details: $e');
    return null;
  }
}

//job card detail
//jm
Future<bool> submitMaterialTransfer(
    BuildContext context, Map<String, dynamic> materialTransferData) async {
  _isJobCardsLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    final success = await _apiService!.submitMaterialTransfer(
      context,
      materialTransferData,
    );

    if (success) {
      debugPrint('Material Transfer successfully submitted.');
      return true;
    } else {
      debugPrint('Material Transfer submission failed.');
      return false;
    }
  } catch (e) {
    _hasError = true; // Indicate an error occurred
    _errorMessage = e.toString();
    debugPrint('Error in provider submitMaterialTransfer: $e');
    return false;
  } finally {
    _isJobCardsLoading = false;
    notifyListeners();
  }
}
 
//jm


//search employee
List<dynamic>? _employees = [];
bool _isEmployeesLoading = false;

List<dynamic>? get employees => _employees;
bool get isEmployeesLoading => _isEmployeesLoading;

Future<void> searchEmployees(BuildContext context, String query) async {
  _isEmployeesLoading = true;
  notifyListeners();

  try {
    _employees = await _apiService!.fetchEmployees(context, query);
  } catch (e) {
    debugPrint('Error fetching employees: $e');
    _employees = [];
  } finally {
    _isEmployeesLoading = false;
    notifyListeners();
  }
}


//up employee
Future<void> updateJobCardEmployees(BuildContext context, String jobCardName, List<dynamic> employees) async {
  try {
    final payload = {
      "data": {"employee": employees.map((e) => {"employee": e['employee']}).toList()}
    };
    await _apiService!.updateJobCard(context, jobCardName, payload);
    notifyListeners();
  } catch (e) {
    debugPrint('Error updating job card employees: $e');
  }
}

//up employee

//work order list

  List<dynamic>? _workOrders = [];
  bool _isWorkOrdersLoading = false;


  bool _hasMoreData = true; // Flag to indicate if there is more data to load

  List<dynamic>? get workOrders => _workOrders;
  bool get isWorkOrdersLoading => _isWorkOrdersLoading;

  bool get hasMoreData => _hasMoreData;

  Future<void> fetchWorkOrders(BuildContext context) async {
    if (_isWorkOrdersLoading || !_hasMoreData) return;

    _isWorkOrdersLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      List<dynamic>? newOrders = await _apiService!.fetchWorkOrders(
        context,
        _limitStart,
        _limitPageLength,
      );

      if (newOrders != null && newOrders.isNotEmpty) {
        _workOrders!.addAll(newOrders);
        _limitStart += _limitPageLength;
      } else {
        _hasMoreData = false; // No more data to load
      }
    } catch (e) {
      _hasError = true; // Only set error for network or API issues
      _errorMessage = e.toString();
    } finally {
      _isWorkOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWorkOrders(BuildContext context) async {
    _workOrders = [];
    _limitStart = 0;
    _hasMoreData = true; // Reset pagination control
    await fetchWorkOrders(context);
  }

//work order list

//wk count

int _workOrderCount = 0;
bool _isWorkOrderCountLoading = false;

int get workOrderCount => _workOrderCount;
bool get isWorkOrderCountLoading => _isWorkOrderCountLoading;


Future<void> fetchWorkOrderCount(BuildContext context, {String? searchQuery}) async {
  _isWorkOrderCountLoading = true;
  notifyListeners();

  try {
    _workOrderCount = await _apiService!.fetchWorkOrderCount(context, searchQuery: searchQuery);
  } catch (e) {
    _workOrderCount = 0;
  } finally {
    _isWorkOrderCountLoading = false;
    notifyListeners();
  }
}


//wk count

//work order search

Future<void> searchWorkOrders(
    BuildContext context, String? searchQuery) async {
  _isWorkOrdersLoading = true;
  notifyListeners();

  try {
    final results = await _apiService!.searchWorkOrders(
      context,
      searchQuery,
    );

    _workOrders = results ?? [];
  } catch (e) {
    _workOrders = [];
    debugPrint('Search error: $e');
  } finally {
    _isWorkOrdersLoading = false;
    notifyListeners();
  }
}



//work order search

//material demand
Future<List<dynamic>?> fetchMaterialDemands(
  BuildContext context,
  DateTime? fromDate,
  DateTime? toDate, {
  int offset = 0,
  int limit = 60,
}) async {
  try {
    final actualUser = await _apiService!.getLoggedInUserIdentifier();

    if (actualUser != null) {
      final materialDemands = await _apiService!.fetchMaterialDemands(
        context,
        actualUser,
        fromDate,
        toDate,
        offset: offset,
        limit: limit,
      ) ?? [];
      return materialDemands;
    } else {
      throw Exception('Failed to resolve logged-in user');
    }
  } catch (e) {
    debugPrint('Error fetching material demands: $e');
    throw e;
  }
}

Future<int> fetchMaterialDemandCount(
  BuildContext context,
  DateTime? fromDate,
  DateTime? toDate,
) async {
  try {
    final count = await _apiService!.fetchMaterialDemandCount(
      context,
      fromDate,
      toDate,
    );
    return count;
  } catch (e) {
    debugPrint('Error fetching material demand count: $e');
    throw e;
  }
}


Future<Map<String, dynamic>?> getMaterialDemandDetails(BuildContext context, String demandName) async {
    try {
      final response = await _apiService!.fetchMaterialDemandDetails(context, demandName);
      if (response != null) {
        return response;
      } else {
        // handle case when response is null
        debugPrint('Material demand details are null');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching material demand details: $e');
      return null;
    }
  }

//material d create



// Future<void> createMaterialDemand(BuildContext context, MaterialDemand demand) async {
//   try {
//     await _apiService!.createMaterialDemand(context, demand);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Material Demand Created Successfully')),
//     );
//   } catch (e) {
//     _errorMessage = e.toString();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to Create Material Demand: $_errorMessage')),
//     );
//     notifyListeners();
//   }
// }
  Future<void> createMaterialDemand(BuildContext context, MaterialDemand demand) async {
    try {
      bool success = await _apiService!.createMaterialDemand(context, demand);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Material Demand Created Successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to Create Material Demand')),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Create Material Demand: $_errorMessage')),
      );
      notifyListeners();
    }
  }


  //mdfi



 
 Future<List<dynamic>?> fetchItemsDemand(BuildContext context, String? query) async {
  return await _apiService!.fetchItemsDemand(context, query);
}

//mdfi
//md put

  Future<bool> updateMaterialDemand(BuildContext context, String demandName, Map<String, dynamic> updatedData) async {
    try {
      return await _apiService!.updateMaterialDemand(context, demandName, updatedData);
    } catch (e) {
      debugPrint('Error updating material demand: $e');
      return false;
    }
  }
  Future<String?> getLoggedInUserIdentifier() async {
    try {
      return await _apiService!.getLoggedInUserIdentifier();
    } catch (e) {
      debugPrint('Error getting user identifier: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchAdditionalFields(String userId) async {
    try {
      return await _apiService!.fetchAdditionalFields(userId);
    } catch (e) {
      debugPrint('Error fetching additional fields: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> fetchCustomerDetail(String customerName) async {
    try {
      return await _apiService!.fetchCustomerDetail(customerName);
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
      rethrow;
    }
  }

//md put
//material demand

//SalesReturn

  final List<dynamic> _deliveryNotes = []; // List to hold delivery notes

  List<dynamic> get deliveryNotes => _deliveryNotes; // Getter for delivery notes

Future<int> fetchDeliveryNotesCount(
  BuildContext context, {
  String? fromDate,
  String? toDate,
}) async {
  try {
    final count = await _apiService!.fetchDeliveryNotesCount(
      context,
      fromDate: fromDate,
      toDate: toDate,
    );
    return count;
  } catch (e) {
    debugPrint('Error fetching delivery notes count: $e');
    throw e;
  }
}


Future<void> fetchDeliveryNotes(
  BuildContext context, {
  int offset = 0,
  int limit = 60,
  String? fromDate,
  String? toDate,
}) async {
  _isLoading = true;
  notifyListeners();

  try {
    final fetchedNotes = await _apiService!.fetchDeliveryNotes(
      context,
      offset: offset,
      limit: limit,
      fromDate: fromDate,
      toDate: toDate,
    );

    _deliveryNotes.clear();
    _deliveryNotes.addAll(fetchedNotes ?? []);

    // Sort the delivery notes by 'name' in descending order
    _deliveryNotes.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
  } catch (e) {
    debugPrint('Error fetching delivery notes: $e');
    throw e;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


//SD item_details

final List<dynamic> _deliveryNoteItems = []; // List to hold delivery note items
bool _isItemLoading = false;

List<dynamic> get deliveryNoteItems => _deliveryNoteItems;
bool get isItemLoading => _isItemLoading;


Future<Map<String, dynamic>> fetchDeliveryNoteItems(BuildContext context, String deliveryNoteName) async {
  try {
    final details = await _apiService!.fetchDeliveryNoteItems(context, deliveryNoteName);
    return details ?? {};
  } catch (e) {
    debugPrint('Error fetching delivery note items: $e');
    return {};
  }
}



Future<bool> returnItems(
  BuildContext context,
  String companyAddress,
  String customer,
  String returnAgainst,
  String SellingPriceListVariable,
  List<Map<String, dynamic>> items,
) async {
  final Map<String, dynamic> requestData = {
    "company_address": companyAddress,
    "customer": customer,
    "is_return": 1,
    "return_against": returnAgainst,
    "docstatus": 0,
"selling_price_list": SellingPriceListVariable,
    "items": items, // Sending all items together in one request
  };

  try {
    // Send request
    await _apiService?.returnItems(context, requestData);

    // If no exception, return true (success)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} items returned successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    return true;
  } catch (e) {
    // If API request fails, return false
    debugPrint('Return quantity exceeds available quantity');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Return quantity exceeds available quantity'),
        backgroundColor: Colors.red,
      ),
    );

    return false;
  }
}


//SalesReturn


//SupplierPricing


List<dynamic> deduplicateAndSortItems(List<dynamic> items) {
  final Map<String, dynamic> latestItems = {};
  for (var item in items) {
    final key = '${item['item_name']}-${item['item_code']}';
    final validFrom = DateTime.tryParse(item['valid_from'] ?? '');

    if (validFrom != null) {
      if (!latestItems.containsKey(key) ||
          DateTime.parse(latestItems[key]['valid_from']).isBefore(validFrom)) {
        latestItems[key] = item;
      }
    }
  }

  // Convert to list and sort by latest `valid_from`
  List<dynamic> sortedItems = latestItems.values.toList();
  sortedItems.sort((a, b) {
    final dateA = DateTime.tryParse(a['valid_from'] ?? '') ?? DateTime(1970);
    final dateB = DateTime.tryParse(b['valid_from'] ?? '') ?? DateTime(1970);
    return dateB.compareTo(dateA); // Sort descending (latest first)
  });

  return sortedItems;
}


List<dynamic>? _itemPrices = [];
List<dynamic>? _filteredItemPrices = [];
List<dynamic>? get itemPrices => _filteredItemPrices; // Use filtered list for UI


int _itemPriceCount = 0;
int get itemPriceCount => _itemPriceCount;


bool _noDataAvailable = false;
bool get noDataAvailable => _noDataAvailable;

Future<void> fetchItemPrices(BuildContext context) async {
  if (_isLoading || !_hasMoreData) return;

  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    final userEmail = await _sharedPrefService.getEmailId();
    if (userEmail != null) {
      List<dynamic>? newPrices = await _apiService!.fetchItemPrices(
          context, _limitStart, 100, userEmail);

      if (newPrices != null && newPrices.isNotEmpty) {
        _itemPrices!.addAll(newPrices);
        _itemPrices = deduplicateAndSortItems(_itemPrices!);
        _filteredItemPrices = List.from(_itemPrices!);
        _itemPriceCount = _filteredItemPrices!.length;

        _limitStart += _limitPageLength;
      } else {
        _hasMoreData = false;
        _noDataAvailable = _itemPrices!.isEmpty; // If no data at all, show message
      }
    } else {
      throw Exception('No logged-in user email found');
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


/// Search functionality: Filters and sorts the list based on the query
void searchItems(String query) {
  if (query.isEmpty) {
    _filteredItemPrices = List.from(_itemPrices!); // Reset to full list
  } else {
    _filteredItemPrices = _itemPrices!.where((item) {
      final itemName = item['item_name']?.toLowerCase() ?? '';
      final itemCode = item['item_code']?.toLowerCase() ?? '';
      return itemName.contains(query.toLowerCase()) ||
          itemCode.contains(query.toLowerCase());
    }).toList();

    // Sort matching items by `item_name` for better readability
    _filteredItemPrices!.sort((a, b) {
      final itemNameA = a['item_name']?.toLowerCase() ?? '';
      final itemNameB = b['item_name']?.toLowerCase() ?? '';
      return itemNameA.compareTo(itemNameB);
    });
  }

  // Update count immediately when filtering
  _itemPriceCount = _filteredItemPrices!.length;
  notifyListeners();
}

Future<void> refreshItemPrices(BuildContext context) async {
  if (_isLoading) return;

  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    final userEmail = await _sharedPrefService.getEmailId();
    if (userEmail != null) {
      // Reset pagination
      _limitStart = 0;
      _hasMoreData = true;

      // Fetch new data
      final newPrices = await _apiService!.fetchItemPrices(
        context, _limitStart, 100, userEmail,
      );

      if (newPrices != null && newPrices.isNotEmpty) {
        // Replace with new data
        _itemPrices = deduplicateAndSortItems(newPrices);
        _filteredItemPrices = List.from(_itemPrices!);

        // Reset pagination
        _itemPriceCount = _filteredItemPrices!.length;
        _limitStart += _limitPageLength;
      } else {
        _hasMoreData = false;
      }
    } else {
      throw Exception('No logged-in user email found');
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
    debugPrint('Error during refresh: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


Future<bool> addItemPrice(BuildContext context, ItemPrice newItemPrice) async {
  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    final success = await _apiService!.addItemPrice(context, newItemPrice);

    if (success) {
      _itemPrices!.add(newItemPrice.toJson());
      _filteredItemPrices = List.from(_itemPrices!);
      _itemPriceCount = _filteredItemPrices!.length;
      notifyListeners();
      return true;
    } else {
      throw Exception('Failed to add the new item price');
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add Item Price: $e')),
    );
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


List<Map<String, dynamic>> _itemSuggestions = [];
List<Map<String, dynamic>> get itemSuggestions => _itemSuggestions;


Future<void> fetchItemSuggestions(BuildContext context, String query) async {
  _isLoading = true;
  notifyListeners();

  try {
    final suggestions = await _apiService!.fetchItemSuggestions(context, query);

    _itemSuggestions = suggestions.map((item) {
      return {
        "item_name": item["item_name"],
        "item_code": item["item_code"],
        "uom": item["uom"] ?? "N/A",
        "item_name_local": item["item_name_local"] ?? "", // Ensure description is never null
      };
    }).toList();

  } catch (e) {
    debugPrint('Error fetching item suggestions: $e');
    _itemSuggestions = [];
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


void clearSuggestions() {
  _itemSuggestions = [];
  notifyListeners();
}

SharedPrefService get sharedPrefService => _sharedPrefService;



Future<void> addItemPriceWithPrefill(BuildContext context, ItemPrice newItemPrice) async {
  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    // Fetch price_list dynamically based on logged-in user
    final priceList = await _apiService!.fetchPriceList();
    
    if (priceList == null || priceList.isEmpty) {
      throw Exception('No price list found for the logged-in user');
    }

    // Update newItemPrice with the fetched price_list
    newItemPrice.priceList = priceList;

    // Add the item price
    final success = await _apiService!.addItemPrice(context, newItemPrice);

    if (success) {
      _itemPrices!.add(newItemPrice.toJson());
      _filteredItemPrices = List.from(_itemPrices!);
      _itemPriceCount = _filteredItemPrices!.length;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item Price added successfully')),
      );
    } else {
      throw Exception('Failed to add the new item price');
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
    notifyListeners();

    // Show an error dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to add Item Price: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}




//SupplierPricing

//Stock Updates
  List<Map<String, dynamic>> _selectedItems = [];

  List<Map<String, dynamic>> get selectedItems => _selectedItems;

  int get selectedItemCount => _selectedItems.length;

  void addSelectedItem(Map<String, dynamic> item) {
    _selectedItems.add(item);
    notifyListeners();
  }

  void removeSelectedItem(Map<String, dynamic> item) {
    _selectedItems.remove(item);
    notifyListeners();
  }

  void clearSelectedItems() {
    _selectedItems.clear();
    notifyListeners();
  }
  void removeZeroQtyItems() {
    _selectedItems.removeWhere((item) => item['entered_qty'] == 0.0);
    notifyListeners();
  }

List<dynamic>? _stockReconciliations = [];
List<dynamic>? get stockReconciliations => _stockReconciliations;


Future<void> fetchStockReconciliations(BuildContext context) async {
  if (_isLoading || !_hasMoreData) return;

  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  notifyListeners();

  try {
    List<dynamic>? newReconciliations = await _apiService!.fetchStockReconciliations(
      context,
      _limitStart,
      _limitPageLength,
    );

    if (newReconciliations != null && newReconciliations.isNotEmpty) {
      debugPrint("✅ Fetched ${newReconciliations.length} new items");

      _stockReconciliations ??= [];
for (var item in newReconciliations) {
  debugPrint("👉 Adding item: ${item['name']}");

  if (!_stockReconciliations!.any((existing) => existing['name'] == item['name'])) {
    _stockReconciliations!.add(item);
  }
}
      _limitStart += _limitPageLength;
    } else {
      _hasMoreData = false;
    }
  } catch (e) {
    debugPrint("📦 Fetching stock reconciliations with limitStart: $_limitStart");

    _hasError = true;
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Map<String, dynamic>? _stockReconciliationDetails;
  bool _isLoadingDetails = false;
  bool _hasErrorDetails = false;
  String? _errorMessageDetails;

  Map<String, dynamic>? get stockReconciliationDetails => _stockReconciliationDetails;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get hasErrorDetails => _hasErrorDetails;
  String? get errorMessageDetails => _errorMessageDetails;


Future<void> fetchStockReconciliationDetails(BuildContext context, String reconciliationName) async {
    _isLoadingDetails = true;
    _hasErrorDetails = false;
    _errorMessageDetails = null;
    notifyListeners();

    try {
      // Fetch details of a specific stock reconciliation
      Map<String, dynamic>? details =
          await _apiService!.fetchStockReconciliationDetails(context, reconciliationName);

      if (details != null) {
        _stockReconciliationDetails = details;
      } else {
        _hasErrorDetails = true;
        _errorMessageDetails = "Stock Reconciliation not found";
      }
    } catch (e) {
      _hasErrorDetails = true;
      _errorMessageDetails = e.toString();
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }


Future<void> refreshStockReconciliations(BuildContext context) async {
  _isLoading = true;
  _hasError = false;
  _errorMessage = null;
  _limitStart = 0;
  _hasMoreData = true;
  _stockReconciliations = [];
  notifyListeners();

  try {
    List<dynamic>? newReconciliations = await _apiService!.fetchStockReconciliations(
      context,
      _limitStart,
      _limitPageLength,
    );

    if (newReconciliations != null && newReconciliations.isNotEmpty) {
      _stockReconciliations!.addAll(newReconciliations);
      _limitStart += _limitPageLength;
    } else {
      _hasMoreData = false;
    }
  } catch (e) {
    _hasError = true;
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  void resetPagination() {
    _stockLedgerEntries.clear();
    _limitStart = 0;
    _hasMoreData = true;
  }
  List<dynamic> _stockLedgerEntries = [];

  List<dynamic> get stockLedgerEntries => _stockLedgerEntries;
  // Pagination variables
  int _limitStart = 0; // Starting index for the requests
  final int _limitPageLength = 0; // Number of requests to load per page

  late Map<String, double> _actualQuantities = {};

  Map<String, double> get actualQtyMap => _actualQuantities;

  Future<void> fetchBinStock(BuildContext context, {bool isPagination = false, bool clearData = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      if (clearData) {
        _stockLedgerEntries.clear();
        _limitStart = 0;
        _hasMoreData = true;
      }

      final warehouse = await _apiService!.fetchUserWarehouse(context);
      if (warehouse == null) throw Exception("Warehouse not found for user POS");

      final entries = await _apiService!.fetchBinStockEntries(
        context,
        warehouse,
        offset: _limitStart,
        limit: _limitPageLength,
      );

      if (entries != null && entries.isNotEmpty) {
        final itemCodeNameMap = await _apiService!.fetchItemCodeNameMap(context);

        final actualQtyMap = <String, double>{};

        for (var entry in entries) {
          final code = entry['item_code'];
          entry['item_name'] = itemCodeNameMap[code] ?? 'Unknown';

          if (entry['actual_qty'] != null) {
            actualQtyMap[code] = (entry['actual_qty'] as num).toDouble();
          }
        }

        _actualQuantities = actualQtyMap;

        final existingCodes = _stockLedgerEntries.map((e) => e['item_code']).toSet();
        final newUniqueEntries = entries.where((e) => !existingCodes.contains(e['item_code'])).toList();

        if (newUniqueEntries.isNotEmpty) {
          _stockLedgerEntries.addAll(newUniqueEntries);
          _limitStart += _limitPageLength;
        } else {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> createMaterialTransfer(
      BuildContext context,
      List<Map<String, dynamic>> selectedItems,
      ) async {
    try {
      await _apiService!.createMaterialTransfer(context, selectedItems);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material Transfer Created Successfully')),
      );
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Create Material Transfer: $_errorMessage')),
      );
      notifyListeners();
    }
  }

  Future<void> deleteStockReconciliationByName(
    BuildContext context,
    String docName,
  ) async {
    try {
      await _apiService!.deleteStockReconciliation(context, docName); // from apiservices.dart
      stockReconciliations!.removeWhere((item) => item['name'] == docName);
      notifyListeners();
    } catch (e) {
      debugPrint('Provider Delete Error: $e');
      rethrow;
    }
  }

  Future<bool> updateStockEntryByName(
      BuildContext context,
      String entryName,
      List<Map<String, dynamic>> updatedItems,
      ) async {
    try {
      await apiService!.updateStockEntry(
        context: context,
        entryName: entryName,
        updatedItems: updatedItems,
      );
      await refreshStockReconciliations(context); // Optional: refresh listing
      return true; // Return true on success
    } catch (e) {
      debugPrint('Provider update error: $e');
      rethrow;
    }
  }

Future<Map<String, dynamic>> fetchStockReconciliationByName(String name) async {
  return await apiService!.fetchReconciliationByName(name);
}

//Stock Updates


// Purchase request

  List<dynamic> _purchaseRequests = [];
  int _totalCount = 0;


  List<dynamic> get purchaseRequests => _purchaseRequests;
  int get totalCount => _totalCount;

String? _currentFromDate;
String? _currentToDate;


Future<void> fetchPurchaseRequests({String? fromDate, String? toDate}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    // Store the current filter values
    _currentFromDate = fromDate;
    _currentToDate = toDate;

    final List<dynamic> purchaseRequests;
    
    if (fromDate == null && toDate == null) {
      purchaseRequests = await _apiService!.fetchPurchaseRequests(); // Fetch all data
    } else {
      final now = DateTime.now();
      final defaultFromDate = fromDate ?? now.subtract(Duration(days: 30)).toIso8601String().split("T")[0];
      final defaultToDate = toDate ?? now.toIso8601String().split("T")[0];

      purchaseRequests = await _apiService!.fetchPurchaseRequests(fromDate: defaultFromDate, toDate: defaultToDate);
    }

    // Sort by "creation" date in descending order (latest first)
    purchaseRequests.sort((a, b) => b['creation'].compareTo(a['creation']));

    _purchaseRequests = purchaseRequests;
    _totalCount = _purchaseRequests.length;
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}



Future<void> updateSupplierConfirmation(String purchaseRequestName, String status) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    await _apiService!.updateSupplierConfirmation(purchaseRequestName, status);

    // Refresh purchase requests with stored filters
    await fetchPurchaseRequests(fromDate: _currentFromDate, toDate: _currentToDate);
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


Map<String, dynamic>? _selectedPurchaseRequest;
bool _isDetailLoading = false;

Map<String, dynamic>? get selectedPurchaseRequest => _selectedPurchaseRequest;
bool get isDetailLoading => _isDetailLoading;

Future<void> fetchPurchaseRequestDetails(String purchaseRequestName) async {
  _isDetailLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _selectedPurchaseRequest = await _apiService!.fetchPurchaseRequestDetails(purchaseRequestName);
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isDetailLoading = false;
    notifyListeners();
  }
}


// purchase request

//pick list
  Set<String> _seenPicklists = {};
  Future<void> loadSeenPicklists() async {
    final pref = await SharedPreferences.getInstance();
    _seenPicklists = pref.getStringList("seen_picklists")?.toSet() ?? {};
  }
  Future<void> saveSeenPicklists() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setStringList("seen_picklists", _seenPicklists.toList());
  }

  Set<String> _openedPickLists = {};
  Set<String> get openedPickLists => _openedPickLists;

  Future<void> loadOpenedPickLists() async {
    final pref = await SharedPreferences.getInstance();
    _openedPickLists = pref.getStringList("opened_picklists")?.toSet() ?? {};
  }

  Future<void> markPickListOpened(String name) async {
    _openedPickLists.add(name);
    final pref = await SharedPreferences.getInstance();
    await pref.setStringList("opened_picklists", _openedPickLists.toList());
    notifyListeners();
  }


  List<dynamic> _pickList = [];
  String? _lastTopPickList;   // <--- Track the latest picklist

  List<dynamic> get pickList => _pickList;

  Future<int> fetchPickList(BuildContext context) async {
    try {
      print("⏳ Fetching picklists...");

      bool restrict = await _apiService!.getRestrictPickListForWarehouseUser(context);
      print("🔐 Restriction enabled: $restrict");

      String? userId = await _apiService!.getLoggedInUserIdentifier();
      String? userWarehouse;

      if (restrict && userId != null) {
        userWarehouse = await _apiService!.fetchWarehouseForUser(userId);
        print("👤 User: $userId → Warehouse: $userWarehouse");
      }

      if (restrict && userWarehouse == null) {
        print("⚠ No warehouse assigned → returning empty picklist");
        _pickList = [];
        notifyListeners();
        return 0;
      }

      List<dynamic>? fetched = await _apiService!.fetchAllPickLists(
        context,
        warehouse: restrict ? userWarehouse : null,
      );

      List<dynamic> newList = fetched ?? [];
      print("📦 API returned total: ${newList.length}");

      // 🔥🔥 REMOVE DUPLICATES BY NAME 🔥🔥
      Map<String, dynamic> uniqueMap = {};
      for (var item in newList) {
        uniqueMap[item["name"]] = item; // replaces duplicates automatically
      }

      List<dynamic> uniqueList = uniqueMap.values.toList();

      print("🧹 Unique picklists: ${uniqueList.length}");

      // Count new unseen picklists
      _seenPicklists ??= {};

      int newCount = 0;
      for (var item in uniqueList) {
        if (!_seenPicklists.contains(item["name"])) {
          newCount++;
        }
      }

      print("🔔 New picklists since last visit: $newCount");

      // Update seen list
      _seenPicklists = uniqueList.map<String>((e) => e["name"] as String).toSet();
      await saveSeenPicklists();

      // Update Provider list
      _pickList = uniqueList;
      for (var item in _pickList) {
        Map<String, dynamic>? details =
        await _apiService!.fetchPickListDetails(context, item["name"]);

        if (details != null && details["locations"] != null) {
          item["locations"] = details["locations"];
        }
      }
      notifyListeners();

      return newCount;

    } catch (e) {
      print("❌ Provider error: $e");
      return 0;
    }
  }




  Map<String, dynamic>? _pickListDetails;
  bool _isDetailsLoading = false;
  bool _hasDetailsError = false;
  String? _detailsErrorMessage;

  Map<String, dynamic>? get pickListDetails => _pickListDetails;
  bool get isDetailsLoading => _isDetailsLoading;
  bool get hasDetailsError => _hasDetailsError;
  String? get detailsErrorMessage => _detailsErrorMessage;

  Future<void> fetchPickListDetails(BuildContext context, String pickListName) async {
    _isDetailsLoading = true;
    _hasDetailsError = false;
    _detailsErrorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic>? details = await _apiService!.fetchPickListDetails(context, pickListName);
      if (details != null) {
        _pickListDetails = details;
      } else {
        _hasDetailsError = true;
        _detailsErrorMessage = "Failed to load details";
      }
    } catch (e) {
      _hasDetailsError = true;
      _detailsErrorMessage = e.toString();
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }
  String computePickListStatus(Map<String, dynamic> pickList) {
    List locations = pickList["locations"] ?? [];

    double totalQty = 0;
    double totalPicked = 0;

    for (var item in locations) {
      totalQty += (item["qty"] ?? 0).toDouble();
      totalPicked += (item["picked_qty"] ?? 0).toDouble();
    }

    if (totalPicked == 0) return "Not Started";
    if (totalPicked < totalQty) return "In Progress";
    if (totalPicked == totalQty) return "Completed";

    return "Unknown";
  }
  Color picklistStatusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      case "Not Started":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  Future<Map<String, dynamic>> updatePickedQtyList(
      BuildContext context,
      String pickListName,
      List<Map<String, dynamic>> updatedItems,
      ) async {
    final autoSubmit = await SharedPrefService().getAutoSubmitPickList();

    if (pickListDetails == null) {
      return {"success": false, "message": "PickList details unavailable"};
    }

    List<dynamic> locations = pickListDetails!["locations"] ?? [];
    List<Map<String, dynamic>> updatedLocations = locations.map((location) {
      final Map<String, dynamic> loc = Map<String, dynamic>.from(location);

      final updatedItem = updatedItems.firstWhere(
            (item) => item["name"] == loc["name"],
        orElse: () => {},
      );

      if (updatedItem.isNotEmpty) {
        loc["picked_qty"] = updatedItem["picked_qty"];
        loc["qty"] = updatedItem["qty"];
        loc["mrp"] = updatedItem["mrp"];
        // loc["scan_mode"] = 1;
      }

      return loc;
    }).toList();

// 🔥 DELETE items where picked_qty == 0
    updatedLocations = updatedLocations
        .where((loc) => (loc["picked_qty"] ?? 0) > 0)
        .toList();


    final result = await _apiService!.updatePickedQty(
      context,
      pickListName,
      updatedLocations,
      autoSubmit,     // ← pass toggle
    );

    if (result["success"] == true) {
      pickListDetails!["locations"] = updatedLocations;
      notifyListeners();
    }

    return result;
  }


//pick list
//pick item

  bool isLoadingPickList = false;
  List<Map<String, dynamic>> pickLists = [];

// Warehouse search
  List<String> warehouseResultss = [];
  bool isSearchingWarehouse = false;
  String? selectedWarehouse;
  String? defaultWarehouse; // ✅ Add this

  Future<void> fetchPickLists({String? warehouse}) async {
    try {
      isLoadingPickList = true;
      notifyListeners();

      pickLists = await apiService!.fetchPickList(warehouse: warehouse);
    } catch (e) {
      debugPrint("fetchPickList Provider Error: $e");
    } finally {
      isLoadingPickList = false;
      notifyListeners();
    }
  }


  void setSelectedWarehouse(String? warehouse) {
    selectedWarehouse = warehouse;
    notifyListeners();
    fetchPickLists(warehouse: warehouse);
  }

  void clearWarehouseFilter() {
    selectedWarehouse = null;
    notifyListeners();
    fetchPickLists();
  }
  bool isLoadingPickDetail = false;
  Map<String, dynamic>? pickDetail;
  bool isLoadingSerialNumbers = false;
  List<String> availableSerialNumbers = [];
  Future<void> fetchPickDetail(String pickName) async {
    try {
      isLoadingPickDetail = true;
      notifyListeners();

      pickDetail = await apiService!.fetchPickDetail(pickName);
    } catch (e) {
      debugPrint("fetchPickDetail Provider Error: $e");
    } finally {
      isLoadingPickDetail = false;
      notifyListeners();
    }
  }
  bool isSavingPick = false;

  Future<bool> updatePick({
    required String pickName,
    required String warehouse,
    required Map<int, int> statuses,
    required Map<int, Map<String, int>> boxAllocations,
    required Map<int, List<String>> serials,
  }) async {
    if (pickDetail == null) return false;

    isSavingPick = true;
    notifyListeners();

    try {
      final List existingItems = pickDetail!["items"];
      final List<Map<String, dynamic>> payloadItems = [];

      for (int i = 0; i < existingItems.length; i++) {
        final item = existingItems[i];

        final serialList = serials[i] ?? [];

        final serialNo = serialList.join("\n"); // empty string if no serials

        final pickedQty =
            double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

        /// 🔹 Build tq_pl_box string
        String tqPlBox = "";

        if (boxAllocations[i] != null &&
            boxAllocations[i]!.isNotEmpty) {

          tqPlBox = boxAllocations[i]!.entries
              .map((entry) => "${entry.key}:${entry.value}")
              .join("\n");
        }

        payloadItems.add({
          "name": item["name"],
          "item_name": item["item_name"],
          "item_code": item["item_code"],
          "qty": item["qty"],
          "picked_qty": pickedQty,            // ✅ SEND PICKED QTY
          "tq_pl_box": tqPlBox,               // ✅ SEND BOX DATA
          "has_serial_no": item["has_serial_no"],
          "status": statuses[i] ?? item["status"],
          "serial_no": serialNo,
          "warehouse": item["warehouse"],
        });

      }

      return await apiService!.updatePick(
        pickName: pickName,
        warehouse: warehouse,
        items: payloadItems,
      );
    } catch (e, stack) {
      debugPrint("updatePick Provider Error: $e");
      debugPrint("$stack");
      return false;
    } finally {
      isSavingPick = false;
      notifyListeners();
    }
  }
  bool isSubmittingPick = false;

  Future<bool> submitPick({required String pickName}) async {
    isSubmittingPick = true;
    notifyListeners();

    try {
      return await apiService!.submitPick(pickName: pickName);
    } catch (e, stack) {
      debugPrint("submitPick Provider Error: $e");
      debugPrint("$stack");
      return false;
    } finally {
      isSubmittingPick = false;
      notifyListeners();
    }
  }
  Future<void> searchWarehouses(String query) async {
    if (query.isEmpty) {
      warehouseResultss = [];
      notifyListeners();
      return;
    }

    isSearchingWarehouse = true;
    notifyListeners();

    warehouseResultss = await apiService!.searchWarehouses(query);

    isSearchingWarehouse = false;
    notifyListeners();
  }

  void clearWarehouseResultss() {
    warehouseResultss.clear();
    notifyListeners();
  }
  Future<void> loadDefaultWarehouse() async {
    final sharedPrefService = SharedPrefService();
    defaultWarehouse = await sharedPrefService.getDefaultWarehouse();

    // If no warehouse is selected yet, use the default
    if (selectedWarehouse == null && defaultWarehouse != null) {
      selectedWarehouse = defaultWarehouse;
    }

    notifyListeners();
  }

  Future<void> setDefaultWarehouse(String? warehouse) async {
    final sharedPrefService = SharedPrefService();

    if (warehouse != null && warehouse.isNotEmpty) {
      await sharedPrefService.saveDefaultWarehouse(warehouse);
      defaultWarehouse = warehouse;
    } else {
      await sharedPrefService.clearDefaultWarehouse();
      defaultWarehouse = null;
    }

    notifyListeners();
  }
  Future<List<String>> fetchSerialNumbers({
    required String itemCode,
    required String warehouse,
  }) async {
    try {
      isLoadingSerialNumbers = true;
      notifyListeners();

      availableSerialNumbers = await apiService!.fetchAvailableSerialNumbers(
        itemCode: itemCode,
        warehouse: warehouse,
      );

      return availableSerialNumbers;
    } catch (e) {
      debugPrint("fetchSerialNumbers Provider Error: $e");
      return [];
    } finally {
      isLoadingSerialNumbers = false;
      notifyListeners();
    }
  }

  void clearSerialNumbers() {
    availableSerialNumbers = [];
    notifyListeners();
  }
  bool isSerialValid(String serial) {
    return availableSerialNumbers.contains(serial);
  }

  //pick item
//purchase receipt
  List<dynamic> _purchaseReceipts = [];

  List<dynamic> get purchaseReceipts => _purchaseReceipts;

Future<void> fetchPurchaseReceipts(BuildContext context) async {
  if (_apiService == null) {
    debugPrint("API Service is not initialized!");
    return;
  }

  _isLoading = true;
  notifyListeners();

  try {
    debugPrint("Fetching purchase receipts...");
    final receipts = await _apiService!.fetchPurchaseOrders(context);

    if (receipts != null) {
      debugPrint("Fetched ${receipts.length} purchase receipts");

      // Sort by 'name' in descending order
      receipts.sort((a, b) => b['name'].compareTo(a['name']));

      _purchaseReceipts = receipts;
    } else {
      debugPrint("No purchase receipts found");
    }
  } catch (e) {
    debugPrint("Error fetching purchase receipts: $e");
  }

  _isLoading = false;
  notifyListeners();
}

// Future<dynamic> createPurchaseReceipt(BuildContext context, PurchaseReceipt receipt) async {
//   _isLoading = true;
//   notifyListeners();
//
//   try {
//     final result = await _apiService!.createPurchaseReceipt(context, receipt.toJson());
//
//     if (result == true) {
//       await fetchPurchaseReceipts(context); // ✅ Refresh list on success
//     }
//
//     return result; // ✅ Could be true or a String error
//   } catch (e) {
//     debugPrint("❌ Provider Error: $e");
//     return "An unexpected error occurred while creating the receipt.";
//   } finally {
//     _isLoading = false;
//     notifyListeners();
//   }
// }
// SUBMIT Purchase Receipt (docstatus = 1)
  Future<dynamic> submitPurchaseReceipt(
      BuildContext context,
      PurchaseReceipt receipt,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService!.createPurchaseReceipt(
        context,
        receipt.toJson(),
        submit: true, // 🔥 submit
      );

      if (result == true) {
        // refresh list
        await fetchPurchaseReceipts(context);
      }

      return result; // true or String error message

    } catch (e) {
      debugPrint("❌ Provider Error: $e");
      return "An unexpected error occurred while submitting receipt.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


// SAVE Purchase Receipt as Draft (docstatus = 0)
  Future<dynamic> savePurchaseReceipt(
      BuildContext context,
      PurchaseReceipt receipt,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService!.createPurchaseReceipt(
        context,
        receipt.toJson(),
        submit: false, // 🔥 draft
      );

      // ⚠️ We do NOT refresh list because drafts are not shown normally
      // but you can do it if you want

      return result; // true or String error message

    } catch (e) {
      debugPrint("❌ Provider Error: $e");
      return "An unexpected error occurred while saving receipt.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


Future<Map<String, dynamic>?> fetchPurchaseOrderDetails(String purchaseOrderName) async {
  try {
    // ✅ Debug before making API call
    debugPrint('🚀 Calling API to fetch Purchase Order: $purchaseOrderName');

    // ✅ Fetch Purchase Order details from API
    final response = await _apiService!.fetchPurchaseOrderDetails(purchaseOrderName);

    // ✅ Debug API response
    if (response != null) {
      debugPrint('✅ API response received successfully');
      debugPrint('🎯 Raw Data: $response');

      // ✅ Extract Purchase Order name
      final orderName = response['name'] ?? '';
      debugPrint('📄 Purchase Order Name: $orderName');

      // ✅ Add purchase_order and purchase_order_item to each item
      if (response['items'] != null && response['items'] is List) {

        for (var item in response['items']) {

          final itemCode = item['item_code'];

          item['purchase_order'] = orderName;
          item['purchase_order_item'] = item['name'] ?? '';

          // 🔥 Fetch additional item details
          final itemDetails = await _apiService!.fetchItemDetails(itemCode);

          // 🔍 Store has_batch_no flag
          item['has_batch_no'] = itemDetails?['has_batch_no'] ?? 0;

          debugPrint("🧪 Item: $itemCode has_batch_no: ${item['has_batch_no']}");
        }

      }

      // ✅ Return modified data correctly
      return response; // Return entire purchase order data
    } else {
      debugPrint('❌ Error: API response is null or empty');
      return null;
    }
  } catch (e) {
    // ✅ Handle errors with detailed debug output
    debugPrint('❗ Error fetching purchase order details: $e');
    return null;
  }
}

Future<List<String>> fetchWarehouse(String query) async {
  if (_apiService == null) {
    throw Exception('API service not initialized');
  }
  return await _apiService!.fetchWarehouse(query);
}

// save changes for purchase receipt

Future<void> savePurchaseReceiptData(String purchaseOrderName, PurchaseReceipt receipt) async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ Convert PurchaseReceipt to JSON
  String receiptJson = jsonEncode(receipt.toJson());

  // ✅ Store data using purchaseOrderName as the key
  await prefs.setString('purchase_receipt_$purchaseOrderName', receiptJson);
  debugPrint("✅ Purchase Receipt data saved for $purchaseOrderName");
}

Future<PurchaseReceipt?> loadSavedPurchaseReceipt(String purchaseOrderName) async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ Check if data exists for the given purchaseOrderName
  String? receiptJson = prefs.getString('purchase_receipt_$purchaseOrderName');

  if (receiptJson != null) {
    // ✅ Convert JSON back to PurchaseReceipt
    Map<String, dynamic> receiptData = jsonDecode(receiptJson);
    return PurchaseReceipt.fromJson(receiptData);
  }

  return null; // No saved data found
}

Future<void> clearSavedPurchaseReceipt(String purchaseOrderName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('purchase_receipt_$purchaseOrderName');
  debugPrint("🧹 Saved Purchase Receipt data cleared for $purchaseOrderName");
}

 Future<bool?> checkBatchExists(String batchId) async {
    debugPrint("🚀 Checking batch: $batchId");

    final exists = await _apiService?.batchExists(batchId);

    debugPrint("📦 Batch $batchId exists: $exists");

    return exists;
  }

// purchase receipt

//sales invoice


GetSalesInvoiceResponse? _salesInvoiceList;

GetSalesInvoiceResponse? get salesInvoiceList => _salesInvoiceList;

  bool _isFilterApplied = false;
  bool get isFilterApplied => _isFilterApplied;
 // Fetch all Sales Invoices
  Future<GetSalesInvoiceResponse?> getSalesInvoice(
    context,
    int limitStart,
    int pageLength,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _salesInvoiceList = await _apiService!.getSalesInvoice(
        context,
        limitStart,
        pageLength,
      );
      _isFilterApplied = false;
      return _salesInvoiceList;
    } catch (e) {
      _salesInvoiceList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Map<String, dynamic>? _invoiceDetails;
  Map<String, dynamic>? get invoiceDetails => _invoiceDetails;

  Future<Map<String, dynamic>?> fetchSalesInvoiceDetails(
      BuildContext context,
      String invoiceName,
      ) async {
    try {
      _invoiceDetails = await _apiService!.getSalesInvoiceDetails(context, invoiceName);
      notifyListeners();
      return _invoiceDetails;
    } catch (e) {
      _invoiceDetails = null;
      notifyListeners();
      return null;
    }
  }

  // Fetch filtered Sales Invoices by date
  Future<GetSalesInvoiceResponse?> getSalesInvoiceDateFilter(
    context,
    String startDate,
    String endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _salesInvoiceList = await _apiService!
          .getSalesInvoiceDateFilter(context, startDate, endDate);
      _isFilterApplied = true;
      return _salesInvoiceList;
    } catch (e) {
      _salesInvoiceList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GetSalesInvoiceResponse?> getSearchSalesInvoice(
      context,
      String? invoiceId,
      String? customerId,
      String? startDate,
      String? endDate,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    _isFilterApplied = true;
    notifyListeners();

    try {
      _salesInvoiceList = await _apiService!.getSearchSalesInvoice(
        context,
        invoiceId,
        customerId,
        startDate,
        endDate,
      );
      return _salesInvoiceList;
    } catch (e) {
      _salesInvoiceList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get sellingPriceList {
    if (invoiceCustomerDetails == null) return null;

    return invoiceCustomerDetails!["selling_price_list"] ??
        invoiceCustomerDetails!["price_list"];
  }


  String? _branch;

  String? get branch => _branch;
Future<void> fetchBranchForUser(BuildContext context) async {
  try {
    final branch = await _apiService!.getUserBranch(context);
    if (branch != null) {
      _branch = branch;
      notifyListeners();
    }
  } catch (e) {
    debugPrint("Error fetching branch: $e");
  }
}

  Map<String, dynamic>? invoiceCustomerDetails;
  List<Map<String, dynamic>> item = [];

  String? eerrorMessage;
  bool iisLoading = false;
  // Future<void> fetchCustomer(BuildContext context, String customerName) async {
  //
  //   iisLoading = true;
  //   notifyListeners();
  //   try {
  //     invoiceCustomerDetails = await _apiService!.fetchInvoiceCustomerDetails(context, customerName);
  //     debugPrint("✅ Customer Details Fetched: $invoiceCustomerDetails");
  //   } catch (e) {
  //     eerrorMessage = "Failed to fetch customer details: $e";
  //     debugPrint("❌ Error fetching customer: $e");
  //   }
  //   iisLoading = false;
  //   notifyListeners();
  // }
  Future<Map<String, dynamic>?> fetchCustomer(
      BuildContext context,
      String customerName,
      ) async {
    iisLoading = true;
    notifyListeners();

    try {
      invoiceCustomerDetails =
      await _apiService!.fetchInvoiceCustomerDetails(context, customerName);

      debugPrint("✅ Customer Details Fetched: $invoiceCustomerDetails");
      return invoiceCustomerDetails;
    } catch (e) {
      eerrorMessage = "Failed to fetch customer details: $e";
      debugPrint("❌ Error fetching customer: $e");
      return null;
    } finally {
      iisLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>?> fetchItem({
  required BuildContext context,
  required String itemCode,
  required String itemName,
  required double quantity,
  required String currency,
  required String customer,
  required String priceList,
}) async {
  try {
    final itemDetails = await _apiService!.fetchInvoiceItemDetail(
      context: context,
      itemCode: itemCode,
      itemName: itemName,
      quantity: quantity,
      currency: currency,
      customer: customer,
      priceList: priceList,
    );
    debugPrint("✅ Item Details Fetched: $itemDetails");
    return itemDetails;
  } catch (e) {
    eerrorMessage = "Failed to fetch item details: $e";
    debugPrint("❌ Error fetching item: $e");
    return null;
  }
}

Future<bool> submitInvoice(
  BuildContext context,
  String customerName,
  DateTime dueDateObj,
    DateTime postingDateObj, // new

    ) async {
  iisLoading = true;
  eerrorMessage = null;
  notifyListeners();

  try {
    final String formattedDueDate = DateFormat('yyyy-MM-dd').format(dueDateObj);
    final String formattedPostingDate = DateFormat('yyyy-MM-dd').format(postingDateObj);


    // ✅ Fetch and store customer details
    await fetchCustomer(context, customerName);
    final customerDetails = invoiceCustomerDetails ?? {};

    // ✅ Ensure selling_price_list is present
    if (!customerDetails.containsKey("selling_price_list")) {
      throw Exception("Selling Price List not found in customer details.");
    }

    // ✅ Prepare detailed items
    List<Map<String, dynamic>> detailedItems = [];

    for (var item in _itemsList) {
      final itemDetailsResponse = await fetchItem(
        context: context,
        itemCode: item.itemCode,
        itemName: item.name,
        quantity: item.quantity.toDouble(),
        currency: "INR",
        customer: customerName,
        priceList: customerDetails["selling_price_list"],
      );

      Map<String, dynamic> itemMap;

      if (itemDetailsResponse != null) {
        itemMap = Map<String, dynamic>.from(itemDetailsResponse);

        // Override with user-entered values
        itemMap['item_code'] = item.itemCode;
        itemMap['item_name'] = item.name;
        itemMap['qty'] = item.quantity;
        itemMap['rate'] = item.rate;
        itemMap['price_list_rate'] = item.priceListRate;
        itemMap['discount_percentage'] = item.discountPercentage;
        itemMap['amount'] = item.rate * item.quantity;
      } else {
        itemMap = {
          "item_code": item.itemCode,
          "item_name": item.name,
          "qty": item.quantity,
          "rate": item.rate,
          "priceListRate": item.priceListRate,
          "discount_percentage": item.discountPercentage,
          "amount": item.rate * item.quantity,
        };
      }

      detailedItems.add(itemMap);
    }
    // final List<Map<String, dynamic>> detailedItems =
    // _itemsList.map((item) {
    //   final discount = item.discountPercentage ?? 0.0;
    //
    //   return {
    //     "item_code": item.itemCode,
    //     "qty": item.quantity.toDouble(),
    //
    //     // 🔥 REQUIRED for discount
    //     "price_list_rate": item.priceListRate ?? item.rate,
    //
    //     // 🔥 ONLY if > 0
    //     if (discount > 0)
    //       "discount_percentage": discount,
    //   };
    // }).toList();

    // ✅ Submit invoice
    await _apiService!.createSalesInvoice(
      context: context,
      customerName: customerName,
      dueDate: formattedDueDate,
      postingDate: formattedPostingDate, // new

      item: List<Map<String, dynamic>>.from(detailedItems),
      customerDetails: customerDetails,
    );

    // ✅ Clear local state after success
    invoiceCustomerDetails = null;
    _itemsList.clear();

    debugPrint("✅ Sales Invoice Submitted");
    return true; // ✅ Mark as success
  } catch (e) {
    eerrorMessage = "Failed to submit invoice: $e";
    debugPrint("❌ Error submitting invoice: $e");

    if (e is DioException) {
      debugPrint("❌ Server response: ${e.response?.data}");
    }

    return false; // ❌ Mark as failure
  } finally {
    iisLoading = false;
    notifyListeners();
  }
}
  Future<List<String>> fetchInvoicePrintFormats() async {
    return await _apiService!.fetchInvoicePrintFormats();
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  }

  Future<void> downloadInvoicePdf({
    required String invoiceName,
    required String printFormat,
  }) async {
    final pdfBytes = await _apiService!.downloadInvoicePdf(
      invoiceName: invoiceName,
      printFormat: printFormat,
    );

    final dir = await getApplicationDocumentsDirectory();

    final safeInvoiceName = _sanitizeFileName(invoiceName);
    final safePrintFormat = _sanitizeFileName(printFormat);

    final filePath =
        '${dir.path}/$safeInvoiceName-$safePrintFormat.pdf';

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);

    await OpenFilex.open(filePath);
  }


  void clearSearchState() {
    _isFilterApplied = false;
    _salesInvoiceList = null;
    notifyListeners();
  }


void clearSearchResults() {
  _itemListModel = null;
  _customerSearchModel = null;
  notifyListeners();
}
  Future<void> getSalesInvoiceByName(
      BuildContext context,
      String invoiceName,
      ) async {
    try {
      final result = await _apiService!.getSalesInvoiceByName(
        context: context,
        invoiceName: invoiceName,
      );
      // Store in the same model your existing list uses
      // so the UI renders without any changes
      _salesInvoiceList = result;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching invoice by name: $e');
    }
  }


//sales invoice

//POS Invoice

  // Expose profile data + discount permission
  Map<String, dynamic>? _posProfile;
  List<String> _modesOfPayment = [];

  Map<String, dynamic>? get posProfile => _posProfile;
  List<String> get modesOfPayment => _modesOfPayment;

// 👇 convenience getter for allow_discount_change
  bool get allowDiscountChange =>
      _posProfile?["allow_discount_change"] == 1;

  /// Fetch POS Profile for current logged in user
  Future<void> fetchPosProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Now API returns the whole profile map (not just name)
      _posProfile = await _apiService?.fetchPosProfile();

      if (_posProfile != null) {
        debugPrint("✅ POS Profile: $_posProfile");

        // Fetch modes of payment using profile name
        final profileName = _posProfile!["name"];
        await fetchModesOfPayment(profileName);
      } else {
        _errorMessage = "No POS Profile found for current user";
      }
    } catch (e) {
      _errorMessage = "Failed to fetch POS Profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

//for opening entry
  /// Fetch modes of payment for given POS Profile
  Future<void> fetchModesOfPayment(String posProfileName) async {
    try {
      _modesOfPayment = await _apiService?.fetchModesOfPayment(posProfileName) ?? [];
      debugPrint("✅ Modes of Payment: $_modesOfPayment");
    } catch (e) {
      _errorMessage = "Failed to fetch modes of payment: $e";
      debugPrint("❌ Error fetching modes of payment: $e");
    }
    notifyListeners();
  }
//for create pos invoice
  List<PaymentEntry> _paymentEntries = [];
  List<PaymentEntry> get paymentEntries => _paymentEntries;

  Future<void> fetchModesOfPayments(String posProfileName, {double invoiceAmount = 0.0}) async {
    try {
      final modes = await _apiService?.fetchModesOfPayment(posProfileName) ?? [];
      // Default: assign full amount to first mode, 0 to others
      _paymentEntries = modes.asMap().entries.map((entry) {
        return PaymentEntry(
          modeOfPayment: entry.value,
          amount: entry.key == 0 ? invoiceAmount : 0.0,
        );
      }).toList();

      debugPrint("✅ Payment Entries: $_paymentEntries");
    } catch (e) {
      _errorMessage = "Failed to fetch modes of payment: $e";
    }
    notifyListeners();
  }


  /// Create POS Opening Entry
  Future<bool> createPosOpeningEntry({
    required List<Map<String, dynamic>> balances,
    required String periodStartDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final company = await _sharedPrefService.getCompany() ?? '';
      if (company.isEmpty || _posProfile == null) {
        throw Exception("Company or POS Profile missing");
      }

      final success = await _apiService!.createPosOpeningEntryForAll(
        company: company,
        posProfile: _posProfile!["name"],
        balances: balances,
        periodStartDate: periodStartDate,
      );

      if (success) {
        debugPrint("✅ POS Opening Entry created");
      } else {
        _errorMessage = "Failed to create POS Opening Entry";
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create POS Invoice
  Future<String?> submitInvoices(
      BuildContext context, PosInvoice invoice, double grandTotal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1️⃣ Ensure POS Profile
      if (_posProfile == null) {
        debugPrint("⚠️ POS Profile not loaded yet. Fetching now...");
        _posProfile = await _apiService?.fetchPosProfile();
        if (_posProfile == null) {
          throw Exception("POS Profile required to create invoice");
        }
      }

      // 2️⃣ Fetch customer details
      final customerDetails = await _apiService?.fetchCustomersDetails(
        invoice.customer,
        _posProfile!["name"],
      );

      if (customerDetails == null || customerDetails["message"] == null) {
        throw Exception("Customer details not found");
      }
      final custMsg = customerDetails["message"];
      debugPrint("✅ Customer details fetched: $custMsg");

      if (!custMsg.containsKey("selling_price_list")) {
        throw Exception("Selling Price List not found in customer details");
      }

      // 3️⃣ Prepare enriched items
      final List<Map<String, dynamic>> detailedItems = [];
      for (final item in invoice.items) {
        final itemDetails = await _apiService?.fetchItemsDetails(
          itemCode: item.itemCode,
          posProfile: _posProfile!["name"],
          customer: invoice.customer,
        );

        Map<String, dynamic> itemMap;
        if (itemDetails != null) {
          itemMap = Map<String, dynamic>.from(itemDetails);

          // override with user-entered values
          itemMap["item_code"] = item.itemCode;
          itemMap["qty"] = item.qty;
          itemMap["rate"] = item.rate;
          itemMap["price_list_rate"] = item.priceListRate;
          itemMap["uom"] = item.uom;
          itemMap["warehouse"] = item.warehouse;
          itemMap["amount"] = (item.rate ?? 0) * (item.qty ?? 1);
        } else {
          itemMap = item.toJson();
        }

        detailedItems.add(itemMap);
      }

      // 4️⃣ Build payments array → ignore invoice.payments and use grandTotal
      final roundedTotal = grandTotal.roundToDouble();
      final payments = invoice.payments.isNotEmpty
          ? [
        {
          "mode_of_payment": invoice.payments.first.modeOfPayment,
          "amount": roundedTotal,
        }
      ]
          : [
        {
          "mode_of_payment": "Cash", // fallback
          "amount": roundedTotal,
        }
      ];

      // 5️⃣ Fetch taxes
      final templateName =
          custMsg["taxes_and_charges"] ?? "Output GST In-state - KSHPDC";
      final taxesData = await _apiService?.fetchTaxes(templateName);

      // 6️⃣ Build enriched invoice JSON
      final enrichedInvoice = {
        ...invoice.toJson(),
        "customer_details": custMsg,
        "items": detailedItems,
        "taxes_and_charges": templateName,
        "taxes": taxesData?["taxes"] ?? [],
        "payments": payments,
      };

      // return success;
      final invoiceName = await _apiService!.createPosInvoice(enrichedInvoice);
      if (invoiceName != null) {
        debugPrint("✅ POS Invoice submitted successfully: $invoiceName");
        return invoiceName;
      } else {
        debugPrint("❌ Failed to submit POS Invoice");
        return null;
      }
    } catch (e, stack) {
      _errorMessage = "Failed to submit invoice: $e";
      debugPrint("❌ Error submitting invoice: $e");
      debugPrint("📌 StackTrace: $stack");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }


  Future<Map<String, dynamic>?> fetchInvoiceDetails(String invoiceName) async {
    try {
      return await _apiService?.fetchPosInvoice(invoiceName);
    } catch (e) {
      debugPrint("❌ Error fetching invoice details: $e");
      return null;
    }
  }

  Future<bool> confirmAndSubmitInvoice(String invoiceName) async {
    try {
      final payments = paymentEntries
          .map((p) => {
        "mode_of_payment": p.modeOfPayment,
        "amount": p.amount,
      })
          .toList();

      // Step 1: Save as Draft (docstatus = 0) with payments
      final draftInvoice = {
        "docstatus": 0,
        "payments": payments,
      };
      debugPrint("🔹 Saving invoice as draft with payload: $draftInvoice");

      final draftSuccess =
      await _apiService!.updatePosInvoice(invoiceName, draftInvoice);

      if (!draftSuccess) {
        debugPrint("❌ Failed to save invoice as draft");
        return false;
      }
      debugPrint("✅ Invoice saved as draft");

      // Step 2: Submit invoice (docstatus = 1) WITHOUT re-sending payments
      final submitInvoice = {
        "docstatus": 1,
      };
      debugPrint("🔹 Submitting invoice with payload: $submitInvoice");

      final submitSuccess =
      await _apiService!.updatePosInvoice(invoiceName, submitInvoice);

      if (submitSuccess) {
        debugPrint("✅ Invoice submitted successfully");
      } else {
        debugPrint("❌ Failed to submit invoice");
      }

      return submitSuccess;
    } catch (e, stack) {
      debugPrint("❌ Error in confirmAndSubmitInvoice: $e");
      debugPrint("📌 Stack: $stack");
      return false;
    }
  }



  Future<bool> updateInvoiceItems(
      String invoiceName,
      List<Items> items, {
        double? additionalDiscountPercentage, // 👈 add param
      }) async {
    try {
      final detailedItems = items.map((item) {
        return {
          "doctype": "POS Invoice Item",   // 🔑 required
          "parentfield": "items",          // 🔑 required
          "item_code": item.itemCode,
          "qty": item.qty,
          "rate": item.rate,
          "price_list_rate": item.priceListRate,
          "uom": item.uom,
          "warehouse": item.warehouse,
          // "amount": (item.rate) * (item.qty), // qty & rate are non-nullable already
        };
      }).toList();

      final updatedInvoice = {
        "docstatus": 0,       // keep it draft
        "items": detailedItems,
        if (additionalDiscountPercentage != null)
          "additional_discount_percentage": additionalDiscountPercentage, // ✅ include discount
      };

      final success =
      await _apiService!.updatePosInvoice(invoiceName, updatedInvoice);
      return success;
    } catch (e, stack) {
      debugPrint("❌ Error in updateInvoiceItems: $e");
      debugPrint("📌 Stack: $stack");
      return false;
    }
  }


  Future<Map<String, dynamic>?> fetchCustomersDetails(String customerName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure POS Profile is loaded before proceeding
      if (_posProfile == null) {
        debugPrint("⚠️ POS Profile not loaded yet. Fetching now...");
        _posProfile = await _apiService?.fetchPosProfile();
        debugPrint("📥 POS Profile fetched inside fetchCustomersDetails: $_posProfile");

        if (_posProfile == null) {
          debugPrint("❌ Still no POS Profile available. Cannot fetch customer details.");
          _errorMessage = "POS Profile is required to fetch customer details";
          return null;
        }
      }

      // Fetch customer details now that POS Profile is available
      debugPrint("📤 Fetching customer details for: $customerName with POS Profile: $_posProfile");
      final details = await _apiService?.fetchCustomersDetails(customerName, _posProfile!["name"],);

      if (details != null) {
        debugPrint("✅ Customer details fetched: ${details['message']}");
        return details['message']; // Only return message part
      } else {
        debugPrint("❌ API returned null for customer details");
        return null;
      }
    } catch (e, stack) {
      _errorMessage = "Failed to fetch customer details: $e";
      debugPrint("❌ Exception in fetchCustomersDetails: $e");
      debugPrint("📌 StackTrace: $stack");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<Map<String, dynamic>?> fetchItemsDetails(
      String itemCode, String posProfile, String customer) async {
    _isLoading = true;
    notifyListeners();
    try {
      final details = await _apiService?.fetchItemsDetails(
        itemCode: itemCode,
        posProfile: posProfile,
        customer: customer,
      );
      return details;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // bool _isPrinterConnected = false;
  // bool get isPrinterConnected => _isPrinterConnected;
  //
  //
  // Future<bool> printInvoiceReceipt(String invoiceName, BuildContext context) async {
  //   try {
  //     // 1. Fetch invoice JSON
  //     final invoice = await _apiService?.fetchInvoiceDetails(invoiceName);
  //     if (invoice == null) {
  //       debugPrint("❌ Invoice not found");
  //       return false;
  //     }
  //
  //     // 2. Fetch cashier full_name
  //     final cashierEmail = invoice['owner'];
  //     if (cashierEmail != null) {
  //       final fullName = await _apiService?.fetchUserFullName(cashierEmail);
  //       if (fullName != null) {
  //         invoice['owner_fullname'] = fullName; // inject into invoice map
  //       }
  //     }
  //
  //     // 3. Select printer
  //     final device = await FlutterBluetoothPrinter.selectDevice(context);
  //     if (device == null) {
  //       debugPrint("❌ No printer selected");
  //       return false;
  //     }
  //
  //     // 4. Build invoice text with full_name
  //     final invoiceText = InvoiceFormatter.buildInvoiceText(invoice);
  //     final bytes = Uint8List.fromList(invoiceText.codeUnits);
  //
  //     // 5. Send to printer
  //     await FlutterBluetoothPrinter.printBytes(
  //       address: device.address,
  //       data: bytes,
  //       keepConnected: false,
  //     );
  //
  //     debugPrint("✅ Invoice printed");
  //     return true;
  //   } catch (e, stack) {
  //     debugPrint("❌ Error printing invoice: $e");
  //     debugPrint("📌 Stack: $stack");
  //     return false;
  //   }
  // }

  Future<bool> printInvoiceReceipt(String invoiceName, BuildContext context) async {
    try {
      // 1. Fetch invoice JSON
      final invoice = await _apiService?.fetchInvoiceDetails(invoiceName);
      if (invoice == null) {
        debugPrint("❌ Invoice not found");
        return false;
      }

      // 2. Fetch cashier full_name
      final cashierEmail = invoice['owner'];
      if (cashierEmail != null) {
        final fullName = await _apiService?.fetchUserFullName(cashierEmail);
        if (fullName != null) {
          invoice['owner_fullname'] = fullName;
        }
      }

      // 3. Check if saved printer exists
      String? savedAddress = await _sharedPrefService.getPrinterAddress();
      BluetoothDevice? device;

      if (savedAddress != null) {
        // Use saved printer directly
        device = BluetoothDevice(address: savedAddress, name: "Saved Printer");
      } else {
        // Ask user to select a printer
        device = await FlutterBluetoothPrinter.selectDevice(context);
        if (device != null) {
          // await _sharedPrefService.savePrinterAddress(device.address);
          await _sharedPrefService.savePrinter(device.name ?? "", device.address);

        }
      }

      if (device == null) {
        debugPrint("❌ No printer selected");
        return false;
      }

      // 4. Load logo from assets
      final ByteData data = await rootBundle.load('assets/images/logoo.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final img.Image? logo = img.decodeImage(imgBytes);

      // 5. ESC/POS generator
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];

      // 6. Add logo
      if (logo != null) {
        final resized = img.copyResize(
          logo,
          width: 350,
          height: (logo.height * 200 / logo.width).round(),
        );
        bytes += generator.image(resized, align: PosAlign.center);
        bytes += generator.feed(1);
      }

      // 7. Add invoice text
      // final invoiceText = InvoiceFormatter.buildInvoiceText(invoice);
      final company = await _sharedPrefService.getCompany() ?? "Company Name";
      final invoiceText = InvoiceFormatter.buildInvoiceText(invoice,
          companyName: company);

      for (final line in invoiceText.split('\n')) {
        if (line.trim().isEmpty) {
          bytes += generator.feed(1);
        } else {
          bytes += generator.text(line, styles: const PosStyles(align: PosAlign.left));
        }
      }

      // 8. Feed & cut
      // bytes += generator.feed(3);
      bytes += generator.cut();

      // 9. Print
      await FlutterBluetoothPrinter.printBytes(
        address: device.address,
        data: Uint8List.fromList(bytes),
        keepConnected: false,
      );

      debugPrint("✅ Invoice printed with logo");
      return true;
    } catch (e, stack) {
      debugPrint("❌ Error printing invoice: $e");
      debugPrint("📌 Stack: $stack");
      return false;
    }
  }

  Future<bool> checkOpeningEntry(String userEmail) async {
    try {
      return await _apiService!.checkOpeningEntry(userEmail);
    } catch (e) {
      debugPrint('Error in provider while checking opening entry: $e');
      return false;
    }
  }
  Future<List<ItemData>?> itemSearchLists(
      String query,
      BuildContext context,
      bool showError,
      ) async {
    try {
      if (_posProfile == null) {
        await fetchPosProfile();
      }

      if (_posProfile == null) {
        debugPrint("❌ POS Profile missing, cannot search items");
        return null;
      }

      final posProfileName = _posProfile!["name"];
      final priceList = _posProfile!["selling_price_list"];

      final result = await _apiService?.searchItems(
        query: query,
        posProfile: posProfileName,
        priceList: priceList,
      );

      if (result == null) return null;

      // ✅ Convert JSON list to List<ItemData>
      return result
          .map<ItemData>((json) => ItemData.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("❌ Error in itemSearchList: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPosInvoiceList(String userEmail) async {
    try {
      final openingEntry = await _apiService!.getOpeningEntry(userEmail);
      if (openingEntry == null) return [];

      final String start = openingEntry["period_start_date"];
      final String posProfile = openingEntry["pos_profile"] ?? "";
      final String end =
      DateTime.now().toIso8601String().substring(0, 19); // "yyyy-MM-ddTHH:mm:ss"

      final invoices = await _apiService!.fetchPosInvoices(
        start: start,
        end: end,
        posProfile: posProfile,
        user: userEmail,
      );

      // 🔹 Sort by name descending (latest first)
      invoices.sort((a, b) {
        final nameA = a["name"]?.toString() ?? "";
        final nameB = b["name"]?.toString() ?? "";
        return nameB.compareTo(nameA); // latest → top
      });

      return invoices;
    } catch (e) {
      debugPrint("Error in provider while fetching invoices: $e");
      return [];
    }
  }


  //POS Invoice
  //item list

  ItemListResponse? _itemListModel;

  ItemListResponse? get itemListModel => _itemListModel;

  Future<ItemListResponse?> itemGroupList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itemListModel = await _apiService!.itemList(context);
      return _itemListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isLoadingItem = false;
  bool get isLoadingItem => _isLoadingItem;
  Future<ItemListResponse?> itemSearchList(
      String item, BuildContext context, bool isItemList) async {
    _isLoadingItem = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itemListModel =
          await _apiService!.itemSearchList(item, context, isItemList);
      return _itemListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoadingItem = false;
      notifyListeners();
    }
  }

// ✅ Added: clear method for items
  void clearItemSearch() {
    _itemListModel = null;
    notifyListeners();
  }



  //item brand list

  // ItemBrandResponse? _itemBrandModel;

  // ItemBrandResponse? get itemBrandModel => _itemBrandModel;

  Future<ItemListResponse?> itemByBrandList(
      String brandName, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("test brand 2");

      _itemListModel = await _apiService!.itemByBrand(brandName, context);
      // if (_itemListModel != null && _itemListModel!.data != null) {
      //   // Iterate through the data and print each item name
      //   _itemListModel!.data!.forEach((item) {
      //     print('Item Name: ${item.itemName}');
      //   });
      // }
      return _itemListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ItemListResponse?> itemByCategoryList(
      String category, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("test category 2");

      _itemListModel = await _apiService!.categoryItemFilter(category, context);

      return _itemListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ItemListResponse?> categoryAndBrandList(
      String brand, String category, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("test category 2");

      _itemListModel = await _apiService!
          .categoryAndBrandItemFilter(brand, category, context);

      return _itemListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //brand list

  BrandListResponse? _brandListModel;

  BrandListResponse? get brandListModel => _brandListModel;

  Future<BrandListResponse?> brandList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _brandListModel = await _apiService!.brandList(context);
      return _brandListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //item list

  CategoryListRespose? _categoryListModel;

  CategoryListRespose? get categoryListModel => _categoryListModel;

  Future<CategoryListRespose?> categoryGroupList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categoryListModel = await _apiService!.categoryList(context);
      return _categoryListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Current Stock list

  CurrentStockResponse? _currentStockListModel;

  CurrentStockResponse? get currentStockListModel => _currentStockListModel;

  Future<CurrentStockResponse?> currentStockList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentStockListModel = await _apiService!.currentStockList(context);
      return _currentStockListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Current Stock filter
  Future<CurrentStockResponse?> currentStockFilter(
      String currentStock, String warehouse, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentStockListModel = await _apiService!
          .currentStockFilter(currentStock, warehouse, context);
      return _currentStockListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;

  Future<void> searchItem(String query, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _apiService!.searchItem(query, context);
    } catch (e) {
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> currentStockListByItem(BuildContext context, String itemCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentStockListModel = await _apiService!.currentStockListByItem(context, itemCode);
    } catch (e) {
      _currentStockListModel = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> currentStockListByWarehouse(BuildContext context, String warehouse) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentStockListModel = await _apiService!.currentStockListByWarehouse(context, warehouse);
    } catch (e) {
      _currentStockListModel = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void clearWarehouseResults() {
    _warehouseResults = [];
    notifyListeners();
  }

  List<Map<String, dynamic>> _warehouseResults = [];
  List<Map<String, dynamic>> get warehouseResults => _warehouseResults;

  Future<void> searchWarehouse(String query, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      _warehouseResults = await _apiService!.searchWarehouse(query, context);
    } catch (e) {
      _warehouseResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Search Customer
  CustomerList? _customerSearchModel;

  CustomerList? get customerSearchModel => _customerSearchModel;

  Future<CustomerList?> searchCustomer(String customer, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerSearchModel =
      await _apiService!.customerSearch(customer, context);

      return _customerSearchModel;
    } catch (e) {
      _customerSearchModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
// ✅ Added: clear method to reset search results
  void clearCustomerSearch() {
    _customerSearchModel = null;
    notifyListeners();
  }

  //Search Customer id
  // CustomerList? _customerSearchModel;

  // CustomerList? get customerSearchModel => _customerSearchModel;
  Future<CustomerList?> searchCustomerId(String customerId, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerSearchModel =
          await _apiService!.searchCustomerId(customerId, context);
      return _customerSearchModel;
    } catch (e) {
      _customerSearchModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //Attendance
  Future<AttendanceDetails?> fetchAttendanceForLoggedInUser(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = await _apiService!.getLoggedInUserIdentifier();
      // debugPrint('ATTENDANCE PROVIDER EMAIL => $email');

      final firstName = await _apiService!.fetchUserFirstName(email!);
      // debugPrint('ATTENDANCE PROVIDER FIRST NAME => $firstName');

      // This returns EMPLOYEE ID (HR-EMP-00003)
      final employeeId =
      await _apiService!.fetchEmployeeByFirstName(firstName!);
      // debugPrint('ATTENDANCE PROVIDER EMPLOYEE ID => $employeeId');

      // 🔴 NEW STEP: Fetch employee_name using employee ID
      final employeeName =
      await _apiService!.fetchEmployeeNameByEmployeeId(
          employeeId!, context);

      // debugPrint('ATTENDANCE PROVIDER EMPLOYEE NAME => $employeeName');

      if (employeeName == null) {
        throw Exception('Employee name not found');
      }

      // ✅ NOW fetch attendance using employee_name
      _attendanceModel =
      await _apiService!.attendanceByEmployeeName(employeeName, context);

      // debugPrint(
      //   'ATTENDANCE PROVIDER RECORD COUNT => ${_attendanceModel?.data?.length}',
      // );

      return _attendanceModel;
    } catch (e) {
      _attendanceModel = null;
      _errorMessage = e.toString();
      debugPrint('Attendance fetch error => $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AttendanceDetails? _attendanceModel;
  AttendanceDetails? get attendanceModel => _attendanceModel;

  // Future<AttendanceDetails?> attendanceDetails(
  //     String employeeId, context) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     _attendanceModel = await _apiService!.attendance(employeeId, context);
  //     return _attendanceModel;
  //   } catch (e) {
  //     _attendanceModel = null;
  //     _errorMessage = e.toString();
  //     return null;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchCustomerDetails() async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();

  //   try {
  //     _customerModel = await _apiService!.customerDetails("developer@gisaxiom.com");
  //   } catch (e) {
  //     _customerModel = null;
  //     _errorMessage = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     // Use SchedulerBinding to delay the notification until after the current frame
  //     SchedulerBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //   }
  // }
  String? _selectedType;
  String? _selectedCustomer;
  String? _selectedPaymentType;

  String? get selectedType => _selectedType;
  String? get selectedCustomer => _selectedCustomer;
  String? get selectedPaymentType => _selectedPaymentType;

  final List<String> items = ['Sales order', 'Receipt'];
  final List<String> customers = ['Customer 1', 'Customer 2'];
  final List<String> paymentType = ['Cash', 'Card', 'Cheque/DD'];

  void setSelectedType(String? value) {
    _selectedType = value;
    notifyListeners();
  }

  void setSelectedCustomer(String? value) {
    _selectedCustomer = value;
    notifyListeners();
  }

  void setPaymentType(String? value) {
    _selectedPaymentType = value;
    notifyListeners();
  }





  //checkin /checkout
  bool _isEmployee = false;
  bool get isEmployee => _isEmployee;

  Future<void> checkIfUserIsEmployee(BuildContext context) async {
    try {
      _isEmployee = await _apiService!.isUserEmployee(context);
    } catch (e) {
      _isEmployee = false;
      debugPrint("Error checking employee: $e");
    }
    notifyListeners();
  }

  CheckInCheckOut? _checkInCheckOut;

  CheckInCheckOut? get checkInCheckOut => _checkInCheckOut;
  bool _isCheckedIn = false;

  bool get isCheckedIn => _isCheckedIn;

  Future<void> checkinOrCheckout(String time, String longitude, String latitude,
      String city, String state, String area, String customer,String remarks, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final logType = _isCheckedIn ? "OUT" : "IN";
      _checkInCheckOut = await _apiService!.checkinOrCheckout(
          logType, time, longitude, latitude, city, state, area, customer,remarks, context);
      await initializeCheckinStatus();
      _isCheckedIn = !_isCheckedIn;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  List<customer.Data> _customers = [];
  List<customer.Data> get customerr => _customers;

  Future<void> fetchCustomers(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _apiService!.fetchCustomers(context);
    } catch (e) {
      _errorMessage = e.toString();
      _customers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  String? _lastRemarks;
  String? get lastRemarks => _lastRemarks;
  String? _lastCheckinTime;
  DateTime? _lastCheckinDateTime;

  String? get lastCheckinTime => _lastCheckinTime;
  DateTime? get lastCheckinDateTime => _lastCheckinDateTime;
  Future<void> initializeCheckinStatus() async {
    try {
      final latestCheckin = await _apiService!.getLatestCheckinDetailsForEmployee();
      if (latestCheckin != null) {
        _isCheckedIn = latestCheckin['log_type'] == "IN";

        /// ✅ TIME PARSING
        final timeStr = latestCheckin['time'];

        if (timeStr != null) {
          try {
            final parsed = DateTime.parse(timeStr);

            _lastCheckinDateTime = parsed;

            _lastCheckinTime =
                DateFormat('hh:mm a').format(parsed); // 10:30 AM
          } catch (e) {
            debugPrint("Time parse error: $e");
            _lastCheckinTime = null;
          }
        }
        // ✅ Store last customer if available
        final lastCustomer = latestCheckin['customer'];
        if (lastCustomer != null && lastCustomer.toString().trim().isNotEmpty) {
          _lastCheckedInCustomer = lastCustomer;
        } else {
          _lastCheckedInCustomer = null;
        }

        // ✅ Store last remarks if available
        final lastRemarks = latestCheckin['remarks'];
        if (lastRemarks != null && lastRemarks.toString().trim().isNotEmpty) {
          _lastRemarks = lastRemarks;
        } else {
          _lastRemarks = null;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error initializing check-in status: $e");
    }
  }

// add new variable in provider
  String? _lastCheckedInCustomer;
  String? get lastCheckedInCustomer => _lastCheckedInCustomer;


  //Home tile
  HomeTileResponse? _homeModel;

  HomeTileResponse? get homeModel => _homeModel;

  Future<HomeTileResponse?> homeDetails(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _homeModel = await _apiService!.homeTile(context);
      return _homeModel;
    } catch (e) {
      _employeeModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //Employee Details (employeeId)

  EmployeeDetails? _employeeModel;

  EmployeeDetails? get employeeModel => _employeeModel;

  Future<EmployeeDetails?> employeeDetails(
      String email, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _employeeModel = await _apiService!.employeeDetails(email, context);
      return _employeeModel;
    } catch (e) {
      _employeeModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //User Details

  UserDetails? _userDetailsModel;

  UserDetails? get userDetailsModel => _userDetailsModel;

  Future<UserDetails?> userDetails(String email, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userDetailsModel = await _apiService!.userDetails(email, context);
      return _userDetailsModel;
    } catch (e) {
      _userDetailsModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
//S Ord
  Map<String, dynamic>? _selectedCustomerDetails;
  Map<String, dynamic>? get selectedCustomerDetails => _selectedCustomerDetails;
  void setSelectedCustomerDetails(Map<String, dynamic> details) {
    _selectedCustomerDetails = details;
    notifyListeners();
  }
Future<Map<String, dynamic>?> fetchCustomerDetails(
    BuildContext context, String customerName) async {
  try {
    return await _apiService!.fetchCustomerDetails(context, customerName);
  } catch (e) {
    _errorMessage = e.toString();
    print("Error in provider while fetching customer details: $e");
    return null;
  }
}

// Future<Map<String, dynamic>?> fetchItemDetails({
//   required BuildContext context,
//   required String itemCode,
//   required double quantity,
//   required String currency,
// }) async {
//   try {
//     return await _apiService!.fetchItemDetail(
//       context: context,
//       itemCode: itemCode,
//       quantity: quantity,
//       currency: currency,
//     );
//   } catch (e) {
//     _errorMessage = e.toString();
//     print("Provider error fetching item details: $e");
//     return null;
//   }
// }
  Future<Map<String, dynamic>?> fetchItemDetails({
    required BuildContext context,
    required String itemCode,
    required double quantity,
    required String currency,
    required String customerName, // add this
  }) async {
    try {
      return await _apiService!.fetchItemDetail(
        context: context,
        itemCode: itemCode,
        quantity: quantity,
        currency: currency,
        customerName: customerName, // pass it down
      );
    } catch (e) {
      _errorMessage = e.toString();
      print("Provider error fetching item details: $e");
      return null;
    }
  }

  int? _allowMultipleItems; // 0 = disallow, 1 = allow
  int? get allowMultipleItems => _allowMultipleItems;

  Future<void> loadAllowMultipleItems(BuildContext context) async {
    final value = await _apiService!.fetchAllowMultipleItems(context);
    if (value != null) {
      _allowMultipleItems = value;
      debugPrint("allowMultipleItems loaded: $_allowMultipleItems");
      notifyListeners();
    }
  }

//Sales Person Report
  String? loggedUser;
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> reportColumns = [];
  Map<String, dynamic>? totalRow;
  // ===== Load logged user from API =====
  Future<void> loadLoggedUser() async {
    loggedUser = await apiService?.getLoggedInUserIdentifier();
    notifyListeners();
  }

  // ===== Fetch Sales Report =====
  Future<void> fetchReport(
      BuildContext context,
      String fromDate,
      String toDate,
      ) async {

    if (loggedUser == null) return;

    notifyListeners();

    // Step 1: Get first_name from user
    final firstName = await apiService?.fetchUserFirstName(loggedUser!);
    if (firstName == null) {
      debugPrint("No first_name for $loggedUser");
      return;
    }

    // Step 2: Get employee.name from first_name
    final employeeId = await apiService?.fetchEmployeeByFirstName(firstName);
    if (employeeId == null) {
      debugPrint("No employee for $firstName");
      return;
    }

    // Step 3: Get sales person from employee.id
    final salesPerson = await apiService?.fetchSalesPersonByEmployee(employeeId);
    if (salesPerson == null) {
      debugPrint("No sales person for $employeeId");
      return;
    }

    // Step 4: Call report API with dynamic sales person
    final res = await apiService?.fetchSalesmanMonthlySales(
      context,
      salesPerson,
      fromDate,
      toDate,
    );

    if (res == null || res["result"] == null || (res["result"] as List).isEmpty) {
      reportData = [];
      reportColumns = [];
      totalRow = null;

      notifyListeners();
      return;
    }


    // your existing mapping logic...
    final result = List<dynamic>.from(res["result"]);
    final cols = List<dynamic>.from(res["columns"]);

    reportColumns = cols.map((c) => {
      "label": c["label"],
      "fieldname": c["fieldname"],
    }).toList();

    if (result.isNotEmpty && result.last is List) {
      final last = result.last;
      totalRow = {};

      for (int i = 0; i < reportColumns.length; i++) {
        final field = reportColumns[i]["fieldname"];
        totalRow![field] = last[i];
      }

      result.removeLast();
    }

    reportData = result.map((r) => Map<String, dynamic>.from(r)).toList();

    notifyListeners();
  }
  // bool isLoadings = false;
  // Future<void> fetchReport(
  //     BuildContext context,
  //     String fromDate,
  //     String toDate,
  //     ) async {
  //   if (loggedUser == null) return;
  //
  //   // 1️⃣ Turn loader ON immediately
  //   isLoadings = true;
  //   reportData = [];
  //   totalRow = null;
  //   notifyListeners();
  //
  //   // 2️⃣ Yield one frame so loader renders
  //   await Future.delayed(Duration.zero);
  //
  //   try {
  //     final firstName =
  //     await apiService?.fetchUserFirstName(loggedUser!);
  //     if (firstName == null) return;
  //
  //     final employeeId =
  //     await apiService?.fetchEmployeeByFirstName(firstName);
  //     if (employeeId == null) return;
  //
  //     final salesPerson =
  //     await apiService?.fetchSalesPersonByEmployee(employeeId);
  //     if (salesPerson == null) return;
  //
  //     final res = await apiService?.fetchSalesmanMonthlySales(
  //       context,
  //       salesPerson,
  //       fromDate,
  //       toDate,
  //     );
  //
  //     if (res == null ||
  //         res["result"] == null ||
  //         (res["result"] as List).isEmpty) {
  //       return;
  //     }
  //
  //     final result = List<dynamic>.from(res["result"]);
  //     final cols = List<dynamic>.from(res["columns"]);
  //
  //     reportColumns = cols
  //         .map((c) => {
  //       "label": c["label"],
  //       "fieldname": c["fieldname"],
  //     })
  //         .toList();
  //
  //     if (result.isNotEmpty && result.last is List) {
  //       final last = result.last;
  //       totalRow = {};
  //
  //       for (int i = 0; i < reportColumns.length; i++) {
  //         totalRow![reportColumns[i]["fieldname"]] = last[i];
  //       }
  //       result.removeLast();
  //     }
  //
  //     reportData =
  //         result.map((r) => Map<String, dynamic>.from(r)).toList();
  //   } catch (e) {
  //     debugPrint("Fetch report error: $e");
  //   } finally {
  //     // 3️⃣ Turn loader OFF
  //     isLoadings = false;
  //     notifyListeners();
  //   }
  // }


  void clearData() {
    reportData = [];
    totalRow = null;
    notifyListeners();
  }

  bool pdfLoading = false;

  /// Call ApiService and save/open the returned PDF
  Future<void> downloadAndOpenReportPdf({
    required BuildContext context,
    required String html,
    String filenamePrefix = 'salesman_monthly_sales',
  }) async {
    try {
      pdfLoading = true;
      notifyListeners();

      final bytes = await apiService?.downloadReportPdf(html);

      if (bytes == null) {
        pdfLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download PDF')),
        );
        return;
      }

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/$filenamePrefix\_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      pdfLoading = false;
      notifyListeners();

      // NEW: Open file using OpenFilex
      final result = await OpenFilex.open(filePath);

      debugPrint("OpenFilex result: ${result.type}"); // optional

    } catch (e) {
      pdfLoading = false;
      notifyListeners();
      debugPrint('downloadAndOpenReportPdf error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while saving/opening PDF')),
      );
    }}

  String formatNumber(dynamic value) {
    if (value == null) return "";
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    // try parse if string
    final v = double.tryParse(value.toString());
    if (v != null) {
      return v.toStringAsFixed(2);
    }
    return value.toString();
  }

//   String buildHtmlReport({
//     required List<Map<String, dynamic>> rows,
//     required List<Map<String, dynamic>> columns,
//     Map<String, dynamic>? totalRow,
//   }) {
//     // Remove "sales_person" column
//     final filteredColumns = columns.where(
//           (col) => col["fieldname"] != "sales_person",
//     ).toList();
//
//     final buffer = StringBuffer();
//
//     buffer.write("""
// <!DOCTYPE html>
// <html>
// <head>
// <meta charset="utf-8">
// <title>Salesman Monthly Sales</title>
// <style>
//   body { font-family: Arial, sans-serif; font-size: 12px; }
//   table { width: 100%; border-collapse: collapse; margin-top: 10px; }
//   th, td { border: 1px solid #ddd; padding: 6px; }
//   th { background: #eee; }
//   .right { text-align: right; }
//   .bold { font-weight: bold; }
// </style>
// </head>
// <body>
//
// <h2>Salesman Monthly Sales</h2>
// <table>
// <thead>
// <tr>
// <th>#</th>
// """);
//
//     // Build column headers
//     for (final col in filteredColumns) {
//       buffer.write("<th>${col["label"]}</th>");
//     }
//
//     buffer.write("</tr></thead><tbody>");
//
//     // Build data rows
//     for (int i = 0; i < rows.length; i++) {
//       final r = rows[i];
//
//       buffer.write("<tr>");
//       buffer.write("<td>${i + 1}</td>");
//
//       for (final col in filteredColumns) {
//         final field = col["fieldname"];
//         // final value = r[field] ?? "";
//         // final align = value is num ? "right" : "";
//         //
//         // buffer.write('<td class="$align">$value</td>');
//         final rawValue = r[field];
//         final formattedValue = formatNumber(rawValue);
//         final align = rawValue is num ? "right" : "";
//         buffer.write('<td class="$align">$formattedValue</td>');
//
//       }
//
//       buffer.write("</tr>");
//     }
//
//     // Total row
//     if (totalRow != null) {
//       buffer.write('<tr class="bold"><td></td>');
//
//       for (final col in filteredColumns) {
//         final field = col["fieldname"];
//         // final value = totalRow[field] ?? "";
//         // final align = value is num ? "right" : "";
//         //
//         // buffer.write('<td class="$align">$value</td>');
//         final rawValue = totalRow[field];
//         final formattedValue = formatNumber(rawValue);
//         final align = rawValue is num ? "right" : "";
//         buffer.write('<td class="$align">$formattedValue</td>');
//
//       }
//
//       buffer.write("</tr>");
//     }
//
//     buffer.write("""
// </tbody>
// </table>
// </body>
// </html>
// """);
//
//     return buffer.toString();
//   }
  String formatIndianCurrency(dynamic value) {
    if (value == null) return "0";

    // Convert to number
    double number;
    if (value is String) {
      number = double.tryParse(value) ?? 0;
    } else if (value is num) {
      number = value.toDouble();
    } else {
      return value.toString();
    }

    // Handle negative numbers
    bool isNegative = number < 0;
    number = number.abs();

    // Split into integer and decimal parts
    String numStr = number.toStringAsFixed(2);
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Indian numbering: last 3 digits, then groups of 2
    String formatted = '';
    int length = integerPart.length;

    if (length <= 3) {
      formatted = integerPart;
    } else {
      // Last 3 digits
      formatted = integerPart.substring(length - 3);
      int remaining = length - 3;

      // Groups of 2 digits
      while (remaining > 0) {
        int end = remaining;
        int start = remaining > 2 ? remaining - 2 : 0;
        formatted = integerPart.substring(start, end) + ',' + formatted;
        remaining = start;
      }
    }

    // Add decimal part
    formatted = '$formatted.$decimalPart';

    // Add negative sign if needed
    if (isNegative) {
      formatted = '-$formatted';
    }

    return formatted;
  }
  String buildHtmlReport({
    required List<Map<String, dynamic>> rows,
    required List<Map<String, dynamic>> columns,
    Map<String, dynamic>? totalRow,
  }) {
    // Remove "sales_person" column
    final filteredColumns = columns.where(
          (col) => col["fieldname"] != "sales_person",
    ).toList();

    final buffer = StringBuffer();

    buffer.write("""
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Salesman Monthly Sales</title>
<style>
  body { font-family: Arial, sans-serif; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 10px; }
  th, td { border: 1px solid #ddd; padding: 6px; }
  th { background: #eee; }
  .right { text-align: right; }
  .bold { font-weight: bold; }
</style>
</head>
<body>

<h2>Salesman Monthly Sales</h2>
<table>
<thead>
<tr>
<th>#</th>
""");

    // Build column headers
    for (final col in filteredColumns) {
      buffer.write("<th>${col["label"]}</th>");
    }

    buffer.write("</tr></thead><tbody>");

    // Build data rows
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];

      buffer.write("<tr>");
      buffer.write("<td>${i + 1}</td>");

      for (final col in filteredColumns) {
        final field = col["fieldname"];
        final rawValue = r[field];

        // Format if it's a number, otherwise use as-is
        final formattedValue = (rawValue is num)
            ? formatIndianCurrency(rawValue)
            : (rawValue ?? "");

        final align = rawValue is num ? "right" : "";
        buffer.write('<td class="$align">$formattedValue</td>');
      }

      buffer.write("</tr>");
    }

    // Total row
    if (totalRow != null) {
      buffer.write('<tr class="bold"><td></td>');

      for (final col in filteredColumns) {
        final field = col["fieldname"];
        final rawValue = totalRow[field];

        // Format if it's a number, otherwise use as-is
        final formattedValue = (rawValue is num)
            ? formatIndianCurrency(rawValue)
            : (rawValue ?? "");

        final align = rawValue is num ? "right" : "";
        buffer.write('<td class="$align">$formattedValue</td>');
      }

      buffer.write("</tr>");
    }

    buffer.write("""
</tbody>
</table>
</body>
</html>
""");

    return buffer.toString();
  }

//Sales Person Report
//Site Visit

//   // ── State variables ──────────────────────────────────
  List<Map<String, dynamic>> _todaySiteVisits = [];
  bool _isSiteVisitsLoading = false;

  List<Map<String, dynamic>> get todaySiteVisits => _todaySiteVisits;
  bool get isSiteVisitsLoading => _isSiteVisitsLoading;

  Future<bool> canCreateSiteVisit() async {
    try {
      loggedUser = await apiService?.getLoggedInUserIdentifier();
      final firstName = await apiService?.fetchUserFirstName(loggedUser!);
      final empData = await apiService?.fetchEmployeeDetails(firstName!);
      final employee = empData?["employee"];

      if (employee == null) return false;

      final logType =
      await apiService!.fetchLatestEmployeeLogType(employee);

      // Must be checked IN to create a site visit
      return logType == "IN";
    } catch (e) {
      debugPrint("canCreateSiteVisit Error: $e");
      return false;
    }
  }
  // ── Fetch today's site visits ─────────────────────────────────────────
  Future<void> fetchTodaySiteVisits() async {
    _isSiteVisitsLoading = true;
    notifyListeners();

    try {
      final ok = await _ensureEmployeeInfo();
      if (!ok) {
        _todaySiteVisits = [];
        return;
      }
      _todaySiteVisits =
      await apiService!.fetchTodaySiteVisits(eemEmployee!);
    } catch (e) {
      debugPrint("Provider fetchTodaySiteVisits Error: $e");
      _todaySiteVisits = [];
    } finally {
      _isSiteVisitsLoading = false;
      notifyListeners();
    }
  }

// ── Create site visit (add to EEM child table) ────────────────────────
  Future<bool> createSiteVisit({
    required BuildContext context,
    required String customer,
    required String site,
    required double latitude,
    required double longitude,
    required String remarks,
    required String time,
    double? actualDistance,
  }) async {
    try {
      // EEM must exist before adding a site visit
      if (!eemCreated || eemDocName == null) {
        Fluttertoast.showToast(
          msg: "Please save expenses first before adding a site visit.",
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
        return false;
      }

      final success = await apiService!.addSiteVisitToEEM(
        eemName: eemDocName!,
        customer: customer,
        site: site,
        siteLat: latitude,
        siteLong: longitude,
        remarks: remarks,
        actualDistance: actualDistance,   // ← add this

      );

      if (success) await fetchTodaySiteVisits();
      return success;
    } catch (e) {
      debugPrint("Provider createSiteVisit Error: $e");
      return false;
    }
  }

// ── Update site visit row ─────────────────────────────────────────────
  Future<bool> updateSiteVisit({
    required String docName,   // row name
    required String customer,
    required String site,
    required double latitude,
    required double longitude,
    required String remarks,
    required String time,
    double? actualDistance,       // ← add this

  }) async {
    try {
      if (eemDocName == null) return false;

      final success = await apiService!.updateSiteVisitInEEM(
        eemName: eemDocName!,
        rowName: docName,
        customer: customer,
        site: site,
        siteLat: latitude,
        siteLong: longitude,
        remarks: remarks,
        actualDistance: actualDistance,   // ← add this

      );

      if (success) await fetchTodaySiteVisits();
      return success;
    } catch (e) {
      debugPrint("Provider updateSiteVisit Error: $e");
      return false;
    }
  }

// ── Delete site visit row ─────────────────────────────────────────────
//   Future<bool> deleteSiteVisit(String rowName) async {
//     // Optimistic removal
//     _todaySiteVisits.removeWhere((v) => v["name"] == rowName);
//     notifyListeners();
//
//     try {
//       final eemName = eemDocName ??
//           _todaySiteVisits.isNotEmpty
//           ? _todaySiteVisits.first["_eem_name"]
//           : null;
//
//       if (eemName == null) return false;
//
//       final success = await apiService!.deleteSiteVisitFromEEM(
//         eemName: eemName,
//         rowName: rowName,
//       );
//
//       if (!success) await fetchTodaySiteVisits(); // rollback
//       return success;
//     } catch (e) {
//       debugPrint("Provider deleteSiteVisit Error: $e");
//       await fetchTodaySiteVisits();
//       return false;
//     }
//   }
  //Site Visit
  //Expense Tracker
  bool isTracking = false;


  Future<void> restoreTrackingState(BuildContext context) async {
    loggedUser = await apiService?.getLoggedInUserIdentifier();
    final firstName = await apiService?.fetchUserFirstName(loggedUser!);
    final empData = await apiService?.fetchEmployeeDetails(firstName!);

    final latestEEM =
    await apiService?.fetchLatestEEM(empData!["employee"]);

    if (latestEEM == null) {
      isTracking = false;
      activeExpenseDocName = null;
      notifyListeners();
      return;
    }

    final endLat = latestEEM["end_lat"];
    final endLong = latestEEM["end_long"];

    final trackingActive =
        (endLat == null || endLat == 0) &&
            (endLong == null || endLong == 0);

    isTracking = trackingActive;
    activeExpenseDocName = trackingActive ? latestEEM["name"] : null;

    notifyListeners();
  }
  // Directly set site visits from EEM data (used in edit mode)
  void setTodaySiteVisitsFromEEM(List<Map<String, dynamic>> visits) {
    _todaySiteVisits = visits;
    notifyListeners();
  }

  List<Map<String, dynamic>> siteVisits = [];
  List<Map<String, dynamic>> expenses = [];

  Future<Map<String, dynamic>?> _getLatestEEM() async {
    loggedUser = await apiService?.getLoggedInUserIdentifier();
    final firstName = await apiService?.fetchUserFirstName(loggedUser!);
    final empData = await apiService?.fetchEmployeeDetails(firstName!);

    final latestEEM =
    await apiService?.fetchLatestEEM(empData!["employee"]);

    if (latestEEM == null) return null;

    return apiService?.fetchEEMDetails(latestEEM["name"]);
  }

  bool isSaveLoading = false;    // ✅ NEW
  bool isSubmitLoading = false;  // ✅ NEW

  void _setSaveLoading(bool value) {
    isSaveLoading = value;
    notifyListeners();
  }

  void _setSubmitLoading(bool value) {
    isSubmitLoading = value;
    notifyListeners();
  }

  // Future<List<Map<String, dynamic>>?> saveEEM(
  //     List<Map<String, dynamic>> expenses,
  //     ) async {
  //   if (isSaveLoading) return null;
  //
  //   _setSaveLoading(true);
  //   try {
  //     final eemDetails = await _getLatestEEM();
  //     if (eemDetails == null) return null;
  //
  //     final ok = await apiService!.saveExecutiveExpenseTracking(
  //       eemData: eemDetails,
  //       siteVisits: siteVisits,
  //       expenses: expenses,
  //     );
  //
  //     if (!ok) return null;
  //
  //     // 🔴 REFRESH FROM SERVER (USE EXISTING METHOD)
  //     final refreshed =
  //     await apiService!.fetchEEMDetails(eemDetails["name"]);
  //
  //     return List<Map<String, dynamic>>.from(
  //       refreshed!["employee_expense_tracking"],
  //     );
  //   } finally {
  //     _setSaveLoading(false);
  //   }
  // }

  // Future<bool> submitEEM(List<Map<String, dynamic>> expenses) async {
  //   if (isSubmitLoading) return false;
  //
  //   _setSubmitLoading(true);
  //
  //   try {
  //     final eemDetails = await _getLatestEEM();
  //     if (eemDetails == null) return false;
  //
  //     // Ensure all expenses have the attachment field
  //     final processedExpenses = expenses.map((expense) {
  //       return {
  //         ...expense,
  //         'attachment': expense['attachment'], // Can be null or file URL
  //       };
  //     }).toList();
  //
  //     return await apiService!.submitExecutiveExpenseTracking(
  //       eemData: eemDetails,
  //       siteVisits: siteVisits,
  //       expenses: processedExpenses,
  //     );
  //   } finally {
  //     _setSubmitLoading(false);
  //   }
  // }

  bool _isUploadingFile = false;
  bool get isUploadingFile => _isUploadingFile;

  void _setUploadingFile(bool value) {
    _isUploadingFile = value;
    notifyListeners();
  }

  /// Pick file from gallery (images) or camera
  Future<File?> pickFile({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
  Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }
  /// Pick multiple images from gallery
  Future<List<File>?> pickMultipleFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        return images.map((xFile) => File(xFile.path)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      return null;
    }
  }

  /// Upload file and return the file URL
  Future<String?> uploadExpenseFile(
      File file, {
        required String expenseRowName,
      }) async {
    if (apiService == null) return null;

    _setUploadingFile(true);
    try {
      return await apiService!.uploadFile(
        file: file,
        expenseRowName: expenseRowName,
      );
    } finally {
      _setUploadingFile(false);
    }
  }


  String? activeExpenseDocName;

  bool isTrackingLoading = false; // ✅ NEW


  void _setTrackingLoading(bool value) {
    isTrackingLoading = value;
    notifyListeners();
  }

  // Future<bool> startTracking({
  //   required BuildContext context,
  //   required String startTime,
  //   required double startLat,
  //   required double startLong,
  // }) async {
  //
  //   if (isTrackingLoading) return false;
  //   _setTrackingLoading(true);
  //
  //   try {
  //     loggedUser = await apiService?.getLoggedInUserIdentifier();
  //     final firstName = await apiService?.fetchUserFirstName(loggedUser!);
  //     final empData = await apiService?.fetchEmployeeDetails(firstName!);
  //
  //     final today = DateTime.now();
  //     final date =
  //         "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  //
  //     activeExpenseDocName =
  //     await apiService!.startExecutiveExpenseTracking(
  //       context: context,
  //       employee: empData!["employee"],
  //       employeeName: empData["employee_name"],
  //       date: date,
  //       startTime: startTime,
  //       startLat: startLat,
  //       startLong: startLong,
  //     );
  //
  //     if (activeExpenseDocName != null) {
  //       isTracking = true;
  //
  //       return true;
  //     }
  //     return false;
  //   } finally {
  //     _setTrackingLoading(false);
  //   }
  // }
  //
  //
  // Future<bool> stopTracking({
  //   required String endTime,
  //   required double endLat,
  //   required double endLong,
  //   required List<Map<String, dynamic>> expenses,
  // }) async {
  //   if (activeExpenseDocName == null || isTrackingLoading) return false;
  //
  //   _setTrackingLoading(true);
  //
  //   try {
  //     final data = await apiService!.stopExecutiveExpenseTracking(
  //       docName: activeExpenseDocName!,
  //       endTime: endTime,
  //       endLat: endLat,
  //       endLong: endLong,
  //       expenses: expenses,
  //     );
  //
  //     if (data != null) {
  //       siteVisits = data;
  //       this.expenses = expenses;
  //
  //       isTracking = false;
  //       activeExpenseDocName = null;
  //       return true;
  //     }
  //     return false;
  //   } finally {
  //     _setTrackingLoading(false); // ✅ ALWAYS reset
  //   }
  // }

  Future<List<String>> fetchExpenseTypes(String query) async {
    return await apiService!.searchExpenseClaimTypes(query);
  }
  Future<bool> canStopTracking() async {
    loggedUser = await apiService?.getLoggedInUserIdentifier();
    final firstName = await apiService?.fetchUserFirstName(loggedUser!);
    final empData = await apiService?.fetchEmployeeDetails(firstName!);

    if (empData == null) return true;

    final logType = await apiService
        ?.fetchLatestEmployeeLogType(empData["employee"]);

    // ❌ If still checked IN, block stopping
    if (logType == "IN") {
      return false;
    }

    return true;
  }
// In provider.dart

  Future<bool> canStartTracking() async {
    loggedUser = await apiService?.getLoggedInUserIdentifier();
    final firstName = await apiService?.fetchUserFirstName(loggedUser!);
    final empData = await apiService?.fetchEmployeeDetails(firstName!);

    if (empData == null) return true;

    final logType = await apiService
        ?.fetchLatestEmployeeLogType(empData["employee"]);

    // ❌ If still checked IN, block starting
    if (logType == "IN") {
      return false;
    }

    return true;
  }
  void setSiteVisits(List<Map<String, dynamic>> visits) {
    siteVisits = visits;
    notifyListeners();
  }
// In your SalesOrderProvider class


  void clearTrackingData() {
    isTracking = false;
    isTrackingLoading = false;
    isSaveLoading = false;
    isSubmitLoading = false;

    // ✅ Clear site visits and expenses
    siteVisits.clear();
    expenses.clear();
    eemDocName = null;
    eemCreated = false;
    eemEmployee = null;
    eemEmployeeName = null;
    eemDate = null;
    isEEMSaveLoading = false;
    isEEMSubmitLoading = false;
    notifyListeners();
    // ✅ Clear active expense document name
    activeExpenseDocName = null;

    // Clear from SharedPreferences
    _clearTrackingFromPrefs();

    notifyListeners();
  }

  Future<void> _clearTrackingFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tracking_state');
    await prefs.remove('start_time');
    await prefs.remove('start_lat');
    await prefs.remove('start_long');
    await prefs.remove('end_time');
    await prefs.remove('end_lat');
    await prefs.remove('end_long');
    await prefs.remove('eem_name');
    await prefs.remove('eem_date');
    // Add any other keys you're storing
  }
  //Expense Tracker
//claude

  // ── State ─────────────────────────────────────────────────────────────
  String? eemDocName;           // active EEM doc name
  String? eemEmployee;          // cached employee id
  String? eemEmployeeName;      // cached employee name
  String? eemDate;              // cached date string
  bool isEEMSaveLoading = false;
  bool isEEMSubmitLoading = false;
  bool eemCreated = false;      // true once EEM is POSTed

  void _setEEMSaveLoading(bool v) { isEEMSaveLoading = v; notifyListeners(); }
  void _setEEMSubmitLoading(bool v) { isEEMSubmitLoading = v; notifyListeners(); }

// ── Fetch & cache employee info ───────────────────────────────────────
  Future<bool> _ensureEmployeeInfo() async {
    if (eemEmployee != null) return true;
    try {
      loggedUser = await apiService?.getLoggedInUserIdentifier();
      final firstName = await apiService?.fetchUserFirstName(loggedUser!);
      final empData = await apiService?.fetchEmployeeDetails(firstName!);
      if (empData == null) return false;

      eemEmployee = empData["employee"];
      eemEmployeeName = empData["employee_name"];

      final today = DateTime.now();
      eemDate =
      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      return true;
    } catch (e) {
      debugPrint("_ensureEmployeeInfo Error: $e");
      return false;
    }
  }

// ── CREATE EEM (POST — called on first Save tap) ──────────────────────
  Future<bool> createEEM({
    double? startLat,
    double? startLong,
    double? startOdometer,
  }) async {
    if (eemCreated) return true;
    final ok = await _ensureEmployeeInfo();
    if (!ok) return false;

    eemDocName = await apiService!.createExecutiveExpenseManager(
      employee: eemEmployee!,
      employeeName: eemEmployeeName!,
      date: eemDate!,
      startLat: startLat,
      startLong: startLong,
      startOdometer: startOdometer,
    );

    if (eemDocName != null) {
      eemCreated = true;
      notifyListeners();
      return true;
    }
    return false;
  }
  bool isEEMEndLoading = false;

  void _setEEMEndLoading(bool v) {
    isEEMEndLoading = v;
    notifyListeners();
  }

  Future<bool> updateEEMEnd({
    required double endOdometer,
    required double endLat,
    required double endLong,
  }) async {
    if (eemDocName == null) return false;
    _setEEMEndLoading(true);

    try {
      final endTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final ok = await apiService!.updateEEMEndDetails(
        eemName: eemDocName!,
        endTime: endTime,
        endLat: endLat,
        endLong: endLong,
        endOdometer: endOdometer,
      );

      return ok;
    } catch (e) {
      debugPrint("updateEEMEnd Error: $e");
      return false;
    } finally {
      _setEEMEndLoading(false);
    }
  }
// ── SAVE EEM (PUT, docstatus=0) ───────────────────────────────────────

  Future<bool> saveEEMExpenses(
      List<Map<String, dynamic>> expenses, {
        double? startOdometer,
        double? startLat,
        double? startLong,
        double? endOdometer,
      }) async {
    if (isEEMSaveLoading) return false;
    _setEEMSaveLoading(true);

    try {
      if (!eemCreated) {
        final created = await createEEM(
          startLat: startLat,
          startLong: startLong,
          startOdometer: startOdometer,
        );
        if (!created) return false;
      }

      final ok = await apiService!.saveEEMWithExpenses(
        eemName: eemDocName!,
        employee: eemEmployee!,
        employeeName: eemEmployeeName!,
        date: eemDate!,
        expenses: expenses,
        startOdometer: startOdometer,
        endOdometer: endOdometer,
      );

      return ok;
    } catch (e) {
      debugPrint("saveEEMExpenses Error: $e");
      return false;
    } finally {
      _setEEMSaveLoading(false);
    }
  }

// ── SUBMIT EEM (PUT, docstatus=1) ─────────────────────────────────────
  Future<bool> submitEEMExpenses(
      List<Map<String, dynamic>> expenses, {
        double? startOdometer,
        double? endOdometer,
      }) async  {
    if (isEEMSubmitLoading) return false;
    _setEEMSubmitLoading(true);

    try {
      if (!eemCreated) {
        final created = await createEEM();
        if (!created) return false;
      }

      final ok = await apiService!.submitEEMWithExpenses(
        eemName: eemDocName!,
        employee: eemEmployee!,
        employeeName: eemEmployeeName!,
        date: eemDate!,
        expenses: expenses,
        startOdometer: startOdometer,
        endOdometer: endOdometer,
      );

      if (ok) {
        // Reset EEM state after successful submit
        eemDocName = null;
        eemCreated = false;
        eemEmployee = null;
        eemEmployeeName = null;
        eemDate = null;
        _todaySiteVisits = [];

        notifyListeners();
      }

      return ok;
    } catch (e) {
      debugPrint("submitEEMExpenses Error: $e");
      return false;
    } finally {
      _setEEMSubmitLoading(false);
    }
  }
  bool isEEMRestoring = false;

  void _setEEMRestoring(bool v) {
    isEEMRestoring = v;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>?> restoreUnsubmittedEEM() async {
    _setEEMRestoring(true);

    try {
      final ok = await _ensureEmployeeInfo();
      if (!ok) return null;

      final eem = await apiService!
          .fetchLatestUnsubmittedEEM(eemEmployee!);

      if (eem == null) return null;

      // Restore EEM state
      eemDocName = eem["name"];
      eemCreated = true;
      eemEmployee = eem["employee"];
      eemEmployeeName = eem["employee_name"];
      eemDate = eem["date"];
      notifyListeners();

      // Return expense rows for UI to restore
      final rows = eem["employee_expense_tracking"];
      if (rows is List) {
        return List<Map<String, dynamic>>.from(rows);
      }
      return [];
    } catch (e) {
      debugPrint("restoreUnsubmittedEEM Error: $e");
      return null;
    } finally {
      _setEEMRestoring(false);
    }
  }
  //claude
  //checkin

  // Future<List<dynamic>> fetchCheckinsAfterEEMStart(
  //     BuildContext context) async {
  //   try {
  //     // Step 1: Identify employee
  //     loggedUser = await apiService?.getLoggedInUserIdentifier();
  //     final firstName = await apiService?.fetchUserFirstName(loggedUser!);
  //     final empData = await apiService?.fetchEmployeeDetails(firstName!);
  //
  //     final employeeId = empData!["employee"];
  //
  //     // Step 2: Fetch latest EEM
  //     final latestEEM = await apiService?.fetchLatestEEM(employeeId);
  //
  //     if (latestEEM == null) {
  //       debugPrint('NO LATEST EEM FOUND');
  //       return [];
  //     }
  //
  //     final int docstatus = latestEEM["docstatus"] ?? 1;
  //
  //     // 🚫 ENFORCE DRAFT CONDITION
  //     if (docstatus != 0) {
  //       debugPrint(
  //         'EEM IS NOT IN DRAFT (docstatus=$docstatus) — CHECKINS NOT DISPLAYED',
  //       );
  //       return [];
  //     }
  //
  //     final eemDate = latestEEM["date"];
  //     final eemStartTime = latestEEM["start_time"];
  //
  //     if (eemDate == null || eemStartTime == null) {
  //       debugPrint('LATEST EEM MISSING START DATA');
  //       return [];
  //     }
  //
  //     // Step 3: Fetch filtered checkins
  //     final checkins =
  //     await apiService!.fetchEmployeeCheckinsAfterStart(
  //       context: context,
  //       employee: employeeId,
  //       eemDate: eemDate,
  //       eemStartTime: eemStartTime,
  //     );
  //
  //     debugPrint('FILTERED CHECKINS COUNT => ${checkins?.length}');
  //     return checkins ?? [];
  //   } catch (e) {
  //     debugPrint('Provider fetchCheckinsAfterEEMStart Error => $e');
  //     return [];
  //   }
  // }
  Future<List<dynamic>> fetchCheckinsAfterEEMStart(
      BuildContext context) async {
    try {
      // Identify employee
      loggedUser = await apiService?.getLoggedInUserIdentifier();
      final firstName = await apiService?.fetchUserFirstName(loggedUser!);
      final empData = await apiService?.fetchEmployeeDetails(firstName!);

      if (empData == null) return [];

      final employeeId = empData["employee"];

      // Fetch today's checkins directly — no EEM dependency
      final checkins = await apiService!
          .fetchTodayEmployeeCheckins(employeeId);

      debugPrint('TODAY CHECKINS COUNT => ${checkins.length}');
      return checkins;
    } catch (e) {
      debugPrint('Provider fetchCheckinsAfterEEMStart Error => $e');
      return [];
    }
  }

  //checkin
//EEM List

  List<Map<String, dynamic>> eemList = [];
  bool isLoadingEEM = false;


    DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  Future<void> fetchEEMList({DateTime? from, DateTime? to}) async {
    try {
      isLoadingEEM = true;
      notifyListeners();

      final loggedUser = await apiService?.getLoggedInUserIdentifier();
      final firstName = await apiService?.fetchUserFirstName(loggedUser!);
      final empData =
      await apiService?.fetchEmployeeDetails(firstName!);

      final employeeId = empData!["employee"];

      fromDate = from ?? fromDate;
      toDate = to ?? toDate;

      eemList = await apiService!.fetchEEMList(
        employeeId,
        fromDate: DateFormat('yyyy-MM-dd').format(fromDate),
        toDate: DateFormat('yyyy-MM-dd').format(toDate),
      );
    } catch (e) {
      debugPrint("fetchEEMList Provider Error: $e");
    } finally {
      isLoadingEEM = false;
      notifyListeners();
    }
  }
  Map<String, dynamic>? eemDetails;
  bool isLoadingEEMDetails = false;
  Future<void> fetchEEMDetails(String eemName) async {
    try {
      isLoadingEEMDetails = true;
      notifyListeners();

      eemDetails = await apiService!.fetchEEMDetail(eemName);
    } catch (e) {
      debugPrint("fetchEEMDetails Provider Error: $e");
    } finally {
      isLoadingEEMDetails = false;
      notifyListeners();
    }
  }

  //EEM List

  //performance report
  // ── Performance Report ─────────────────────────────────────────────────────


  PerformanceReportState performanceReportState = PerformanceReportState.idle;
  String? performanceReportError;
  String? resolvedSalesPerson;

  List<Map<String, dynamic>> perfSalesOrders = [];
  List<Map<String, dynamic>> perfEstimates = [];
  List<Map<String, dynamic>> perfQuotations = [];
  List<Map<String, dynamic>> perfPaymentCollections = [];
  List<Map<String, dynamic>> perfVisits = [];
  int get perfVisitCount => perfVisits.length;

// Aggregation helpers
  int perfTotalCount(List<Map<String, dynamic>> list) =>
  list.fold(0, (sum, e) => sum + (e['total_count'] as int? ?? 0));

  double perfTotalAmount(List<Map<String, dynamic>> list) =>
  list.fold(0.0, (sum, e) => sum + (e['total_amount'] as num? ?? 0).toDouble());

  /// Pass [salesperson] to skip auto-resolution (manager view).
  /// Omit to resolve from the logged-in user session.
  Future<void> fetchPerformanceReport({String? salesperson}) async {
  performanceReportState = PerformanceReportState.loading;
  performanceReportError = null;
  notifyListeners();

  try {
  String? sp = salesperson;

  if (sp == null) {
  sp = await _resolveSalesPerson();
  if (sp == null) {
  performanceReportState = PerformanceReportState.error;
  performanceReportError = 'Could not resolve salesperson from logged-in user.';
  notifyListeners();
  return;
  }
  }

  resolvedSalesPerson = sp;

  final data = await _apiService?.fetchSalesPersonDashboard(
  salesperson: sp,
  fromDate: _perfFromDateApi,
  toDate: _perfToDateApi,
  );

  if (data == null) {
  performanceReportState = PerformanceReportState.error;
  performanceReportError = 'Failed to load report. Please try again.';
  notifyListeners();
  return;
  }

  _mapPerformanceData(data);
  performanceReportState = PerformanceReportState.success;
  } catch (e) {
  performanceReportState = PerformanceReportState.error;
  performanceReportError = 'Unexpected error: $e';
  debugPrint('fetchPerformanceReport: $e');
  }

  notifyListeners();
  }

// ── Date filter state ──────────────────────────────────────────────────────

  final DateFormat _apiFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _displayFmt = DateFormat('dd MMM yyyy');

  // DateTime _perfFromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _perfFromDate = DateTime.now();
  DateTime _perfToDate = DateTime.now();

  DateTime get perfFromDate => _perfFromDate;
  DateTime get perfToDate => _perfToDate;

  String get perfFromDateDisplay => _displayFmt.format(_perfFromDate);
  String get perfToDateDisplay => _displayFmt.format(_perfToDate);

  String get _perfFromDateApi => _apiFmt.format(_perfFromDate);
  String get _perfToDateApi => _apiFmt.format(_perfToDate);

  void setPerfFromDate(DateTime date) {
  _perfFromDate = date;
  notifyListeners();
  }

  void setPerfToDate(DateTime date) {
  _perfToDate = date;
  notifyListeners();
  }

// ── Private helpers ────────────────────────────────────────────────────────

  Future<String?> _resolveSalesPerson() async {
  final loggedUser = await _apiService?.getLoggedInUserIdentifier();
  if (loggedUser == null) return null;

  final firstName = await _apiService?.fetchUserFirstName(loggedUser);
  if (firstName == null) return null;

  final employeeId = await _apiService?.fetchEmployeeByFirstName(firstName);
  if (employeeId == null) return null;

  return await _apiService?.fetchSalesPersonByEmployee(employeeId);
  }

  void _mapPerformanceData(Map<String, dynamic> data) {
  perfSalesOrders     = _toMapList(data['sales_order']);
  perfEstimates       = _toMapList(data['estimate']);
  perfQuotations      = _toMapList(data['quotation']);
  perfPaymentCollections = _toMapList(data['payment_collection']);
  perfVisits          = _toMapList(data['visit']);
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
  if (raw is List) {
  return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
  }

  void resetPerformanceReport() {
  performanceReportState = PerformanceReportState.idle;
  performanceReportError = null;
  resolvedSalesPerson = null;
  perfSalesOrders = [];
  perfEstimates = [];
  perfQuotations = [];
  perfPaymentCollections = [];
  perfVisits = [];
  notifyListeners();
  }

  bool isPdfDownloading = false;
  String _buildReportHtml() {
    return PerformanceReportHtmlBuilder(
      salesperson: resolvedSalesPerson,
      fromDate: _perfFromDateApi,
      toDate: _perfToDateApi,
      salesOrders: perfSalesOrders,
      estimates: perfEstimates,
      quotations: perfQuotations,
      paymentCollections: perfPaymentCollections,
      visits: perfVisits,
    ).build();
  }

  Future<void> downloadPerformanceReportPdf() async {
    isPdfDownloading = true;
    notifyListeners();

    try {
      final html = _buildReportHtml();

      // Get temp directory to save PDF
      final dir = await getTemporaryDirectory();
      final fileName =
          'performance_report_${resolvedSalesPerson ?? 'report'}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final savePath = '${dir.path}/$fileName';

      final filePath = await _apiService?.downloadPerformanceReportPdf(
        html: html,
        savePath: savePath,
      );

      if (filePath != null) {
        // Open/share the PDF
        await OpenFilex.open(filePath);
      } else {
        debugPrint('PDF download failed');
      }
    } catch (e) {
      debugPrint('downloadPerformanceReportPdf provider error: $e');
    }

    isPdfDownloading = false;
    notifyListeners();
  }
  // ToDo List
  bool isLoadingToDos = false;
  List<Map<String, dynamic>> toDoList = [];

  Future<void> fetchToDoList() async {
    try {
      isLoadingToDos = true;
      notifyListeners();

      toDoList = await apiService!.fetchToDoList();
    } catch (e) {
      debugPrint("fetchToDoList Provider Error: $e");
    } finally {
      isLoadingToDos = false;
      notifyListeners();
    }
  }
  bool isUpdatingToDo = false;
  int? updatingIndex;
  // updatingIndex = index;
  notifyListeners();

  Future<void> updateToDoStatus({
    required int index,
    required String newStatus,
  }) async {
    final todo = toDoList[index];
    final todoName = todo["name"];

    if (todoName == null) return;

    try {
      isUpdatingToDo = true;
      notifyListeners();

      final success = await apiService!.updateToDoStatus(
        todoName: todoName,
        status: newStatus,
      );

      if (success) {
        // Optimistic local update
        toDoList[index]["status"] = newStatus;
      }
    } catch (e) {
      debugPrint("updateToDoStatus Provider Error: $e");
    } finally {
      isUpdatingToDo = false;
      notifyListeners();
    }
  }
  // Future<bool> maintenanceVisitExistsForSalesOrder(String salesOrderName) async {
  //   return await apiService!
  //       .maintenanceVisitExistsForSalesOrder(salesOrderName);
  // }
  Future<String?> fetchMaintenanceVisitStatusForSalesOrder(
      String salesOrderName) async {
    return await apiService!
        .fetchMaintenanceVisitStatusForSalesOrder(salesOrderName);
  }
  // ToDo List
//Task List

  bool isLoadingTasks = false;
  List<Map<String, dynamic>> taskList = [];

// Fetch Tasks
  Future<void> fetchTaskList() async {
    try {
      isLoadingTasks = true;
      notifyListeners();

      taskList = await apiService!.fetchTaskList();
    } catch (e) {
      debugPrint("fetchTaskList Provider Error: $e");
    } finally {
      isLoadingTasks = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask({
    required int index,
    String? newStatus,
    double? newProgress,
    String? completedBy,
    String? completedOn,
  }) async {
    if (index < 0 || index >= taskList.length) return false;

    try {
      final taskName = taskList[index]["name"];
      if (taskName == null) return false;

      updatingIndex = index;
      notifyListeners();

      final success = await apiService!.updateTask(
        taskName: taskName,
        status: newStatus,
        progress: newProgress,
        completedBy: completedBy,
        completedOn: completedOn,
      );

      if (success) {
        if (newStatus != null) taskList[index]["status"] = newStatus;
        if (newProgress != null) taskList[index]["progress"] = newProgress;
        if (completedBy != null) taskList[index]["completed_by"] = completedBy;
        if (completedOn != null) taskList[index]["completed_on"] = completedOn;
      }

      return success;
    } finally {
      updatingIndex = -1;
      notifyListeners();
    }
  }


// Legacy method for backward compatibility (optional)
  Future<void> updateTaskStatus(int index, String newStatus) async {
    await updateTask(index: index, newStatus: newStatus);
  }

//Task List

  // Project list

  bool isLoadingProjects = false;
  List<Map<String, dynamic>> projectList = [];

  Future<void> fetchProjectList() async {
    try {
      isLoadingProjects = true;
      notifyListeners();
      projectList = await apiService!.fetchProjectsList();
    } catch (e) {
      debugPrint("fetchProjectList Provider Error: $e");
    } finally {
      isLoadingProjects = false;
      notifyListeners();
    }
  }

  // Project

  //maintenance visit

  bool isCreatingMaintenanceVisit = false;
  bool maintenanceVisitCreated = false;

  Future<void> createMaintenanceVisit({
    required String customer,
    required String customerName,
    required String mntcDate,
    required String mntcTime,
    required String completionStatus,
    required String maintenanceType,
    required String customerFeedback,
    required List<Map<String, dynamic>> purposes,
    String? prevDocName,
    String? prevDocType,
  }) async {
    try {
      isCreatingMaintenanceVisit = true;
      maintenanceVisitCreated = false;
      notifyListeners();

      // ✅ Get company here (NOT from UI)
      final company = await _sharedPrefService.getCompany() ?? "";

      if (company.isEmpty) {
        debugPrint("No company selected");
        maintenanceVisitCreated = false;
        return;
      }

      final result = await apiService!.createMaintenanceVisit(
        customer: customer,
        customerName: customerName,
        mntcDate: mntcDate,
        mntcTime: mntcTime,
        completionStatus: completionStatus,
        maintenanceType: maintenanceType,
        customerFeedback: customerFeedback,
        company: company,
        purposes: purposes,
        prevDocName: prevDocName,
        prevDocType: prevDocType,
      );

      maintenanceVisitCreated = result;

    } catch (e) {
      debugPrint("Provider createMaintenanceVisit Error: $e");
    } finally {
      isCreatingMaintenanceVisit = false;
      notifyListeners();
    }
  }
  Future<void> updateMaintenanceVisit({
    required String name,
    required String customer,
    required String customerName,
    required String mntcDate,
    required String mntcTime,
    required String completionStatus,
    required String maintenanceType,
    required String customerFeedback,

    required List<Map<String, dynamic>> purposes,
  }) async {
    try {
      isCreatingMaintenanceVisit = true;
      maintenanceVisitCreated = false;
      notifyListeners();

      final company = await _sharedPrefService.getCompany() ?? "";

      if (company.isEmpty) {
        maintenanceVisitCreated = false;
        return;
      }

      final result = await apiService!.updateMaintenanceVisit(
        name: name,
        customer: customer,
        customerName: customerName,
        mntcDate: mntcDate,
        mntcTime: mntcTime,
        completionStatus: completionStatus,
        maintenanceType: maintenanceType,
        company: company,
        customerFeedback: customerFeedback,

        purposes: purposes,
      );

      maintenanceVisitCreated = result;
    } catch (e) {
      debugPrint("Provider updateMaintenanceVisit Error: $e");
    } finally {
      isCreatingMaintenanceVisit = false;
      notifyListeners();
    }
  }
  List<String> customerSearchResults = [];
  bool isSearchingCustomer = false;

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      customerSearchResults = [];
      notifyListeners();
      return;
    }

    isSearchingCustomer = true;
    notifyListeners();

    customerSearchResults = await apiService!.searchCustomers(query);

    isSearchingCustomer = false;
    notifyListeners();
  }
  List<Map<String, String>> itemSearchResults = [];
  bool isSearchingItem = false;

  Future<void> searchItemm(String query) async {
    if (query.isEmpty) {
      itemSearchResults = [];
      notifyListeners();
      return;
    }

    isSearchingItem = true;
    notifyListeners();

    itemSearchResults = await apiService!.searchItemm(query);

    isSearchingItem = false;
    notifyListeners();
  }
  Future<Map<String, dynamic>?> fetchSalesOrderByName(String name) async {
    return await apiService!.fetchSalesOrderByName(name);
  }

  bool isLoadingSerials = false;
  List<String> serialSearchResults = [];

  Future<void> fetchSerialNumber(String itemCode) async {
    if (itemCode.isEmpty) return;

    isLoadingSerials = true;
    notifyListeners();

    serialSearchResults =
    await apiService!.fetchSerialNumbers(itemCode: itemCode);

    isLoadingSerials = false;
    notifyListeners();
  }
  bool isLoadingMaintenanceVisits = false;
  List<Map<String, dynamic>> maintenanceVisitList = [];

  Future<void> fetchMaintenanceVisitList() async {
    try {
      isLoadingMaintenanceVisits = true;
      notifyListeners();

      // 🔥 Resolve logged-in sales person
      final salesPerson =
      await apiService!.resolveLoggedInSalesPerson();

      if (salesPerson == null || salesPerson.isEmpty) {
        maintenanceVisitList = [];
        return;
      }

      final result =
      await apiService!.fetchMaintenanceVisitList(
        salesPerson: salesPerson,
      );

      maintenanceVisitList = result;
    } catch (e) {
      debugPrint("Provider fetchMaintenanceVisitList Error: $e");
    } finally {
      isLoadingMaintenanceVisits = false;
      notifyListeners();
    }
  }
  Future<Map<String, dynamic>?> fetchMaintenanceVisitByName(String name) async {
    return await apiService!.fetchMaintenanceVisitByName(name);
  }
  //maintenance visit

    //estimate preparation

  bool isCreatingEstimate = false;

  Future<Map<String, dynamic>> createEstimate({
    required BuildContext context,
    required String customer,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required String message,
  }) async {
    isCreatingEstimate = true;
    notifyListeners();

    try {
      final company = await _sharedPrefService.getCompany();
      final double gstAmount = (rate * gstPerc) / 100;
      final double totalAmount = rate + gstAmount;

      return await apiService!.createEstimate(
        context: context,
        customer: customer,
        company: company ?? '',
        date: date,
        contact: contact,
        validTill: validTill,
        itemCode: itemCode,
        itemName: itemName,
        itemDescription: itemDescription,
        rate: rate,
        gstPerc: gstPerc,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        message: message,
      );
    } catch (e) {
      debugPrint("Provider createEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    } finally {
      isCreatingEstimate = false;
      notifyListeners();
    }
  }
  Future<String?> getCustomerContact(String customer) async {
    try {
      return await _apiService!.getCustomerContact(customer);
    } catch (e) {
      debugPrint("Provider getCustomerContact Error: $e");
      return null;
    }
  }
  Future<double?> getItemGstPerc(String itemCode) async {
    try {
      final company = await _sharedPrefService.getCompany();
      return await apiService!.getItemGstPerc(itemCode, company ?? '');
    } catch (e) {
      debugPrint("Provider getItemGstPerc Error: $e");
      return null;
    }
  }
  Future<double?> getItemRate(String itemCode) async {
    try {
      return await apiService!.getItemRate(itemCode);
    } catch (e) {
      debugPrint("Provider getItemRate Error: $e");
      return null;
    }
  }
  List<Map<String, dynamic>> _estimateList = [];
  List<Map<String, dynamic>> get estimateList => _estimateList;

  bool _isLoadingEstimates = false;
  bool get isLoadingEstimates => _isLoadingEstimates;
  //
  // Future<void> fetchEstimateList() async {
  //   _isLoadingEstimates = true;
  //   notifyListeners();
  //
  //   try {
  //     _estimateList = await apiService!.fetchEstimateList();
  //   } catch (e) {
  //     debugPrint("Provider fetchEstimateList Error: $e");
  //     _estimateList = [];
  //   } finally {
  //     _isLoadingEstimates = false;
  //     notifyListeners();
  //   }
  // }
  Future<void> fetchEstimateList({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _isLoadingEstimates = true;
    notifyListeners();

    try {
      _estimateList = await apiService!.fetchEstimateList(
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      debugPrint("Provider fetchEstimateList Error: $e");
      _estimateList = [];
    } finally {
      _isLoadingEstimates = false;
      notifyListeners();
    }
  }
  Future<Map<String, dynamic>> updateEstimate({
    required BuildContext context,
    required String docname,
    required String customer,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required String message,
  }) async {
    isCreatingEstimate = true;
    notifyListeners();

    try {
      final company = await _sharedPrefService.getCompany();
      final double gstAmount = (rate * gstPerc) / 100;
      final double totalAmount = rate + gstAmount;

      return await apiService!.updateEstimate(
        context: context,
        docname: docname,
        customer: customer,
        company: company ?? '',
        date: date,
        contact: contact,
        validTill: validTill,
        itemCode: itemCode,
        itemName: itemName,
        itemDescription: itemDescription,
        rate: rate,
        gstPerc: gstPerc,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        message: message,
      );
    } catch (e) {
      debugPrint("Provider updateEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    } finally {
      isCreatingEstimate = false;
      notifyListeners();
    }
  }
  // Save only (docstatus: 0) — POST for new, PUT for existing
  Future<Map<String, dynamic>> saveDraftEstimate({
    required BuildContext context,
    required String? docname,     // null = new estimate
    required String customer,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required String message,
  }) async {
    isCreatingEstimate = true;
    notifyListeners();

    try {
      final company = await _sharedPrefService.getCompany();
      final double gstAmount = (rate * gstPerc) / 100;
      final double totalAmount = rate + gstAmount;

      return await apiService!.saveDraftEstimate(
        context: context,
        docname: docname,
        customer: customer,
        company: company ?? '',
        date: date,
        contact: contact,
        validTill: validTill,
        itemCode: itemCode,
        itemName: itemName,
        itemDescription: itemDescription,
        rate: rate,
        gstPerc: gstPerc,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        message: message,
      );
    } catch (e) {
      debugPrint("Provider saveDraftEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    } finally {
      isCreatingEstimate = false;
      notifyListeners();
    }
  }

// Submit + WhatsApp only
  Future<Map<String, dynamic>> submitEstimate({
    required BuildContext context,
    required String docname,
    required String contact,
  }) async {
    isCreatingEstimate = true;
    notifyListeners();

    try {
      return await apiService!.submitEstimate(
        docname: docname,
        contact: contact,
      );
    } catch (e) {
      debugPrint("Provider submitEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    } finally {
      isCreatingEstimate = false;
      notifyListeners();
    }
  }
  //estimate preparation

  //appointments

  bool isLoadingAppointments = false;
  List<Map<String, dynamic>> appointmentList = [];

  Future<void> fetchAppointments() async {
    try {
      isLoadingAppointments = true;
      notifyListeners();

      appointmentList = await apiService!.fetchAppointments();
    } catch (e) {
      debugPrint("fetchAppointments Provider Error: $e");
    } finally {
      isLoadingAppointments = false;
      notifyListeners();
    }
  }


  //appointments
//S Ord
//Sales Order
  SalesOrderResponse? _salesOrderModel;

  SalesOrderResponse? get salesOrderModel => _salesOrderModel;

  Future<SalesOrderResponse?> salesOrder(
    String customerName,
    String deliveryDate,
    List items,
    BuildContext context, {
    Map<String, dynamic>? customerDetails, // 🆕 Accept customer details also
            String? setWarehouse,
        // String? quotation,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _salesOrderModel = await _apiService!.salesOrder(
        customerName,
        deliveryDate,
        items,
        context,
        customerDetails: customerDetails, // 🆕 Pass along
        setWarehouse: setWarehouse,
        // quotation: quotation,

      );
      return _salesOrderModel;
    } catch (e) {
      _salesOrderModel = null;
      _errorMessage = e.toString(); // already formatted from API service

      _errorMessage = e.toString();
      print("Provider error creating sales order: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<Map<String, dynamic>?> mapQuotationToSalesOrder(
      String quotationName) async {
    try {
      final data = await _apiService!
          .createSalesOrderFromQuotation(quotationName: quotationName);

      return data;
    } catch (e) {
      debugPrint("❌ Provider mapping error: $e");
      return null;
    }
  }

  String? _setWarehouse;
  String? get setWarehouse => _setWarehouse;

  void setWarehousee(String warehouse) {
    _setWarehouse = warehouse;
    notifyListeners();
  }

  void clearWarehouse() {
    _setWarehouse = null;
    notifyListeners();
  }
  void clearSalesOrderModel() {
    _salesOrderModel = null;
  }
  bool get hasActiveOrder {
    return (_selectedSalesOrderName != null &&
        _selectedSalesOrderName!.isNotEmpty) ||
        (_salesOrderModel?.data?.name != null &&
            _salesOrderModel!.data!.name!.isNotEmpty);
  }

  Future<SalesOrderResponse?> updateSalesOrder(
      String name,
      String customerName,
      String deliveryDate,
      String? setWarehouse,
      List items,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _salesOrderModel = await _apiService!.updateSalesOrder(
        name,
        customerName,
        deliveryDate,
        setWarehouse,
        items,
        context,
        customerDetails: customerDetails,
      );
      return _salesOrderModel;
    } catch (e) {
      _salesOrderModel = null;
      _errorMessage = e.toString(); // already formatted from API service

      _errorMessage = e.toString();
      debugPrint("Provider error updating sales order: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> submitSalesOrder(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService!.submitSalesOrder(name);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("❌ Provider submit error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<List<String>> fetchPrintFormats() async {
    return await _apiService!.fetchPrintFormats();
  }

  // Future<void> downloadSalesOrderPdf(
  //     String name,
  //     String format,
  //     // BuildContext context,
  //     ) async {
  //   await _apiService!.downloadSalesOrderPdf(name, format);
  // }
  Future<String?> downloadSalesOrderPdf(
      String name,
      String format,
      ) async {
    return await _apiService!.downloadSalesOrderPdf(name, format);
  }

  //mode of payment list

  ModeOfPaymentResponse? _modeOfPaymentList;

  ModeOfPaymentResponse? get modeOfPaymentList => _modeOfPaymentList;

  Future<ModeOfPaymentResponse?> modeOfPayment(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _modeOfPaymentList = await _apiService!.modeOfPayemntList(context);
      return _modeOfPaymentList;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //payment type and paid to

  PayymentTypePaidToResponse? _payymentTypePaidToList;

  PayymentTypePaidToResponse? get payymentTypePaidToList =>
      _payymentTypePaidToList;

  Future<PayymentTypePaidToResponse?> payymentTypePaidTo(
      context, String paidTo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payymentTypePaidToList =
          await _apiService!.payemntTypePaidTo(context, paidTo);
      return _payymentTypePaidToList;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //get payment recipt

  GetPaymentEntryResponse? _getPaymentReciptList;

  GetPaymentEntryResponse? get getPaymentReciptList => _getPaymentReciptList;

  Future<GetPaymentEntryResponse?> getPaymentRecipt(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getPaymentReciptList = await _apiService!.getPaymentReecipt(context);
      return _getPaymentReciptList;
    } catch (e) {
      _getPaymentReciptList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //recipt
  ReceiptResponse? _recieptModel;

  ReceiptResponse? get recieptModel => _recieptModel;

  Future<ReceiptResponse?> receipt(
      String party,
      String partyName,
      String postingDate,
      String paidTo,
      double paidAmount,
      double receivedAmount,
      String modeOfPayment,
      String referenceNo,
      String referenceDate,
      context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recieptModel = await _apiService!.receipt(
          party,
          partyName,
          postingDate,
          paidTo,
          paidAmount,
          receivedAmount,
          modeOfPayment,
          referenceNo,
          referenceDate,
          context);
      return _recieptModel;
    } catch (e) {
      _recieptModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  //get sales order

  GetSalesOrderResponse? _getSalesOrderList;

  GetSalesOrderResponse? get getSalesOrderList => _getSalesOrderList;

  Future<GetSalesOrderResponse?> getSalesOrder(
  context,
  int limitStart,
  int pageLength,
) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    // Call a new API method that fetches sales orders sorted by name (descending)
    _getSalesOrderList = await _apiService!.getSalesOrder(
      context,
      limitStart,
      pageLength,
    );
    return _getSalesOrderList;
  } catch (e) {
    _getSalesOrderList = null; // Fixed this also (you were resetting _customerListModel by mistake)
    _errorMessage = e.toString();
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  SalesOrderDetails? _selectedSalesOrder;
  SalesOrderDetails? get selectedSalesOrder => _selectedSalesOrder;

// Original method — keep for Draft (needs form rebuild)
  Future<void> fetchSalesOrderDetails(String orderName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedSalesOrder = await _apiService!.getSalesOrderDetails(orderName);

      if (_selectedSalesOrder != null) {
        setSelectedSalesOrderName(_selectedSalesOrder!.name);
        setSelectedTransactionDate(_selectedSalesOrder!.transactionDate);

        final netTotal = _selectedSalesOrder!.netTotal;
        final total = _selectedSalesOrder!.total;
        setSelectedSalesOrderTotal(
          (netTotal != null && netTotal != 0)
              ? netTotal.toString()
              : (total?.toString() ?? '0'),
        );
      }
    } catch (e) {
      _selectedSalesOrder = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Silent fetch — for dialog preview (no notifyListeners, no rebuild)
//   Future<SalesOrderDetails?> fetchSalesOrderDetailsSilent(String orderName) async {
//     try {
//       final data = await _apiService!.getSalesOrderDetails(orderName);
//       _selectedSalesOrder = data; // updates field silently
//
//       if (data != null) {
//         setSelectedSalesOrderName(data.name);
//         setSelectedTransactionDate(data.transactionDate);
//
//         final netTotal = data.netTotal;
//         final total = data.total;
//         setSelectedSalesOrderTotal(
//           (netTotal != null && netTotal != 0)
//               ? netTotal.toString()
//               : (total?.toString() ?? '0'),
//         );
//       }
//
//       return data;
//     } catch (e) {
//       debugPrint('Error fetching sales order details (silent): $e');
//       return null;
//     }
//   }
  Future<SalesOrderDetails?> fetchSalesOrderDetailsSilent(String orderName) async {
    try {
      final data = await _apiService!.getSalesOrderDetails(orderName);
      // ✅ Do NOT update any provider state — just return the data
      return data;
    } catch (e) {
      debugPrint('Error fetching sales order details (silent): $e');
      return null;
    }
  }
  Future<GetSalesOrderResponse?> getSalesOrdersWithFilters(
      context, {
        String? startDate,
        String? endDate,
        String? salesId,
        String? customerId,
        String? customerName,
      }) async {

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getSalesOrderList =
      await _apiService!.getSalesOrdersWithFilters(
        context,
        startDate: startDate,
        endDate: endDate,
        salesId: salesId,
        customerId: customerId,
        customerName: customerName,
      );
      return _getSalesOrderList;
    } catch (e) {
      _getSalesOrderList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Sales Quotation
  GetQuotationResponse? _quotationList;
  GetQuotationResponse? get quotationList => _quotationList;

  Future<GetQuotationResponse?> getQuotationListFromERP(
      BuildContext context,
      int limitStart,
      int pageLength,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotationList =
      await _apiService?.getQuotationList(context, limitStart, pageLength);
      return _quotationList;
    } catch (e) {
      _quotationList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  CreateQuotationResponse? _quotationResponse;

  CreateQuotationResponse? get quotationResponse => _quotationResponse;


  Map<String, dynamic>? _customerDetails;
  Map<String, dynamic>? get customerDetail => _customerDetails;
  Future<void> fetchCustomerDetailss(String customerName, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerDetails = await _apiService?.getCustomerDetails(customerName, context);
    } catch (e) {
      _customerDetails = null;
      _errorMessage = e.toString();
      debugPrint('Error fetching customer details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchItemDetail({
    required BuildContext context,
    required String itemCode,
    required String currency,
    required double quantity,
    required String customerName,
  }) async {
    try {
      final company = await _sharedPrefService.getCompany();
      final customerData = _customerDetails;
      final priceList = _customerDetails?['selling_price_list'] ?? 'Standard Selling';

      if (company == null) throw Exception('Company not found in SharedPreferences');

      // ✅ Fetch both in parallel
      final results = await Future.wait([
        _apiService!.getItemDetails(
          context: context,
          itemCode: itemCode,
          currency: currency,
          quantity: quantity,
          company: company,
          priceList: priceList,
        ),
        _apiService!.getLastPurchaseRate(itemCode: itemCode),
      ]);

      final itemDetailsResponse = results[0] as Map<String, dynamic>?;
      final lastPurchaseRate = results[1] as double?;

      // ✅ Inject lastPurchaseRate into the response map
      if (itemDetailsResponse != null && itemDetailsResponse['message'] != null) {
        itemDetailsResponse['message']['last_purchase_rate'] = lastPurchaseRate ?? 0.0;
      }

      return itemDetailsResponse;
    } catch (e) {
      debugPrint('Error in provider.fetchItemDetails: $e');
      return null;
    }
  }

  Future<double> getLastPurchaseRate(String itemCode) async {
    try {
      final item = await _apiService?.fetchItemDetails(itemCode);

      if (item != null && item['last_purchase_rate'] != null) {
        return (item['last_purchase_rate'] as num).toDouble();
      }

      return 0.0;
    } catch (e) {
      debugPrint("Error fetching last purchase rate: $e");
      return 0.0;
    }
  }
  Future<CreateQuotationResponse?> createQuotationWithDetails({
    required String partyName,
    required String transactionDate,
    required String validTill,
    required List<Map<String, dynamic>> items,
    required BuildContext context,
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> itemDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotationResponse = await _apiService?.createQuotation(
        partyName,
        transactionDate,
        validTill,
        items,
        context,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
      );

      return _quotationResponse;
    } catch (e) {
      _quotationResponse = null;
      _errorMessage = e.toString();
      debugPrint('Error creating quotation with details: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Map<String, dynamic>? _quotationDetails;
  // Map<String, dynamic>? get quotationDetails => _quotationDetails;
  //
  // Future<void> fetchQuotationDetails(String quotationName, BuildContext context) async {
  //   _isLoading = true;
  //   notifyListeners();
  //   try {
  //     _quotationDetails = await _apiService?.getQuotationDetails(quotationName, context);
  //   } catch (e) {
  //     _quotationDetails = null;
  //     debugPrint('Error fetching quotation details: $e');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  Map<String, dynamic>? _quotationDetails;
  Map<String, dynamic>? get quotationDetails => _quotationDetails;

// Original method — keep this for Draft prefill (it needs to rebuild the form)
  Future<void> fetchQuotationDetails(String quotationName, BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      _quotationDetails = await _apiService?.getQuotationDetails(quotationName, context);
    } catch (e) {
      _quotationDetails = null;
      debugPrint('Error fetching quotation details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Silent fetch — for dialog preview (no notifyListeners, no rebuild)
  Future<Map<String, dynamic>?> fetchQuotationDetailsSilent(String quotationName, BuildContext context) async {
    try {
      final data = await _apiService?.getQuotationDetails(quotationName, context);
      _quotationDetails = data; // still updates the field, just silently
      return data;
    } catch (e) {
      debugPrint('Error fetching quotation details (silent): $e');
      return null;
    }
  }

  void setItemsFromQuotation(List<Map<String, dynamic>> items) {
    _itemsList
      ..clear()
      ..addAll(items.map((i) => Item(
        itemCode: i["item_code"] ?? '',
        name: i["item_name"] ?? '',
        quantity: (i["qty"] ?? 1).toDouble(),
        rate: (i["rate"] ?? 0.0).toDouble(),
        priceListRate: (i["price_list_rate"] ?? 0.0).toDouble(),
        discountPercentage: (i["discount_percentage"] ?? 0.0).toDouble(),
      )));
    notifyListeners();
  }

  Future<bool> updateQuotation({
    required String quotationName,
    required String partyName,
    required String transactionDate,
    required String validTill,
    required List<Map<String, dynamic>> items,
    required BuildContext context,
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> itemDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService?.updateQuotation(
        quotationName,
        partyName,
        transactionDate,
        validTill,
        items,
        context,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
      );

      return success ?? false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<GetQuotationResponse?> getQuotationDateFilter(
      BuildContext context,
      String startDate,
      String endDate,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotationList = await _apiService?.getQuotationDateFilter(context, startDate, endDate);
      return _quotationList;
    } catch (e) {
      _errorMessage = e.toString();
      _quotationList = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<GetQuotationResponse?> getSearchQuotation(
      BuildContext context,
      String quotationName,
      String partyName,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quotationList = await _apiService?.getSearchQuotation(
        context,
        quotationName,
        partyName,
      );
      return _quotationList;
    } catch (e) {
      _errorMessage = e.toString();
      _quotationList = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<bool> submitQuotation(String quotationName, BuildContext context) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     final result = await _apiService?.submitQuotationToERP(quotationName);
  //     if (result == true) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Quotation submitted successfully!')),
  //       );
  //       return true;
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to submit quotation')),
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     debugPrint('Error submitting quotation: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $_errorMessage')),
  //     );
  //     return false;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  Future<bool> submitQuotation(String quotationName, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService?.submitQuotationToERP(quotationName);
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation submitted successfully!')),
        );

        // 🆕 Optionally update the local list immediately if you have the updated data
        // This provides instant feedback before the full refresh
        _updateQuotationStatusInList(quotationName, 'Submitted');
        notifyListeners();

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit quotation')),
        );
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error submitting quotation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_errorMessage')),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// 🆕 Helper method to update quotation status locally
  void _updateQuotationStatusInList(String quotationName, String newStatus) {
    if (_quotationList == null || _quotationList!.data == null) return;

    final index = _quotationList!.data!.indexWhere((q) => q.name == quotationName);
    if (index != -1) {
      _quotationList!.data![index].status = newStatus;
    }
  }

  bool _isServerConnected = false;
  bool get isServerConnected => _isServerConnected;

  Timer? _connectionTimer;

  Future<void> startConnectionCheck() async {
    // Cancel any existing timer to avoid duplication
    _connectionTimer?.cancel();

    // Run immediately on start
    await _checkConnection();

    // Run periodically every 30 seconds
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    final connected = await _apiService!.checkServerConnection();
    if (_isServerConnected != connected) {
      _isServerConnected = connected;
      notifyListeners();
    }
  }

  void stopConnectionCheck() {
    _connectionTimer?.cancel();
  }
  Future<void> downloadQuotationPdf(
      String quotationName,
      BuildContext context, {
        required String formatName,
      }) async {
    try {
      await _apiService?.downloadQuotationPdf(
        quotationName,
        context,
        formatName: formatName,
      );
    } catch (e) {
      debugPrint('Error in provider while downloading PDF: $e');
    }
  }
  Future<List<String>> getQuotationPrintFormats(BuildContext context) async {
    try {
      return await _apiService?.getQuotationPrintFormats(context) ?? [];
    } catch (e) {
      debugPrint('Error fetching print formats: $e');
      return [];
    }
  }
  //Sales Quotation


  Future<GetPaymentEntryResponse?> getReceiptDateFilter(
      context, String startDate, String endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getPaymentReciptList =
          await _apiService!.getReciptDateFilter(context, startDate, endDate);
      return _getPaymentReciptList;
    } catch (e) {
      _getPaymentReciptList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GetPaymentEntryResponse?> getReceiptSearchName(
      context, String customerName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getPaymentReciptList =
          await _apiService!.getReciptNameSearch(context, customerName);
      return _getPaymentReciptList;
    } catch (e) {
      _getPaymentReciptList = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GetSalesOrderResponse?> getSearchCustomerSalesOrder(
    context,
    String customerId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getSalesOrderList =
          await _apiService!.getSearchCustomerSales(context, customerId);
      return _getSalesOrderList;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GetSalesOrderResponse?> getSearchCustomerNameSalesOrder(
    context,
    String customerName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getSalesOrderList =
          await _apiService!.getSearchCustomerNameSales(context, customerName);
      return _getSalesOrderList;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  //  final List<Item> _itemsList = [];

  // List<Item> get itemsList => _itemsList;

  // void addItem(double rate, int quantity,String name) {
  //   _itemsList.add(Item(rate, quantity,name));
  //   notifyListeners();
  // }



  
  final List<Item> _itemsList = [];

  List<Item> get itemsList => _itemsList;

  // Add an item with price_list_rate and discount_percentage
  // void addItem(double rate, double quantity, String name, String itemCode, double priceListRate, double discountPercentage) {
  //   _itemsList.add(Item(
  //     rate: rate,
  //     quantity: quantity,
  //     name: name,
  //     itemCode: itemCode,
  //     priceListRate: priceListRate,
  //     discountPercentage: discountPercentage,
  //   ));
  //   notifyListeners();
  // }
  void addItem(
      double rate,
      double quantity,
      String name,
      String itemCode,
      double priceListRate,
      double discountPercentage,
      String itemTaxTemplate,       // ✅ NEW
      double lastPurchaseRate,      // ✅ NEW
      ) {
    _itemsList.add(Item(
      rate: rate,
      quantity: quantity,
      name: name,
      itemCode: itemCode,
      priceListRate: priceListRate,
      discountPercentage: discountPercentage,
      itemTaxTemplate: itemTaxTemplate,
      lastPurchaseRate: lastPurchaseRate,
    ));
    notifyListeners();
  }

  // Edit an existing item with new values for rate, quantity, price_list_rate, and discount_percentage
  // void editItem(int index, double newRate, double newQuantity, double newPriceListRate, double newDiscountPercentage) {
  //   _itemsList[index] = Item(
  //     rate: newRate,
  //     quantity: newQuantity,
  //     name: _itemsList[index].name,
  //     itemCode: _itemsList[index].itemCode,
  //     priceListRate: newPriceListRate,
  //     discountPercentage: newDiscountPercentage,
  //   );
  //   notifyListeners();
  // }
  void editItem(
      int index,
      double newRate,
      double newQuantity,
      double newPriceListRate,
      double newDiscountPercentage,
      ) {
    _itemsList[index] = Item(
      rate: newRate,
      quantity: newQuantity,
      name: _itemsList[index].name,
      itemCode: _itemsList[index].itemCode,
      priceListRate: newPriceListRate,
      discountPercentage: newDiscountPercentage,

      /// ✅ PRESERVE OLD VALUES
      itemTaxTemplate: _itemsList[index].itemTaxTemplate,
      lastPurchaseRate: _itemsList[index].lastPurchaseRate,
    );
    notifyListeners();
  }
  void deleteItem(int index) {
    _itemsList.removeAt(index);
    notifyListeners();
  }

  void clearItem() {
    _itemsList.clear();
    notifyListeners();
  }
  // ✅ New method: set entire list
  void setItems(List<Item> items) {
    _itemsList
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void clearSelectedSalesOrder() {
    _selectedSalesOrder = null;
    _selectedSalesOrderName = null;
    _selectedSalesOrderTotal = null;
    _itemsList.clear();
    notifyListeners();
  }
  void clearTransactionDate() {
    _selectedTransactionDate = null;
    notifyListeners();
  }

  String? _selectedSalesOrderName;
  String? get selectedSalesOrderName => _selectedSalesOrderName;

  void setSelectedSalesOrderName(String? name) {
    _selectedSalesOrderName = name;
    notifyListeners();
  }
  String? _selectedTransactionDate;

  String? get selectedTransactionDate => _selectedTransactionDate;

  void setSelectedTransactionDate(String? date) {
    _selectedTransactionDate = date;
    notifyListeners();
  }
  String? _selectedSalesOrderTotal;
  String? get selectedSalesOrderTotal => _selectedSalesOrderTotal;

  void setSelectedSalesOrderTotal(String? total) {
    _selectedSalesOrderTotal = total;
    notifyListeners();
  }

  double get totalItemAmount {
    if (itemsList.isEmpty) return 0.0;

    return itemsList.fold(0.0, (sum, item) {
      final rate = item.rate;
      final qty = item.quantity;
      final discount = item.discountPercentage;

      final discountedRate =
      discount! > 0 ? rate * (1 - discount / 100) : rate;

      return sum + (discountedRate * qty);
    });
  }

  double _getCurrentTotal() {
    return double.tryParse(_selectedSalesOrderTotal ?? '0') ?? 0.0;
  }

// Add item amount to total
  void addToTotal(double amount) {
    final currentTotal = _getCurrentTotal();
    final newTotal = currentTotal + amount;
    _selectedSalesOrderTotal = newTotal.toStringAsFixed(2);
    notifyListeners();
  }

// Subtract item amount from total
  void subtractFromTotal(double amount) {
    final currentTotal = _getCurrentTotal();
    final newTotal = (currentTotal - amount).clamp(0, double.infinity);
    _selectedSalesOrderTotal = newTotal.toStringAsFixed(2);
    notifyListeners();
  }
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }
}

