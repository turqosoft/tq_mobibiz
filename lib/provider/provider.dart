import 'dart:convert';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:dio/dio.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart' hide CapabilityProfile, Generator, PaperSize;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart' hide CapabilityProfile, Generator, PaperSize;
import 'package:intl/intl.dart';
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

import '../model/payment_entry.dart';
import '../model/pos_invoice_model.dart';

// import 'dart:typed_data';

import '../utils/invoice_formatter.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer;





class SalesOrderProvider extends ChangeNotifier {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String _domain = '';
  ApiService? _apiService;

  ApiService? get apiService => _apiService;

  Future<void> initialize() async {
    final pref = await _sharedPrefService.getLoginDetails();
    _domain = pref['domain'] ?? '';
    _apiService = ApiService(baseUrl: 'https://$_domain.turqosoft.cloud/api');
    notifyListeners();
  }

  String get domain => _domain;

  void setDomain(String domain) {
    _domain = domain;
    _apiService = ApiService(baseUrl: 'https://$_domain.turqosoft.cloud/api');
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

//     // Login new

//   LoginNewModel? _loginNewModel;
//  // bool _isLoading = false;
//   //String? _errorMessage;

//   LoginNewModel? get loginNewModel => _loginNewModel;
//  // bool get isLoading => _isLoading;
//  // String? get errorMessage => _errorMessage;

//   Future<void> loginNew(String username, String password, String domain) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       _loginModel = await _apiService!.loginNew(username, password, domain);
//     } catch (e) {
//       _loginModel = null;
//       _errorMessage = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
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

  CustomerList? _customerListModel;

  CustomerList? get customerListModel => _customerListModel;

  Future<CustomerList?> customerList(context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch initial customer list
      _customerListModel = await _apiService!.customerList(context);

      // 🔑 Enrich each customer with billing and unpaid details
      for (var customer in _customerListModel?.data ?? []) {
        await _apiService!.fetchCustomerDetailss(customer, context);
        debugPrint(
            "Customer ${customer.name}: billingThisYear=${customer.billingThisYear}, totalUnpaid=${customer.totalUnpaid}"
        );
      }

      return _customerListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
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
  

  //customer category filter
  // Future<CustomerList?> customerGroupFilter(
  //     String customerGroup, BuildContext context) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     _customerListModel =
  //         await _apiService!.customerGroupFilter(customerGroup, context);
  //     return _customerListModel;
  //   } catch (e) {
  //     _customerListModel = null;
  //     _errorMessage = e.toString();
  //     return null;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  //
  // //customer name search list
  // Future<CustomerList?> customerNameSearch(
  //     String customerName, BuildContext context) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     _customerListModel =
  //         await _apiService!.customerNameSearchList(customerName, context);
  //     return _customerListModel;
  //   } catch (e) {
  //     _customerListModel = null;
  //     _errorMessage = e.toString();
  //     return null;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  // filter by customer group
  Future<CustomerList?> customerGroupFilter(
      String customerGroup, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerListModel =
      await _apiService!.customerGroupFilter(customerGroup, context);

      // 🔑 fetch details for each customer in the new list
      for (var customer in _customerListModel?.data ?? []) {
        await _apiService!.fetchCustomerDetailss(customer, context);
      }

      return _customerListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// search by customer name
  Future<CustomerList?> customerNameSearch(
      String customerName, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customerListModel =
      await _apiService!.customerNameSearchList(customerName, context);

      // 🔑 fetch details for each customer in the new list
      for (var customer in _customerListModel?.data ?? []) {
        await _apiService!.fetchCustomerDetailss(customer, context);
      }

      return _customerListModel;
    } catch (e) {
      _customerListModel = null;
      _errorMessage = e.toString();
      return null;
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

  
  List<dynamic> _pickList = [];

  List<dynamic> get pickList => _pickList;
 

  Future<void> fetchPickList(BuildContext context) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      List<dynamic>? newPickList = await _apiService!.fetchPickList(context);

      if (newPickList != null) {
        _pickList = newPickList;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

Future<bool> updatePickedQtyList(BuildContext context, String pickListName, List<Map<String, dynamic>> updatedItems) async {
  if (pickListDetails == null) return false;

  List<dynamic> locations = pickListDetails!["locations"] ?? [];

  // Update only modified locations in the list
  List<Map<String, dynamic>> updatedLocations = locations.map((location) {
    final Map<String, dynamic> loc = Map<String, dynamic>.from(location);
    
    // Find the corresponding updated item
    final updatedItem = updatedItems.firstWhere(
      (item) => item["name"] == loc["name"],
      orElse: () => {},
    );

    if (updatedItem.isNotEmpty) {
      loc["picked_qty"] = updatedItem["picked_qty"];
    }
    return loc;
  }).toList();

  // Call API to update in bulk
  bool success = await _apiService!.updatePickedQty(context, pickListName, updatedLocations);
  
  if (success) {
    pickListDetails!["locations"] = updatedLocations;
    notifyListeners();
  }
  return success;
}



//pick list

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


//   Future<dynamic> createPurchaseReceipt(BuildContext context, PurchaseReceipt receipt) async {
//   _isLoading = true;
//   notifyListeners();

//   // ✅ Corrected to handle dynamic return type
//   final result = await _apiService!.createPurchaseReceipt(context, receipt.toJson());

//   if (result == true) {
//     await fetchPurchaseReceipts(context); // Refresh list after creation
//   }

//   _isLoading = false;
//   notifyListeners();
//   return result; // ✅ Return result (either true or error message)
// }

Future<dynamic> createPurchaseReceipt(BuildContext context, PurchaseReceipt receipt) async {
  _isLoading = true;
  notifyListeners();

  try {
    final result = await _apiService!.createPurchaseReceipt(context, receipt.toJson());

    if (result == true) {
      await fetchPurchaseReceipts(context); // ✅ Refresh list on success
    }

    return result; // ✅ Could be true or a String error
  } catch (e) {
    debugPrint("❌ Provider Error: $e");
    return "An unexpected error occurred while creating the receipt.";
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
          item['purchase_order'] = orderName; // ✅ Main purchase order name
          item['purchase_order_item'] = item['name'] ?? ''; // ✅ Sub-item name
          debugPrint('📝 Updated Item: $item');
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


// save changes for purchase receipt


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
) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _salesInvoiceList = await _apiService!
        .getSearchSalesInvoice(context, invoiceId, customerId);
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
  Future<void> fetchCustomer(BuildContext context, String customerName) async {
    
    iisLoading = true;
    notifyListeners();
    try {
      invoiceCustomerDetails = await _apiService!.fetchInvoiceCustomerDetails(context, customerName);
      debugPrint("✅ Customer Details Fetched: $invoiceCustomerDetails");
    } catch (e) {
      eerrorMessage = "Failed to fetch customer details: $e";
      debugPrint("❌ Error fetching customer: $e");
    }
    iisLoading = false;
    notifyListeners();
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


void clearSearchResults() {
  _itemListModel = null;
  _customerSearchModel = null;
  notifyListeners();
}



//sales invoice
//POS Invoice
//   String? get posProfile => _posProfile;
//   List<String> get modesOfPayment => _modesOfPayment;
//
//   String? _posProfile;
//   List<String> _modesOfPayment = [];
//   /// Fetch POS Profile for current logged in user
//   Future<void> fetchPosProfile() async{
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
//
//     try {
//       _posProfile = await _apiService?.fetchPosProfile();
//       if (_posProfile != null) {
//         debugPrint("✅ POS Profile: $_posProfile");
//         await fetchModesOfPayment(_posProfile!);
//       } else {
//         _errorMessage = "No POS Profile found for currant user";
//       }
//     } catch (e) {
//       _errorMessage = "Failed to fetch POS Profile: $e";
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
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
  Future<CustomerList?> searchCustomer(String customer, context) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _customerSearchModel = await _apiService!.customerSearch(customer, context);
    return _customerSearchModel;
  } on Exception catch (e) {
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

  AttendanceDetails? _attendanceModel;
  //bool _isLoading = false;
  //String? _errorMessage;

  AttendanceDetails? get attendanceModel => _attendanceModel;
  //bool get isLoading => _isLoading;
  // String? get errorMessage => _errorMessage;

  Future<AttendanceDetails?> attendanceDetails(
      String employeeId, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendanceModel = await _apiService!.attendance(employeeId, context);
      return _attendanceModel;
    } catch (e) {
      _attendanceModel = null;
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
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

  CheckInCheckOut? _checkInCheckOut;

  CheckInCheckOut? get checkInCheckOut => _checkInCheckOut;
  bool _isCheckedIn = false;

  bool get isCheckedIn => _isCheckedIn;

  Future<void> checkinOrCheckout(String time, String longitude, String latitude,
      String city, String state, String area, String customer, context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final logType = _isCheckedIn ? "OUT" : "IN";
      _checkInCheckOut = await _apiService!.checkinOrCheckout(
          logType, time, longitude, latitude, city, state, area, customer, context);
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

  // Future<void> initializeCheckinStatus() async {
  //   try {
  //     final latestCheckin = await _apiService!.getLatestCheckinDetailsForEmployee();
  //     if (latestCheckin != null) {
  //       _isCheckedIn = latestCheckin['log_type'] == "IN";
  //
  //       // ✅ Store last customer if exists
  //       if (latestCheckin['customer'] != null && latestCheckin['customer'].toString().isNotEmpty) {
  //         _lastCheckedInCustomer = latestCheckin['customer'];
  //       }
  //
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     debugPrint("Error initializing check-in status: $e");
  //   }
  // }
  Future<void> initializeCheckinStatus() async {
    try {
      final latestCheckin = await _apiService!.getLatestCheckinDetailsForEmployee();
      if (latestCheckin != null) {
        _isCheckedIn = latestCheckin['log_type'] == "IN";

        // ✅ Store last customer only if not empty
        final lastCustomer = latestCheckin['customer'];
        if (lastCustomer != null && lastCustomer.toString().trim().isNotEmpty) {
          _lastCheckedInCustomer = lastCustomer;
        } else {
          _lastCheckedInCustomer = null; // leave blank if empty
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

  Future<SalesOrderResponse?> updateSalesOrder(
      String name,
      String customerName,
      String deliveryDate,
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

  Future<void> fetchSalesOrderDetails(String orderName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedSalesOrder = await _apiService!.getSalesOrderDetails(orderName);

      if (_selectedSalesOrder != null) {
        // ✅ Store name and transaction date
        setSelectedSalesOrderName(_selectedSalesOrder!.name);
        setSelectedTransactionDate(_selectedSalesOrder!.transactionDate);

        // ✅ Store total (prefer net_total if available, else total)
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


  Future<GetSalesOrderResponse?> getSearchSalesOrder(
    context,
    String? salesId,
    String? customerId,
    String? customerName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getSalesOrderList = await _apiService!
          .getSearchSalesOrder(context, salesId!, customerId!, customerName!);
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

  Future<GetSalesOrderResponse?> getSalesOrderDateFilter(
      context, String startDate, String endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _getSalesOrderList = await _apiService!
          .getSalesOrderDateFilter(context, startDate, endDate);
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
  void addItem(double rate, double quantity, String name, String itemCode, double priceListRate, double discountPercentage) {
    _itemsList.add(Item(
      rate: rate,
      quantity: quantity,
      name: name,
      itemCode: itemCode,
      priceListRate: priceListRate,
      discountPercentage: discountPercentage,
    ));
    notifyListeners();
  }

  // Edit an existing item with new values for rate, quantity, price_list_rate, and discount_percentage
  void editItem(int index, double newRate, double newQuantity, double newPriceListRate, double newDiscountPercentage) {
    _itemsList[index] = Item(
      rate: newRate,
      quantity: newQuantity,
      name: _itemsList[index].name,
      itemCode: _itemsList[index].itemCode,
      priceListRate: newPriceListRate,
      discountPercentage: newDiscountPercentage,
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
    _itemsList.clear(); // clear items list too
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
    return itemsList.fold(0.0, (sum, item) => sum + (item.rate * item.quantity));
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
}

