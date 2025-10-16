// ignore_for_file: body_might_complete_normally_nullable

import 'dart:convert';
import 'dart:typed_data';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:sales_ordering_app/model/material_request_model.dart';
import 'package:sales_ordering_app/model/mode_of_payement.dart';
import 'package:sales_ordering_app/model/payment_type_paid_to_response.dart';
import 'package:sales_ordering_app/model/recipet_model.dart';
import 'package:sales_ordering_app/model/sales_order_response.dart';
// import 'package:sales_ordering_app/model/stock_reconciliation_model.dart';
import 'package:sales_ordering_app/model/supplier_pricing_model.dart';
import 'package:sales_ordering_app/model/user_details_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/login.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart'as customer_models;
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer;


// import 'package:sales_ordering_app/view/material_demand/material_demand.dart';
import 'package:sales_ordering_app/model/material_demand_model.dart';

import '../model/pos_invoice_model.dart';
// import 'package:sales_ordering_app/model/sales_invoice_model.dart';

class ApiService {
  final String baseUrl;
  final Dio _dio;
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final apiErrorHandler = ApiErrorHandler();
  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<String> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  // Login
  Future<LoginModel?> login(
      String username, String password, String domain) async {
    try {
      debugPrint('Base URL: $baseUrl');
      debugPrint('Making login request with:');
      debugPrint('Username: $username');
      debugPrint('Password: $password');
      debugPrint('Domain: $domain');

      final response = await _dio.post(
        '/method/login',
        data: {
          'usr': username,
          'pwd': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint("Login Success");
        // Save login details and cookies
        await _sharedPrefService.saveLoginDetails(username, password, domain);
        await _sharedPrefService
            .saveCookies(response.headers.map['set-cookie']?.join('; ') ?? '');
        final loginModel = LoginModel.fromJson(response.data);

        await _sharedPrefService.saveEmailId(username);

        // Save the full name
        await _sharedPrefService.saveFullName(loginModel.fullName ?? '');

        return loginModel;
        //return LoginModel.fromJson(response.data);
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized: Incorrect username, password, or domain.');
        throw Exception(
            'Unauthorized: Incorrect username, password, or domain.');
      } else {
        throw Exception('Failed to login');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to login');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to login');
    }
  }

  //logout
  Future<LoginModel?> logoutService(String username, context) async {
    try {
      debugPrint('Base URL: $baseUrl');
      debugPrint('Making login request with:');
      debugPrint('Username: $username');
      //debugPrint('Password: $password');

      final response = await _dio.post(
        '/method/logout',
        data: {
          'usr': username,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        await _sharedPrefService.clearLoginDetails();
        //   apiErrorHandler.logout(context);
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized: Incorrect username, password, or domain.');
        throw Exception(
            'Unauthorized: Incorrect username, password, or domain.');
      } else {
        throw Exception('Failed to logout');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to logout');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to logout');
    }
  }
  Future<String?> fetchAndSaveDefaultCompany({BuildContext? context}) async {
    const path1 =
        '/method/frappe.core.doctype.session_default_settings.session_default_settings.get_session_default_values';
    const path2 = '/method/frappe.defaults.get_defaults'; // fallback

    try {
      // 1) Include cookies like your Attendance call
      final cookies = await _sharedPrefService.getCookies();

      // --- Primary attempt: session_default_settings ---
      debugPrint('Requesting session defaults from URL: ${baseUrl + path1}');
      final resp1 = await _dio.get(
        path1,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      debugPrint('Response status (session defaults): ${resp1.statusCode}');
      debugPrint('Response data (session defaults): ${resp1.data}');

      if (resp1.statusCode == 200) {
        final company = _extractCompanyFromMessage(resp1.data?['message']);
        if (company != null && company.toString().trim().isNotEmpty) {
          await _sharedPrefService.saveCompany(company);
          debugPrint('✅ Company saved: $company');
          return company;
        }
      } else {
        // optional: apiErrorHandler.handleHttpError(context, resp1);
      }

      // --- Fallback: frappe.defaults.get_defaults (often returns a map) ---
      debugPrint('Fallback: requesting defaults from URL: ${baseUrl + path2}');
      final resp2 = await _dio.get(
        path2,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      debugPrint('Response status (defaults): ${resp2.statusCode}');
      debugPrint('Response data (defaults): ${resp2.data}');

      if (resp2.statusCode == 200) {
        final msg = resp2.data?['message'];
        final fallbackCompany = (msg is Map)
            ? (msg['company'] ?? msg['Company'])
            : null;

        if (fallbackCompany != null && fallbackCompany.toString().trim().isNotEmpty) {
          await _sharedPrefService.saveCompany(fallbackCompany);
          debugPrint('✅ Company (fallback) saved: $fallbackCompany');
          return fallbackCompany;
        }
      } else {
        // optional: apiErrorHandler.handleHttpError(context, resp2);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch company: $e');
    }
    return null;
  }

  // Handles: stringified JSON array, real List, or Map
  String? _extractCompanyFromMessage(dynamic message) {
    if (message == null) return null;

    // If it's a JSON string, decode it
    if (message is String) {
      try {
        final decoded = jsonDecode(message);
        return _extractCompanyFromMessage(decoded);
      } catch (_) {
        return null;
      }
    }

    // If it's already a list of settings: [{fieldname: company, default: X}, ...]
    if (message is List) {
      for (final item in message) {
        if (item is Map &&
            (item['fieldname'] == 'company' || item['fieldname'] == 'Company')) {
          final value = item['default'] ?? item['value'];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
      return null;
    }

    // Some versions may return a map of defaults
    if (message is Map) {
      final value = message['company'] ?? message['Company'];
      return (value == null || value.toString().trim().isEmpty)
          ? null
          : value.toString();
    }

    return null;
  }


  //Home Tile visibility
  Future<HomeTileResponse?> homeTile(BuildContext context) async {
    final url =
        '/method/tqerp_mobibiz_admin.tqerp_mobibiz_admin.doctype.tq_mobile_user_permission.tq_mobile_user_permission.mobile_user_permission_list';
    print(" details::::$url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data in employee: ${response.data}');

      // if (response.statusCode == 200) {
      //   final details = HomeTileResponse.fromJson(response.data);

      //   return details;
      // } else {
      //   apiErrorHandler.handleHttpError(context, response);
      // }
      if (response.statusCode == 200 && response.data != null) {
  final details = HomeTileResponse.fromJson(response.data);
  if (details.message == null || details.message!.isEmpty) {
    throw Exception("No home tiles available for this user.");
  }
  return details;
}

      //   else if (response.statusCode == 401) {
      //   debugPrint('Unauthorized: Incorrect username, password, or domain.');
      //   throw Exception('Unauthorized: Incorrect username, password, or domain.');
      // } else if (response.data['session_expired'] == 1) {
      //   debugPrint('Session expired. Logging out...');
      //    apiErrorHandler.logout(context); .
      //   throw Exception('Session expired. Please log in again.');
      // } else {
      //   throw Exception('Failed to fetch data');
      // }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }


  // Attendance
  Future<AttendanceDetails?> attendance(String employeeId, context) async {
    var url =
        '/resource/Attendance?fields=["employee_name","status","attendance_date","employee"]&filters=[["employee","=","$employeeId"]]';

    try {
      // Retrieve cookies from shared preferences
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting attendance data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response attendance status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return AttendanceDetails.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch attendance data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch attendance data');
    }
  }

  Future<String> getDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.id ?? 'unknown'; // ✅ only `id` available now
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else {
      return 'unsupported-platform';
    }
  }
  //checkin / checkout
  // Future<CheckInCheckOut?> checkinOrCheckout(
  //     String logType,
  //     String time,
  //     String longitude,
  //     String latitude,
  //     String city,
  //     String state,
  //     String area,
  //     context) async {
  //
  //   String? employeeId = await _sharedPrefService.getEmployeeId();
  //   String deviceId = await getDeviceId(); // <-- Get device ID here
  //
  //   const url = '/resource/Employee Checkin';
  //   print(
  //       "EmployeeId:$employeeId  logType:$logType time:$time longitude:$longitude latitude:$latitude city:$city state:$state area:$area deviceId:$deviceId");
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     debugPrint('Requesting  data from URL: ${baseUrl + url}');
  //     final response = await _dio.post(
  //       url,
  //       data: {
  //         "employee": employeeId,
  //         "log_type": logType,
  //         "time": time,
  //         "longitude": longitude,
  //         "latitude": latitude,
  //         "city": city,
  //         "state": state,
  //         "area": area,
  //         "device_id": deviceId, // <-- Add it in the request body
  //       },
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return CheckInCheckOut.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch  data');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch  data');
  //   }
  // }
  Future<CheckInCheckOut?> checkinOrCheckout(
      String logType,
      String time,
      String longitude,
      String latitude,
      String city,
      String state,
      String area,
      String customer, // 👈 add this
      context) async {

    String? loggedInUser = await getLoggedInUserIdentifier(); // 👈 get email/user_id
    String deviceId = await getDeviceId();

    if (loggedInUser == null) {
      throw Exception("Unable to get logged-in user identifier");
    }

    // ✅ Fetch employee ID using the user_id from ERPNext
    final employeeResponse = await _dio.get(
      '/resource/Employee',
      queryParameters: {
        'filters': '[["user_id", "=", "$loggedInUser"]]',
        'fields': '["name"]'
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': await _sharedPrefService.getCookies(),
        },
      ),
    );

    if (employeeResponse.statusCode != 200 ||
        employeeResponse.data['data'] == null ||
        employeeResponse.data['data'].isEmpty) {
      throw Exception("Employee not found for logged-in user $loggedInUser");
    }

    String employeeId = employeeResponse.data['data'][0]['name'];

    const url = '/resource/Employee Checkin';
    debugPrint(
        // "EmployeeId:$employeeId logType:$logType time:$time longitude:$longitude latitude:$latitude city:$city state:$state area:$area deviceId:$deviceId");
        "EmployeeId:$employeeId logType:$logType customer:$customer time:$time longitude:$longitude latitude:$latitude city:$city state:$state area:$area deviceId:$deviceId");

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: {
          "employee": employeeId,
          "log_type": logType,
          "time": time,
          "longitude": longitude,
          "latitude": latitude,
          "city": city,
          "state": state,
          "area": area,
          "device_id": deviceId,
          "customer": customer, // 👈 send customer
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CheckInCheckOut.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch data');
    }

    return null;
  }


  // Future<List<customer.Data>> fetchCustomers(BuildContext context) async {
  //   // ✅ Add filters and limit parameters
  //   const url = '/resource/Customer?filters=[["Customer","disabled","=",0]]&limit_page_length=None';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.get(
  //       url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     debugPrint('Customer response data: ${response.data}');
  //
  //     if (response.statusCode == 200 && response.data != null) {
  //       final List<dynamic> list = response.data['data'];
  //
  //       // ✅ Convert into List<customer.Data>
  //       return list.map((e) {
  //         return customer.Data.fromJson(e as Map<String, dynamic>);
  //       }).toList();
  //
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       return [];
  //     }
  //   } catch (e) {
  //     debugPrint('Exception (customers): $e');
  //     throw Exception('Failed to fetch customers');
  //   }
  // }
  Future<List<customer.Data>> fetchCustomers(BuildContext context) async {
    // Fetch customers with latitude and longitude fields
    const url =
        '/resource/Customer?fields=["name","customer_name","latitude","longitude"]'
        '&filters=[["Customer","disabled","=",0]]&limit_page_length=None';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      debugPrint('Customer response data: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['data'];
        return list
            .map((e) => customer.Data.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return [];
      }
    } catch (e) {
      debugPrint('Exception (customers): $e');
      throw Exception('Failed to fetch customers');
    }
  }


  Future<String?> getLatestLogTypeForEmployee() async {
    String? employeeId = await _sharedPrefService.getEmployeeId();

    const url = '/resource/Employee Checkin';
    final queryParams =
        '?filters=[["employee","=","$employeeId"]]&fields=["log_type"]&order_by=creation desc&limit_page_length=1';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '$url$queryParams',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data'].isNotEmpty) {
        return response.data['data'][0]['log_type']; // "IN" or "OUT"
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching latest log_type: $e');
      return null;
    }
  }
  Future<Map<String, dynamic>?> getLatestCheckinDetailsForEmployee() async {
    String? employeeId = await _sharedPrefService.getEmployeeId();

    const url = '/resource/Employee Checkin';
    final queryParams =
        '?filters=[["employee","=","$employeeId"]]'
        '&fields=["log_type","customer"]'
        '&order_by=creation desc&limit_page_length=1';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '$url$queryParams',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data'].isNotEmpty) {
        return response.data['data'][0]; // contains log_type and customer
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching latest checkin details: $e');
      return null;
    }
  }


  //user details
  Future<UserDetails?> userDetails(String email, context) async {
    final url =
        '/resource/User?filters=[["User", "name","=", "$email"]]&fields=["name","email","full_name"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return UserDetails.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //customer details
  Future<CustomerDetails?> customerDetails(String email, context) async {
    final url = '/User/$email';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CustomerDetails.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //customer list
  Future<CustomerList?> customerList(context) async {
    final url =
        '/resource/Customer?fields=["name","tax_id","gstin","territory","customer_primary_contact","customer_primary_address","primary_address","mobile_no","email_id","tax_category","territory","customer_group"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CustomerList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }
  Future<Map<String, dynamic>?> fetchCustomerLocation(String customerName, BuildContext context) async {
    final url = '/resource/Customer/$customerName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Fetching customer location from: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data["data"]; // standard frappe resource response
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch location data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch location data');
    }
    return null;
  }
  Future<void> saveCustomerLocation(
      String customerName, double latitude, double longitude, BuildContext context) async {
    final url = '/resource/Customer/$customerName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Saving customer location to: ${baseUrl + url}');
      final response = await _dio.put(
        url,
        data: {
          "latitude": latitude,
          "longitude": longitude,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Save response status: ${response.statusCode}');
      debugPrint('Save response data: ${response.data}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location saved successfully.")),
        );
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save location.")),
      );
    } catch (e) {
      debugPrint('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving location.")),
      );
    }
  }


  Future<void> fetchCustomerDetailss(customer_models.Data customer, BuildContext context) async {
    final url = '/method/frappe.desk.form.load.getdoc?doctype=Customer&name=${customer.name}';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['docs'][0];
        final dashboard = data['__onload']['dashboard_info'][0];

        customer.billingThisYear = (dashboard['billing_this_year'] ?? 0).toDouble();
        customer.totalUnpaid = (dashboard['total_unpaid'] ?? 0).toDouble();

      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
    }
  }

  // Future<Map<String, dynamic>?> fetchGeneralLedger(
  //     BuildContext context, String customer, String fromDate, String toDate) async {
  //   const url = "/method/frappe.desk.query_report.run";
  //
  //   try {
  //     // Get cookies
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     // Get company from SharedPreferences
  //     final company = await _sharedPrefService.getCompany();
  //     if (company == null || company.isEmpty) {
  //       debugPrint("No company found in SharedPreferences");
  //       return null;
  //     }
  //
  //     final body = {
  //       "report_name": "General Ledger",
  //       "filters": {
  //         "company": company,
  //         "from_date": fromDate,
  //         "to_date": toDate,
  //         "account": [],
  //         "party_type": "Customer",
  //         "party": [customer],
  //         "party_name": customer,
  //         "categorize_by": "Categorize by Voucher (Consolidated)",
  //         "cost_center": [],
  //         "branch": [],
  //         "project": [],
  //         "include_dimensions": 1,
  //         "include_default_book_entries": 1
  //       }
  //     };
  //
  //     final response = await _dio.post(
  //       url,
  //       data: body,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = response.data;
  //
  //       // ✅ Case 1: Prepared report - need to re-fetch using GET with query params
  //       if (data is Map<String, dynamic> &&
  //           data["message"]?["prepared_report"] == true) {
  //         debugPrint("Prepared report detected. Fetching fresh data...");
  //
  //         final queryParams = {
  //           "report_name": "General Ledger",
  //           "filters": jsonEncode({
  //             "company": company,
  //             "from_date": fromDate,
  //             "to_date": toDate,
  //             "account": [],
  //             "party_type": "Customer",
  //             "party": [customer],
  //             "party_name": customer,
  //             "categorize_by": "Categorize by Voucher (Consolidated)",
  //             "cost_center": [],
  //             "branch": [],
  //             "project": [],
  //             "include_dimensions": 1,
  //             "include_default_book_entries": 1
  //           }),
  //           "ignore_prepared_report": "false",
  //           "are_default_filters": "false",
  //         };
  //
  //         final freshResponse = await _dio.get(
  //           url,
  //           queryParameters: queryParams,
  //           options: Options(
  //             headers: {
  //               'Content-Type': 'application/json',
  //               'Cookie': cookies,
  //             },
  //             validateStatus: (status) => status! < 500,
  //           ),
  //         );
  //
  //         if (freshResponse.statusCode == 200) {
  //           return freshResponse.data;
  //         } else {
  //           apiErrorHandler.handleHttpError(context, freshResponse);
  //         }
  //       }
  //
  //       // ✅ Case 2: Normal ledger data
  //       return data;
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } catch (e) {
  //     debugPrint("fetchGeneralLedger Error: $e");
  //   }
  //   return null;
  // }
  Future<Map<String, dynamic>?> fetchGeneralLedger(
      BuildContext context,
      String customer,
      String fromDate,
      String toDate,
      ) async {
    const url = "/method/tqerp_concord.api.get_general_ledger";

    try {
      final cookies = await _sharedPrefService.getCookies();
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        debugPrint("No company found in SharedPreferences");
        return null;
      }

      final queryParams = {
        "party_type": "Customer",
        "from_date": fromDate,
        "to_date": toDate,
        "party": customer,
        "company": company,
      };

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        apiErrorHandler.handleHttpError(context, response);

      }
    } catch (e) {
      debugPrint("fetchGeneralLedger Error: $e");
    }
    return null;
  }



  Future<Uint8List?> generatePdfFromHtml(
      BuildContext context, String html) async {
    const url = "/method/frappe.utils.print_format.report_to_pdf";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: {
          "html": html,
          "orientation": "Landscape",
          "blob": "1",
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': cookies,
          },
          responseType: ResponseType.bytes, // very important to get PDF as bytes
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // PDF bytes
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint("generatePdfFromHtml Error: $e");
    }
    return null;
  }

//material request

Future<Map<String, dynamic>?> fetchMaterialRequests(
    BuildContext context,
    String ownerEmail,
    int limitStart,
    int limitPageLength,
    {String? fromDate, String? toDate}) async {
  
  String filters = '[["Material Request","owner","=","$ownerEmail"]]';

  if (fromDate != null && toDate != null) {
    filters =
        '[["Material Request","owner","=","$ownerEmail"],["schedule_date",">=","$fromDate"],["schedule_date","<=","$toDate"]]';
  }

  final url =
      '/resource/Material Request?filters=$filters&fields=["name","material_request_type","status","set_warehouse","transaction_date","schedule_date"]&limit_start=$limitStart&limit_page_length=$limitPageLength';

  final countUrl = '/resource/Material Request?filters=$filters&limit_page_length=0';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Fetching Material Requests from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Content-Type': 'application/json', 'Cookie': cookies},
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Fetching Total Count from URL: ${baseUrl + countUrl}');
    final countResponse = await _dio.get(
      countUrl,
      options: Options(
        headers: {'Content-Type': 'application/json', 'Cookie': cookies},
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200 && countResponse.statusCode == 200) {
      return {
        "data": response.data['data'],
        "total_count": countResponse.data['data']?.length ?? 0
      };
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    throw Exception('Failed to fetch Material Requests');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Material Requests');
  }
}


  //material request

  //mtq detail

  Future<Map<String, dynamic>?> fetchMaterialRequestDetails(
      BuildContext context, String requestName) async {
    final url = '/resource/Material Request/$requestName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint(
          'Requesting Material Request Details from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return the material request details
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Material Request details');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Material Request details');
    }
  }
  //mtq detail

  //mtq put edit

  Future<bool> updateMaterialRequest(BuildContext context, String requestName,
      Map<String, dynamic> updatedData) async {
    final url = '/resource/Material Request/$requestName';

    try {
      // updatedData['docstatus'] = 1;
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Updating Material Request at URL: ${baseUrl + url}');
      final response = await _dio.put(
        url,
        data: updatedData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return true; // Update was successful
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to update Material Request');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to update Material Request');
    }
  }

  //mtq put

  //mtq form
  Future<void> createMaterialRequest(
      BuildContext context, MaterialRequest request) async {
    final url = '/resource/Material Request';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
        data: {
          'data': request.toJson(),
        },
      );

      if (response.statusCode != 200) {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to create Material Request');
    } catch (e) {
      throw Exception('Failed to create Material Request');
    }
  }

  //mtq form

  Future<List<Map<String, String>>> fetchItems(String query) async {
    final isNumeric = int.tryParse(query) != null;
    final url = isNumeric
        ? '/resource/Item?filters=[["Item","item_code","=","$query"]]&fields=["item_name","item_code"]'
        : '/resource/Item?or_filters=[["Item","item_name","like","%$query%"],["Item","item_code","like","%$query%"]]&filters=[["Item","is_stock_item","=","1"]]&fields=["item_name","item_code"]';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, String>>.from(
            response.data['data'].map((item) => {
                  'item_name': item['item_name'] as String,
                  'item_code': item['item_code'] as String,
                }));
      } else {
        throw Exception('Failed to fetch items');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch items');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch items');
    }
  }

  //mtq search

//mtq wh
  Future<List<String>> fetchWarehouseCodes(String query) async {
    final url =
        '/resource/Warehouse?filters=[["Warehouse","name","like","%$query%"]]&fields=["name"]';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<String>.from(
            response.data['data'].map((item) => item['name']));
      } else {
        throw Exception('Failed to fetch warehouse codes');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch warehouse codes');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch warehouse codes');
    }
  }
//mtq wh

//job card list
  Future<List<dynamic>?> fetchJobCards(
      BuildContext context, int limitStart, int limitPageLength) async {
    final url =
        '/resource/Job Card?fields=["name","work_order","production_item","status","for_quantity","operation","workstation_type","wip_warehouse"]&limit_start=$limitStart&limit_page_length=$limitPageLength';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Job Cards from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      // Add this line to print the full response data
      debugPrint('Response data: ${response.data}');

      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.data['data']; // Return the job cards
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Job Cards');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Job Cards');
    }
  }

//job card list

//job card detail

  Future<Map<String, dynamic>?> fetchJobCardDetails(
      BuildContext context, String jobCardName) async {
    final url = '/resource/Job Card/$jobCardName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Job Card Details from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return the job card details
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Job Card details');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Job Card details');
    }
  }

//job card detail

//jm

  Future<bool> submitMaterialTransfer(
      BuildContext context, Map<String, dynamic> materialTransferData) async {
    final url = '/resource/Stock Entry';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Submitting Material Transfer to URL: ${baseUrl + url}');
      debugPrint('Payload: ${materialTransferData.toString()}');

      final response = await _dio.post(
        url,
        data: materialTransferData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Successfully submitted
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to submit Material Transfer');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to submit Material Transfer');
    }
  }

//jm

// Fetch employees based on name or code for search

  Future<List<dynamic>?> fetchEmployees(
      BuildContext context, String employeeQuery) async {
    // Build filters dynamically
    final filters = [
      ["Employee", "name", "like", "%$employeeQuery%"],
      ["Employee", "employee_name", "like", "%$employeeQuery%"],
    ];

    // Encode filters for the URL
    final url =
        '/resource/Employee?fields=["name","employee_name"]&or_filters=${Uri.encodeComponent(jsonEncode(filters))}';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Employees from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return the employees
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching Employees: $e');
      throw Exception('Failed to fetch Employees');
    }
  }

//search job card employee
//update  employee to job card
  Future<void> updateJobCard(BuildContext context, String jobCardName,
      Map<String, dynamic> payload) async {
    final url = '/resource/Job Card/$jobCardName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.put(
        url,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode != 200) {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint('Error updating job card: $e');
      throw Exception('Failed to update Job Card');
    }
  }
//update employee

//employee name fetching to display
  Future<String?> fetchEmployeeName(
      BuildContext context, String employeeId) async {
    final url =
        '/resource/Employee?fields=["name","employee_name"]&filters=[["name","=","$employeeId"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data.isNotEmpty) {
          return data.first['employee_name'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching employee name: $e');
      return null;
    }
  }

//employee name fetching to display

//
//work order list
  Future<List<dynamic>?> fetchWorkOrders(
      BuildContext context, int limitStart, int limitPageLength) async {
    final url =
        '/resource/Work Order?fields=["production_item","item_name","name","status","creation"]&limit_start=$limitStart&limit_page_length=$limitPageLength';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Work Orders from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return the work orders
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Work Orders');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Work Orders');
    }
  }
//work order list

//work order count

  Future<int> fetchWorkOrderCount(BuildContext context,
      {String? searchQuery}) async {
    final filters = [];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filters.add(["item_name", "like", "%$searchQuery%"]);
      filters.add(["production_item", "like", "%$searchQuery%"]);
      filters.add(["name", "like", "%$searchQuery%"]);
    }

    final url =
        '/resource/Work Order?fields=["count(name)"]&or_filters=${Uri.encodeComponent(jsonEncode(filters))}';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Work Order Count from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'][0]['count(name)'] ?? 0;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return 0;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch Work Order Count');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Work Order Count');
    }
  }

//work order count

//wk filter
  Future<List<dynamic>?> searchWorkOrders(
      BuildContext context, String? searchQuery) async {
    final filters = [];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filters.add(["Work Order", "item_name", "like", "%$searchQuery%"]);
      filters.add(["Work Order", "production_item", "like", "%$searchQuery%"]);
      filters.add(["Work Order", "name", "like", "%$searchQuery%"]);
    }

    final url =
        '/resource/Work Order?fields=["production_item","item_name","name","status","creation"]&or_filters=${Uri.encodeComponent(jsonEncode(filters))}';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Searching Work Orders from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return filtered work orders
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } catch (e) {
      debugPrint('Error searching Work Orders: $e');
      throw Exception('Failed to search Work Orders');
    }
  }
//wk filter

// material demand
Future<String?> getLoggedInUserIdentifier() async {
  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      '/method/frappe.auth.get_logged_user',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data['message']; // The actual User.name
    } else {
      debugPrint('Failed to get logged in user: ${response.data}');
      return null;
    }
  } catch (e) {
    debugPrint('Error getting logged in user: $e');
    return null;
  }
}

Future<List<dynamic>?> fetchMaterialDemands(
  BuildContext context,
  String userIdentifier,
  DateTime? fromDate,
  DateTime? toDate, {
  int offset = 0,
  int limit = 60,
}) async {
  List<List<dynamic>> filters = [
    ["Material Demand", "owner", "=", userIdentifier]
  ];

  if (fromDate != null) {
    filters.add(["schedule_date", ">=", fromDate.toIso8601String()]);
  }
  if (toDate != null) {
    filters.add(["schedule_date", "<=", toDate.toIso8601String()]);
  }

  final filterString = Uri.encodeComponent(jsonEncode(filters));
  final url =
      '/resource/Material Demand?filters=$filterString&fields=["name","docstatus","schedule_date","creation","document_status"]&limit_start=$offset&limit_page_length=$limit';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Material Demands from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200) {
      return response.data['data'];
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Material Demands');
  }
}

Future<int> fetchMaterialDemandCount(
  BuildContext context,
  DateTime? fromDate,
  DateTime? toDate,
) async {
  try {
    final actualUser = await getLoggedInUserIdentifier();

    if (actualUser == null) {
      throw Exception('Failed to identify logged-in user');
    }

    List<List<dynamic>> filters = [
      ["Material Demand", "owner", "=", actualUser]
    ];

    if (fromDate != null) {
      filters.add(["schedule_date", ">=", fromDate.toIso8601String()]);
    }
    if (toDate != null) {
      filters.add(["schedule_date", "<=", toDate.toIso8601String()]);
    }

    final filterString = Uri.encodeComponent(jsonEncode(filters));
    final url = '/resource/Material Demand?fields=["count(name)"]&filters=$filterString';

    final cookies = await _sharedPrefService.getCookies();
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200) {
      return response.data['data'][0]['count(name)'];
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return 0;
    }
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Material Demand Count');
  }
}

//material demand

  Future<Map<String, dynamic>?> fetchMaterialDemandDetails(
      BuildContext context, String demandName) async {
    final url = '/resource/Material Demand/$demandName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint(
          'Requesting Material Demand Details from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data']; // Return the material demand details
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Material Demand details');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Material Demand details');
    }
  }

//material d create
// Future<void> createMaterialDemand(
//   BuildContext context,
//   MaterialDemand demand,
// ) async {
//   final url = '/resource/Material Demand';
//
//   try {
//     final cookies = await _sharedPrefService.getCookies();
//     final currentUser = await getLoggedInUserIdentifier();
//
//     if (currentUser == null) {
//       throw Exception('Logged in user not found. Please log in again.');
//     }
//
//     final additionalData = await fetchAdditionalFields(currentUser);
//
//     if (additionalData['user_types'] != 'Customer' && additionalData['user_types'] != 'POS') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: You are not authorized to create Material Demand.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     final customerDetails = await fetchCustomerDetail(additionalData['customer_info']);
//     final customerType = customerDetails['customer_type'];
//     final purpose = (customerType == 'Own Stalls') ? 'Material Transfer' : 'Sales';
//
//
//     final requestData = {
//       ...demand.toJson(),
//       'user': currentUser,
//       'customer_info': additionalData['customer_info'],
//       'user_types': additionalData['user_types'],
//       'territory': customerDetails['territory'],
//       'branch': customerDetails['branch'],
//       'purpose': purpose, // <-- Set dynamically
//
//     };
//
//     final response = await _dio.post(
//       url,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) => status! < 500,
//       ),
//       data: {
//         'data': requestData,
//       },
//     );
//
//     if (response.statusCode != 200) {
//       apiErrorHandler.handleHttpError(context, response);
//       throw Exception('Failed to create Material Demand: ${response.data}');
//     }
//   } catch (e) {
//     debugPrint('Exception: $e');
//     throw Exception('Failed to create Material Demand');
//   }
// }
  Future<bool> createMaterialDemand(
      BuildContext context,
      MaterialDemand demand,
      ) async {
    final url = '/resource/Material Demand';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final currentUser = await getLoggedInUserIdentifier();

      if (currentUser == null) {
        throw Exception('Logged in user not found. Please log in again.');
      }

      final additionalData = await fetchAdditionalFields(currentUser);

      if (additionalData['user_types'] != 'Customer' && additionalData['user_types'] != 'POS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: You are not authorized to create Material Demand.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final customerDetails = await fetchCustomerDetail(additionalData['customer_info']);
      final customerType = customerDetails['customer_type'];
      final purpose = (customerType == 'Own Stalls') ? 'Material Transfer' : 'Sales';

      final requestData = {
        ...demand.toJson(),
        'user': currentUser,
        'customer_info': additionalData['customer_info'],
        'user_types': additionalData['user_types'],
        'territory': customerDetails['territory'],
        'branch': customerDetails['branch'],
        'purpose': purpose,
      };

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          'data': requestData,
        },
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return true;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return false;
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return false;
    }
  }


  Future<Map<String, dynamic>> fetchAdditionalFields(String userEmail) async {
  final customerUrl = '/resource/User/$userEmail'; // Construct the URL dynamically

  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      customerUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch additional fields: ${response.data}');
    }

    // Extract necessary fields from the response data
    final data = response.data['data'];
    return {
      'customer_info': data['customer_info'] ?? '', // Extract customer_info
      'user_types': data['user_types'] ?? '',       // Extract user_types
    };
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to fetch additional fields');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch additional fields');
  }
}


Future<Map<String, String>> fetchCustomerDetail(String customerName) async {
  final customerUrl = '/resource/Customer/$customerName';

  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      customerUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch customer details: ${response.data}');
    }

    final data = response.data['data'];
    return {
      'territory': data['territory'] ?? '',
      'branch': data['branch'] ?? '',
      'customer_type': data['customer_type'] ?? '', // <-- Add this

    };
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to fetch customer details');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch customer details');
  }
}


//mdfi

Future<List<dynamic>?> fetchItemsDemand(
    BuildContext context, String? query) async {
  final filters = [];
  if (query != null && query.isNotEmpty) {
    filters.add(["Item", "item_code", "like", "%$query%"]);
    filters.add(["Item", "item_name", "like", "%$query%"]);
  }

  final url =
      '/resource/Item?fields=["item_name","item_code","stock_uom"]&or_filters=${Uri.encodeComponent(jsonEncode(filters))}&filters=${Uri.encodeComponent(jsonEncode([
        ["Item", "is_stock_item", "=", "1"],
        ["published_customer", "=", "1"]
      ]))}';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Fetching Items Demand from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return response.data['data']; // Return the fetched items
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching Items Demand: $e');
    throw Exception('Failed to fetch Items Demand');
  }
}

//mdfi
//md put

  Future<bool> updateMaterialDemand(BuildContext context, String demandName,
      Map<String, dynamic> updatedData) async {
    final url = '/resource/Material Demand/$demandName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Updating Material Demand at URL: ${baseUrl + url}');
      final response = await _dio.put(
        url,
        data: updatedData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return true; // Update was successful
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to update Material Demand');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to update Material Demand');
    }
  }



//md put

//material demand

//salesreturn


// Future<String?> _fetchCustomerInfo(BuildContext context) async {
//   try {
//     final userEmail = await _sharedPrefService.getEmailId();
//     if (userEmail == null || userEmail.isEmpty) {
//       throw Exception('User email is missing');
//     }

//     final userUrl = '/resource/User/$userEmail';
//     final cookies = await _sharedPrefService.getCookies();

//     debugPrint('Fetching customer_info from: ${baseUrl + userUrl}');
//     final userResponse = await _dio.get(
//       userUrl,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) => status! < 500,
//       ),
//     );

//     if (userResponse.statusCode == 200) {
//       final customerInfo = userResponse.data['data']['customer_info'];
//       if (customerInfo == null || customerInfo.isEmpty) {
//         throw Exception('No customer_info found for user');
//       }
//       return customerInfo;
//     } else {
//       apiErrorHandler.handleHttpError(context, userResponse);
//       return null;
//     }
//   } catch (e) {
//     debugPrint('Error fetching customer_info: $e');
//     return null;
//   }
// }
Future<String?> _fetchCustomerInfo(BuildContext context) async {
  try {
    final userId = await getLoggedInUserIdentifier();
    if (userId == null || userId.isEmpty) {
      throw Exception('User identifier is missing');
    }

    final userUrl = '/resource/User/$userId';
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Fetching customer_info from: ${baseUrl + userUrl}');
    final userResponse = await _dio.get(
      userUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (userResponse.statusCode == 200) {
      final customerInfo = userResponse.data['data']['customer_info'];
      if (customerInfo == null || customerInfo.isEmpty) {
        throw Exception('No customer_info found for user');
      }
      return customerInfo;
    } else {
      apiErrorHandler.handleHttpError(context, userResponse);
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching customer_info: $e');
    return null;
  }
}


Future<List<dynamic>?> fetchDeliveryNotes(
  BuildContext context, {
  int offset = 0,
  int limit = 60,
  String? fromDate,
  String? toDate,
}) async {
  try {
    final customerInfo = await _fetchCustomerInfo(context);
    if (customerInfo == null) {
      throw Exception('Failed to retrieve customer information');
    }

    List<List<dynamic>> filters = [
      ["Delivery Note", "customer", "=", customerInfo],
    ];

    if (fromDate != null && toDate != null) {
      filters.add(["posting_date", ">=", fromDate]);
      filters.add(["posting_date", "<=", toDate]);
    }

    final filterString = Uri.encodeComponent(jsonEncode(filters));
    final url =
        '/resource/Delivery Note?filters=$filterString&fields=["name","creation","docstatus","is_return","title","status","grand_total","posting_date","selling_price_list"]&limit_start=$offset&limit_page_length=$limit';

    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Delivery Notes from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return response.data['data'];
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching delivery notes: $e');
    throw Exception('Failed to fetch Delivery Notes');
  }
}

Future<int> fetchDeliveryNotesCount(
  BuildContext context, {
  String? fromDate,
  String? toDate,
}) async {
  try {
    final customerInfo = await _fetchCustomerInfo(context);
    if (customerInfo == null) {
      throw Exception('Failed to retrieve customer information');
    }

    List<List<dynamic>> filters = [
      ["Delivery Note", "customer", "=", customerInfo],
    ];

    if (fromDate != null && toDate != null) {
      filters.add(["posting_date", ">=", fromDate]);
      filters.add(["posting_date", "<=", toDate]);
    }

    final filterString = Uri.encodeComponent(jsonEncode(filters));
    final url =
        '/resource/Delivery Note?fields=["count(name)"]&filters=$filterString';

    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Delivery Notes Count from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return response.data['data'][0]['count(name)'];
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return 0;
    }
  } catch (e) {
    debugPrint('Error fetching delivery notes count: $e');
    throw Exception('Failed to fetch Delivery Notes Count');
  }
}



  Future<Map<String, dynamic>?> fetchDeliveryNoteItems(
      BuildContext context, String deliveryNoteName) async {
    final url = '/resource/Delivery Note/$deliveryNoteName';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Delivery Note Details from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data[
            'data']; // Ensure this includes 'customer' and 'company_address'
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch Delivery Note Items');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Delivery Note Items');
    }
  }


Future<void> returnItems(
    BuildContext context, Map<String, dynamic> data) async {
  final url = '/resource/Delivery Note';

  final cookies = await _sharedPrefService.getCookies();
  debugPrint('Request Data: ${jsonEncode(data)}');

  final response = await _dio.post(
    url,
    options: Options(
      headers: {
        'Content-Type': 'application/json',
        'Cookie': cookies,
      },
      validateStatus: (status) => status! < 500,
    ),
    data: {'data': data},  // Sending all items together in one request
  );

  if (response.statusCode == 200) {
    debugPrint('All items returned successfully.');
  } else {
    apiErrorHandler.handleHttpError(context, response);
    throw Exception('Failed to return items: ${response.data}');
  }
}


//salesreturn

//SupplierPricing


  // Future<List<dynamic>?> fetchItemPrices(
  //     BuildContext context, int limitStart,
  //     [int limitPageLength = 100, String? userEmail]) async { // Default limit to 100

  //   if (userEmail == null) {
  //     throw Exception("User email is required to fetch item prices");
  //   }

  //   List<List<dynamic>> filters = [
  //     ["Item Price", "owner", "=", userEmail], // Filter by logged-in user
  //   ];

  //   final filterString = Uri.encodeComponent(jsonEncode(filters));
  //   final url =
  //       '/resource/Item Price?filters=$filterString&fields=["name","item_name","item_code","price_list_rate","valid_from","uom"]&limit_start=$limitStart&limit_page_length=$limitPageLength&order_by=valid_from desc';

  //   try {
  //     final cookies = await _sharedPrefService.getCookies();

  //     debugPrint('Requesting Item Prices from URL: ${baseUrl + url}');
  //     final response = await _dio.get(
  //       baseUrl + url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );

  //     debugPrint('Response status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');

  //     if (response.statusCode == 200) {
  //       final data = response.data['data'];
  //       if (data != null) {
  //         // Deduplicate and keep the latest `valid_from`
  //         final Map<String, dynamic> latestItems = {};

  //         for (var item in data) {
  //           final key = '${item['item_name']}-${item['item_code']}';
  //           final validFrom = DateTime.tryParse(item['valid_from'] ?? '');

  //           if (validFrom != null) {
  //             if (!latestItems.containsKey(key) ||
  //                 DateTime.parse(latestItems[key]['valid_from']).isBefore(validFrom)) {
  //               latestItems[key] = item;
  //             }
  //           }
  //         }

  //         return latestItems.values.toList(); // Return only latest unique items
  //       }
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       return null;
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     throw Exception('Failed to fetch item prices');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch item prices');
  //   }
  //   return null;
  // }

Future<List<dynamic>?> fetchItemPrices(
    BuildContext context, int limitStart,
    [int limitPageLength = 100, String? userEmail]) async {
  
  if (userEmail == null) {
    throw Exception("User email is required to fetch item prices");
  }

  List<List<dynamic>> filters = [
    ["Item Price", "owner", "=", userEmail], // Filter by logged-in user
  ];

  final filterString = Uri.encodeComponent(jsonEncode(filters));
  final url =
      '/resource/Item Price?filters=$filterString&fields=["name","item_name","item_code","price_list_rate","valid_from","uom"]&limit_start=$limitStart&limit_page_length=$limitPageLength&order_by=valid_from desc';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Item Prices from URL: ${baseUrl + url}');
    final response = await _dio.get(
      baseUrl + url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data != null) {
        // Deduplicate and keep the latest `valid_from`
        final Map<String, dynamic> latestItems = {};

        for (var item in data) {
          final key = '${item['item_name']}-${item['item_code']}';
          final validFrom = DateTime.tryParse(item['valid_from'] ?? '');

          if (validFrom != null) {
            if (!latestItems.containsKey(key) ||
                DateTime.parse(latestItems[key]['valid_from']).isBefore(validFrom)) {
              latestItems[key] = item;
            }
          }
        }

        // ✅ Fetch `item_name_local` for each item
        List<dynamic> itemPrices = latestItems.values.toList();
        for (var item in itemPrices) {
          if (item.containsKey("item_code")) {
            String itemCode = item["item_code"];
            String? itemNameLocal = await fetchItemNameLocal(context, itemCode);
            item["item_name_local"] = itemNameLocal ?? ""; // Attach local name
          }
        }

        return itemPrices; // Return updated list with `item_name_local`
      }
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    throw Exception('Failed to fetch item prices');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch item prices');
  }
  return null;
}


Future<bool> addItemPrice(BuildContext context, ItemPrice itemPrice) async {
  final url = '/resource/Item Price';
  try {
    final cookies = await _sharedPrefService.getCookies();
    final response = await _dio.post(
      baseUrl + url,
      data: {'data': itemPrice.toJson()},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true; // Success
    } else {
      // Show error dialog directly
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
              response.data['message'] ?? 'You can only add or update the price of an item once per day',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Close the dialog
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
      return false; // Indicate failure
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('Network error: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    return false; // Failure
  } catch (e) {
    debugPrint('Exception: $e');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('An unexpected error occurred.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    return false; // Failure
  }
}

Future<List<Map<String, dynamic>>> fetchItemSuggestions(BuildContext context, String query) async {
  final filters = [
    ["Item", "item_name", "like", "%$query%"],
    ["Item", "item_code", "like", "%$query%"],
  ];

  final url =
      '/resource/Item?fields=["item_name","item_code","item_name_local","uoms.uom"]&or_filters=${Uri.encodeComponent(jsonEncode(filters))}';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Item Suggestions from URL: ${baseUrl + url}');
    final response = await _dio.get(
      baseUrl + url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    } else {
      apiErrorHandler.handleHttpError(context, response);
    }
  } catch (e) {
    debugPrint('Error fetching Item Suggestions: $e');
    throw Exception('Failed to fetch item suggestions');
  }

  return [];
}


// Future<String?> fetchPriceList(String supplierName) async {
//   final url = '/resource/Supplier/$supplierName';
//   try {
//     final cookies = await _sharedPrefService.getCookies();
//     final response = await _dio.get(
//       baseUrl + url,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) => status != null && status < 500,
//       ),
//     );

//     debugPrint('Response status: ${response.statusCode}');
//     debugPrint('Response data: ${response.data}');

//     if (response.statusCode == 200) {
//       final data = response.data['data'];
//       return data['default_price_list']; // Assuming `default_price_list` holds the `price_list`
//     } else {
//       throw Exception('Failed to fetch price list for $supplierName');
//     }
//   } catch (e) {
//     debugPrint('Exception: $e');
//     throw Exception('Failed to fetch price list');
//   }
// }

  /// Fetches the price list for the logged-in user
  Future<String?> fetchPriceList() async {
    try {
      // Step 1: Get the logged-in user's email
      final email = await _sharedPrefService.getEmailId();
      if (email == null || email.isEmpty) {
        throw Exception("User email is missing");
      }

      // Step 2: Fetch Supplier Info using the user email
      final userUrl = '/resource/User/$email';
      final cookies = await _sharedPrefService.getCookies();

      final userResponse = await _dio.get(
        baseUrl + userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('User API Response: ${userResponse.data}');

      if (userResponse.statusCode != 200 || userResponse.data['data'] == null) {
        throw Exception("Failed to fetch user details");
      }

      final supplierInfo = userResponse.data['data']['supplier_info'];
      if (supplierInfo == null || supplierInfo.isEmpty) {
        throw Exception("Supplier info not found for user $email");
      }

      // Step 3: Fetch Price List using the Supplier Info
      final supplierUrl = '/resource/Supplier/$supplierInfo';
      final supplierResponse = await _dio.get(
        baseUrl + supplierUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('Supplier API Response: ${supplierResponse.data}');

      if (supplierResponse.statusCode != 200 || supplierResponse.data['data'] == null) {
        throw Exception("Failed to fetch supplier details");
      }

      final priceList = supplierResponse.data['data']['default_price_list'];
      if (priceList == null || priceList.isEmpty) {
        throw Exception("Price list not found for supplier $supplierInfo");
      }

      return priceList;
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch price list');
    }
  }


//SupplierPricing

//Stock Updates

  Future<List<dynamic>?> fetchStockReconciliations(
      BuildContext context, int limitStart, int limitPageLength) async {
    try {
      // Get the actual logged-in user (can be email, username, or phone)
      final loggedInUser = await getLoggedInUserIdentifier();

      if (loggedInUser == null) {
        throw Exception("No logged-in user found.");
      }

      // Construct the API URL with filters, ordering, and pagination
      final url = '/resource/Stock Entry'
          '?fields=["name","posting_date","docstatus","owner"]'
          '&filters=[["owner", "=", "$loggedInUser"]]'
          '&order_by=creation desc'
          '&limit_start=$limitStart'
          '&limit_page_length=$limitPageLength';

      final cookies = await _sharedPrefService.getCookies();
      debugPrint('Fetching Stock Reconciliations for user: $loggedInUser');

      final response = await _dio.get(
        baseUrl + url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch stock reconciliations');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch stock reconciliations');
    }
  }


Future<Map<String, dynamic>?> fetchStockReconciliationDetails(
    BuildContext context, String reconciliationName) async {
  try {
    // Construct the API URL
    final url = '/resource/Stock Entry/$reconciliationName';

    final cookies = await _sharedPrefService.getCookies();
    debugPrint('Fetching Stock Reconciliation details for: $reconciliationName');

    final response = await _dio.get(
      baseUrl + url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return response.data['data']; // Return the stock reconciliation details
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    throw Exception('Failed to fetch stock reconciliation details');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch stock reconciliation details');
  }
}

  Future<String?> fetchUserWarehouse(BuildContext context) async {
    try {
      // final userIdentifier = await _sharedPrefService.getEmailId();
      final userIdentifier = await getLoggedInUserIdentifier();
      if (userIdentifier == null) {
        throw Exception('Unable to determine logged-in user identifier.');
      }

      final encodedUser = Uri.encodeComponent(userIdentifier);
      final userUrl = '$baseUrl/resource/User/$encodedUser';
      final cookies = await _sharedPrefService.getCookies();

      // Step 1: Fetch user data
      final userResponse = await _dio.get(
        userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('User details response: ${userResponse.data}');

      if (userResponse.statusCode == 200 && userResponse.data != null) {
        final userData = userResponse.data['data'];
        if (userData != null && userData.containsKey('pos') && userData['pos'] != null) {
          final posProfile = userData['pos'];


          // Step 2: Fetch POS profile data
          final posProfileUrl = '$baseUrl/resource/POS Profile/${Uri.encodeComponent(posProfile)}';
          final posResponse = await _dio.get(
            posProfileUrl,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookies,
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          debugPrint('POS Profile details response: ${posResponse.data}');

          if (posResponse.statusCode == 200 && posResponse.data != null) {
            final posData = posResponse.data['data'];
            if (posData != null && posData.containsKey('warehouse')) {
              return posData['warehouse']; // ✅ final warehouse
            } else {
              throw Exception('Warehouse not found in POS Profile');
            }
          } else {
            throw Exception('Failed to fetch POS profile: ${posResponse.data}');
          }
        } else {
          throw Exception('POS profile not found in user details');
        }
      } else {
        throw Exception('Failed to fetch user details: ${userResponse.data}');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('Exception: $e');
      return null;
    }
  }

  Future<List<dynamic>?> fetchBinStockEntries(
      BuildContext context,
      String warehouse, {
        int offset = 0,
        int limit = 15,
      }) async {
    final filters = Uri.encodeComponent(jsonEncode([
      ["warehouse", "=", warehouse]
    ]));

    final fields = Uri.encodeComponent(jsonEncode([
      "name", "item_code", "warehouse", "actual_qty", "stock_uom"
    ]));

    final url = '$baseUrl/resource/Bin?filters=$filters&fields=$fields'
        '&limit_start=$offset&limit_page_length=$limit';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch bin stock entries: ${response.data}');
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return null;
    }
  }


  Future<double?> fetchIncomingRate({
    required String itemCode,
    required String warehouse,
    required double qty, // Pass qty explicitly
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final postingDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await _dio.post(
        '$baseUrl/method/erpnext.stock.utils.get_incoming_rate',
        data: jsonEncode({
          "args": {
            "item_code": itemCode,
            "posting_date": postingDate,
            "warehouse": warehouse,
            "qty": -qty, // Incoming rate requires negative qty
          }
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        return (response.data['message'] as num).toDouble();
      } else {
        debugPrint("Incoming rate fetch failed: ${response.data}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching incoming rate: $e");
      return null;
    }
  }


  Future<void> createMaterialTransfer(
      BuildContext context,
      List<Map<String, dynamic>> selectedItems,
      ) async {
    try {
      final sWarehouse = await fetchUserWarehouse(context);
      if (sWarehouse == null) {
        throw Exception("Source warehouse not found for user POS.");
      }

      const String tWarehouse = "Own Stall Damage - KSHPDC";

      List<Map<String, dynamic>> itemList = [];
      double baseGrandTotal = 0.0;

      for (final item in selectedItems) {
        final itemCode = item['item_code'];
        final qty = item['entered_qty'];

        final basicRate = await fetchIncomingRate(
          itemCode: itemCode,
          warehouse: sWarehouse,
          qty: (qty as num).toDouble(),
        );


        if (basicRate == null) {
          throw Exception("Failed to fetch basic_rate for item: $itemCode");
        }

        // ✅ Add to grand total
        baseGrandTotal += basicRate * (qty as num).toDouble();

        itemList.add({
          "item_code": itemCode,
          "qty": qty,
          "s_warehouse": sWarehouse,
          "t_warehouse": tWarehouse,
          "basic_rate": basicRate,
        });
      }

      // final requestData = {
      //   "data": {
      //     "docstatus": 0,
      //     "stock_entry_type": "Material Transfer",
      //     "items": itemList,
      //     "base_grand_total": baseGrandTotal, // ✅ Include grand total
      //   },
      // };
      final requestData = {
        "data": {
          "docstatus": 0,
          "stock_entry_type": "Material Transfer",
          "from_warehouse": sWarehouse,   // ✅ Add this
          "to_warehouse": tWarehouse,     // ✅ Add this
          "items": itemList,
          "base_grand_total": baseGrandTotal,
        },
      };

      final url = '$baseUrl/resource/Stock Entry';
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: jsonEncode(requestData),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Material Transfer Response: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint("Material transfer successfully created.");
      } else {
        throw Exception("Failed to create material transfer: ${response.data}");
      }
    } catch (e) {
      debugPrint("Error in createMaterialTransfer: $e");
      rethrow;
    }
  }



  Future<Map<String, String>> fetchItemCodeNameMap(BuildContext context) async {
    final url = '$baseUrl/resource/Item?fields=["item_code","item_name"]&limit_page_length=10000';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['data'] as List<dynamic>;
        final Map<String, String> itemMap = {
          for (var item in items) item['item_code']: item['item_name']
        };
        return itemMap;
      } else {
        throw Exception('Failed to fetch item list');
      }
    } catch (e) {
      debugPrint('Exception in fetchItemCodeNameMap: $e');
      return {};
    }
  }


Future<void> deleteStockReconciliation(BuildContext context, String docName) async {
  final url = '$baseUrl/resource/Stock Entry/$docName';
  final cookies = await _sharedPrefService.getCookies();

  try {
    final response = await _dio.delete(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Delete Response: ${response.statusCode} ${response.data}');

    if (response.statusCode == 202) {
      debugPrint("Stock Update $docName deleted successfully.");
    } else {
      throw Exception("Failed to delete Stock Update: ${response.data}");
    }
  } catch (e) {
    debugPrint('Error deleting Stock Reconciliation: $e');
    throw Exception("An error occurred while deleting.");
  }
}

  Future<void> updateStockEntry({
    required BuildContext context,
    required String entryName,
    required List<Map<String, dynamic>> updatedItems,
  }) async {
    final url = '$baseUrl/resource/Stock Entry/$entryName';

    final requestData = {
      "data": {
        "items": updatedItems,
      }
    };

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.put(
        url,
        data: jsonEncode(requestData),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Stock Entry updated successfully.");
      } else {
        apiErrorHandler.handleHttpError(context, response);
        throw Exception("Failed to update Stock Entry: ${response.data}");
      }
    } catch (e) {
      debugPrint('Update failed: $e');
      throw Exception("Failed to update Stock Entry");
    }
  }

Future<Map<String, dynamic>> fetchReconciliationByName(String name) async {
  final url = '$baseUrl/resource/Stock Entry/$name';
  final cookies = await _sharedPrefService.getCookies();

  final response = await _dio.get(
    url,
    options: Options(headers: {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    }),
  );

  if (response.statusCode == 200) {
    return response.data['data'];
  } else {
    throw Exception("Failed to fetch reconciliation details");
  }
}

//Stock Updates


// Purchase request

Future<String?> fetchLoggedInSupplier() async {
  try {
    final email = await _sharedPrefService.getEmailId();
    if (email == null || email.isEmpty) {
      throw Exception("User email is missing");
    }

    final userUrl = '/resource/User/$email';
    final cookies = await _sharedPrefService.getCookies();

    final userResponse = await _dio.get(
      userUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (userResponse.statusCode != 200 || userResponse.data['data'] == null) {
      throw Exception("Failed to fetch user details");
    }

    final supplierInfo = userResponse.data['data']['supplier_info'];
    if (supplierInfo == null || supplierInfo.isEmpty) {
      throw Exception("Supplier info not found for user $email");
    }

    return supplierInfo;
  } catch (e) {
    debugPrint('Error fetching supplier info: $e');
    return null;
  }
}

Future<List<dynamic>> fetchPurchaseRequests({String? fromDate, String? toDate}) async {
  const baseUrl = '/resource/Purchase Request?fields=["name","docstatus","required_by","supplier_confirmation","creation"]';

  try {
    final cookies = await _sharedPrefService.getCookies();
    final supplierInfo = await fetchLoggedInSupplier();

    if (supplierInfo == null) {
      throw Exception('No logged-in supplier found');
    }

    List<List<dynamic>> filters = [
      ["supplier", "=", supplierInfo]
    ];

    if (fromDate != null && toDate != null) {
      filters.add(["required_by", ">=", fromDate]);
      filters.add(["required_by", "<=", toDate]);
    }

    final encodedFilters = Uri.encodeComponent(jsonEncode(filters));
    final purchaseRequestUrl = '$baseUrl&filters=$encodedFilters';

    final response = await _dio.get(
      purchaseRequestUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchase requests: ${response.data}');
    }

    return response.data['data'];
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to fetch purchase requests');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch purchase requests');
  }
}

Future<int> fetchPurchaseRequestCount() async {
  const baseUrl = '/resource/Purchase Request?fields=["count(name)"]';

  try {
    final cookies = await _sharedPrefService.getCookies();
    final supplierInfo = await fetchLoggedInSupplier();

    if (supplierInfo == null) {
      throw Exception('No logged-in supplier found');
    }

    final countUrl = '$baseUrl&filters=[["supplier", "=", "$supplierInfo"]]';

    final response = await _dio.get(
      countUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchase request count: ${response.data}');
    }

    final data = response.data['data'];
    return data.isNotEmpty ? data[0]['count(name)'] ?? 0 : 0;
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to fetch purchase request count');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch purchase request count');
  }
}


Future<void> updateSupplierConfirmation(String purchaseRequestName, String status) async {
  final url = '/resource/Purchase Request/$purchaseRequestName';

  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.put(
      url,
      data: {
        "data": {
          "supplier_confirmation": status,
        }
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500, // Accept all 2xx and 4xx responses
      ),
    );

    if (response.statusCode == 200) {
      debugPrint('Supplier confirmation updated successfully.');
    } else {
      throw Exception('Failed to update supplier confirmation: ${response.data}');
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to update supplier confirmation');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to update supplier confirmation');
  }
}

Future<Map<String, dynamic>> fetchPurchaseRequestDetails(String purchaseRequestName) async {
  final url = '/resource/Purchase Request/$purchaseRequestName';

  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchase request details: ${response.data}');
    }

    return response.data['data'];
  } on DioException catch (e) {
    debugPrint('DioException: ${e.response?.data}');
    throw Exception('Failed to fetch purchase request details');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch purchase request details');
  }
}


// Purchase request

// pick list

 Future<List<dynamic>?> fetchPickList(BuildContext context) async {
    final url = '/resource/Pick List?fields=["name","status","customer","employee_name"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting Pick List from URL: ${baseUrl + url}');
      final response = await _dio.get(
        baseUrl + url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response data: ${response.data}');
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch Pick List');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch Pick List');
    }
  }
// Future<List<dynamic>?> fetchPickList(BuildContext context) async {
//   try {
//     // Step 1: Get logged-in employee's email
//     final email = await _sharedPrefService.getEmailId();
//     if (email == null) {
//       throw Exception('No email found in SharedPreferences');
//     }

//     // Step 2: Get Employee Name using email
//     final employeeUrl = '/resource/Employee?filters=[["user_id","=","$email"]]';
//     final cookies = await _sharedPrefService.getCookies();

//     debugPrint('Requesting Employee details from URL: ${baseUrl + employeeUrl}');
//     final employeeResponse = await _dio.get(
//       baseUrl + employeeUrl,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) {
//           return status! < 500;
//         },
//       ),
//     );

//     debugPrint('Employee Response data: ${employeeResponse.data}');
//     debugPrint('Employee Response status: ${employeeResponse.statusCode}');

//     if (employeeResponse.statusCode != 200 || employeeResponse.data['data'].isEmpty) {
//       throw Exception('Failed to fetch Employee details');
//     }

//     final employeeName = employeeResponse.data['data'][0]['name'];
//     if (employeeName == null) {
//       throw Exception('No employee name found for the given email');
//     }

//     // Step 3: Fetch Pick List using Employee Name
//     final pickListUrl = '/resource/Pick List?filters=[["employee","=","$employeeName"]]&fields=["name","status","customer","employee_name"]';
//     debugPrint('Requesting Pick List from URL: ${baseUrl + pickListUrl}');
//     final pickListResponse = await _dio.get(
//       baseUrl + pickListUrl,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) {
//           return status! < 500;
//         },
//       ),
//     );

//     debugPrint('Pick List Response data: ${pickListResponse.data}');
//     debugPrint('Pick List Response status: ${pickListResponse.statusCode}');

//     if (pickListResponse.statusCode == 200) {
//       return pickListResponse.data['data'];
//     } else {
//       apiErrorHandler.handleHttpError(context, pickListResponse);
//       return null;
//     }
//   } on DioException catch (e) {
//     debugPrint('DioException: ${e.message}');
//     if (e.response != null) {
//       debugPrint('Response data: ${e.response?.data}');
//     }
//     throw Exception('Failed to fetch Pick List');
//   } catch (e) {
//     debugPrint('Exception: $e');
//     throw Exception('No Pick List Assigned');
//   }
// }


Future<Map<String, dynamic>?> fetchPickListDetails(BuildContext context, String pickListName) async {
  final url = '/resource/Pick List/$pickListName';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Pick List Details from URL: ${baseUrl + url}');
    final response = await _dio.get(
      baseUrl + url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    debugPrint('Response data: ${response.data}');
    debugPrint('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      Map<String, dynamic> pickListDetails = response.data['data'];
      List<dynamic> locations = pickListDetails["locations"] ?? [];

      // Fetch item_name_local for each item in parallel
      for (var item in locations) {
        if (item.containsKey("item_code")) {
          String itemCode = item["item_code"];
          String? itemNameLocal = await fetchItemNameLocal(context, itemCode);
          item["item_name_local"] = itemNameLocal; // Attach local name to item
        }
      }

      return pickListDetails;
    } else {
      apiErrorHandler.handleHttpError(context, response);
      return null;
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch Pick List details');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Pick List details');
  }
}

Future<String?> fetchItemNameLocal(BuildContext context, String itemCode) async {
  final url = '/resource/Item/$itemCode';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Fetching item_name_local from URL: ${baseUrl + url}');
    final response = await _dio.get(
      baseUrl + url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data['data']['item_name_local'];
    } else {
      debugPrint('Failed to fetch item_name_local for item_code: $itemCode');
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching item_name_local for item_code: $itemCode - $e');
    return null;
  }
}


  Future<bool> updatePickedQty(BuildContext context, String pickListName, List<Map<String, dynamic>> locations) async {
    final url = '$baseUrl/resource/Pick List/$pickListName';
    final Map<String, dynamic> updatedData = {
      "data": {
        "name": pickListName,
        "docstatus": 0,
        "locations": locations,
      }
    };

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.put(
        url,
        data: updatedData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return false;
      }
    } catch (e) {
      debugPrint("Error updating picked_qty: $e");
      return false;
    }
  }

//pick list

// purchase receipt


  Future<String?> getUserBranch(BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final email = await _sharedPrefService.getEmailId();

      if (email == null) {
        debugPrint("No logged-in user email found");
        return null;
      }

      final userUrl = '/resource/User/$email';
      final response = await _dio.get(
        userUrl,
        options: Options(headers: {'Content-Type': 'application/json', 'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return response.data['data']['branch'];
      } else {
        debugPrint("Failed to fetch user branch");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching user branch: $e");
      return null;
    }
  }

  /// Fetch Purchase Receipts based on user branch
  Future<List<dynamic>?> fetchPurchaseOrders(BuildContext context, {int offset = 0, int limit = 60}) async {
    try {
      final branch = await getUserBranch(context);
      if (branch == null) return null;

      final filterString = Uri.encodeComponent(jsonEncode([["branch", "=", branch]]));
      final url = '/resource/Purchase Order?filters=$filterString&fields=["name","supplier","status","schedule_date","set_warehouse"]&limit_start=$offset&limit_page_length=$limit&order_by=creation desc';

      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json', 'Cookie': cookies}),
      );

      return response.statusCode == 200 ? response.data['data'] : null;
    } catch (e) {
      debugPrint('Exception: $e');
      return null;
    }
  }

Future<dynamic> createPurchaseReceipt(
    BuildContext context, Map<String, dynamic> receiptData) async {
  try {
    // ✅ Fetch and set branch dynamically
    final branch = await getUserBranch(context);
    if (branch == null) {
      debugPrint("⚠️ Branch is null. Cannot proceed with receipt creation.");
      return "Branch is missing. Cannot proceed.";
    }

    // ✅ Update receiptData with branch and docstatus
    receiptData['branch'] = branch; // Set branch dynamically
    receiptData['docstatus'] = 1; // Mark as submitted

    // ✅ Debug: Print the request payload
    debugPrint('🔼 Sending Purchase Receipt Data: ${jsonEncode(receiptData)}');

    final url = '/resource/Purchase Receipt';
    final cookies = await _sharedPrefService.getCookies();

    // ✅ Send the POST request with JSON payload
    final response = await _dio.post(
      url,
      data: jsonEncode({"data": receiptData}), // Wrapping in {"data": ...}
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
      ),
    );

    // ✅ Debug: Print the response data
    debugPrint('🔽 Purchase Receipt Response: ${response.statusCode} - ${response.data}');

    // ✅ Handle success (200 or 201)
    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint("✅ Purchase Receipt created successfully.");
      return true; // Success
    }

    // 🚨 Handle 417 - Limit Crossed
    else if (response.statusCode == 417) {
      // ✅ Extract and show the desired error part
      final errorMessage = _extractErrorMessage(response.data.toString());
      debugPrint("❗ Limit Crossed: $errorMessage");
      return errorMessage; // Return the extracted error
    }

    // ❌ Handle other response codes
    else {
      debugPrint(
          "❌ Failed to create Purchase Receipt: ${response.statusCode} - ${response.data}");
      return "Failed to create Purchase Receipt. Status Code: ${response.statusCode}";
    }
  } catch (e) {
    // ❗ Handle Dio or unexpected errors
    debugPrint("❗ Error creating Purchase Receipt: $e");

    // ✅ Check if it's a DioException for better error handling
    if (e is DioException) {
      if (e.response?.statusCode == 417) {
        final errorMessage = _extractErrorMessage(e.response!.data.toString());
        debugPrint("❗ DioException 417 Error: $errorMessage");
        return errorMessage; // Return extracted error for 417
      }
      return "❗ DioException: ${e.response?.statusCode ?? 'Unknown'} - ${e.message}";
    }

    return "❗ An unexpected error occurred while creating the receipt.";
  }
}

String _extractErrorMessage(String fullError) {
  const startMarker = "This document is over limit by";
  const endMarker = "for item";

  try {
    int startIndex = fullError.indexOf(startMarker);
    int endIndex = fullError.indexOf(endMarker, startIndex);

    if (startIndex != -1 && endIndex != -1) {
      String extracted = fullError.substring(startIndex, endIndex + endMarker.length);

      RegExp itemCodeRegex = RegExp(r'for item <strong>(.*?)</strong>');
      Match? match = itemCodeRegex.firstMatch(fullError);
      String itemCode = match?.group(1) ?? "Unknown";

      String cleanError = extracted.replaceAll(RegExp(r'<.*?>'), '');

      return "$cleanError $itemCode";
    }
  } catch (e) {
    debugPrint("⚠️ Error extracting message: $e");
  }

  // Improved fallback
  return "⚠️ Purchase limit exceeded or invalid data. Please review the quantities or limits.";
}




Future<Map<String, dynamic>?> fetchPurchaseOrderDetails(String purchaseOrderName) async {
  try {
    // ✅ Debug the API URL to verify correctness
    final url = '/resource/Purchase Order/$purchaseOrderName';
    debugPrint('🔍 Fetching Purchase Order from URL: $url');

    // ✅ Get cookies for authentication
    final cookies = await _sharedPrefService.getCookies();
    debugPrint('🍪 Cookies used: $cookies');

    // ✅ Make API request
    final response = await _dio.get(
      url,
      options: Options(headers: {'Content-Type': 'application/json', 'Cookie': cookies}),
    );

    // ✅ Debug full response details
    debugPrint('📡 API Response Status: ${response.statusCode}');
    debugPrint('📦 Response Data: ${response.data}');

    // ✅ Check if the response is successful
    if (response.statusCode == 200 && response.data != null) {
      return response.data['data']; // Correctly return data
    } else {
      debugPrint('❌ Error: Unexpected status code: ${response.statusCode}');
      debugPrint('Response body: ${response.data}');
      return null;
    }
  } catch (e) {
    // ✅ Handle DioError for more detailed error info
    if (e is DioError) {
      debugPrint('❗ DioError Type: ${e.type}');
      debugPrint('❗ DioError Message: ${e.message}');
      debugPrint('❗ Response data: ${e.response?.data}');
    } else {
      debugPrint('❗ Exception fetching order details: $e');
    }
    return null;
  }
}

  Future<List<String>> fetchWarehouse(String query) async {
    final url =
        // '/resource/Warehouse?filters=[["Warehouse","name","like","%$query%"]]&fields=["name"]';
        '/resource/Warehouse?filters=[["Warehouse","name","like","%$query%"],["Warehouse","is_rejected_warehouse","=","1"]]&fields=["name"]';


    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<String>.from(
            response.data['data'].map((item) => item['name']));
      } else {
        throw Exception('Failed to fetch warehouse codes');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch warehouse codes');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch warehouse codes');
    }
  }

// purchase receipt

// sales invoice

  Future<Map<String, String>?> fetchUserBranch(BuildContext context) async {
    try {
      final userIdentifier = await getLoggedInUserIdentifier();
      if (userIdentifier == null) {
        throw Exception('Unable to determine logged-in user identifier.');
      }

      final encodedUser = Uri.encodeComponent(userIdentifier);
      final userUrl = '$baseUrl/resource/User/$encodedUser';
      final cookies = await _sharedPrefService.getCookies();

      // Step 1: Fetch user data
      final userResponse = await _dio.get(
        userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (userResponse.statusCode == 200 && userResponse.data != null) {
        final userData = userResponse.data['data'];
        if (userData != null && userData.containsKey('customer_info')) {
          final customerInfo = userData['customer_info'];

          // Step 2: Fetch customer data
          final customerUrl = '$baseUrl/resource/Customer/$customerInfo';
          final customerResponse = await _dio.get(
            customerUrl,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookies,
              },
              validateStatus: (status) => status! < 500,
            ),
          );

          if (customerResponse.statusCode == 200 && customerResponse.data != null) {
            final customerData = customerResponse.data['data'];
            final branch = customerData['branch'];
            final defaultWarehouse = customerData['default_warehouse'];

            if (branch != null && defaultWarehouse != null) {
              return {
                "branch": branch,
                "default_warehouse": defaultWarehouse,
              };
            } else {
              throw Exception('branch or default_warehouse not found in customer data.');
            }
          } else {
            throw Exception('Failed to fetch customer details.');
          }
        } else {
          throw Exception('customer_info not found in user data.');
        }
      } else {
        throw Exception('Failed to fetch user details.');
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return null;
    }
  }


  Future<GetSalesInvoiceResponse?> getSalesInvoice(
    BuildContext context, int limitStart, int pageLength) async {
  try {
    final cookies = await _sharedPrefService.getCookies();

    // ✅ Step 1: Get logged-in user identifier
    final userId = await getLoggedInUserIdentifier();
    if (userId == null) {
      throw Exception('Unable to determine logged-in user.');
    }

    // ✅ Step 2: Fetch customer_info from User
    final userUrl = '$baseUrl/resource/User/${Uri.encodeComponent(userId)}';
    final userResponse = await _dio.get(
      userUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (userResponse.statusCode != 200 || userResponse.data['data'] == null) {
      throw Exception('Failed to fetch user details.');
    }

    final customerInfo = userResponse.data['data']['customer_info'];
    if (customerInfo == null || customerInfo.isEmpty) {
      throw Exception('customer_info field not found for user.');
    }

    // ✅ Step 3: Fetch Sales Invoice filtered by customer_info
    final salesInvoiceUrl =
        '/resource/Sales Invoice'
        '?fields=["name","customer","posting_date","due_date","status","grand_total"]'
        '&limit_start=$limitStart'
        '&limit_page_length=$pageLength'
        '&order_by=posting_date desc'
        '&filters=[["customer","=","$customerInfo"]]';

    debugPrint('Requesting Sales Invoice data from URL: ${baseUrl + salesInvoiceUrl}');
    final invoiceResponse = await _dio.get(
      salesInvoiceUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    debugPrint('Response status: ${invoiceResponse.statusCode}');
    debugPrint('Response data: ${invoiceResponse.data}');

    if (invoiceResponse.statusCode == 200) {
      return GetSalesInvoiceResponse.fromJson(invoiceResponse.data);
    } else {
      apiErrorHandler.handleHttpError(context, invoiceResponse);
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch Sales Invoice');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Sales Invoice');
  }
}


Future<GetSalesInvoiceResponse?> getSalesInvoiceDateFilter(
  context,
  String startDate,
  String endDate,
) async {
  final url =
      '/resource/Sales Invoice?fields=["name","customer","posting_date","due_date","status","grand_total"]&filters=[["posting_date", ">=", "$startDate"], ["posting_date", "<=", "$endDate"]]';

  print("Sales Invoice Filter URL ::: $url");

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Sales Invoice data from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500; // only throw for server errors
        },
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return GetSalesInvoiceResponse.fromJson(response.data);
    } else {
      apiErrorHandler.handleHttpError(context, response);
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch Sales Invoice data');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Sales Invoice data');
  }
}

Future<GetSalesInvoiceResponse?> getSearchSalesInvoice(
  context,
  String? invoiceId,
  String? customerId,
) async {
  String url;

  List<String> filters = [];

  if (invoiceId != null && invoiceId.isNotEmpty) {
    filters.add('["name", "like", "%$invoiceId%"]');
  }
  if (customerId != null && customerId.isNotEmpty) {
    filters.add('["customer", "like", "%$customerId%"]');
  }

  if (filters.isEmpty) {
    throw Exception("Please provide at least one search parameter.");
  }

  url =
      '/resource/Sales Invoice?fields=["name","customer","posting_date","due_date","status","grand_total"]&filters=[${filters.join(",")}]';

  try {
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode == 200) {
      return GetSalesInvoiceResponse.fromJson(response.data);
    } else {
      apiErrorHandler.handleHttpError(context, response);
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    throw Exception('Failed to fetch Sales Invoice data');
  } catch (e) {
    throw Exception('Failed to fetch Sales Invoice data');
  }
}

// Future<Map<String, dynamic>> fetchInvoiceCustomerDetails(
//   BuildContext context,
//   String customerName,
// ) async {
//   final url =
//       '/method/erpnext.accounts.party.get_party_details?company=Kerala%20State%20Horticultural%20Products%20Development%20Corporation&party=$customerName&doctype=Sales%20Invoice';
//
//   final cookies = await _sharedPrefService.getCookies();
//
//   final response = await _dio.post(
//     url,
//     options: Options(
//       headers: {
//         'Content-Type': 'application/json',
//         'Cookie': cookies,
//       },
//     ),
//   );
//
//   if (response.statusCode == 200) {
//     return response.data["message"];
//   } else {
//     throw Exception("Failed to fetch customer details");
//   }
// }
//
// Future<Map<String, dynamic>> fetchInvoiceItemDetail({
//   required BuildContext context,
//   required String itemCode,
//   required String itemName,
//   required double quantity,
//   required String currency,
//   required String customer,
//   required String priceList,
// }) async {
//   const url = '/method/erpnext.stock.get_item_details.get_item_details';
//
//   final data = {
//     "args": {
//       "item_code": itemCode,
//       "item_name": itemName,
//       "customer": customer,
//       "company": "Kerala State Horticultural Products Development Corporation",
//       "currency": currency,
//       "selling_price_list": priceList,
//       "qty": quantity,
//       "doctype": "Sales Invoice",
//     }
//   };
//
//   final cookies = await _sharedPrefService.getCookies();
//
//   final response = await _dio.post(
//     url,
//     data: data,
//     options: Options(
//       headers: {
//         'Content-Type': 'application/json',
//         'Cookie': cookies,
//       },
//     ),
//   );
//
//   if (response.statusCode == 200) {
//     return response.data["message"];
//   } else {
//     throw Exception("Failed to fetch item details");
//   }
// }
  Future<Map<String, dynamic>> fetchInvoiceCustomerDetails(
      BuildContext context,
      String customerName,
      ) async {
    try {
      // Get company from SharedPreferences
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      final url =
          '/method/erpnext.accounts.party.get_party_details?company=${Uri.encodeComponent(company)}&party=$customerName&doctype=Sales%20Invoice';

      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data["message"];
      } else {
        throw Exception("Failed to fetch customer details");
      }
    } catch (e) {
      debugPrint("Error in fetchInvoiceCustomerDetails: $e");
      throw Exception("Failed to fetch customer details");
    }
  }

  Future<Map<String, dynamic>> fetchInvoiceItemDetail({
    required BuildContext context,
    required String itemCode,
    required String itemName,
    required double quantity,
    required String currency,
    required String customer,
    required String priceList,
  }) async {
    const url = '/method/erpnext.stock.get_item_details.get_item_details';

    try {
      // Get company from SharedPreferences
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      final data = {
        "args": {
          "item_code": itemCode,
          "item_name": itemName,
          "customer": customer,
          "company": company,
          "currency": currency,
          "selling_price_list": priceList,
          "qty": quantity,
          "doctype": "Sales Invoice",
        }
      };

      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data["message"];
      } else {
        throw Exception("Failed to fetch item details");
      }
    } catch (e) {
      debugPrint("Error in fetchInvoiceItemDetail: $e");
      throw Exception("Failed to fetch item details");
    }
  }

  Future<void> createSalesInvoice({
    required BuildContext context,
    required String customerName,
    required String dueDate,
    required String postingDate,
    required List<Map<String, dynamic>> item,
    required Map<String, dynamic> customerDetails,
  }) async {
    const url = '/resource/Sales Invoice';

    try {
      final cookies = await _sharedPrefService.getCookies();

      // ✅ Fetch both branch and warehouse
      final userData = await fetchUserBranch(context);
      if (userData == null) {
        throw Exception('Failed to fetch user branch and warehouse.');
      }

      final defaultWarehouse = userData["default_warehouse"];

      // ✅ Set the warehouse field in each item to the defaultWarehouse
      final updatedItems = item.map((itm) {
        return {
          ...itm,
          "warehouse": defaultWarehouse,
        };
      }).toList();

      final invoiceData = {
        "customer": customerName,
        ...customerDetails,
        "due_date": dueDate,
        "posting_date": postingDate,
        "set_posting_time": 1,
        "items": updatedItems,
        "branch": userData["branch"],
        "set_warehouse": defaultWarehouse,
      };

      final response = await _dio.post(
        url,
        data: {"data": invoiceData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to create Sales Invoice:');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Data: ${response.data}');
        throw Exception('Failed to create Sales Invoice');
      }

      debugPrint('✅ Sales Invoice created successfully');
      debugPrint('Response: ${response.data}');
    } on DioError catch (dioError) {
      debugPrint('❌ DioError while creating Sales Invoice:');
      debugPrint('Type: ${dioError.type}');
      debugPrint('Message: ${dioError.message}');
      if (dioError.response != null) {
        debugPrint('Status Code: ${dioError.response?.statusCode}');
        debugPrint('Response Data: ${dioError.response?.data}');
        debugPrint('Headers: ${dioError.response?.headers}');
      } else {
        debugPrint('No response from server.');
      }
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception while creating Sales Invoice: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }



//sales invoices

//POS Invoice

  /// Fetch POS Profile for a given user
  // Future<String?> fetchPosProfile() async {
  //   try {
  //     // Step 1: Get the canonical logged-in user identifier (email)
  //     final loggedInUser = await getLoggedInUserIdentifier();
  //     if (loggedInUser == null) {
  //       debugPrint("Failed to fetch logged-in user identifier");
  //       return null;
  //     }
  //
  //     // Step 2: Use that email/identifier to fetch the POS Profile
  //     final url =
  //         '/resource/POS Profile?filters=[["POS Profile User","user","=","$loggedInUser"]]';
  //
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.get(
  //       url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = response.data['data'] as List<dynamic>;
  //       if (data.isNotEmpty) {
  //         return data.first['name'];
  //       } else {
  //         debugPrint("No POS Profile found for user: $loggedInUser");
  //       }
  //     } else {
  //       debugPrint("Failed POS Profile request: ${response.data}");
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching POS Profile: $e");
  //   }
  //   return null;
  // }
  Future<Map<String, dynamic>?> fetchPosProfile() async {
    try {
      // Step 1: Get logged-in user identifier
      final loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) {
        debugPrint("Failed to fetch logged-in user identifier");
        return null;
      }

      // Step 2: Find the POS Profile name for the user
      final url =
          '/resource/POS Profile?filters=[["POS Profile User","user","=","$loggedInUser"]]';

      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        if (data.isNotEmpty) {
          final profileName = data.first['name'];

          // ✅ Fetch full profile with allow_discount_change field
          final profileResponse = await _dio.get(
            '/resource/POS Profile/$profileName',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookies,
              },
            ),
          );

          if (profileResponse.statusCode == 200) {
            return profileResponse.data['data']; // full profile map
          }
        } else {
          debugPrint("No POS Profile found for user: $loggedInUser");
        }
      } else {
        debugPrint("Failed POS Profile request: ${response.data}");
      }
    } catch (e) {
      debugPrint("Error fetching POS Profile: $e");
    }
    return null;
  }



  /// Fetch Mode of Payment for given POS Profile
  Future<List<String>> fetchModesOfPayment(String posProfileName) async {
    final url = '/resource/POS Profile/$posProfileName';
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final List<dynamic> payments = data['payments'] ?? [];
      return payments.map<String>((p) => p['mode_of_payment'] as String).toList();
    }
    return [];
  }

  /// Create POS Opening Entry
  Future<bool> createPosOpeningEntryForAll({
    required String company,
    required String posProfile,
    required List<Map<String, dynamic>> balances,
    required String periodStartDate,
  }) async {
    const url = '/resource/POS Opening Entry';
    final cookies = await _sharedPrefService.getCookies();

    // ✅ Always fetch the logged-in user email here
    final loggedInUser = await getLoggedInUserIdentifier();
    if (loggedInUser == null) {
      debugPrint("❌ Could not fetch logged-in user email");
      return false;
    }

    final body = {
      "docstatus": 1,
      "doctype": "POS Opening Entry",
      "company": company,
      "period_start_date": periodStartDate,
      "user": loggedInUser, // ✅ always email
      "pos_profile": posProfile,
      "balance_details": balances,
    };

    debugPrint("📤 Creating POS Opening Entry: $body");

    final response = await _dio.post(
      url,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    debugPrint("Response status: ${response.statusCode}");
    debugPrint("Response data: ${response.data}");

    return response.statusCode == 200;
  }

  /// Create POS Invoice
  Future<String?> createPosInvoice(Map<String, dynamic> enrichedInvoice) async {
    const url = '/resource/POS Invoice';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.post(
        url,
        data: enrichedInvoice,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      debugPrint("📤 Creating POS Invoice: $enrichedInvoice");
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response data: ${response.data}");

      if (response.statusCode == 200 && response.data["data"] != null) {
        final invoiceName = response.data["data"]["name"];
        debugPrint("✅ POS Invoice created: $invoiceName");
        return invoiceName;
      }

      debugPrint("❌ Failed to create invoice: ${response.data}");
      return null;
    } catch (e, stack) {
      debugPrint("❌ Error creating POS Invoice: $e");
      debugPrint("📌 Stack: $stack");
      return null;
    }
  }


  Future<Map<String, dynamic>?> fetchTaxes(String templateName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/method/erpnext.controllers.accounts_controller.get_taxes_and_charges',
        queryParameters: {
          "master_doctype": "Sales Taxes and Charges Template",
          "master_name": templateName,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint("✅ Taxes fetched: ${response.data}");
        return response.data["message"]; // contains taxes list
      } else {
        debugPrint("❌ Failed taxes response: ${response.data}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching taxes: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchCustomersDetails(
      String customerName, String posProfile) async {
    try {
      final company = await _sharedPrefService.getCompany();
      if (company == null) {
        debugPrint("❌ Company not found in SharedPreferences");
        return null;
      }

      final url =
          '/method/erpnext.accounts.party.get_party_details?posting_date=${DateTime.now().toIso8601String().split("T").first}'
          '&party=$customerName'
          '&party_type=Customer'
          '&doctype=POS Invoice'
          '&company=$company'
          '&pos_profile=$posProfile';

      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
        debugPrint("✅ Customer Details (party API): $result");

        final custMsg = result["message"] ?? {};

        // 🔎 If taxes_and_charges missing, fetch directly from Customer doctype
        if (!custMsg.containsKey("taxes_and_charges") ||
            custMsg["taxes_and_charges"] == null) {
          final custRes = await _dio.get(
            '/resource/Customer/$customerName',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookies,
              },
            ),
          );

          if (custRes.statusCode == 200 && custRes.data != null) {
            final custDoc = custRes.data["data"] ?? {};
            if (custDoc.containsKey("taxes_and_charges")) {
              custMsg["taxes_and_charges"] = custDoc["taxes_and_charges"];
              debugPrint(
                  "✅ Added taxes_and_charges from Customer doctype: ${custDoc["taxes_and_charges"]}");
            }
          }
        }

        // update message with enriched data
        result["message"] = custMsg;
        return result;
      } else {
        debugPrint("❌ Failed Customer details response: ${response.data}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching customer details: $e");
    }
    return null;
  }

  Future<double?> _fetchAvailableQty({
    required String itemCode,
    required String warehouse,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    try {
      final res = await _dio.get(
        '/method/erpnext.accounts.doctype.pos_invoice.pos_invoice.get_stock_availability',
        queryParameters: {
          'item_code': itemCode,
          'warehouse': warehouse,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200) {
        final msg = res.data?['message'];
        if (msg is List && msg.isNotEmpty) {
          // ✅ index 0 contains the available qty
          final qty = msg[0];
          if (qty is num) return qty.toDouble();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching available qty: $e');
    }
    return null;
  }
  Future<Map<String, dynamic>?> fetchItemsDetails({
    required String itemCode,
    required String posProfile,
    required String customer,
  }) async {
    try {
      final company = await _sharedPrefService.getCompany();
      final cookies = await _sharedPrefService.getCookies();

      // 1) POS Profile → get warehouse
      final posResponse = await _dio.get(
        '/resource/POS Profile/$posProfile',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        }),
      );
      if (posResponse.statusCode != 200 || posResponse.data == null) {
        debugPrint("❌ Failed POS Profile details: ${posResponse.data}");
        return null;
      }
      final posData = posResponse.data["data"];
      final String warehouse = (posData["warehouse"] ?? '').toString();

      // 2) Customer details → price list
      final customerDetails = await fetchCustomersDetails(customer, posProfile);
      if (customerDetails == null || customerDetails["message"] == null) {
        debugPrint("❌ Customer details not found");
        return null;
      }
      final priceList = customerDetails["message"]["selling_price_list"];

      // 3) Item details
      final body = {
        "args": {
          "item_code": itemCode,
          "set_warehouse": warehouse,
          "customer": customer,
          "currency": "INR",
          "price_list": priceList,
          "company": company,
          "doctype": "POS Invoice",
          "pos_profile": posProfile,
        }
      };

      final response = await _dio.post(
        '/method/erpnext.stock.get_item_details.get_item_details',
        data: body,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> details =
        Map<String, dynamic>.from(response.data["message"] ?? {});

        // Ensure we return the warehouse we used
        details["warehouse"] = warehouse;

        // 4) POS-accurate availability
        final avail = await _fetchAvailableQty(itemCode: itemCode, warehouse: warehouse);
        if (avail != null) {
          details["available_qty"] = avail; // ✅ POS accurate qty
        }

        debugPrint("✅ Item Details (merged): $details");
        return details;
      } else {
        debugPrint("❌ Failed Item details: ${response.data}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching item details: $e");
    }
    return null;
  }


  Future<Map<String, dynamic>?> fetchPosInvoice(String invoiceName) async {
    final url = '/resource/POS Invoice/$invoiceName';
    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data['data'];
    }
    return null;
  }
  Future<bool> updatePosInvoice(String invoiceName, Map<String, dynamic> updatedInvoice) async {
    final url = '/resource/POS Invoice/$invoiceName';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.put(
        url,
        data: updatedInvoice,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      debugPrint("📤 Updating POS Invoice $invoiceName: $updatedInvoice");
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response data: ${response.data}");

      if (response.statusCode == 200 && response.data["data"] != null) {
        debugPrint("✅ POS Invoice updated successfully");
        return true;
      }

      debugPrint("❌ Failed to update POS Invoice: ${response.data}");
      return false;
    } catch (e, stack) {
      debugPrint("❌ Error updating POS Invoice: $e");
      debugPrint("📌 Stack: $stack");
      return false;
    }
  }
  Future<Map<String, dynamic>?> fetchInvoiceDetails(String invoiceName) async {
    final url = '/resource/POS Invoice/$invoiceName';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint("✅ Invoice JSON fetched for $invoiceName");
        return response.data['data']; // ERPNext wraps response in "data"
      }

      debugPrint("❌ Failed to fetch invoice JSON: ${response.statusCode}");
      return null;
    } catch (e, stack) {
      debugPrint("❌ Error fetching invoice JSON: $e");
      debugPrint("📌 Stack: $stack");
      return null;
    }
  }

  Future<bool> checkOpeningEntry(String userEmail) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        '/method/erpnext.selling.page.point_of_sale.point_of_sale.check_opening_entry',
        queryParameters: {'user': userEmail},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final message = response.data["message"];
        // ✅ Check if message is a non-empty list
        if (message is List && message.isNotEmpty) {
          return true; // Opening entry exists
        } else {
          return false; // No opening entry
        }
      } else {
        debugPrint("Failed to check opening entry: ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("Error checking opening entry: $e");
      return false;
    }
  }

  Future<String?> fetchUserFullName(String email) async {
    final url = '/resource/User/$email';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']?['full_name'];
      }
      return null;
    } catch (e, stack) {
      debugPrint("❌ Error fetching full_name for $email: $e");
      debugPrint("📌 Stack: $stack");
      return null;
    }
  }

  Future<List<dynamic>?> searchItems({
    required String query,
    required String posProfile,
    required String priceList,
    int start = 0,
    int pageLength = 40,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url =
          '/method/erpnext.selling.page.point_of_sale.point_of_sale.get_items'
          '?start=$start'
          '&page_length=$pageLength'
          '&price_list=$priceList'
          '&item_group=All Item Groups'
          '&pos_profile=$posProfile'
          '&search_term=$query';  // 👈 ERPNext supports this param

      final res = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (res.statusCode == 200) {
        final data = res.data["message"];
        return data["items"] as List<dynamic>;
      } else {
        debugPrint("❌ Item search failed: ${res.data}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error searching items: $e");
      return null;
    }
  }
  Future<Map<String, dynamic>?> getOpeningEntry(String userEmail) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        '/method/erpnext.selling.page.point_of_sale.point_of_sale.check_opening_entry',
        queryParameters: {'user': userEmail},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final message = response.data["message"];
        if (message is List && message.isNotEmpty) {
          return message.first; // Opening entry details (contains period_start_date, pos_profile, etc.)
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error getting opening entry: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPosInvoices({
    required String start,
    required String end,
    required String posProfile,
    required String user,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        '/method/erpnext.accounts.doctype.pos_closing_entry.pos_closing_entry.get_pos_invoices',
        queryParameters: {
          'start': start,
          'end': end,
          'pos_profile': posProfile,
          'user': user,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data["message"];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching POS Invoices: $e");
      return [];
    }
  }



  //POS Invoice
  //customer group filter
  Future<CustomerList?> customerGroupFilter(
      String customerGroup, BuildContext context) async {
    final url =
        '/resource/Customer?fields=["name","tax_id","gstin","territory","customer_primary_contact","customer_primary_address","primary_address","mobile_no","email_id","tax_category","territory","customer_group"]&filters=[["Customer","customer_group","=","$customerGroup"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        Navigator.pop(context);
        return CustomerList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //customer name search

  Future<CustomerList?> customerNameSearchList(
      String customerName, BuildContext context) async {
    final url =
        '/resource/Customer?fields=["name","tax_id","gstin","territory","customer_primary_contact","customer_primary_address","primary_address","mobile_no","email_id","tax_category","territory","customer_group"]&filters=[["Customer","name","Like","%$customerName%"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Navigator.pop(context);
        return CustomerList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //customer group list
  Future<CustomerGroupList?> customerGroupList(context) async {
    final url = '/resource/Customer Group';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CustomerGroupList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //Employee details (emplayeeId)
  Future<EmployeeDetails?> employeeDetails(
      String email, BuildContext context) async {
    final url =
        '/resource/Employee?filters=[["Employee", "user_id","=", "$email"]]&fields=["name","employee_name","leave_approver","expense_approver","user_id"]';
    print("employee details::::$url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data in employee: ${response.data}');

      if (response.statusCode == 200) {
        final employeeDetails = EmployeeDetails.fromJson(response.data);
        if (employeeDetails.data != null && employeeDetails.data!.isNotEmpty) {
          // Assuming you want to save the 'name' field of the first employee in the list
          final employeeId = employeeDetails.data!.first.name;
          if (employeeId != null) {
            await _sharedPrefService.saveEmployeeId(employeeId);
          }
        }
        return employeeDetails;
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //Item list
  Future<ItemListResponse?> itemList(context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //Item list
// Future<ItemListResponse?> itemSearchList(
//     String itemName, BuildContext context, bool isItemList) async {
//   try {
//     final cookies = await _sharedPrefService.getCookies();
//
//     // Fields to fetch
//     final fields = Uri.encodeQueryComponent(
//         '["item_code","item_name","valuation_rate","brand","item_group"]');
//
//     // OR filters: match either item_code or item_name
//     final orFilters = Uri.encodeComponent(jsonEncode([
//       ["Item", "item_code", "like", "%$itemName%"],
//       ["Item", "item_name", "like", "%$itemName%"],
//     ]));
//
//     // AND filters: must be stock item and published for customer
//     final filters = Uri.encodeComponent(jsonEncode([
//       ["Item", "is_stock_item", "=", "1"],
//     ]));
//
//     final url =
//         '/resource/Item?fields=$fields&or_filters=$orFilters&filters=$filters';
//
//     debugPrint('Fetching item search list from URL: ${baseUrl + url}');
//
//     final response = await _dio.get(
//       url,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) => status! < 500,
//       ),
//     );
//
//     if (isItemList) Navigator.pop(context);
//
//     if (response.statusCode == 200) {
//       final rawData = response.data['data'];
//
//       // Deduplicate by item_code
//       final uniqueMap = {
//         for (var item in rawData) item['item_code']: item
//       };
//       final uniqueList = uniqueMap.values.toList();
//
//       final dataList = uniqueList.map((e) => ItemData.fromJson(e)).toList();
//       return ItemListResponse(data: dataList);
//     } else {
//       apiErrorHandler.handleHttpError(context, response);
//       return null;
//     }
//   } catch (e) {
//     debugPrint('Exception: $e');
//     throw Exception('Failed to fetch item list');
//   }
// }
  Future<ItemListResponse?> itemSearchList(
      String itemName, BuildContext context, bool isItemList) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // Fields to fetch (added normalized_item_code)
      final fields = Uri.encodeQueryComponent(
          '["item_code","item_name","normalized_item_code","valuation_rate","brand","item_group"]');

      // OR filters: match item_code, item_name OR normalized_item_code
      final orFilters = Uri.encodeComponent(jsonEncode([
        ["Item", "item_code", "like", "%$itemName%"],
        ["Item", "item_name", "like", "%$itemName%"],
        ["Item", "normalized_item_code", "like", "%$itemName%"],
      ]));

      // AND filters: must be stock item and published for customer
      final filters = Uri.encodeComponent(jsonEncode([
        ["Item", "is_stock_item", "=", "1"],
      ]));

      final url =
          '/resource/Item?fields=$fields&or_filters=$orFilters&filters=$filters';

      debugPrint('Fetching item search list from URL: ${baseUrl + url}');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (isItemList) Navigator.pop(context);

      if (response.statusCode == 200) {
        final rawData = response.data['data'];

        // Deduplicate by item_code
        final uniqueMap = {
          for (var item in rawData) item['item_code']: item
        };
        final uniqueList = uniqueMap.values.toList();

        final dataList = uniqueList.map((e) => ItemData.fromJson(e)).toList();
        return ItemListResponse(data: dataList);
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch item list');
    }
  }


  //Item filter by brand
  Future<ItemListResponse?> itemByBrand(
      String brandName, BuildContext context) async {
    print("test brand 3");

    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group"]&filters=[["Item", "brand","=", "$brandName"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        print("test brand 4");

        //print("Response details :::::${response.data[0].}");
        Navigator.pop(context);
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //brand list
  Future<BrandListResponse?> brandList(context) async {
    final url = '/resource/Brand';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return BrandListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //brand list
  Future<CategoryListRespose?> categoryList(context) async {
    final url = '/resource/Item Group';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return CategoryListRespose.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //item category filter
  Future<ItemListResponse?> categoryItemFilter(
      String category, BuildContext context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","item_group","brand"]&filters=[["Item","item_group","=","$category"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        Navigator.pop(context);
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //item category and Brand filter
  Future<ItemListResponse?> categoryAndBrandItemFilter(
      String brand, String category, context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","item_group","brand"]&filters=[["Item","item_group","=","$category","brand","=", "$brand"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

// //sales Order
//   Future<SalesOrderResponse?> salesOrder1() async {
//     final url = '/resource/Sales Order';
//     final requestData = {
//       "customer": "CUST-2024-00001",
//       "delivery_date": "2024-06-28",
//       "items": [
//         {
//           "item_code": "HS1M1-30-NIPL-EHS1M130",
//           "item_name": "SLIP ON HINGE OVERLAY - EURO WITH 4 HOLE - 30MM-E",
//           "qty": 10,
//           "rate": 102
//         }
//       ]
//     };
//     try {
//       final cookies = await _sharedPrefService.getCookies();

//       debugPrint('Requesting  data from URL: ${baseUrl + url}');
//       final response = await _dio.post(
//         url,
//         data: requestData,
//         options: Options(
//           headers: {'Content-Type': 'application/json'},
//           validateStatus: (status) {
//             return status! < 500;
//           },
//         ),
//       );

//       debugPrint('Request data: $requestData');

//       debugPrint('Response  status: ${response.statusCode}');
//       debugPrint('Response data: ${response.data}');

//       if (response.statusCode == 200) {
//         // print("Response details :::::${response.data[0].itemCode}");
//         return SalesOrderResponse.fromJson(response.data);
//       } else if (response.statusCode == 401) {
//         debugPrint('Unauthorized: Incorrect username, password, or domain.');
//         throw Exception(
//             'Unauthorized: Incorrect username, password, or domain.');
//       } else {
//         throw Exception('Failed to fetch  data');
//       }
//     } on DioException catch (e) {
//       debugPrint('DioException: ${e.message}');
//       if (e.response != null) {
//         debugPrint('Response data: ${e.response?.data}');
//       }
//       throw Exception('Failed to fetch  data');
//     } catch (e) {
//       debugPrint('Exception: $e');
//       throw Exception('Failed to fetch  data');
//     }
//   }

  //current stock list
  Future<CurrentStockResponse?> currentStockList(context) async {
    final url =
        '/method/erpnext.stock.dashboard.item_dashboard.get_data?fields=["name","item_code","item_name","actual_qty","planned_qty","projected_qty","reserved_qty","reserved_stock","warehouse"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return CurrentStockResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //current stock filter
  Future<CurrentStockResponse?> currentStockFilter(
      String itemCode, String warehouse, context) async {
    final url =
        '/method/erpnext.stock.dashboard.item_dashboard.get_data?item_code=$itemCode&warehouse=$warehouse';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return CurrentStockResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }
  Future<List<Map<String, dynamic>>> searchItem(String query, BuildContext context) async {
    final url =
        '/method/frappe.desk.search.search_link?doctype=Item&reference_doctype=Bin&page_length=10&txt=$query';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['message'] ?? [];
        // Each result has "value" and "description"
        return results.map((item) => {
          'value': item['value'],
          'description': item['description'],
        }).toList();
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return [];
      }
    } catch (e) {
      debugPrint("Error searching items: $e");
      return [];
    }
  }
  Future<CurrentStockResponse?> currentStockListByItem(BuildContext context, String itemCode) async {
    final url =
        '/method/erpnext.stock.dashboard.item_dashboard.get_data?item_code=$itemCode';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting filtered data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CurrentStockResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint('Error fetching filtered stock: $e');
      throw Exception('Failed to fetch filtered stock data');
    }
    return null;
  }
  Future<CurrentStockResponse?> currentStockListByWarehouse(BuildContext context, String warehouse) async {
    final url = '/method/erpnext.stock.dashboard.item_dashboard.get_data?warehouse=$warehouse';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting filtered data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CurrentStockResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint('Error fetching warehouse stock: $e');
      throw Exception('Failed to fetch stock data by warehouse');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchWarehouse(String query, BuildContext context) async {
    final url =
        '/method/frappe.desk.search.search_link?doctype=Warehouse&reference_doctype=Bin&page_length=10&txt=$query';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['message'] ?? [];
        return results.map((item) => {
          'value': item['value'],
          'description': item['description'],
        }).toList();
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return [];
      }
    } catch (e) {
      debugPrint("Error searching warehouses: $e");
      return [];
    }
  }

  //Search customer
  // Future<CustomerList?> customerSearch(String customer, context) async {
  //   final url =
  //       '/resource/Customer?fields=["name","customer_name","customer_name","tax_id","gstin","territory","customer_primary_contact","customer_primary_address","primary_address","mobile_no","email_id","tax_category","territory","customer_group"]&filters=[["Customer","name","Like","$customer%"]]';

  //   try {
  //     final cookies = await _sharedPrefService.getCookies();

  //     debugPrint('Requesting  data from URL: ${baseUrl + url}');
  //     final response = await _dio.get(
  //       url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) {
  //           return status! < 500;
  //         },
  //       ),
  //     );

  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');

  //     if (response.statusCode == 200) {
  //       // print("Response details :::::${response.data[0].itemCode}");
  //       return CustomerList.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch  data');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch  data');
  //   }
  // }

  Future<CustomerList?> customerSearch(String customer, context) async {
  final encodedCustomer = Uri.encodeComponent(customer); // Important!

  final url =
      '/resource/Customer?fields=["name","customer_name","tax_id","gstin","territory","customer_primary_contact","customer_primary_address","primary_address","mobile_no","email_id","tax_category","customer_group"]&filters=[["Customer","name","like","$encodedCustomer%"]]';

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting data from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return CustomerList.fromJson(response.data);
    } else {
      apiErrorHandler.handleHttpError(context, response);
      throw Exception('API Error: ${response.statusCode}');
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch data');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch data');
  }
}


  Future<CustomerList?> searchCustomerId(String customerName, context) async {
    final url =
        '/resource/Customer?filters=[["Customer", "customer_name","=", "$customerName"]]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return CustomerList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //mode of payement list
  Future<ModeOfPaymentResponse?> modeOfPayemntList(context) async {
    final url = '/resource/Payment Type';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return ModeOfPaymentResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //payement type  paid to
  Future<PayymentTypePaidToResponse?> payemntTypePaidTo(
      context, String paidTo) async {
    final url = '/resource/Payment Type/$paidTo';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return PayymentTypePaidToResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //recipt
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
    String? employeeId = await _sharedPrefService.getEmployeeId();

    const url = '/resource/Payment Entry';
    // print(
    //  "EmployeeId:$employeeId  logType:$logType time:$time longitude:$longitude latitude:$latitude");

    try {
      // Retrieve cookies from shared preferences
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.post(
        url,
        data: {
          "party_type": "Customer",
          "party": party,
          "payment_type": "Receive",
          "party_name": partyName,
          "posting_date": postingDate,
          "paid_to": paidTo,
          "paid_amount": paidAmount,
          "received_amount": receivedAmount,
          "mode_of_payment": "Wire Transfer",
          // modeOfPayment,
          "reference_no": referenceNo,
          "reference_date": referenceDate
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return ReceiptResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //sales Order
//   Future<SalesOrderResponse?> salesOrder(
//     String customerName,
//     String deliveryDate,
//     List item,
//     BuildContext context,
//     {Map<String, dynamic>? customerDetails} // <-- new optional param
// ) async {
//   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//   String? employeeId = await _sharedPrefService.getEmployeeId();
//
//   const url = '/resource/Sales Order';
//   var request = {
//     "customer": customerName,
//     "delivery_date": deliveryDate,
//     "items": item,
//     if (customerDetails != null) ...customerDetails, // add customer fields if provided
//   };
//
//   try {
//     final cookies = await _sharedPrefService.getCookies();
//
//     debugPrint('Requesting  data from URL: ${baseUrl + url}');
//     final response = await _dio.post(
//       url,
//       data: request,
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': cookies,
//         },
//         validateStatus: (status) {
//           return status! < 500;
//         },
//       ),
//     );
//
//     debugPrint('Response  status: ${response.statusCode}');
//     debugPrint('Response data: ${response.data}');
//     debugPrint('Request data: $request');
//
//     if (response.statusCode == 200) {
//       provider.clearItem();
//       return SalesOrderResponse.fromJson(response.data);
//     } else {
//       apiErrorHandler.handleHttpError(context, response);
//     }
//   } on DioException catch (e) {
//     debugPrint('DioException: ${e.message}');
//     if (e.response != null) {
//       debugPrint('Response data: ${e.response?.data}');
//     }
//     throw Exception('Failed to fetch data');
//   } catch (e) {
//     debugPrint('Exception: $e');
//     throw Exception('Failed to fetch data');
//   }
// }
//
//   Future<SalesOrderResponse?> updateSalesOrder(
//       String name,
//       String customerName,
//       String deliveryDate,
//       List items,
//       BuildContext context, {
//         Map<String, dynamic>? customerDetails,
//       }) async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//     const baseUrlPath = '/resource/Sales Order/';
//     final url = '$baseUrlPath$name';
//
//     try {
//       final cookies = await _sharedPrefService.getCookies();
//
//       // 🔹 Fetch selling_price_list (from Customer or fallback to Selling Settings)
//       final sellingPriceList = await _getSellingPriceList(customerName);
//       debugPrint("Fetched selling_price_list: $sellingPriceList");
//
//       // final request = {
//       //   "customer": customerName,
//       //   "delivery_date": deliveryDate,
//       //   "items": items,
//       //   "selling_price_list": sellingPriceList, // <-- mandatory field added
//       //   if (customerDetails != null) ...customerDetails,
//       // };
//       final request = {
//         "items": items,
//       };
//
//
//       debugPrint('Updating sales order at: ${baseUrl + url}');
//       final response = await _dio.put(
//         url,
//         data: request,
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Cookie': cookies,
//           },
//           validateStatus: (status) => status! < 500,
//         ),
//       );
//
//       debugPrint('PUT Response status: ${response.statusCode}');
//       debugPrint('PUT Response data: ${response.data}');
//       debugPrint('PUT Request data: $request');
//
//       if (response.statusCode == 200) {
//         provider.clearItem();
//         return SalesOrderResponse.fromJson(response.data);
//       } else {
//         apiErrorHandler.handleHttpError(context, response);
//       }
//     } on DioException catch (e) {
//       debugPrint('DioException (PUT): ${e.message}');
//       if (e.response != null) {
//         debugPrint('Response data: ${e.response?.data}');
//       }
//       throw Exception('Failed to update sales order');
//     } catch (e) {
//       debugPrint('Exception: $e');
//       throw Exception('Failed to update sales order');
//     }
//   }
  Future<SalesOrderResponse?> salesOrder(
      String customerName,
      String deliveryDate,
      List item,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
      }) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    const url = '/resource/Sales Order';
    var request = {
      "customer": customerName,
      "delivery_date": deliveryDate,
      "items": item,
      if (customerDetails != null) ...customerDetails,
    };

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting data from URL: ${baseUrl + url}');
      final response = await _dio.post(
        url,
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      debugPrint('Request data: $request');

      if (response.statusCode == 200) {
        provider.clearItem();
        return SalesOrderResponse.fromJson(response.data);
      } else {
        // 🔹 Extract ERP error
        final data = response.data;
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
        throw Exception('Failed to create sales order');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        final data = e.response?.data;
        debugPrint('Response data: $data');
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
      }
      throw Exception('Failed to create sales order');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception(e.toString());
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
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    const baseUrlPath = '/resource/Sales Order/';
    final url = '$baseUrlPath$name';

    try {
      final cookies = await _sharedPrefService.getCookies();

      // final request = {
      //   "items": items,
      // };
      final request = {
        "delivery_date": deliveryDate,
        "items": items,
      };

      debugPrint('Updating sales order at: ${baseUrl + url}');
      final response = await _dio.put(
        url,
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('PUT Response status: ${response.statusCode}');
      debugPrint('PUT Response data: ${response.data}');
      debugPrint('PUT Request data: $request');

      if (response.statusCode == 200) {
        provider.clearItem();
        return SalesOrderResponse.fromJson(response.data);
      } else {
        final data = response.data;
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
        throw Exception('Failed to update sales order');
      }
    } on DioException catch (e) {
      debugPrint('DioException (PUT): ${e.message}');
      if (e.response != null) {
        final data = e.response?.data;
        debugPrint('Response data: $data');
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
      }
      throw Exception('Failed to update sales order');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception(e.toString());
    }
  }



  //payment recipt
  Future<GetPaymentEntryResponse?> getPaymentReecipt(context) async {
    final url =
        '/resource/Payment Entry?fields=["name","payment_type","posting_date","mode_of_payment","party_type","party","party_name","party_balance","paid_from","paid_from_account_balance","paid_to","paid_to_account_type","paid_amount","received_amount","reference_no","reference_date","remarks"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetPaymentEntryResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  //S Ord
  
  Future<Map<String, dynamic>> fetchCustomerDetails(
      BuildContext context,
      String customerName,
      ) async {
    try {
      // Get company name from SharedPreferences
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      final url =
          '/method/erpnext.accounts.party.get_party_details?company=${Uri.encodeComponent(company)}&party=$customerName&doctype=Sales Order';

      print("Fetching customer details with URL: $url");

      final cookies = await _sharedPrefService.getCookies();

      // Debugging output
      debugPrint('Requesting data from URL: ${baseUrl + url}');

      // Sending POST request using Dio
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500; // Accepts status less than 500
          },
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        throw Exception('Failed to fetch customer details');
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch customer details due to DioException');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch customer details');
    }
  }

  Future<String> _getSellingPriceList(String customerName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // 1. Try fetching default_price_list from Customer
      final customerResponse = await _dio.get(
        '/resource/Customer/$customerName',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (customerResponse.statusCode == 200) {
        final customerData = customerResponse.data;
        final defaultPriceList = customerData["data"]?["default_price_list"];
        if (defaultPriceList != null && defaultPriceList.toString().isNotEmpty) {
          return defaultPriceList;
        }
      }

      // 2. If not available, fetch from Selling Settings
      final settingsResponse = await _dio.get(
        '/method/frappe.client.get_single_value?doctype=Selling+Settings&field=selling_price_list',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (settingsResponse.statusCode == 200) {
        return settingsResponse.data["message"];
      } else {
        throw Exception("Failed to fetch selling price list from Selling Settings");
      }
    } catch (e) {
      debugPrint("Error fetching selling_price_list: $e");
      throw Exception("Failed to fetch selling price list");
    }
  }

  // Future<Map<String, dynamic>> fetchItemDetail({
  //   required BuildContext context,
  //   required String itemCode,
  //   required double quantity,
  //   required String currency,
  // }) async {
  //   const url = '/method/erpnext.stock.get_item_details.get_item_details';
  //
  //   try {
  //     // Get company from SharedPreferences
  //     final company = await _sharedPrefService.getCompany();
  //
  //     if (company == null || company.isEmpty) {
  //       throw Exception("Company not found in SharedPreferences");
  //     }
  //
  //     final data = {
  //       "args": {
  //         "item_code": itemCode,
  //         "company": company,
  //         "selling_price_list": "Standard Selling",
  //         "currency": currency,
  //         "qty": quantity,
  //         "doctype": "Sales Order"
  //       }
  //     };
  //
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.post(
  //       url,
  //       data: data,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     debugPrint('Item Details Response: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return response.data;
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       throw Exception('Failed to fetch item details');
  //     }
  //   } catch (e) {
  //     debugPrint('Error in fetchItemDetails: $e');
  //     throw Exception('Failed to fetch item details');
  //   }
  // }
  Future<Map<String, dynamic>> fetchItemDetail({
    required BuildContext context,
    required String itemCode,
    required double quantity,
    required String currency,
    required String customerName, // add customerName here
  }) async {
    const url = '/method/erpnext.stock.get_item_details.get_item_details';

    try {
      // Get company from SharedPreferences
      final company = await _sharedPrefService.getCompany();
      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      // Get selling_price_list (customer -> fallback to settings)
      final sellingPriceList = await _getSellingPriceList(customerName);

      final data = {
        "args": {
          "item_code": itemCode,
          "company": company,
          "selling_price_list": sellingPriceList,
          "currency": currency,
          "qty": quantity,
          "doctype": "Sales Order"
        }
      };

      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Item Details Response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        throw Exception('Failed to fetch item details');
      }
    } catch (e) {
      debugPrint('Error in fetchItemDetails: $e');
      throw Exception('Failed to fetch item details');
    }
  }


  Future<int?> fetchAllowMultipleItems(BuildContext context) async {
    const url =
        '/method/frappe.client.get_single_value?doctype=Selling+Settings&field=allow_multiple_items';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Allow multiple items response: ${response.data}');

      if (response.statusCode == 200) {
        // ✅ ERP returns { "message": 1 } or { "message": 0 }
        return (response.data['message'] as num?)?.toInt();
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching allow_multiple_items: $e');
      return null;
    }
  }


  //S Ord

  // //getsales order
  // Future<GetSalesOrderResponse?> getSalesOrder(
  //     context, int limitStart, int pageLength) async {
  //   final url =
  //       '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status","transaction_date"]&limit_page_lengthlimit_start=$limitStart&limit_page_length=$pageLength';

  //   // '/resource/Sales Order?fields=["name","customer","delivery_date","creation","status","items"]';

  //   try {
  //     final cookies = await _sharedPrefService.getCookies();

  //     debugPrint('Requesting  data from URL: ${baseUrl + url}');
  //     final response = await _dio.get(
  //       url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) {
  //           return status! < 500;
  //         },
  //       ),
  //     );

  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');

  //     if (response.statusCode == 200) {
  //       // print("Response details :::::${response.data[0].itemCode}");
  //       return GetSalesOrderResponse.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch  data');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch  data');
  //   }
  // }
// Get Sales Order (sorted by latest name first)
Future<GetSalesOrderResponse?> getSalesOrder(
    context, int limitStart, int pageLength) async {
  final url =
      '/resource/Sales Order'
      '?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status","transaction_date"]'
      '&limit_start=$limitStart'
      '&limit_page_length=$pageLength'
      '&order_by=name desc'; // 🔥 Sort by name descending

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Sales Order data from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return GetSalesOrderResponse.fromJson(response.data);
    } else {
      apiErrorHandler.handleHttpError(context, response);
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch Sales Order');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Sales Order');
  }
}
  Future<SalesOrderDetails?> getSalesOrderDetails(String orderName) async {
    final url = '/resource/Sales Order/$orderName';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        return SalesOrderDetails.fromJson(response.data['data']);
      } else {
        debugPrint("Error fetching order: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception fetching order details: $e");
      return null;
    }
  }

  Future<GetSalesOrderResponse?> getSearchSalesOrder(
    context,
    String? salesId,
    String? customerId,
    String? customerName,
  ) async {
    String url;
    // final url = salesId != null
    //     ? '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "name","Like", "%$salesId%"],]'
    //     : customerId != null
    //         ? '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "customer","Like", "%$customerId%"]]'
    //         : customerName != null
    //             ? '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "customer_name","Like", "%$customerName%"]]'
    //             : '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "name","Like", "%$salesId%"],["Sales Order", "customer","Like", "%$customerId%"],["Sales Order", "customer_name","Like", "%$customerName%"]]';

    // Construct the query based on the provided values
    List<String> filters = [];

    if (salesId != null && salesId.isNotEmpty) {
      filters.add('["Sales Order", "name", "Like", "%$salesId%"]');
    }
    if (customerId != null && customerId.isNotEmpty) {
      filters.add('["Sales Order", "customer", "Like", "%$customerId%"]');
    }
    if (customerName != null && customerName.isNotEmpty) {
      filters
          .add('["Sales Order", "customer_name", "Like", "%$customerName%"]');
    }

    // Build the final URL with filters
    if (filters.isNotEmpty) {
      url =
          '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status","transaction_date"]&filters=[${filters.join(",")}]';
    } else {
      throw Exception("Please provide at least one search parameter.");
    }
    print("Test url ::: $url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetSalesOrderResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

Future<GetSalesOrderResponse?> getSalesOrderDateFilter(
  context,
  String startDate,
  String endDate,
) async {
  final url =
      '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status","transaction_date"]&filters=[["delivery_date", ">=", "$startDate"], ["delivery_date", "<=", "$endDate"]]';

  print("Test url ::: $url");

  try {
    final cookies = await _sharedPrefService.getCookies();

    debugPrint('Requesting Sales Order data from URL: ${baseUrl + url}');
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        },
        validateStatus: (status) {
          return status! < 500; // only throw for server errors
        },
      ),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');

    if (response.statusCode == 200) {
      return GetSalesOrderResponse.fromJson(response.data);
    } else {
      apiErrorHandler.handleHttpError(context, response);
    }
  } on DioException catch (e) {
    debugPrint('DioException: ${e.message}');
    if (e.response != null) {
      debugPrint('Response data: ${e.response?.data}');
    }
    throw Exception('Failed to fetch Sales Order data');
  } catch (e) {
    debugPrint('Exception: $e');
    throw Exception('Failed to fetch Sales Order data');
  }
}


  Future<GetPaymentEntryResponse?> getReciptDateFilter(
    context,
    String startDate,
    String endDate,
  ) async {
    final url =
        '/resource/Payment Entry?fields=["name","payment_type","posting_date","mode_of_payment","party_type","party","party_name","party_balance","paid_from","paid_from_account_balance","paid_to","paid_to_account_type","paid_amount","received_amount","reference_no","reference_date","remarks"]&filters=[["Payment+Entry","posting_date","Between",["$startDate","$endDate"]]]';

    print("Test url ::: $url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetPaymentEntryResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

//search name
  Future<GetPaymentEntryResponse?> getReciptNameSearch(
    context,
    String customerName,
  ) async {
    final url =
        '/resource/Payment Entry?fields=["name","payment_type","posting_date","mode_of_payment","party_type","party","party_name","party_balance","paid_from","paid_from_account_balance","paid_to","paid_to_account_type","paid_amount","received_amount","reference_no","reference_date","remarks"]&filters=[["Payment Entry", "name","Like", "%$customerName%"]]';

    print("Test url ::: $url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetPaymentEntryResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  Future<GetSalesOrderResponse?> getSearchCustomerSales(
    context,
    String customerId,
  ) async {
    final url =
        '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "customer","Like", "%$customerId%"]]';

    print("Test url ::: $url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetSalesOrderResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }

  Future<GetSalesOrderResponse?> getSearchCustomerNameSales(
    context,
    String customerName,
  ) async {
    final url =
        '/resource/Sales Order?fields=["name","customer_name","customer","delivery_date","creation","grand_total","status"]&filters=[["Sales Order", "customer_name","Like", "%$customerName%"]]';

    print("Test url ::: $url");
    try {
      final cookies = await _sharedPrefService.getCookies();

      debugPrint('Requesting  data from URL: ${baseUrl + url}');
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      debugPrint('Response  status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // print("Response details :::::${response.data[0].itemCode}");
        return GetSalesOrderResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch  data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch  data');
    }
  }
}

class ApiErrorHandler {
  final SharedPrefService _sharedPrefService = SharedPrefService();

  void handleHttpError(BuildContext context, Response response) {
    if (response.statusCode == 401) {
      debugPrint('Unauthorized: Incorrect username, password, or domain.');
      throw Exception('Unauthorized: Incorrect username, password, or domain.');
    } else if (response.data['_server_messages'] != null) {
      String serverMessages = response.data['_server_messages'].toString();
      if (serverMessages.contains('PermissionError') ||
          response.data['_error_message'] != null &&
              response.data['_error_message']
                  .contains('Insufficient Permission')) {
        debugPrint(
            'Permission Error: Insufficient permission for this operation.');
        //   Fluttertoast.showToast(msg: 'Permission Error: Insufficient permission for this operation.');
        logout(context);
      } else if (response.data['session_expired'] == 1) {
        debugPrint('Session expired. Logging out...');
        logout(context);
        throw Exception('Session expired. Please log in again.');
      } else {
        // throw Exception('Failed to fetch data');
      }
    } else {
      // throw Exception('Failed to fetch data');
    }
  }

  Future<void> logout(BuildContext context) async {
    await _sharedPrefService.clearLoginDetails();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
