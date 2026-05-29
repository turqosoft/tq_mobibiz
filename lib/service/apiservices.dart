// ignore_for_file: body_might_complete_normally_nullable

import 'dart:convert';
import 'dart:typed_data';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
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
import 'package:sales_ordering_app/service/user_cache_service.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/login.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart'as customer_models;
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer;

import 'package:http_parser/http_parser.dart';

// import 'package:sales_ordering_app/view/material_demand/material_demand.dart';
import 'package:sales_ordering_app/model/material_demand_model.dart';

import '../model/create_quotation_response.dart';
import '../model/get_quotation_response.dart';
import '../model/pos_invoice_model.dart';
// import 'package:sales_ordering_app/model/sales_invoice_model.dart';

class ApiService {
  final String baseUrl;
  final Dio _dio;
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final apiErrorHandler = ApiErrorHandler();
  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));
  // Strips /api to get the root server URL for file paths
  String get serverUrl => baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;

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
  Future<List<String>> fetchCompanyList() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/resource/Company',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      final list = response.data?['data'] as List<dynamic>?;

      if (list == null) return [];

      return list
          .map((e) => e['name']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      debugPrint('❌ fetchCompanyList error: $e');
      return [];
    }
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

      if (response.statusCode == 200 && response.data != null) {
  final details = HomeTileResponse.fromJson(response.data);
  if (details.message == null || details.message!.isEmpty) {
    throw Exception("No home tiles available for this user.");
  }
  return details;
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
//profile

  Future<Map<String, dynamic>?> fetchUserDetails(String email) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/resource/User/$email',
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
      }
    } catch (e) {
      debugPrint('fetchUserDetails error: $e');
    }
    return null;
  }


  //profile

  // Attendance
  // Future<AttendanceDetails?> attendance(String employeeId, context) async {
  //   var url =
  //       '/resource/Attendance?fields=["employee_name","status","attendance_date","employee"]&filters=[["employee","=","$employeeId"]]';
  //
  //   try {
  //     // Retrieve cookies from shared preferences
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     debugPrint('Requesting attendance data from URL: ${baseUrl + url}');
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
  //
  //     debugPrint('Response attendance status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return AttendanceDetails.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch attendance data');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch attendance data');
  //   }
  // }
  Future<AttendanceDetails?> attendanceByEmployeeName(
      String employeeName, context) async {

    final url =
        '/resource/Attendance?fields=["employee_name","status","attendance_date"]'
        '&filters=[["employee_name","=","$employeeName"]]';

    // debugPrint('ATTENDANCE API URL => $url');

    try {
      final cookies = await _sharedPrefService.getCookies();
      // debugPrint('ATTENDANCE API COOKIES => $cookies');

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

      // debugPrint('ATTENDANCE API STATUS => ${response.statusCode}');
      // debugPrint('ATTENDANCE API RAW RESPONSE => ${response.data}');

      if (response.statusCode == 200) {
        final model = AttendanceDetails.fromJson(response.data);
        debugPrint('ATTENDANCE PARSED COUNT => ${model.data?.length}');
        return model;
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      // debugPrint('attendanceByEmployeeName Error => $e');
    }
    return null;
  }
  Future<String?> fetchEmployeeNameByEmployeeId(
      String employeeId, context) async {
    final url = '/resource/Employee/$employeeId';

    debugPrint('EMPLOYEE API URL => $url');

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

      // debugPrint('EMPLOYEE API STATUS => ${response.statusCode}');
      // debugPrint('EMPLOYEE API RAW RESPONSE => ${response.data}');

      if (response.statusCode == 200) {
        final employeeName = response.data['data']?['employee_name'];
        debugPrint('EMPLOYEE NAME FROM EMPLOYEE DOC => $employeeName');
        return employeeName;
      }
    } catch (e) {
      debugPrint('fetchEmployeeNameByEmployeeId Error => $e');
    }

    return null;
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
  Future<bool> isUserEmployee(BuildContext context) async {
    try {
      String? loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) return false;

      final response = await _dio.get(
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

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data'].isNotEmpty) {
        return true; // ✅ Employee exists
      }
    } catch (e) {
      debugPrint("Error checking employee status: $e");
    }
    return false; // ❌ Not an employee
  }

  Future<CheckInCheckOut?> checkinOrCheckout(
      String logType,
      String time,
      String longitude,
      String latitude,
      String city,
      String state,
      String area,
      String customer,
      String remarks,// 👈 add this
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
          "customer": customer,
          "remarks": remarks,
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
    try {
      // 1️⃣ Get the logged-in user's email/identifier
      final loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) {
        debugPrint('Error: Could not get logged-in user identifier.');
        return null;
      }

      // 2️⃣ Fetch Employee record using user email (link field "user_id")
      final employeeResponse = await _dio.get(
        '/resource/Employee',
        queryParameters: {
          'filters': '[["user_id","=","$loggedInUser"]]',
          'fields': '["name"]',
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
        debugPrint('No employee found for user: $loggedInUser');
        return null;
      }

      final employeeId = employeeResponse.data['data'][0]['name'];

      // 3️⃣ Fetch latest Employee Checkin for that employee
      const baseUrl = '/resource/Employee Checkin';
      final queryParams =
          '?filters=[["employee","=","$employeeId"]]'
          '&fields=["log_type","customer","remarks","time"]'
          '&order_by=creation desc&limit_page_length=1';

      final response = await _dio.get(
        '$baseUrl$queryParams',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': await _sharedPrefService.getCookies(),
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data'].isNotEmpty) {
        return response.data['data'][0]; // contains log_type and customer
      } else {
        debugPrint('No checkin records found for employee: $employeeId');
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
  String parseFrappeError(dynamic responseData) {
    // 1️⃣ Direct exception message (ex: InvalidEmailAddressError)
    if (responseData["exception"] != null) {
      return responseData["exception"];
    }

    // 2️⃣ Parse _server_messages (warnings + errors)
    if (responseData["_server_messages"] != null) {
      try {
        final raw = jsonDecode(responseData["_server_messages"]);
        final messages = raw.map((msg) {
          final decoded = jsonDecode(msg);
          return decoded["message"] ?? decoded.toString();
        }).toList();

        return messages.join("\n"); // Show all warnings + errors neatly
      } catch (e) {
        return "Unknown server error";
      }
    }

    return "Unknown error occurred";
  }

  Future<dynamic> createCustomer(
      Map<String, dynamic> customerData, BuildContext context) async {
    const url = "/method/frappe.client.save";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: {"doc": customerData},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      // ✅ CASE 1: Success (ERPNext sometimes returns no "data")
      if (response.statusCode == 200) {
        // If "data" exists -> success
        if (response.data["data"] != null) {
          return true;
        }

        // If no error messages and status = 200 -> also success
        if (response.data["_server_messages"] == null)
          return customerData["customer_name"]; {
          return true;
        }
      }

      // ❌ CASE 2: ERPNext error (_server_messages present)
      if (response.data["_server_messages"] != null) {
        final serverMessages = jsonDecode(response.data["_server_messages"]);
        final firstMessage = jsonDecode(serverMessages[0]);
        return firstMessage["message"];
      }

      return "Failed to create customer";
    } catch (e) {
      debugPrint("Create customer error: $e");
      return "Failed to create customer";
    }
  }

  Future<dynamic> createAddress(
      Map<String, dynamic> addressData, BuildContext context) async {
    const url = "/method/frappe.client.save";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: {"doc": addressData},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data["data"] != null) {
          return true;
        }

        if (response.data["_server_messages"] == null) {
          return true;
        }
      }

      if (response.data["_server_messages"] != null) {
        final serverMessages = jsonDecode(response.data["_server_messages"]);
        final firstMessage = jsonDecode(serverMessages[0]);
        return firstMessage["message"];
      }

      return "Failed to create address";
    } catch (e) {
      debugPrint("Create address error: $e");
      return "Failed to create address";
    }
  }

  Future<bool> checkCustomerExists(String name, BuildContext context) async {
    final url = "/resource/Customer/$name";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
          validateStatus: (_) => true,
        ),
      );

      // Customer Exists → status = 200
      if (response.statusCode == 200 && response.data["data"] != null) {
        return true;
      }

      // Customer NOT found → response contains exc_type: DoesNotExistError
      if (response.data is Map && response.data["exc_type"] == "DoesNotExistError") {
        return false;
      }

      return false;
    } catch (e) {
      debugPrint("checkCustomerExists ERROR: $e");
      return false;
    }
  }

  final UserCacheService _userCache = UserCacheService();

// ✅ Optimized method to get sales person with caching
  Future<String> getSalesPersonWithCache() async {
    // Check cache first
    final cached = _userCache.salesPerson;
    if (cached != null) {
      debugPrint('Using cached sales person: $cached');
      return cached;
    }

    // Fetch if not cached
    final loggedUser = await getLoggedInUserIdentifier();
    if (loggedUser == null) throw Exception("Could not get logged in user");

    final firstName = await fetchUserFirstName(loggedUser);
    if (firstName == null) throw Exception("Could not get first name");

    final employeeId = await fetchEmployeeByFirstName(firstName);
    if (employeeId == null) throw Exception("Could not get employee");

    final salesPerson = await fetchSalesPersonByEmployee(employeeId);
    if (salesPerson == null) throw Exception("Could not get sales person");

    // Cache the result
    _userCache.cacheSalesPerson(salesPerson, loggedUser);

    return salesPerson;
  }

  Future<CustomerList?> customerList(
      BuildContext context,
      String? salesPerson, {
        bool filterBySalesPerson = true,
        int pageLength = 20,
        int start = 0,
        bool onlyLiked = false,
        String? loggedUser,
      }) async {
    final url = '/resource/Customer';
    List filters = [];
    if (filterBySalesPerson && salesPerson != null) {
      filters.add(["Sales Team", "sales_person", "=", salesPerson]);
    }
    // ⭐ Add liked filter
    if (onlyLiked && loggedUser != null) {
      filters.add(["Customer", "_liked_by", "like", "%$loggedUser%"]);
    }
    final queryParams = {
      "fields": jsonEncode([
        "name",
        "tax_id",
        "gstin",
        "territory",
        "customer_primary_contact",
        "customer_primary_address",
        "primary_address",
        "mobile_no",
        "email_id",
        "tax_category",
        "customer_group",
        "_liked_by"
      ]),
      // "filters": jsonEncode([
      //   ["Sales Team", "sales_person", "=", salesPerson]
      // ]),
      "filters": jsonEncode(filters),

      "limit_page_length": pageLength,
      "limit_start": start,
    };

    try {
      final cookies = await _sharedPrefService.getCookies();

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

      debugPrint('Customer Fetch Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return CustomerList.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch customers');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch customers');
    }

    return null;
  }
  Future<bool> toggleCustomerLike({
    required BuildContext context,
    required String customerName,
    required bool add,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        "/method/frappe.desk.like.toggle_like",
        queryParameters: {
          "doctype": "Customer",
          "name": customerName,
          "add": add ? "Yes" : "No",
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
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
      debugPrint("toggleCustomerLike error: $e");
      return false;
    }
  }

  Future<void> fetchCustomerDetailss(
      customer_models.Data customer,
      BuildContext context
      ) async {

    final encodedName = Uri.encodeComponent(customer.name ?? "");
    final url =
        '/method/frappe.desk.form.load.getdoc?doctype=Customer&name=$encodedName';

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

        /// ⭐ Extract ALL sales persons
        final salesTeam = data['sales_team'];

        if (salesTeam != null && salesTeam.isNotEmpty) {
          customer.salesPersons =
              salesTeam.map<String>((e) => e['sales_person'].toString()).toList();
        }

        /// Dashboard data
        final dashboardList = data['__onload']?['dashboard_info'];

        if (dashboardList != null && dashboardList.isNotEmpty) {
          final dashboard = dashboardList[0];

          customer.billingThisYear =
              (dashboard['billing_this_year'] ?? 0).toDouble();

          customer.totalUnpaid =
              (dashboard['total_unpaid'] ?? 0).toDouble();
        }
      }

    } catch (e) {
      debugPrint('Error fetching customer details for ${customer.name}: $e');
    }
  }
  Future<double> fetchCustomerOutstandingBalance({
    required String customerName,
    required BuildContext context,
  }) async {
    try {
      final encodedName = Uri.encodeComponent(customerName);
      final url =
          '/method/erpnext.accounts.utils.get_balance_on'
          '?party_type=Customer&party=$encodedName';

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
        return (response.data['message'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error fetching balance for $customerName: $e');
      return 0.0;
    }
  }

  Future<int> fetchCustomerCount({
    required BuildContext context,
    String? salesPerson,
    bool filterBySalesPerson = true,
    String? search,
  }) async {
    final url = '/method/frappe.desk.reportview.get_count';

    List filters = [];

    // ✅ Apply Sales Person filter only if toggle is ON
    if (filterBySalesPerson && salesPerson != null) {
      filters.add(["Sales Team", "sales_person", "=", salesPerson]);
    }

    // ✅ Apply search filter if provided
    if (search != null && search.isNotEmpty) {
      filters.add(["name", "like", "%$search%"]);
    }

    final queryParams = {
      "doctype": "Customer",
      "filters": jsonEncode(filters),
    };

    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      queryParameters: queryParams,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data["message"] ?? 0;
    }

    throw Exception("Failed to fetch customer count");
  }

  Future<CustomerList?> customerSearchPaged({
    required BuildContext context,
    String? salesPerson,
    bool filterBySalesPerson = true,
    required String search,
    required int pageLength,
    required int start,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    List filters = [];

    // ✅ Apply Sales Person filter only when toggle is ON
    if (filterBySalesPerson && salesPerson != null) {
      filters.add(["Sales Team", "sales_person", "=", salesPerson]);
    }

    // ✅ Always apply search filter
    filters.add(["name", "like", "%$search%"]);

    final queryParams = {
      "fields": jsonEncode([
        "name",
        "tax_id",
        "gstin",
        "territory",
        "customer_primary_contact",
        "customer_primary_address",
        "primary_address",
        "mobile_no",
        "email_id",
        "tax_category",
        "territory",
        "customer_group",
        "_liked_by"
      ]),
      "filters": jsonEncode(filters),
      "limit_page_length": pageLength,
      "limit_start": start,
    };

    final response = await _dio.get(
      "/resource/Customer",
      queryParameters: queryParams,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      return CustomerList.fromJson(response.data);
    }

    return null;
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

  // Future<List<Map<String, dynamic>>> fetchCustomerSalesInvoices({
  //   required String customerName,
  //   required BuildContext context,
  // }) async {
  //   try {
  //     final encodedFilter = Uri.encodeComponent(
  //       '[["Sales Invoice","customer","=","$customerName"]]',
  //     );
  //     final encodedFields = Uri.encodeComponent(
  //       '["name","customer","posting_date","due_date","status","grand_total","rounded_total"]',
  //     );
  //
  //     final url =
  //         '/resource/Sales Invoice?filters=$encodedFilter&fields=$encodedFields';
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
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = response.data['data'] as List<dynamic>? ?? [];
  //       // 👇 Return full map instead of just the name string
  //       return data.map((e) => Map<String, dynamic>.from(e)).toList();
  //     }
  //     return [];
  //   } catch (e) {
  //     debugPrint('Error fetching invoices for $customerName: $e');
  //     return [];
  //   }
  // }

  Future<List<Map<String, dynamic>>> fetchCustomerSalesInvoices({
    required String customerName,
    required BuildContext context,
  }) async {
    try {
      final encodedFilter = Uri.encodeComponent(
        '[["Sales Invoice","customer","=","$customerName"],'
            '["Sales Invoice","status","not in","Paid,Cancelled"]]', // 👈 exclude Paid & Cancelled
      );
      final encodedFields = Uri.encodeComponent(
        '["name","customer","posting_date","due_date","status","grand_total","rounded_total"]',
      );

      // 👇 page_length=0 removes the default 20-item cap — returns all matching records
      final url =
          '/resource/Sales Invoice?filters=$encodedFilter&fields=$encodedFields&limit=999999';

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
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching invoices for $customerName: $e');
      return [];
    }
  }

// For General Ledger
  Future<Map<String, dynamic>?> FetchGeneralLedger(
      BuildContext context,
      String customer,
      String fromDate,
      String toDate,
      ) async {
    const url = "/method/tqerp_mobibiz_serv.api.get_general_ledger";

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
  // For Accounts Receivable
  Future<String?> fetchLetterHeadContent(BuildContext context) async {
    const url = "/resource/Letter Head/ccent letterhead";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data["data"]["content"] as String?;
        return content;
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint("fetchLetterHeadContent Error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchAccountsReceivable(
      BuildContext context,
      String company,
      String postingDate,
      String party,
      String range, // <-- NEW (example: "30,60")
      ) async {

    const url = "/method/tqerp_mobibiz_serv.api.get_accounts_receivable";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        queryParameters: {
          "company": company,
          "posting_date": postingDate,
          "party": party,
          "range": range, // <-- PASS RANGE
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("ACCOUNTS RECEIVABLE RAW RESPONSE: ${response.data}");
        return response.data["message"]; // <-- IMPORTANT: unwrap `message`
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint("fetchAccountsReceivable Error: $e");
    }

    return null;
  }


  Future<Uint8List?> generatePdfFromHtml(
      BuildContext context, String html) async {

    const url = "/method/frappe.utils.print_format.report_to_pdf";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final formData = FormData.fromMap({
        "html": html,
        "orientation": "Landscape",
        "blob": "1",
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            "Cookie": cookies,
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Uint8List) {
          return response.data;
        } else {
          try {
            final text = utf8.decode(response.data);
            debugPrint("PDF ERROR RESPONSE (decoded HTML): $text");
          } catch (_) {
            debugPrint("PDF ERROR RESPONSE (raw bytes): ${response.data}");
          }
          return null;
        }
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }

    } catch (e) {
      debugPrint("generatePdfFromHtml Error: $e");
    }

    return null;
  }

  Future<bool> createPaymentCollection(
      Map<String, dynamic> paymentData, BuildContext context) async {
    const url = "/resource/Payment Collection";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: paymentData,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Create payment collection error: $e");
      return false;
    }
  }
  Future<List<String>> fetchModeOfPayments() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/method/frappe.desk.search.search_link',
        queryParameters: {
          "doctype": "Mode of Payment",
          "reference_doctype": "Payment Collection",
          "txt": "",
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List message = response.data['message'] ?? [];
        return message.map((e) => e['value'].toString()).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching mode of payments: $e');
      return [];
    }
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
  Future<bool> getRestrictPickListForWarehouseUser(BuildContext context) async {
    const url = "/method/frappe.client.get_single_value"
        "?doctype=Stock+Settings&field=restrict_picklist_for_warehouse_user";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        baseUrl + url,
        options: Options(
          headers: {'Cookie': cookies},
          validateStatus: (s) => s! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data["message"] == 1;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<String?> fetchWarehouseForUser(String userId) async {
    final url =
        '/resource/Warehouse?filters=[["Warehouse","dflt_user","=", "$userId"]]'
        '&fields=["name","dflt_user"]';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        baseUrl + url,
        options: Options(
          headers: {'Cookie': cookies},
          validateStatus: (s) => s! < 500,
        ),
      );

      if (response.statusCode == 200 &&
          response.data["data"] != null &&
          response.data["data"].isNotEmpty) {
        return response.data["data"][0]["name"];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> fetchAllPickLists(
      BuildContext context, {
        String? warehouse,
      }) async {

    String url =
        '/resource/Pick List'
        '?fields=["name","status","company","parent_warehouse","customer","creation","locations.sales_order","locations.qty","locations.picked_qty"]'
        '&filters=[["Pick List","status","=","Draft"]]'
        '&order_by=creation desc';

    // If warehouse restriction required → add warehouse filter
    if (warehouse != null) {
      url =
      '/resource/Pick List'
          '?fields=["name","status","company","parent_warehouse","customer","creation","locations.sales_order","locations.qty","locations.picked_qty"]'
          '&filters=[["Pick List","status","=","Draft"],'
          '["Pick List","parent_warehouse","=","$warehouse"]]'
          '&order_by=creation desc';
    }

    try {
      final cookies = await _sharedPrefService.getCookies();

      print("🔍 Fetching picklists with URL: $url");

      final response = await _dio.get(
        baseUrl + url,
        options: Options(
          headers: {'Cookie': cookies},
          validateStatus: (s) => s! < 500,
        ),
      );

      print("📥 Picklist response: ${response.data}");

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print("❌ Picklist API error: $e");
      return null;
    }
  }


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

  String formatErpError(String raw) {
    if (raw.isEmpty) return raw;

    String msg = raw;

    // Remove frappe exception prefix
    msg = msg.replaceAll(RegExp(r'frappe\.exceptions\.\w+: '), '');

    // Remove HTML tags like <strong>
    msg = msg.replaceAll(RegExp(r'<[^>]*>'), '');

    // Fix double spaces
    msg = msg.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Replace 'None' with empty or readable text
    msg = msg.replaceAll("None", "N/A");

    return msg;
  }

  Future<Map<String, dynamic>> updatePickedQty(
      BuildContext context,
      String pickListName,
      List<Map<String, dynamic>> locations,
      bool autoSubmit
      ) async {

    final url = '$baseUrl/resource/Pick List/$pickListName';
    final Map<String, dynamic> updatedData = {
      "data": {
        "name": pickListName,
        // "scan_mode": 1,
        "docstatus": autoSubmit ? 1 : 0,  // ← Toggle used here
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
        return {"success": true};
      } else {
        // Extract ERPNext error message
        final rawError = response.data?["exception"] ??
            response.data?["message"] ??
            "Unknown error";

        final cleanedError = formatErpError(rawError);

        debugPrint("❌ ERPNext Update Error: $cleanedError");

        return {
          "success": false,
          "message": cleanedError,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Unexpected error: $e",
      };
    }
  }


//pick list

// Pick Item

  Future<List<Map<String, dynamic>>> fetchPickList({String? warehouse}) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // Build filters dynamically
      List<List<dynamic>> filters = [
        ["docstatus", "=", 0], // Draft only
      ];

      // Add warehouse filter if provided
      if (warehouse != null && warehouse.isNotEmpty) {
        filters.add(["Pick", "warehouse", "=", warehouse]);
      }

      final response = await _dio.get(
        "/resource/Pick",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "docstatus",
            "date",
            "delivery_note",
            "sales_invoice",
            "customer",
            "warehouse", // Add warehouse to fields
          ]),
          "filters": jsonEncode(filters),
          "order_by": "date desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("fetchPickList Error: $e");
    }

    return [];
  }


  Future<Map<String, dynamic>?> fetchPickDetail(String pickName) async {
    debugPrint("➡️ fetchPickDetail: $pickName");

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Pick/$pickName",
        options: Options(headers: {'Cookie': cookies}),
      );

      debugPrint("📦 Pick Detail response: ${response.data}");

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data["data"]);
      }
    } catch (e, stack) {
      debugPrint("❌ fetchPickDetail Error: $e");
      debugPrint("$stack");
    }

    return null;
  }
  Future<bool> updatePick({
    required String pickName,
    required String warehouse,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.put(
        "/resource/Pick/$pickName",
        data: {
          "warehouse": warehouse,
          "items": items,
        },
        options: Options(
          headers: {
            "Cookie": cookies,
            "Content-Type": "application/json",
          },
        ),
      );

      debugPrint("✅ Pick updated: ${response.data}");
      return response.statusCode == 200;
    } catch (e, stack) {
      debugPrint("❌ updatePick error: $e");
      debugPrint("$stack");
      return false;
    }
  }
  Future<bool> submitPick({required String pickName}) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.put(
        "/resource/Pick/$pickName",
        data: {"docstatus": 1},
        options: Options(
          headers: {
            "Cookie": cookies,
            "Content-Type": "application/json",
          },
        ),
      );

      debugPrint("✅ Pick submitted: ${response.data}");
      return response.statusCode == 200;
    } catch (e, stack) {
      debugPrint("❌ submitPick error: $e");
      debugPrint("$stack");
      return false;
    }
  }
  Future<List<String>> searchWarehouses(String query) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // 🔹 Fetch company from SharedPreferences
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      // 🔹 Build ERPNext filters
      final filters = jsonEncode([
        ["Warehouse", "company", "in", ["", company]],
        ["Warehouse", "is_group", "=", 0],
      ]);

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "doctype": "Warehouse",
          "reference_doctype": "Pick Items",
          "txt": query,
          "filters": filters,
        },
        options: Options(
          headers: {
            'Cookie': cookies,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List list = response.data["message"] ?? [];
        return list
            .map<String>((e) => e["value"].toString())
            .toList();
      }
    } catch (e, stack) {
      debugPrint("❌ searchWarehouses error: $e");
      debugPrintStack(stackTrace: stack);
    }

    return [];
  }

  Future<List<String>> fetchAvailableSerialNumbers({
    required String itemCode,
    required String warehouse,
    int qty = 1000,
  }) async {
    debugPrint("➡️ fetchAvailableSerialNumbers: item=$itemCode, warehouse=$warehouse");

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/erpnext.stock.doctype.serial_no.serial_no.auto_fetch_serial_number",
        queryParameters: {
          'qty': qty,
          'warehouse': warehouse,
          'item_code': itemCode,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      debugPrint("📦 Serial Numbers response: ${response.data}");

      if (response.statusCode == 200) {
        final message = response.data["message"];
        if (message is List) {
          return message.map((e) => e.toString()).toList();
        }
      }
    } catch (e, stack) {
      debugPrint("❌ fetchAvailableSerialNumbers Error: $e");
      debugPrint("$stack");
    }

    return [];
  }
  Future<List<String>> fetchItemBarcodes(String itemCode) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Item/$itemCode",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        final barcodes = data["barcodes"] as List<dynamic>? ?? [];

        return barcodes
            .map((b) => b["barcode"]?.toString() ?? "")
            .where((b) => b.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint("fetchItemBarcodes error: $e");
    }

    return [];
  }
//pick item

// purchase receipt

  Future<String?> getUserBranch(BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // 1️⃣ Always get the logged in user id from Frappe
      final userIdentifier = await getLoggedInUserIdentifier();

      if (userIdentifier == null) {
        debugPrint("No logged-in user identifier found");
        return null;
      }

      // 2️⃣ Fetch user doc directly using identifier
      final userUrl = '/resource/User/$userIdentifier';

      final response = await _dio.get(
        userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final branch = response.data['data']['branch'];
        debugPrint("User Branch: $branch");
        return branch;
      } else {
        debugPrint("Failed to fetch user branch: ${response.data}");
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
  Future<Map<String, dynamic>?> makeMappedPurchaseReceipt(String purchaseOrderName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url =
          "/method/frappe.model.mapper.make_mapped_doc"
          "?method=erpnext.buying.doctype.purchase_order.purchase_order.make_purchase_receipt"
          "&source_name=$purchaseOrderName";

      debugPrint("🌐 Mapping PO -> Purchase Receipt: $url");

      final response = await _dio.get(
        url,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        }),
      );

      debugPrint("📥 Mapped Doc Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        return response.data["message"]; // important!
      }

      debugPrint("❌ Unexpected status code: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("❗ Error creating mapped doc: $e");
      return null;
    }
  }

  // Future<dynamic> createPurchaseReceipt(
  //     BuildContext context,
  //     Map<String, dynamic> receiptData,
  //     ) async {
  Future<dynamic> createPurchaseReceipt(
      BuildContext context,
      Map<String, dynamic> receiptData, {
        bool submit = true, // default true to avoid breaking
      }) async {
    try {
      // 1️⃣ Check PO name
      final poName = receiptData["purchase_order"];
      if (poName == null) {
        return "Purchase Order not found in data";
      }

      // 2️⃣ Step: Get mapped PR data from ERPNext
      final mappedDoc = await makeMappedPurchaseReceipt(poName);

// get user items
      final mappedItems = mappedDoc?["items"] as List;
      final uiItems = receiptData["items"] as List;
      final uiItemCodes = uiItems.map((i) => i["item_code"]).toSet();

      // Filter mapped items to only items that still exist in UI
      mappedDoc?["items"] = mappedItems.where((m) {
        final code = m["item_code"];
        return uiItemCodes.contains(code);
      }).toList();

      // 3️⃣ Re-fetch mapped items safely
      final filteredItems = mappedDoc?["items"] as List;

// 4️⃣ Validate: cannot submit empty
      if (filteredItems.isEmpty) {
        return "Cannot submit Purchase Receipt without items";
      }
// // 🟢 Create batches before PR
      for (var ui in uiItems) {
        final itemCode = ui["item_code"];
        final batchId = ui["batch_no"];

        if (batchId != null && batchId.toString().trim().isNotEmpty) {

          // 1️⃣ Check if batch already exists
          final exists = await batchExists(batchId);

          // 2️⃣ If exists → do NOT create, just continue
          if (exists == true) {
            debugPrint("♻️ Batch $batchId already exists. Skipping creation.");
            continue;
          }

          // 3️⃣ If not exists → create
          final ok = await createBatch(context, itemCode, batchId);
          if (!ok) return "Failed creating batch for $itemCode";
        }
      }

// 2.1 merge values
      for (int i = 0; i < uiItems.length; i++) {
        final mapped = mappedDoc?["items"][i];
        final ui = uiItems[i];

        final acceptedQty = ui["qty"] ?? 0.0;
        final rejectedQty = ui["rejected_qty"] ?? 0.0;

        mapped["qty"] = acceptedQty; // accepted qty only
        mapped["rejected_qty"] = rejectedQty;
        mapped["received_qty"] = acceptedQty + rejectedQty; // 🔥 FIX

        mapped["wastage_quantity"] = ui["wastage_quantity"];
        mapped["excess_quantity"] = ui["excess_quantity"];

        if (ui["batch_no"] != null && ui["batch_no"].toString().isNotEmpty) {
          mapped["batch_no"] = ui["batch_no"];
        }

        if ((ui["rejected_qty"] ?? 0) > 0) {
          mapped["rejected_warehouse"] = ui["rejected_warehouse"];
        }
      }

      for (final m in mappedDoc?["items"]) {
        if (m["has_batch_no"] == 1) {
          if (m["batch_no"] == null || m["batch_no"].toString().trim().isEmpty) {
            return "Batch is required for item ${m["item_code"]}";
          }
        }
      }

      // 3️⃣ Add custom fields to mapped doc if needed
      final branch = await getUserBranch(context);
      mappedDoc?["branch"] = branch;
      // mappedDoc?["docstatus"] = 1;
      mappedDoc?["docstatus"] = submit ? 1 : 0;

      // 4️⃣ Debug outgoing payload
      debugPrint("📤 Final Payload: ${jsonEncode(mappedDoc)}");

      // 5️⃣ POST request
      final url = "/resource/Purchase Receipt";
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: jsonEncode({"data": mappedDoc}),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        }),
      );

      debugPrint("📬 Purchase Receipt Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final errorMessage = _extractErrorMessage(response.data.toString());
      return errorMessage;
    } catch (e) {
      debugPrint("❗ Error creating Purchase Receipt: $e");

      if (e is DioException) {
        final message = _extractErrorMessage(e.response?.data.toString() ?? "");
        return message;
      }

      return "Unexpected error occurred";
    }
  }

  String _extractErrorMessage(String data) {
    try {
      final start = data.toLowerCase().indexOf("message");
      if (start == -1) return data;
      final end = start + 200;
      return data.substring(start, end.clamp(0, data.length));
    } catch (_) {
      return data;
    }
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
        '/resource/Warehouse?filters=[["Warehouse","name","like","%$query%"],["Warehouse","is_rejected_warehouse","=","0"]]&fields=["name"]';


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
  Future<Map<String, dynamic>?> fetchItemDetails(String itemCode) async {
    try {
      final url = '/resource/Item/$itemCode';
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies,
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']; // item data
      }

      return null;
    } catch (e) {
      debugPrint("❗ Error fetching item details: $e");
      return null;
    }
  }
  Future<bool> createBatch(BuildContext context, String itemCode, String batchId) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        "/resource/Batch",
        data: jsonEncode({
          "data": {
            "item": itemCode,
            "batch_id": batchId,
          }
        }),
        options: Options(headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        }),
      );

      debugPrint("📦 Batch Response: ${response.statusCode} - ${response.data}");

      return response.statusCode == 200 || response.statusCode == 201;

    } catch (e) {
      debugPrint("❗ Error creating batch: $e");
      return false;
    }
  }

  Future<bool> batchExists(String batchId) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Batch/$batchId",
        options: Options(headers: {
          "Cookie": cookies,
        }),
      );

      return response.statusCode == 200 && response.data["data"] != null;

    } catch (e) {
      if (e is DioException && e.response?.data?["exc_type"] == "DoesNotExistError") {
        return false;
      }

      debugPrint("❗ batchExists error: $e");
      return false; // safer for logic
    }
  }


// purchase receipt

// sales invoice

  Future<Map<String, String>?> fetchUserBranch(BuildContext context) async {
    try {
      final userIdentifier = await getLoggedInUserIdentifier();
      if (userIdentifier == null) {
        throw Exception('Unable to determine logged-in user.');
      }

      final encodedUser = Uri.encodeComponent(userIdentifier);
      final userUrl = '$baseUrl/resource/User/$encodedUser';
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] != null) {

        final userData = response.data['data'];

        final branch = userData['branch'];
        final defaultWarehouse = userData['dflt_warehouse'];

        // branch is mandatory
        if (branch == null || branch.toString().isEmpty) {
          throw Exception('Branch not set for logged-in user.');
        }

        // dflt_warehouse is OPTIONAL
        return {
          "branch": branch.toString(),
          "default_warehouse": defaultWarehouse?.toString() ?? "",
        };
      } else {
        throw Exception('Failed to fetch User details.');
      }
    } catch (e) {
      debugPrint('fetchUserBranch Exception: $e');
      return null;
    }
  }


  Future<String?> resolveLoggedInSalesPerson() async {
    try {
      /// 1. Logged-in user (email / user.name)
      final email = await getLoggedInUserIdentifier();
      if (email == null) return null;

      /// 2. User first_name
      final firstName = await fetchUserFirstName(email);
      if (firstName == null) return null;

      /// 3. Employee from first_name
      final employeeId = await fetchEmployeeByFirstName(firstName);
      if (employeeId == null) return null;

      /// 4. Sales Person from employee
      final salesPerson = await fetchSalesPersonByEmployee(employeeId);
      return salesPerson;
    } catch (e) {
      debugPrint("resolveLoggedInSalesPerson Error: $e");
      return null;
    }
  }

  Future<GetSalesInvoiceResponse?> getSalesInvoice(
      BuildContext context,
      int limitStart,
      int pageLength,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      /// Resolve sales person
      final salesPerson = await resolveLoggedInSalesPerson();
      if (salesPerson == null) {
        throw Exception("Sales person not mapped for logged-in user");
      }

      final url =
          '/resource/Sales Invoice'
          '?fields=["name","customer","posting_date","due_date","status","grand_total","rounded_total"]'
          // '&filters=[["Sales Team","sales_person","=","$salesPerson"]]'
          '&filters=['
          '["Sales Team","sales_person","=","$salesPerson"],'
          '["Sales Invoice","status","!=","Cancelled"]'
          ']'
          '&limit_start=$limitStart'
          '&limit_page_length=$pageLength'
          '&order_by=posting_date desc';

      debugPrint("Sales Invoice URL: $url");

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return GetSalesInvoiceResponse.fromJson(response.data);
      }

      apiErrorHandler.handleHttpError(context, response);
      return null;
    } catch (e) {
      debugPrint("getSalesInvoice Error: $e");
      throw Exception("Failed to fetch Sales Invoice");
    }
  }


  Future<Map<String, dynamic>?> getSalesInvoiceDetails(
      BuildContext context,
      String invoiceName,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url =
          '/resource/Sales Invoice/$invoiceName'
          '?fields=['
          '"name","customer","posting_date","due_date","status",'
          '"net_total","total","total_taxes_and_charges",'
          '"rounded_total","grand_total","outstanding_amount",'
          '"discount_amount","additional_discount_percentage",'
          '"items.item_name","items.item_code","items.uom","items.qty",'
          '"items.price_list_rate","items.net_amount","items.amount",'
          '"items.discount_amount","items.discount_percentage",'
          '"items.rate","distributed_discount_amount","items.net_rate"'
          ']';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching invoice details: $e");
      return null;
    }
  }

  Future<GetSalesInvoiceResponse?> getSalesInvoiceDateFilter(
      BuildContext context,
      String startDate,
      String endDate,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final salesPerson = await resolveLoggedInSalesPerson();
      if (salesPerson == null) return null;

      final url =
          '/resource/Sales Invoice'
          '?fields=["name","customer","posting_date","due_date","status","grand_total","rounded_total"]'
          '&filters=['
          '["posting_date",">=","$startDate"],'
          '["posting_date","<=","$endDate"],'
          '["Sales Team","sales_person","=","$salesPerson"],'
          '["Sales Invoice","status","!=","Cancelled"]'
          ']';


      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (s) => s! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return GetSalesInvoiceResponse.fromJson(response.data);
      }

      apiErrorHandler.handleHttpError(context, response);
      return null;
    } catch (e) {
      debugPrint("getSalesInvoiceDateFilter Error: $e");
      throw Exception("Failed to fetch filtered Sales Invoice");
    }
  }

  Future<GetSalesInvoiceResponse?> getSearchSalesInvoice(
      BuildContext context,
      String? invoiceId,
      String? customerId,
      String? startDate,
      String? endDate,
      ) async {
    final cookies = await _sharedPrefService.getCookies();
    final salesPerson = await resolveLoggedInSalesPerson();
    if (salesPerson == null) return null;

    List<String> filters = [
      '["Sales Team","sales_person","=","$salesPerson"]',
      '["Sales Invoice","status","!=","Cancelled"]',
    ];

    if (invoiceId?.isNotEmpty == true) {
      filters.add('["name","like","%$invoiceId%"]');
    }

    if (customerId?.isNotEmpty == true) {
      filters.add('["customer","like","%$customerId%"]');
    }

    if (startDate != null && endDate != null) {
      filters.add('["posting_date",">=","$startDate"]');
      filters.add('["posting_date","<=","$endDate"]');
    }

    final url =
        '/resource/Sales Invoice'
        '?fields=["name","customer","posting_date","due_date","status","grand_total","rounded_total"]'
        '&filters=[${filters.join(",")}]';

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
      return GetSalesInvoiceResponse.fromJson(response.data);
    }

    apiErrorHandler.handleHttpError(context, response);
    return null;
  }



  // Future<Map<String, dynamic>> fetchInvoiceCustomerDetails(
  //     BuildContext context,
  //     String customerName,
  //     ) async {
  //   try {
  //     // Get company from SharedPreferences
  //     final company = await _sharedPrefService.getCompany();
  //
  //     if (company == null || company.isEmpty) {
  //       throw Exception("Company not found in SharedPreferences");
  //     }
  //
  //     final url =
  //         '/method/erpnext.accounts.party.get_party_details?company=${Uri.encodeComponent(company)}&party=$customerName&doctype=Sales%20Invoice';
  //
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.post(
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
  //       return response.data["message"];
  //     } else {
  //       throw Exception("Failed to fetch customer details");
  //     }
  //   } catch (e) {
  //     debugPrint("Error in fetchInvoiceCustomerDetails: $e");
  //     throw Exception("Failed to fetch customer details");
  //   }
  // }
  Future<Map<String, dynamic>> fetchInvoiceCustomerDetails(
      BuildContext context,
      String customerName,
      ) async {
    try {
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      // ✅ Encode customerName to handle special chars like &
      final encodedCompany = Uri.encodeComponent(company);
      final encodedCustomer = Uri.encodeComponent(customerName);

      final url =
          '/method/erpnext.accounts.party.get_party_details?company=$encodedCompany&party=$encodedCustomer&doctype=Sales%20Invoice';

      debugPrint('┌─ [fetchInvoiceCustomerDetails] REQUEST ────────');
      debugPrint('│ raw customerName : $customerName');
      debugPrint('│ encoded customer : $encodedCustomer');
      debugPrint('│ raw company      : $company');
      debugPrint('│ encoded company  : $encodedCompany');
      debugPrint('│ full URL         : ${baseUrl + url}');
      debugPrint('└────────────────────────────────────────────────');

      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('┌─ [fetchInvoiceCustomerDetails] RESPONSE ───────');
      debugPrint('│ status : ${response.statusCode}');
      debugPrint('│ data   : ${response.data}');
      debugPrint('└────────────────────────────────────────────────');

      if (response.statusCode == 200) {
        return response.data["message"];
      } else {
        debugPrint('[fetchInvoiceCustomerDetails] ❌ status ${response.statusCode}');
        apiErrorHandler.handleHttpError(context, response);
        throw Exception("Failed to fetch customer details");
      }
    } on DioException catch (e) {
      debugPrint('┌─ [fetchInvoiceCustomerDetails] DIO ERROR ──────');
      debugPrint('│ type    : ${e.type}');
      debugPrint('│ status  : ${e.response?.statusCode}');
      debugPrint('│ message : ${e.message}');
      debugPrint('│ response: ${e.response?.data}');
      debugPrint('└────────────────────────────────────────────────');
      throw Exception("Failed to fetch customer details due to DioException");
    } catch (e, stack) {
      debugPrint('┌─ [fetchInvoiceCustomerDetails] ERROR ──────────');
      debugPrint('│ error : $e');
      debugPrint('│ stack : $stack');
      debugPrint('└────────────────────────────────────────────────');
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
  //
  // Future<void> createSalesInvoice({
  //   required BuildContext context,
  //   required String customerName,
  //   required String dueDate,
  //   required String postingDate,
  //   required List<Map<String, dynamic>> item,
  //   required Map<String, dynamic> customerDetails,
  // }) async {
  //   const url = '/resource/Sales Invoice';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     // 🔹 Fetch user data (may be null or partial)
  //     final userData = await fetchUserBranch(context);
  //
  //     final String? branch = userData?["branch"];
  //     final String? defaultWarehouse = userData?["default_warehouse"];
  //
  //     // 🔹 Set warehouse only if available
  //     final updatedItems = item.map((itm) {
  //       final updated = Map<String, dynamic>.from(itm);
  //       if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
  //         updated["warehouse"] = defaultWarehouse;
  //       }
  //       return updated;
  //     }).toList();
  //
  //     // 🔹 Build invoice payload
  //     final Map<String, dynamic> invoiceData = {
  //       "customer": customerName,
  //       ...customerDetails,
  //       "due_date": dueDate,
  //       "posting_date": postingDate,
  //       "set_posting_time": 1,
  //       "items": updatedItems,
  //     };
  //
  //     // 🔹 Add branch ONLY if present
  //     if (branch != null && branch.isNotEmpty) {
  //       invoiceData["branch"] = branch;
  //     }
  //
  //     // 🔹 Add warehouse ONLY if present
  //     if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
  //       invoiceData["set_warehouse"] = defaultWarehouse;
  //     }
  //
  //     final response = await _dio.post(
  //       url,
  //       data: {"data": invoiceData},
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode != 200) {
  //       debugPrint('❌ Failed to create Sales Invoice');
  //       debugPrint('Status: ${response.statusCode}');
  //       debugPrint('Response: ${response.data}');
  //       throw Exception('Failed to create Sales Invoice');
  //     }
  //
  //     debugPrint('✅ Sales Invoice created successfully');
  //     debugPrint('Response: ${response.data}');
  //   } on DioError catch (dioError) {
  //     debugPrint('❌ DioError while creating Sales Invoice');
  //     debugPrint('Message: ${dioError.message}');
  //     if (dioError.response != null) {
  //       debugPrint('Status: ${dioError.response?.statusCode}');
  //       debugPrint('Response: ${dioError.response?.data}');
  //     }
  //     rethrow;
  //   } catch (e, stackTrace) {
  //     debugPrint('❌ Exception while creating Sales Invoice: $e');
  //     debugPrint('StackTrace: $stackTrace');
  //     rethrow;
  //   }
  // }
  Future<void> createSalesInvoice({
    required BuildContext context,
    required String customerName,
    required String dueDate,
    required String postingDate,
    required List<Map<String, dynamic>> item,
    required Map<String, dynamic> customerDetails,
    String applyDiscountOn = 'Net Total',       // 👇 new
    double additionalDiscountPercentage = 0.0,    // 👇 new
    double discountAmount = 0.0,                  // 👇 new
  }) async {
    const url = '/resource/Sales Invoice';

    try {
      final cookies = await _sharedPrefService.getCookies();
      final userData = await fetchUserBranch(context);

      final String? branch = userData?["branch"];
      final String? defaultWarehouse = userData?["default_warehouse"];

      final updatedItems = item.map((itm) {
        final updated = Map<String, dynamic>.from(itm);
        if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
          updated["warehouse"] = defaultWarehouse;
        }
        return updated;
      }).toList();

      final Map<String, dynamic> invoiceData = {
        "customer": customerName,
        ...customerDetails,
        "due_date": dueDate,
        "posting_date": postingDate,
        "set_posting_time": 1,
        "items": updatedItems,
        // 👇 Discount fields — only include non-zero values to keep payload clean
        "apply_discount_on": applyDiscountOn,
        if (additionalDiscountPercentage > 0)
          "additional_discount_percentage": additionalDiscountPercentage,
        if (discountAmount > 0)
          "discount_amount": discountAmount,
      };

      if (branch != null && branch.isNotEmpty) {
        invoiceData["branch"] = branch;
      }

      if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
        invoiceData["set_warehouse"] = defaultWarehouse;
      }

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
        debugPrint('❌ Failed to create Sales Invoice');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Response: ${response.data}');
        throw Exception('Failed to create Sales Invoice');
      }

      debugPrint('✅ Sales Invoice created successfully');
      debugPrint('Response: ${response.data}');
    } on DioError catch (dioError) {
      debugPrint('❌ DioError while creating Sales Invoice');
      debugPrint('Message: ${dioError.message}');
      if (dioError.response != null) {
        debugPrint('Status: ${dioError.response?.statusCode}');
        debugPrint('Response: ${dioError.response?.data}');
      }
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception while creating Sales Invoice: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
  // Future<bool> fetchDiscountSettings(BuildContext context) async {
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.get(
  //       '/method/frappe.client.get_single_value',
  //       queryParameters: {
  //         'doctype': 'Accounts Settings',
  //         'field': 'enable_discounts_and_margin',
  //       },
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final message = response.data['message'];
  //       // message can come back as int (1/0) or string ("1"/"0")
  //       return message == 1 || message == '1';
  //     }
  //
  //     return false;
  //   } catch (e) {
  //     debugPrint('❌ Error fetching discount settings: $e');
  //     return false;
  //   }
  // }
  Future<bool> fetchDiscountSettings(BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/method/frappe.client.get_single_value',
        queryParameters: {
          'doctype': 'Accounts Settings',
          'field': 'enable_discounts_and_margin',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          // 👇 Don't throw on 4xx/5xx — we handle all responses manually
          validateStatus: (status) => status! < 600,
        ),
      );

      final data = response.data;

      // 👇 If the field doesn't exist on Accounts Settings, show the section
      if (data is Map && data.containsKey('exception')) {
        final exception = data['exception'] as String? ?? '';
        if (exception.contains('does not exist')) {
          debugPrint('ℹ️ enable_discounts_and_margin field not found — showing discount section by default');
          return true;
        }
      }

      // 👇 Only hide if message is explicitly 0
      if (response.statusCode == 200 && data is Map) {
        final message = data['message'];
        if (message == 0 || message == '0') return false;
      }

      // 👇 Default: show the section (covers message == 1, null, or any other value)
      return true;
    } catch (e) {
      // 👇 On any network/parse error, default to showing the section
      debugPrint('❌ Error fetching discount settings — defaulting to visible: $e');
      return true;
    }
  }
  Future<List<String>> fetchInvoicePrintFormats() async {
    const url =
        '/resource/Print Format?filters=[["doc_type","=","Sales Invoice"],["disabled","=","0"]]&fields=["name"]';

    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Cookie': cookies},
      ),
    );

    final List data = response.data["data"];
    return data.map((e) => e["name"].toString()).toList();
  }
  Future<Uint8List> downloadInvoicePdf({
    required String invoiceName,
    required String printFormat,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    final url =
        '/method/frappe.utils.print_format.download_pdf'
        '?doctype=Sales Invoice'
        '&name=$invoiceName'
        '&format=$printFormat';

    final response = await _dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Cookie': cookies},
      ),
    );

    return Uint8List.fromList(response.data);
  }

  // Future<GetSalesInvoiceResponse?> getSalesInvoiceByName({
  //   required BuildContext context,
  //   required String invoiceName,
  // }) async {
  //   final encodedFilter = Uri.encodeComponent(
  //     '[["Sales Invoice","name","=","$invoiceName"]]',
  //   );
  //   final url = '/resource/Sales Invoice?filters=$encodedFilter';
  //
  //   final cookies = await _sharedPrefService.getCookies();
  //
  //   final response = await _dio.get(
  //     url,
  //     options: Options(
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Cookie': cookies,
  //       },
  //       validateStatus: (status) => status! < 500,
  //     ),
  //   );
  //
  //   // Replace with your actual model parser
  //   return GetSalesInvoiceResponse?.fromJson(response.data);
  // }
  Future<GetSalesInvoiceResponse?> getSalesInvoiceByName({
    required BuildContext context,
    required String invoiceName,
  }) async {
    final encodedFilter = Uri.encodeComponent(
      '[["Sales Invoice","name","=","$invoiceName"]]',
    );
    final encodedFields = Uri.encodeComponent(
      '["name","customer","posting_date","due_date","status","grand_total","rounded_total"]',
    );

    final url =
        '/resource/Sales Invoice?filters=$encodedFilter&fields=$encodedFields';

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

    return GetSalesInvoiceResponse?.fromJson(response.data);
  }

//sales invoices

//POS Invoice

  /// Fetch POS Profile for a given user
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

  // Future<CustomerList?> customerGroupPaged({
  //   required BuildContext context,
  //   required String salesPerson,
  //   required String customerGroup,
  //   required int pageLength,
  //   required int start,
  // }) async {
  //   final cookies = await _sharedPrefService.getCookies();
  //
  //   final queryParams = {
  //     "fields": jsonEncode([
  //       "name",
  //       "tax_id",
  //       "gstin",
  //       "territory",
  //       "customer_primary_contact",
  //       "customer_primary_address",
  //       "primary_address",
  //       "mobile_no",
  //       "email_id",
  //       "tax_category",
  //       "customer_group",
  //       "_liked_by"
  //     ]),
  //     "filters": jsonEncode([
  //       ["Sales Team", "sales_person", "=", salesPerson],
  //       ["customer_group", "=", customerGroup],
  //     ]),
  //     "limit_page_length": pageLength,
  //     "limit_start": start,
  //   };
  //
  //   final response = await _dio.get(
  //     "/resource/Customer",
  //     queryParameters: queryParams,
  //     options: Options(
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Cookie": cookies,
  //       },
  //     ),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return CustomerList.fromJson(response.data);
  //   }
  //
  //   return null;
  // }

  Future<CustomerList?> customerGroupPaged({
    required BuildContext context,
    required String salesPerson,
    required String customerGroup,
    required int pageLength,
    required int start,
    bool onlyLiked = false,
    String? loggedUser,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    List filters = [
      ["Sales Team", "sales_person", "=", salesPerson],
      ["customer_group", "=", customerGroup],
    ];

    // ⭐ Add liked filter
    if (onlyLiked && loggedUser != null) {
      filters.add(["Customer", "_liked_by", "like", "%$loggedUser%"]);
    }

    final queryParams = {
      "fields": jsonEncode([
        "name",
        "tax_id",
        "gstin",
        "territory",
        "customer_primary_contact",
        "customer_primary_address",
        "primary_address",
        "mobile_no",
        "email_id",
        "tax_category",
        "customer_group",
        "_liked_by"
      ]),
      "filters": jsonEncode(filters),
      "limit_page_length": pageLength,
      "limit_start": start,
    };

    final response = await _dio.get(
      "/resource/Customer",
      queryParameters: queryParams,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        },
      ),
    );

    if (response.statusCode == 200) {
      return CustomerList.fromJson(response.data);
    }

    return null;
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
  // Future<ItemListResponse?> itemList(context) async {
  //   final url =
  //       '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group"]';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
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
  //
  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       // print("Response details :::::${response.data[0].itemCode}");
  //       return ItemListResponse.fromJson(response.data);
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

  Future<ItemListResponse?> itemList(context, {int limit = 20, int offset = 0}) async {
    // final url =
        // '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group"]'
        // '&filters=[["Item","disabled","=",0]]'
        // '&limit=$limit&limit_start=$offset';
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group","product_brochure"]'
        '&filters=[["Item","disabled","=",0]]'
        '&limit=$limit&limit_start=$offset';

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
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch data');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch data');
    }
    return null;
  }
  //Item list
  Future<ItemListResponse?> itemSearchListProducts(
      String itemName, BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final filters = Uri.encodeComponent(jsonEncode([
        ["Item", "disabled", "=", 0],
      ]));

      final orFilters = Uri.encodeComponent(jsonEncode([
        ["Item", "item_name", "like", "%$itemName%"],
        ["Item", "item_code", "like", "%$itemName%"],
        ["Item", "normalized_item_code", "like", "%$itemName%"],
      ]));

      final fields = Uri.encodeComponent(jsonEncode([
        "item_code", "item_name", "valuation_rate", "image",
        "brand", "item_group", "product_brochure"
      ]));

      final url =
          '/method/frappe.desk.reportview.get?doctype=Item&filters=$filters&or_filters=$orFilters&fields=$fields';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );

      // if (response.statusCode == 200) {
      //   final message = response.data['message'];
      //   final List<String> keys = List<String>.from(message['keys']);
      //   final List<dynamic> values = message['values'];
      //
      //   final List<ItemData> dataList = values.map((row) {
      //     final Map<String, dynamic> map = {};
      //     for (int i = 0; i < keys.length; i++) {
      //       map[keys[i]] = row[i];
      //     }
      //     return ItemData.fromJson(map);
      //   }).toList();
      //
      //   return ItemListResponse(data: dataList);
      // } else {
      //   apiErrorHandler.handleHttpError(context, response);
      //   return null;
      // }
      if (response.statusCode == 200) {
        final message = response.data['message'];
        final List<String> keys = List<String>.from(message['keys'] ?? []);
        final List<dynamic> values = message['values'] ?? [];

        // Empty values = no results, return empty list instead of throwing
        if (values.isEmpty) {
          return ItemListResponse(data: []);
        }

        final List<ItemData> dataList = values.map((row) {
          final Map<String, dynamic> map = {};
          for (int i = 0; i < keys.length; i++) {
            map[keys[i]] = row[i];
          }
          return ItemData.fromJson(map);
        }).toList();

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

  Future<ItemListResponse?> itemSearchList(
      String itemName, BuildContext context, bool isItemList) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final fields = Uri.encodeQueryComponent('["item_code","item_name","normalized_item_code"]');
      // final fields = Uri.encodeQueryComponent('["item_code","item_name"]');

      final orFilters = Uri.encodeComponent(jsonEncode([
        ["Item", "item_code", "like", "%$itemName%"],
        ["Item", "item_name", "like", "%$itemName%"],
        ["Item", "normalized_item_code", "like", "%$itemName%"],
      ]));
      final filters = Uri.encodeComponent(jsonEncode([
        ["Item", "is_stock_item", "=", "1"],
      ]));

      final url = '/resource/Item?fields=$fields&or_filters=$orFilters&filters=$filters';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (isItemList) Navigator.pop(context);

      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        final uniqueMap = {for (var item in rawData) item['item_code']: item};
        final uniqueList = uniqueMap.values.toList();

        // ✅ Fetch actual qty for all items in parallel
        final qtyFutures = uniqueList.map((e) =>
            fetchItemActualQty(e['item_code']));
        final qtyResults = await Future.wait(qtyFutures);

        // ✅ Merge qty into each item
        final mergedList = uniqueList.asMap().entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          final qtyMap = qtyResults[entry.key];
          item['actual_qty'] = qtyMap[item['item_code']] ?? 0.0;
          return item;
        }).toList();

        final dataList = mergedList.map((e) => ItemData.fromJson(e)).toList();
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
  Future<Map<String, double>> fetchItemActualQty(String itemCode) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final url = '/method/erpnext.stock.dashboard.item_dashboard.get_data'
          '?item_code=$itemCode';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List message = response.data['message'] ?? [];
        // ✅ Sum actual_qty across all warehouses for this item
        double total = 0;
        for (final entry in message) {
          if (entry['item_code'] == itemCode) {
            total += (entry['actual_qty'] ?? 0).toDouble();
          }
        }
        return {itemCode: total};
      }
      return {itemCode: 0};
    } catch (e) {
      debugPrint('Error fetching actual qty: $e');
      return {itemCode: 0};
    }
  }
  //Item filter by brand
  // Future<ItemListResponse?> itemByBrand(
  //     String brandName, BuildContext context) async {
  //   print("test brand 3");
  //
  //   final url =
  //       '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group"]&filters=[["Item", "brand","=", "$brandName"]]';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
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
  //
  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       print("test brand 4");
  //
  //       //print("Response details :::::${response.data[0].}");
  //       Navigator.pop(context);
  //       return ItemListResponse.fromJson(response.data);
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
  // Future<CategoryListRespose?> categoryList(context) async {
  //   final url = '/resource/Item Group';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
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
  //
  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       // print("Response details :::::${response.data[0].itemCode}");
  //       return CategoryListRespose.fromJson(response.data);
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
  Future<CategoryListRespose?> categoryList(context) async {
    final url = '/resource/Item Group?limit=0';  // limit=0 returns all records

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
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return CategoryListRespose.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception('Failed to fetch categories');
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch categories');
    }
  }
  //item category filter
  Future<ItemListResponse?> categoryItemFilter(
      String category, BuildContext context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","item_group","brand","product_brochure"]&filters=[["Item","item_group","=","$category"]]';

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
        // Navigator.pop(context);
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
// 1. Fetch variant list
  Future<List<String>> variantList(BuildContext context) async {
    const url =
        '/method/frappe.desk.search.search_link?txt=&doctype=Item&page_length=0&link_fieldname=variant_of';
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200) {
        final List data = response.data['message'] ?? [];
        return data.map((e) => e['value'].toString()).toList();
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching variants: $e');
      return [];
    }
  }

// 2. Filter items by variant
  Future<ItemListResponse?> itemByVariant(
      String variantOf, BuildContext context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group","product_brochure"]'
        '&filters=[["Item","disabled","=",0],["Item","variant_of","=","$variantOf"]]';
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200) {
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch items by variant');
    }
  }
  // //item category and Brand filter
  // Future<ItemListResponse?> categoryAndBrandItemFilter(
  //     String brand, String category, context) async {
  //   final url =
  //       '/resource/Item?fields=["item_code","item_name","valuation_rate","image","item_group","brand"]&filters=[["Item","item_group","=","$category","brand","=", "$brand"]]';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
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
  //
  //     debugPrint('Response  status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       // print("Response details :::::${response.data[0].itemCode}");
  //       return ItemListResponse.fromJson(response.data);
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

// 3. Fix categoryAndBrandItemFilter — filters array was malformed
  Future<ItemListResponse?> categoryAndBrandItemFilter(
      String brand, String category, BuildContext context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","item_group","brand","product_brochure"]'
        '&filters=[["Item","disabled","=",0],["Item","item_group","=","$category"],["Item","brand","=","$brand"]]';
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200) {
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch filtered items');
    }
  }

// 4. itemByBrand — remove Navigator.pop, add disabled filter
  Future<ItemListResponse?> itemByBrand(
      String brandName, BuildContext context) async {
    final url =
        '/resource/Item?fields=["item_code","item_name","valuation_rate","image","brand","item_group","product_brochure"]'
        '&filters=[["Item","disabled","=",0],["Item","brand","=","$brandName"]]';
    try {
      final cookies = await _sharedPrefService.getCookies();
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json', 'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );
      if (response.statusCode == 200) {
        // ❌ Navigator.pop(context) removed
        return ItemListResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
        return null;
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.message}');
      throw Exception('Failed to fetch items by brand');
    }
  }
  //Sales person report
  Future<String?> fetchUserFirstName(String email) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/User/$email",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return response.data["data"]["first_name"];
      }
    } catch (e) {
      debugPrint("fetchUserFirstName Error: $e");
    }

    return null;
  }
  Future<String?> fetchEmployeeByFirstName(String firstName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Employee",
        queryParameters: {
          "fields": '["name","first_name"]',
          "filters": '[["first_name","=","$firstName"]]'
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          return data.first["name"];
        }
      }
    } catch (e) {
      debugPrint("fetchEmployeeByFirstName Error: $e");
    }

    return null;
  }
  Future<String?> fetchSalesPersonByEmployee(String employeeId) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Sales Person",
        queryParameters: {
          "filters": '[["employee","=","$employeeId"]]'
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          return data.first["name"];
        }
      }
    } catch (e) {
      debugPrint("fetchSalesPersonByEmployee Error: $e");
    }

    return null;
  }

  String getFiscalYear(DateTime date) {
    final year = date.year;

    // If month is Jan–Mar → fiscal year started the previous year
    if (date.month < 4) {
      return "${year - 1}-$year";
    }

    // If month is Apr–Dec → fiscal year continues to next year
    return "$year-${year + 1}";
  }

  Future<Map<String, dynamic>?> fetchSalesmanMonthlySales(
      BuildContext context,
      String salesPerson,
      String fromDate,
      String toDate,
      ) async {
    const url = "/method/frappe.desk.query_report.run";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final fiscalYear = getFiscalYear(DateTime.now());

      final filters = {
        "sales_person": salesPerson,
        "fiscal_year": fiscalYear,   // DYNAMIC
        "from_date": fromDate,
        "to_date": toDate,
      };

      final queryParams = {
        "report_name": "Salesman Monthly Sales",
        "filters": jsonEncode(filters),
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
        return response.data["message"];
      } else {
        debugPrint("Fetch Sales Error: ${response.data}");
      }
    } catch (e) {
      debugPrint("fetchSalesmanMonthlySales Error: $e");
    }

    return null;
  }


  Future<Uint8List?> downloadReportPdf(String html) async {
    const url = "/method/frappe.utils.print_format.report_to_pdf";

    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        url,
        data: {
          'html': html,
        },
        options: Options(
          headers: {
            'Content-Type': Headers.formUrlEncodedContentType,
            'Cookie': cookies,
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // the body is bytes of the PDF
        final bytes = Uint8List.fromList(response.data);
        return bytes;
      } else {
        debugPrint('PDF download failed: ${response.statusCode} ${response.data}');
      }
    } catch (e) {
      debugPrint('downloadReportPdf error: $e');
    }
    return null;
  }

  //Sales person report
// Site Visit

// ── Add site visit row to EEM child table ─────────────────────────────
  Future<bool> addSiteVisitToEEM({
    required String eemName,
    required String customer,
    required String site,
    required double siteLat,
    required double siteLong,
    required String remarks,
    double? actualDistance,       // ← add this

  }) async {
    final cookies = await _sharedPrefService.getCookies();

    try {
      // First fetch existing site tracking rows
      final detailResponse = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (detailResponse.statusCode != 200) return false;

      final existing = detailResponse.data["data"];
      final List existingRows = existing["employee_site_tracking"] ?? [];
      // final checkinTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Append new row
      final updatedRows = [
        ...existingRows,
        {
          "customer": customer,
          "site": site,             // ← add this
          "site_lat": siteLat,
          "site_long": siteLong,
          "remarks": remarks,
          "distance_travelled": 0,
          "actual_distance": 0,
          // "checkin_time": checkinTime,  // ← added

        }
      ];

      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: {
          "data": {
            "employee_site_tracking": updatedRows,
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("addSiteVisitToEEM Error: $e");
      return false;
    }
  }

// ── Update existing site visit row in EEM child table ─────────────────
  Future<bool> updateSiteVisitInEEM({
    required String eemName,
    required String rowName,
    required String customer,
    required String site,
    required double siteLat,
    required double siteLong,
    required String remarks,
    double? actualDistance,       // ← add this

  }) async {
    final cookies = await _sharedPrefService.getCookies();

    try {
      // Fetch existing rows
      final detailResponse = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (detailResponse.statusCode != 200) return false;

      final existing = detailResponse.data["data"];
      final List existingRows =
      List.from(existing["employee_site_tracking"] ?? []);

      // Find and update the matching row
      final updatedRows = existingRows.map((row) {
        if (row["name"] == rowName) {
          return {
            ...Map<String, dynamic>.from(row),
            "customer": customer,
            "site": site,           // ← add this
            "site_lat": siteLat,
            "site_long": siteLong,
            "remarks": remarks,
            if (actualDistance != null) "actual_distance": actualDistance,

          };
        }
        return row;
      }).toList();

      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: {
          "data": {
            "employee_site_tracking": updatedRows,
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("updateSiteVisitInEEM Error: $e");
      return false;
    }
  }

// ── Fetch today's site visits from EEM child table ────────────────────
  Future<List<Map<String, dynamic>>> fetchTodaySiteVisits(
      String employee) async {
    final cookies = await _sharedPrefService.getCookies();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Find today's unsubmitted EEM for this employee
      final listResponse = await _dio.get(
        "/resource/Executive Expense Manager",
        queryParameters: {
          "fields": jsonEncode(["name"]),
          "filters": jsonEncode([
            ["Executive Expense Manager", "employee", "=", employee],
            ["Executive Expense Manager", "date", "=", today],
            ["Executive Expense Manager", "docstatus", "=", 0],
          ]),
          "order_by": "creation desc",
          "limit_page_length": 1,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (listResponse.statusCode != 200) return [];
      final list = listResponse.data["data"];
      if (list is! List || list.isEmpty) return [];

      final eemName = list.first["name"];

      // Fetch full EEM to get child rows
      final detailResponse = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (detailResponse.statusCode == 200) {
        final data = detailResponse.data["data"];
        final List rows = data["employee_site_tracking"] ?? [];
        // Inject eemName into each row so UI knows which EEM to update
        return rows
            .map((r) => {
          ...Map<String, dynamic>.from(r),
          "_eem_name": eemName,
        })
            .toList();
      }
    } catch (e) {
      debugPrint("fetchTodaySiteVisits Error: $e");
    }

    return [];
  }

// ── Delete site visit row from EEM child table ────────────────────────
  Future<bool> deleteSiteVisitFromEEM({
    required String eemName,
    required String rowName,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    try {
      final detailResponse = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (detailResponse.statusCode != 200) return false;

      final existing = detailResponse.data["data"];
      final List existingRows =
      List.from(existing["employee_site_tracking"] ?? []);

      // Remove the matching row
      final updatedRows =
      existingRows.where((r) => r["name"] != rowName).toList();

      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: {
          "data": {
            "employee_site_tracking": updatedRows,
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("deleteSiteVisitFromEEM Error: $e");
      return false;
    }
  }
  //Site Visit
  //Expense Tracker

  Future<Map<String, dynamic>?> fetchLatestEEM(String employee) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Executive Expense Manager",
        queryParameters: {
          "fields":
          '["name","date","start_time","docstatus","end_lat","end_long"]',
          "filters": '[["employee","=","$employee"]]',
          "order_by": "name desc",
          "limit_page_length": 1,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          return data.first;
        }
      }
    } catch (e) {
      debugPrint("fetchLatestEEM Error: $e");
    }
    return null;
  }


  Future<Map<String, dynamic>?> fetchEEMDetails(String eemName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return response.data["data"];
      }
    } catch (e) {
      debugPrint("fetchEEMDetails Error: $e");
    }
    return null;
  }


  Future<Map<String, dynamic>?> fetchEmployeeDetails(String firstName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Employee",
        queryParameters: {
          "fields": '["name","first_name","employee_name"]',
          "filters": '[["first_name","=","$firstName"]]'
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          return {
            "employee": data.first["name"],
            "employee_name": data.first["employee_name"],
          };
        }
      }
    } catch (e) {
      debugPrint("fetchEmployeeDetails Error: $e");
    }

    return null;
  }


  /// Upload file to ERPNext
  Future<String?> uploadFile({
    required File file,
    required String expenseRowName, // child row name
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final baseUrl = _dio.options.baseUrl;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/method/upload_file'),
      );

      request.headers['Cookie'] = cookies;

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(parts[0], parts[1]),
        ),
      );

      // 🔴 THESE FIELDS ARE REQUIRED
      request.fields.addAll({
        'is_private': '1',
        'attached_to_doctype': 'Employee Expense Tracking',
        'attached_to_name': expenseRowName,
        'fieldname': 'attachment',
      });

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['message']['file_url'];
      }

      debugPrint('Upload failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('uploadFile error: $e');
      return null;
    }
  }

  Future<List<String>> searchExpenseClaimTypes(String query) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "doctype": "Expense Claim Type",
          "reference_doctype": "Employee Expense Tracking",
          "txt": query,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final results = response.data["message"];
        if (results is List) {
          return results.map<String>((e) => e["value"].toString()).toList();
        }
      }
    } catch (e) {
      debugPrint("searchExpenseClaimTypes Error: $e");
    }

    return [];
  }

  Future<String?> fetchLatestEmployeeLogType(String employee) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayStart = '$today 00:00:00';
      final todayEnd = '$today 23:59:59';

      final response = await _dio.get(
        "/resource/Employee Checkin",
        queryParameters: {
          "fields": '["name","log_type","time"]',
          "filters": jsonEncode([
            ["employee", "=", employee],
            ["time", ">=", todayStart],
            ["time", "<=", todayEnd],
          ]),
          "order_by": "time desc",
          "limit_page_length": 1,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          return data.first["log_type"]; // IN / OUT
        }
      }
    } catch (e) {
      debugPrint("fetchLatestEmployeeLogType Error: $e");
    }
    return null; // null means no checkin today at all
  }
//claude

  Future<String?> createExecutiveExpenseManager({
    required String employee,
    required String employeeName,
    required String date,
    double? startLat,
    double? startLong,
    double? startOdometer,
  }) async {
    const url = "/resource/Executive Expense Manager";
    final cookies = await _sharedPrefService.getCookies();

    final body = {
      "data": {
        "docstatus": 0,
        "employee": employee,
        "employee_name": employeeName,
        "date": date,
        if (startLat != null) "start_lat": startLat,
        if (startLong != null) "start_long": startLong,
        if (startOdometer != null) "start_odometerkm": startOdometer,
      }
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data["data"]["name"];
      }
    } catch (e) {
      debugPrint("createExecutiveExpenseManager Error: $e");
    }
    return null;
  }
  Future<bool> updateEEMEndDetails({
    required String eemName,
    required String endTime,
    required double endLat,
    required double endLong,
    required double endOdometer,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    final body = {
      "data": {
        "end_time": endTime,
        "end_lat": endLat,
        "end_long": endLong,
        "end_odometerkm": endOdometer,
      }
    };

    try {
      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("updateEEMEndDetails Error: $e");
      return false;
    }
  }
// ── SAVE EEM (docstatus = 0, PUT) ────────────────────────────────────
  Future<bool> saveEEMWithExpenses({
    required String eemName,
    required String employee,
    required String employeeName,
    required String date,
    required List<Map<String, dynamic>> expenses,
    double? startOdometer,
    double? endOdometer,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    final body = {
      "data": {
        "docstatus": 0,
        "employee": employee,
        "employee_name": employeeName,
        "date": date,
        "employee_expense_tracking": expenses,
        if (startOdometer != null) "start_odometerkm": startOdometer,
        if (endOdometer != null) "end_odometerkm": endOdometer,
      }
    };

    try {
      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("saveEEMWithExpenses Error: $e");
      return false;
    }
  }

// ── SUBMIT EEM (docstatus = 1, PUT) ──────────────────────────────────
  Future<bool> submitEEMWithExpenses({
    required String eemName,
    required String employee,
    required String employeeName,
    required String date,
    required List<Map<String, dynamic>> expenses,
    double? startOdometer,
    double? endOdometer,
  }) async {
    final cookies = await _sharedPrefService.getCookies();

    final body = {
      "data": {
        "docstatus": 1,
        "employee": employee,
        "employee_name": employeeName,
        "date": date,
        "employee_expense_tracking": expenses,
        if (startOdometer != null) "start_odometerkm": startOdometer,
        if (endOdometer != null) "end_odometerkm": endOdometer,
      }
    };

    try {
      final response = await _dio.put(
        "/resource/Executive Expense Manager/$eemName",
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("submitEEMWithExpenses Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchLatestUnsubmittedEEM(
      String employee) async {
    final cookies = await _sharedPrefService.getCookies();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final listResponse = await _dio.get(
        "/resource/Executive Expense Manager",
        queryParameters: {
          "fields": jsonEncode(["name", "employee", "employee_name", "date"]),
          "filters": jsonEncode([
            ["Executive Expense Manager", "employee", "=", employee],
            ["Executive Expense Manager", "docstatus", "=", 0],
            ["Executive Expense Manager", "date", "=", today],
          ]),
          "order_by": "creation desc",
          "limit_page_length": 1,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (listResponse.statusCode == 200) {
        final list = listResponse.data["data"];
        if (list is List && list.isNotEmpty) {
          final eemName = list.first["name"];

          final detailResponse = await _dio.get(
            "/resource/Executive Expense Manager/$eemName",
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Cookie': cookies,
              },
            ),
          );

          if (detailResponse.statusCode == 200) {
            return detailResponse.data["data"];
          }
        }
      }
    } catch (e) {
      debugPrint("fetchLatestUnsubmittedEEM Error: $e");
    }
    return null;
  }
  //claude

  // Performance Report
  Future<Map<String, dynamic>?> fetchSalesPersonDashboard({
    required String salesperson,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/method/tqerp_mobibiz_serv.api.get_sales_person_dashboard',
        queryParameters: {
          'from_date': fromDate,
          'to_date': toDate,
          'salesperson': salesperson,
        },
        options: Options(
          headers: {'Cookie': cookies},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final msg = response.data['message'];
        if (msg['status'] == 'success') {
          return msg['data'] as Map<String, dynamic>;
        }
      } else {
        debugPrint('fetchSalesPersonDashboard Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchSalesPersonDashboard Exception: $e');
    }
    return null;
  }

  Future<String?> downloadPerformanceReportPdf({
    required String html,
    required String savePath,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.post(
        '/method/frappe.utils.print_format.report_to_pdf',
        data: FormData.fromMap({'html': html}),
        options: Options(
          headers: {
            'Cookie': cookies,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.data);
        return savePath;
      } else {
        debugPrint('downloadPerformanceReportPdf Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('downloadPerformanceReportPdf Exception: $e');
    }
    return null;
  }

  //Expense Tracker

  //Checkin
  // Future<List<dynamic>?> fetchEmployeeCheckinsAfterStart({
  //   required BuildContext context,
  //   required String employee,
  //   required String eemDate,     // YYYY-MM-DD
  //   required String eemStartTime // HH:mm:ss
  // }) async {
  //
  //   // Combine date + time into ERPNext-compatible datetime
  //   final startDateTime = '$eemDate $eemStartTime';
  //
  //   final url =
  //       '/resource/Employee Checkin'
  //       '?fields=["name","employee","employee_name","log_type","time","latitude","longitude","customer","remarks"]'
  //       '&filters='
  //       '[["employee","=","$employee"],'
  //       '["time",">=","$startDateTime"]]';
  //
  //   debugPrint('CHECKIN FILTER URL => $url');
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
  //     debugPrint('CHECKIN STATUS => ${response.statusCode}');
  //     debugPrint('CHECKIN RAW RESPONSE => ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return List<dynamic>.from(response.data['data']);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //     }
  //   } catch (e) {
  //     debugPrint('fetchEmployeeCheckinsAfterStart Error => $e');
  //   }
  //
  //   return null;
  // }
  Future<List<dynamic>> fetchTodayEmployeeCheckins(
      String employee) async {
    final cookies = await _sharedPrefService.getCookies();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayStart = '$today 00:00:00';
    final todayEnd = '$today 23:59:59';

    try {
      final response = await _dio.get(
        '/resource/Employee Checkin',
        queryParameters: {
          'fields': jsonEncode([
            'name',
            'employee',
            'employee_name',
            'log_type',
            'time',
            'latitude',
            'longitude',
            'customer',
            'remarks',
          ]),
          'filters': jsonEncode([
            ['employee', '=', employee],
            ['time', '>=', todayStart],
            ['time', '<=', todayEnd],
          ]),
          'order_by': 'time asc',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return List<dynamic>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('fetchTodayEmployeeCheckins Error => $e');
    }

    return [];
  }

  //checkin
// EEM List

  Future<List<Map<String, dynamic>>> fetchEEMList(
      String employee, {
        String? fromDate,
        String? toDate,
      }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final List<List<dynamic>> filters = [
        ["employee", "=", employee],
      ];

      if (fromDate != null && toDate != null) {
        filters.add(["date", "between", [fromDate, toDate]]);
      }

      final response = await _dio.get(
        "/resource/Executive Expense Manager",
        queryParameters: {
          "fields":
          jsonEncode([
            "name",
            "expense_claim_status",
            "date",
            "employee_name",
            "total_expense",
            "docstatus",
          ]),
          "filters": jsonEncode(filters),
          "order_by": "name desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("fetchEEMList Error: $e");
    }

    return [];
  }
  Future<Map<String, dynamic>?> fetchEEMDetail(String eemName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Executive Expense Manager/$eemName",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data["data"]);
      }
    } catch (e) {
      debugPrint("fetchEEMDetails Error: $e");
    }
    return null;
  }

// EEM LIst
  // ToDo List


  Future<List<Map<String, dynamic>>> fetchToDoList() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/ToDo",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "description",
            "status",
            "priority",
            "date",
            "reference_type",   // ✅ ADD
            "reference_name",   // ✅ ADD
          ]),
          "order_by": "date desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("fetchToDoList Error: $e");
    }

    return [];
  }
  Future<bool> updateToDoStatus({
    required String todoName,
    required String status,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.put(
        "/resource/ToDo/$todoName",
        data: {
          "status": status,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("updateToDoStatus Error: $e");
      return false;
    }
  }

  Future<String?> fetchMaintenanceVisitStatusForSalesOrder(
      String salesOrderName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/resource/Maintenance Visit',
        queryParameters: {
          'fields': jsonEncode([
            "name",
            "completion_status",
            "creation",
          ]),
          'filters': jsonEncode([
            [
              "Maintenance Visit Purpose",
              "prevdoc_docname",
              "=",
              salesOrderName
            ]
          ]),
          'order_by': "creation desc", // 🔥 latest first
          'limit_page_length': 1,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return null;

      final data = response.data["data"];

      if (data == null || data.isEmpty) return null;

      return data.first["completion_status"];

    } catch (e) {
      debugPrint("fetchMaintenanceVisitStatus Error: $e");
      return null;
    }
  }

  // ToDo List

  //Task List

  Future<List<Map<String, dynamic>>> fetchTaskList() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // ✅ Get logged-in user
      final loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) {
        debugPrint("No logged-in user found");
        return [];
      }

      // ✅ Get selected company from SharedPreferences
      final company = await _sharedPrefService.getCompany();

      // ✅ Build filters dynamically
      List<List<dynamic>> filters = [
        ["Task", "_assign", "like", "%$loggedInUser%"]
      ];

      if (company != null && company.isNotEmpty) {
        filters.add(["Task", "company", "=", company]);
      }

      // ✅ Fetch Tasks (Assignment + Company filter)
      final taskResponse = await _dio.get(
        "/resource/Task",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "subject",
            "status",
            "priority",
            "exp_start_date",
            "exp_end_date",
            "progress",
            "project",
            "parent_task",
            "type",
            "task_weight",
            "issue",
            "expected_time",
            "company",
            "description",
            "project",
          ]),
          "filters": jsonEncode(filters),
          "order_by": "modified desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (taskResponse.statusCode != 200) return [];

      final data = taskResponse.data["data"];
      if (data is! List) return [];

      List<Map<String, dynamic>> tasks =
      List<Map<String, dynamic>>.from(data);
// ✅ Batch check which tasks have attachments
      final taskNames = tasks.map((e) => e["name"].toString()).toList();

      if (taskNames.isNotEmpty) {
        try {
          final attachmentResponse = await _dio.get(
            "/resource/File",
            queryParameters: {
              "fields": jsonEncode(["name", "attached_to_name"]),
              "filters": jsonEncode([
                ["File", "attached_to_doctype", "=", "Task"],
                ["File", "attached_to_name", "in", taskNames],
              ]),
            },
            options: Options(headers: {'Cookie': cookies}),
          );

          if (attachmentResponse.statusCode == 200) {
            final attachData = attachmentResponse.data["data"];
            if (attachData is List) {
              final attachedTaskNames =
              attachData.map((e) => e["attached_to_name"].toString()).toSet();
              for (var task in tasks) {
                task["has_attachment"] =
                    attachedTaskNames.contains(task["name"].toString());
              }
            }
          }
        } catch (e) {
          debugPrint("Attachment check error: $e");
          for (var task in tasks) {
            task["has_attachment"] = false;
          }
        }
      }
      if (tasks.isEmpty) return tasks;

      // ✅ Collect unique project IDs
      final projectIds = tasks
          .map((e) => e["project"])
          .where((e) => e != null && e.toString().isNotEmpty)
          .toSet()
          .toList();

      if (projectIds.isEmpty) {
        for (var task in tasks) {
          task["project_name"] = "No Project";
        }
        return tasks;
      }

      // ✅ Batch fetch project names (SINGLE CALL)
      final projectResponse = await _dio.get(
        "/resource/Project",
        queryParameters: {
          "fields": jsonEncode(["name", "project_name"]),
          "filters": jsonEncode([
            ["Project", "name", "in", projectIds]
          ]),
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      Map<String, String> projectMap = {};

      if (projectResponse.statusCode == 200) {
        final projectData = projectResponse.data["data"];
        if (projectData is List) {
          for (var project in projectData) {
            projectMap[project["name"]] =
                project["project_name"] ?? project["name"];
          }
        }
      }

      // ✅ Attach project_name to each task
      for (var task in tasks) {
        final projectId = task["project"];
        task["project_name"] =
            projectMap[projectId] ?? "No Project";
      }

      return tasks;
    } catch (e) {
      debugPrint("fetchTaskList Error: $e");
    }

    return [];
  }
  Future<List<Map<String, String>>> fetchProjectList({
    String searchText = "",
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "txt": searchText,
          "doctype": "Project",
          "reference_doctype": "Task",
          "page_length": 50,
        },
        options: Options(headers: {"Cookie": cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["message"];
        if (data is List) {
          return data.map<Map<String, String>>((e) {
            return {
              "value": e["value"].toString(),  // PROJ-0001
              "label": e["label"].toString(),  // Add Modules
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("fetchProjectList Error: $e");
    }

    return [];
  }

  Future<bool> updateTask({
    required String taskName,
    String? status,
    double? progress,
    String? completedBy,
    String? completedOn,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      Map<String, dynamic> updateData = {};

      if (status != null) {
        updateData["status"] = status;
      }

      if (progress != null) {
        updateData["progress"] = progress;
      }

      if (completedBy != null) {
        updateData["completed_by"] = completedBy;
      }

      if (completedOn != null) {
        updateData["completed_on"] = completedOn;
      }

      final response = await _dio.put(
        "/resource/Task/$taskName",
        data: updateData,
        options: Options(
          headers: {
            'Cookie': cookies,
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("updateTask Error: $e");
    }

    return false;
  }

  Future<bool> uploadTaskAttachment({
    required String taskName,
    required String filePath,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final fileName = filePath.split('/').last;

      // STEP 1️⃣ Upload File
      FormData formData = FormData();
      formData.files.add(
        MapEntry(
          "file",
          await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        ),
      );

      formData.fields.add(MapEntry("is_private", "1"));

      final uploadResponse = await _dio.post(
        "/method/upload_file",
        data: formData,
        options: Options(headers: {"Cookie": cookies}),
      );

      if (uploadResponse.statusCode != 200) return false;

      final uploadedFileName =
      uploadResponse.data["message"]?["name"];

      if (uploadedFileName == null) {
        debugPrint("File upload failed: No file name returned");
        return false;
      }

      // STEP 2️⃣ Fetch file_url from File doctype
      final fileResponse = await _dio.get(
        "/resource/File/$uploadedFileName",
        options: Options(headers: {"Cookie": cookies}),
      );

      if (fileResponse.statusCode != 200) return false;

      final fileUrl = fileResponse.data["data"]?["file_url"];

      if (fileUrl == null) {
        debugPrint("File URL not found");
        return false;
      }

      // STEP 3️⃣ Attach file to Task
      final attachResponse = await _dio.post(
        "/method/upload_file",
        queryParameters: {
          "docname": taskName,
          "doctype": "Task",
          "is_private": "1",
          "folder": "Home/Attachments",
          "file_url": fileUrl,
        },
        options: Options(headers: {"Cookie": cookies}),
      );

      if (attachResponse.statusCode == 200) {
        debugPrint("File successfully attached to Task");
        return true;
      }

    } catch (e) {
      debugPrint("uploadTaskAttachment Error: $e");
    }

    return false;
  }
  /// Fetch all attachments for a given task
  Future<List<Map<String, dynamic>>> fetchTaskAttachments({
    required String taskName,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/File",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "file_name",
            "file_url",
            "file_type",
            "file_size",
            "is_private",
            "creation",
          ]),
          "filters": jsonEncode([
            ["File", "attached_to_doctype", "=", "Task"],
            ["File", "attached_to_name", "=", taskName],
          ]),
          "order_by": "creation desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint("fetchTaskAttachments Error: $e");
    }
    return [];
  }

  /// Download a private file (returns raw bytes)
  Future<Uint8List?> downloadPrivateFile(String fileUrl) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // Extract just the filename from the file_url
      // e.g. "/private/files/IMG-20260215-WA0006b0e5d0.jpg" → "IMG-20260215-WA0006b0e5d0.jpg"
      final fileName = fileUrl.split('/').last;

      // ERPNext serves private files through this endpoint
      final response = await _dio.get(
        "/method/frappe.utils.file_manager.download_file",
        queryParameters: {
          "file_url": fileUrl,
        },
        options: Options(
          headers: {'Cookie': cookies},
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint("downloadPrivateFile status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }

      // Fallback: try the direct baseUrl + file_url approach
      if (response.statusCode == 404) {
        debugPrint("Trying fallback download via baseUrl...");
        final fallbackResponse = await _dio.get(
          "$baseUrl$fileUrl",
          options: Options(
            headers: {'Cookie': cookies},
            responseType: ResponseType.bytes,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (fallbackResponse.statusCode == 200) {
          return Uint8List.fromList(fallbackResponse.data);
        }

        debugPrint("Fallback also failed: ${fallbackResponse.statusCode}");
      }

    } catch (e) {
      debugPrint("downloadPrivateFile Error: $e");
    }
    return null;
  }
  Future<bool> deleteTaskAttachment(String fileName) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.delete(
        "/resource/File/$fileName",
        options: Options(
          headers: {'Cookie': cookies},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint("deleteTaskAttachment status: ${response.statusCode}");

      if (response.statusCode == 202) return true;

      debugPrint("deleteTaskAttachment response: ${response.data}");
      return false;

    } catch (e) {
      debugPrint("deleteTaskAttachment Error: $e");
      return false;
    }
  }
  //Task List

  // Project list

  Future<List<Map<String, dynamic>>> fetchProjectsList() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // ✅ Get logged-in user
      final loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) {
        debugPrint("No logged-in user found");
        return [];
      }

      // ✅ Get selected company
      final company = await _sharedPrefService.getCompany();

      // ✅ Build filters dynamically (same pattern as Task)
      List<List<dynamic>> filters = [
        ["Project", "_assign", "like", "%$loggedInUser%"]
      ];

      if (company != null && company.isNotEmpty) {
        filters.add(["Project", "company", "=", company]);
      }

      // ✅ Fetch Projects
      final response = await _dio.get(
        "/resource/Project",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "project_name",
            "status",
            "priority",
            "expected_start_date",
            "expected_end_date",
            "project_type",
            "department",
            "is_active",
            "percent_complete_method",
            "percent_complete",
            "customer",
            "company", // good to include if filtering
          ]),
          "filters": jsonEncode(filters),
          "order_by": "modified desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return [];

      final data = response.data["data"];
      if (data is! List) return [];

      return List<Map<String, dynamic>>.from(data);

    } catch (e) {
      debugPrint("fetchProjectsList Error: $e");
      return [];
    }
  }
  Future<List<String>> fetchProjectTypes({
    String searchText = "",
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "txt": searchText,
          "doctype": "Project Type",
          "reference_doctype": "Project",
          "page_length": 20,
        },
        options: Options(headers: {"Cookie": cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["message"];

        if (data is List) {
          // Return only the "value" field
          return data
              .map<String>((e) => e["value"].toString())
              .toList();
        }
      }
    } catch (e) {
      debugPrint("fetchProjectTypes Error: $e");
    }

    return [];
  }

  //Project

  //maintenance visit

  Future<Map<String, dynamic>?> fetchCustomerDetaill({
    required String customer,
    required String company,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/erpnext.accounts.party.get_party_details",
        queryParameters: {
          "party": customer,
          "party_type": "Customer",
          "company": company,
          "doctype": "Maintenance Visit",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return null;

      final data = response.data["message"];
      if (data == null) return null;

      return {
        "customer_address": data["customer_address"],
        "territory": data["territory"],
        "contact_person": data["contact_person"],
        "customer_group": data["customer_group"],
      };
    } catch (e) {
      debugPrint("fetchCustomerDetails Error: $e");
      return null;
    }
  }

  Future<bool> createMaintenanceVisit({
    required String customer,
    required String customerName,
    required String mntcDate,
    required String mntcTime,
    required String completionStatus,
    required String maintenanceType,
    required String company,
    required List<Map<String, dynamic>> purposes,
    required String customerFeedback,
    String? prevDocName,
    String? prevDocType,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // 🔹 Step 1: Fetch customer details first
      final customerDetails = await fetchCustomerDetaill(
        customer: customer,
        company: company,
      );

      if (customerDetails == null) {
        debugPrint("Customer details not found");
        return false;
      }

      // 🔹 Step 2: Build request body
      final body = {
        "data": {
          "docstatus": 0,
          "customer": customer,
          "customer_name": customerName,
          "mntc_date": mntcDate,
          "mntc_time": mntcTime,
          "completion_status": completionStatus,
          "maintenance_type": maintenanceType,
          "company": company,
          "customer_address": customerDetails["customer_address"],
          "territory": customerDetails["territory"],
          "contact_person": customerDetails["contact_person"],
          "customer_group": customerDetails["customer_group"],
          "customer_feedback": customerFeedback,

          // "purposes": purposes,
          "purposes": purposes.map((row) {
            final newRow = Map<String, dynamic>.from(row);

            if (prevDocName != null && prevDocType != null) {
              newRow["prevdoc_docname"] = prevDocName;
              newRow["prevdoc_doctype"] = prevDocType;
            }

            return newRow;
          }).toList(),
        }
      };

      // 🔹 Step 3: POST request
      final response = await _dio.post(
        "/resource/Maintenance Visit",
        data: body,
        options: Options(headers: {'Cookie': cookies}),
      );

      return response.statusCode == 200 || response.statusCode == 201;

    } on DioException catch (e) {
      debugPrint("Status Code: ${e.response?.statusCode}");
      debugPrint("Response Data: ${e.response?.data}");
      return false;
    }
  }
  Future<bool> updateMaintenanceVisit({
    required String name,
    required String customer,
    required String customerName,
    required String mntcDate,
    required String mntcTime,
    required String completionStatus,
    required String maintenanceType,
    required String company,
    required String customerFeedback,
    required List<Map<String, dynamic>> purposes,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final body = {
        "docstatus": 1,
        "customer": customer,
        "customer_name": customerName,
        "mntc_date": mntcDate,
        "mntc_time": mntcTime,
        "completion_status": completionStatus,
        "maintenance_type": maintenanceType,
        "company": company,
        "customer_feedback": customerFeedback,
        "purposes": purposes,
      };

      final response = await _dio.put(
        "/resource/Maintenance Visit/$name",
        data: body,
        options: Options(headers: {'Cookie': cookies}),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint("Update Status Code: ${e.response?.statusCode}");
      debugPrint("Update Response Data: ${e.response?.data}");
      return false;
    }
  }
  Future<List<String>> searchCustomers(String query) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "doctype": "Customer",
          "reference_doctype": "Maintenance Visit",
          "txt": query,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return [];

      final List data = response.data["message"] ?? [];

      return data.map<String>((e) => e["value"].toString()).toList();
    } catch (e) {
      debugPrint("searchCustomers Error: $e");
      return [];
    }
  }

  Future<List<Map<String, String>>> searchItemm(String query) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "doctype": "Item",
          "reference_doctype": "Maintenance Visit Purpose",
          "txt": query,
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return [];

      final List data = response.data["message"] ?? [];

      return data.map<Map<String, String>>((e) {
        return {
          "item_code": e["value"].toString(),
          "item_name": e["description"]
              .toString()
              .split(",")
              .first
              .trim(),
        };
      }).toList();
    } catch (e) {
      debugPrint("searchItemm Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchSalesOrderByName(String name) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Sales Order/$name",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return response.data["data"];
      }
    } catch (e) {
      debugPrint("fetchSalesOrderByName Error: $e");
    }

    return null;
  }

  Future<List<String>> fetchSerialNumbers({
    required String itemCode,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.desk.search.search_link",
        queryParameters: {
          "doctype": "Serial No",
          "reference_doctype": "Maintenance Visit Purpose",
          "txt": "", // empty search
          "filters": jsonEncode({
            "item_code": itemCode,
          }),
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return [];

      final List data = response.data["message"] ?? [];

      return data.map<String>((e) => e["value"].toString()).toList();
    } catch (e) {
      debugPrint("fetchSerialNumbers Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMaintenanceVisitList({
    required String salesPerson,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        '/resource/Maintenance Visit',
        queryParameters: {
          'fields':
          '["name","customer","status","completion_status","maintenance_type","mntc_time","mntc_date","creation"]',

          // ✅ Child filter
          'filters': jsonEncode([
            ["Maintenance Visit Purpose", "service_person", "=", salesPerson]
          ]),

          // ✅ Remove duplicates
          'group_by': 'name',

          // ✅ Latest first
          'order_by': 'creation desc',
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode != 200) return [];

      final data = response.data["data"];
      if (data == null) return [];

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("fetchMaintenanceVisitList Error: $e");
      return [];
    }
  }
  Future<Map<String, dynamic>?> fetchMaintenanceVisitByName(String name) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Maintenance Visit/$name",
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        return response.data["data"];
      }
    } catch (e) {
      debugPrint("fetchMaintenanceVisitByName Error: $e");
    }

    return null;
  }
  //maintenance visit

  //estimate preparation

  Future<Map<String, dynamic>> createEstimate({
    required BuildContext context,
    required String customer,
    required String company,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required double gstAmount,
    required double totalAmount,
    required String message,
  }) async {
    final cookies = await _sharedPrefService.getCookies();
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    };

    try {
      // ── Step 1: Save (docstatus: 0) ──────────────────────────
      final saveBody = {
        "docstatus": 0,
        "customer": customer,
        "company": company,
        "Date": date,
        "contact": contact,
        "valid_till": validTill,
        "item_code": itemCode,
        "gst_perc": gstPerc.toString(),
        "gst_amount": gstAmount,
        "item_name": itemName,
        "rate": rate,
        "total_amount": totalAmount,
        "item_description": itemDescription,
        "message": "<div class=\"ql-editor read-mode\"><p>$message</p></div>",
      };

      final saveResponse = await _dio.post(
        "/resource/Tq Estimate",
        data: saveBody,
        options: Options(headers: headers),
      );

      if (saveResponse.statusCode != 200) {
        debugPrint("Save failed: ${saveResponse.data}");
        return {"success": false, "error": "Failed to save estimate"};
      }

      final docname = saveResponse.data["data"]["name"]?.toString();
      if (docname == null || docname.isEmpty) {
        return {"success": false, "error": "Docname not found in response"};
      }
      debugPrint("Estimate saved. Docname: $docname");

      // ── Step 2: Submit (docstatus: 1) ────────────────────────
      final submitResponse = await _dio.put(
        "/resource/Tq Estimate/$docname",
        data: {"docstatus": 1},
        options: Options(headers: headers),
      );

      if (submitResponse.statusCode != 200) {
        debugPrint("Submit failed: ${submitResponse.data}");
        return {
          "success": false,
          "error": "Saved (${docname}) but submission failed"
        };
      }
      debugPrint("Estimate submitted: $docname");

      // ── Step 3: Send WhatsApp ─────────────────────────────────
      final phone = "91$contact";
      final whatsappResponse = await _dio.post(
        "/method/tqerp_mobibiz_serv.api.send_whatsapp_estimate",
        queryParameters: {
          "docname": docname,
          "phone": phone,
        },
        options: Options(headers: headers),
      );

      if (whatsappResponse.statusCode == 200) {
        debugPrint("WhatsApp sent to $phone for $docname");
      } else {
        debugPrint("WhatsApp failed (non-critical): ${whatsappResponse.data}");
      }

      return {"success": true, "docname": docname};
    } catch (e) {
      debugPrint("createEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    }
  }

  Future<String?> getCustomerContact(String customer) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Contact",
        queryParameters: {
          "fields": jsonEncode(["phone", "mobile_no"]),
          "filters": jsonEncode([["company_name", "=", customer]]),
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data["data"] ?? [];
        if (data.isNotEmpty) {
          final contact = data[0];
          final phone = contact["phone"]?.toString() ?? '';
          final mobileNo = contact["mobile_no"]?.toString() ?? '';

          // ✅ Phone takes priority, fallback to mobile_no
          if (phone.isNotEmpty) return phone;
          if (mobileNo.isNotEmpty) return mobileNo;
        }
      }
    } catch (e) {
      debugPrint("getCustomerContact Error: $e");
    }
    return null;
  }
  Future<double?> getItemGstPerc(String itemCode, String company) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final args = jsonEncode({
        "item_code": itemCode,
        "company": company,
      });

      final response = await _dio.get(
        "/method/erpnext.stock.get_item_details.get_item_tax_template",
        queryParameters: {"args": args},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final String message = response.data["message"] ?? "";
        // Extract number from strings like "GST 18% - BDA" or "GST 5% - BDA"
        final match = RegExp(r'(\d+(\.\d+)?)%').firstMatch(message);
        if (match != null) {
          return double.tryParse(match.group(1)!);
        }
      }
    } catch (e) {
      debugPrint("getItemGstPerc Error: $e");
    }
    return null;
  }
  Future<double?> getItemRate(String itemCode) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/method/frappe.client.get",
        queryParameters: {
          "doctype": "Item",
          "name": itemCode,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final message = response.data["message"];
        final rate = message?["standard_rate"];
        if (rate != null) {
          return double.tryParse(rate.toString());
        }
      }
    } catch (e) {
      debugPrint("getItemRate Error: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchEstimateList({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      // 🔹 Fetch logged in user
      final loggedInUser = await getLoggedInUserIdentifier();
      if (loggedInUser == null) {
        debugPrint("fetchEstimateList: Could not get logged in user");
        return [];
      }

      final toDateInclusive = toDate.add(const Duration(days: 1));

      final response = await _dio.get(
        "/resource/Tq Estimate",
        queryParameters: {
          "fields": jsonEncode([
            "name", "customer", "customer_name","contact", "docstatus", "valid_till",
            "item_code", "item_name", "item_description", "message",
            "Date", "gst_perc", "gst_amount", "rate", "total_amount"
          ]),
          "filters": jsonEncode([
            ["docstatus", "!=", 2],
            ["Date", ">=", DateFormat('yyyy-MM-dd').format(fromDate)],
            ["Date", "<",  DateFormat('yyyy-MM-dd').format(toDateInclusive)],
            ["Tq Estimate", "owner", "=", loggedInUser],  // 🔹 owner filter
          ]),
          "order_by": "creation desc",
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Cookie": cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data["data"] ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("fetchEstimateList Error: $e");
    }
    return [];
  }
  Future<Map<String, dynamic>> updateEstimate({
    required BuildContext context,
    required String docname,
    required String customer,
    required String company,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required double gstAmount,
    required double totalAmount,
    required String message,
  }) async {
    final cookies = await _sharedPrefService.getCookies();
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    };

    try {
      // ── Step 1: Update (PUT with docstatus: 0) ───────────────
      final updateBody = {
        "docstatus": 0,
        "customer": customer,
        "company": company,
        "Date": date,
        "contact": contact,
        "valid_till": validTill,
        "item_code": itemCode,
        "gst_perc": gstPerc.toString(),
        "gst_amount": gstAmount,
        "item_name": itemName,
        "rate": rate,
        "total_amount": totalAmount,
        "item_description": itemDescription,
        "message": "<div class=\"ql-editor read-mode\"><p>$message</p></div>",
      };

      final updateResponse = await _dio.put(
        "/resource/Tq Estimate/$docname",
        data: updateBody,
        options: Options(headers: headers),
      );

      if (updateResponse.statusCode != 200) {
        return {"success": false, "error": "Failed to update estimate"};
      }
      debugPrint("Estimate updated: $docname");

      // ── Step 2: Submit (docstatus: 1) ────────────────────────
      final submitResponse = await _dio.put(
        "/resource/Tq Estimate/$docname",
        data: {"docstatus": 1},
        options: Options(headers: headers),
      );

      if (submitResponse.statusCode != 200) {
        return {
          "success": false,
          "error": "Updated ($docname) but submission failed"
        };
      }
      debugPrint("Estimate submitted: $docname");

      // ── Step 3: Send WhatsApp ─────────────────────────────────
      final phone = "91$contact";
      await _dio.post(
        "/method/tqerp_mobibiz_serv.api.send_whatsapp_estimate",
        queryParameters: {"docname": docname, "phone": phone},
        options: Options(headers: headers),
      );
      debugPrint("WhatsApp sent to $phone for $docname");

      return {"success": true, "docname": docname};
    } catch (e) {
      debugPrint("updateEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    }
  }
  // Save draft — POST (new) or PUT (existing)
  // Future<Map<String, dynamic>> saveDraftEstimate({
  //   required BuildContext context,
  //   required String? docname,
  //   required String customer,
  //   required String customerName,
  //   required String company,
  //   required String date,
  //   required String contact,
  //   required String validTill,
  //   required String itemCode,
  //   required String itemName,
  //   required String itemDescription,
  //   required double rate,
  //   required double gstPerc,
  //   required double gstAmount,
  //   required double totalAmount,
  //   required String message,
  // }) async {
  //   final cookies = await _sharedPrefService.getCookies();
  //   final headers = {
  //     'Content-Type': 'application/json',
  //     'Cookie': cookies,
  //   };
  //
  //   final body = {
  //     "docstatus": 0,
  //     "customer": customer,
  //     "customer_name": customerName,
  //     "company": company,
  //     "Date": date,
  //     "contact": contact,
  //     "valid_till": validTill,
  //     "item_code": itemCode,
  //     "gst_perc": gstPerc.toString(),
  //     "gst_amount": gstAmount,
  //     "item_name": itemName,
  //     "rate": rate,
  //     "total_amount": totalAmount,
  //     "item_description": itemDescription,
  //     "message": "<div class=\"ql-editor read-mode\"><p>$message</p></div>",
  //   };
  //
  //   try {
  //     final response = docname == null
  //         ? await _dio.post(
  //       "/resource/Tq Estimate",
  //       data: body,
  //       options: Options(headers: headers),
  //     )
  //         : await _dio.put(
  //       "/resource/Tq Estimate/$docname",
  //       data: body,
  //       options: Options(headers: headers),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final name = response.data["data"]["name"]?.toString() ?? docname ?? '';
  //       debugPrint("Draft saved: $name");
  //       return {"success": true, "docname": name};
  //     }
  //
  //     return {"success": false, "error": "Failed to save draft"};
  //   } catch (e) {
  //     debugPrint("saveDraftEstimate Error: $e");
  //     return {"success": false, "error": e.toString()};
  //   }
  // }
  Future<Map<String, dynamic>> saveDraftEstimate({
    required BuildContext context,
    required String? docname,
    required String customer,
    required String customerName,
    required String company,
    required String date,
    required String contact,
    required String validTill,
    required String itemCode,
    required String itemName,
    required String itemDescription,
    required double rate,
    required double gstPerc,
    required double gstAmount,
    required double totalAmount,
    required String message,
  }) async {
    final cookies = await _sharedPrefService.getCookies();
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    };

    // ✅ Only send customer link if selected from list (valid ERPNext customer)
    // If manually entered, leave customer blank and rely on customer_name only
    final bool isLinkedCustomer = customer.isNotEmpty && customer != customerName;

    final body = {
      "docstatus": 0,
      "customer": isLinkedCustomer ? customer : "",   // ✅ empty if manual entry
      "customer_name": customerName.isNotEmpty
          ? customerName
          : customer,                                  // ✅ always has a value
      "company": company,
      "Date": date,
      "contact": contact,
      "valid_till": validTill,
      "item_code": itemCode,
      "gst_perc": gstPerc.toString(),
      "gst_amount": gstAmount,
      "item_name": itemName,
      "rate": rate,
      "total_amount": totalAmount,
      "item_description": itemDescription,
      "message": "<div class=\"ql-editor read-mode\"><p>$message</p></div>",
    };

    try {
      final response = docname == null
          ? await _dio.post(
        "/resource/Tq Estimate",
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      )
          : await _dio.put(
        "/resource/Tq Estimate/$docname",
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final name =
            response.data["data"]["name"]?.toString() ?? docname ?? '';
        debugPrint("Draft saved: $name");
        return {"success": true, "docname": name};
      }

      // ✅ Extract server error message if available
      final serverMessage = response.data?["exception"] ??
          response.data?["message"] ??
          "Failed to save draft (${response.statusCode})";
      debugPrint("saveDraftEstimate failed: $serverMessage");
      return {"success": false, "error": serverMessage};
    } catch (e) {
      debugPrint("saveDraftEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    }
  }

// Submit + WhatsApp
//   Future<Map<String, dynamic>> submitEstimate({
//     required String docname,
//     required String contact,
//   }) async {
//     final cookies = await _sharedPrefService.getCookies();
//     final headers = {
//       'Content-Type': 'application/json',
//       'Cookie': cookies,
//     };
//
//     try {
//       // Submit
//       final submitResponse = await _dio.put(
//         "/resource/Tq Estimate/$docname",
//         data: {"docstatus": 1},
//         options: Options(headers: headers),
//       );
//
//       if (submitResponse.statusCode != 200) {
//         return {"success": false, "error": "Submission failed"};
//       }
//       debugPrint("Submitted: $docname");
//
//       // WhatsApp
//       final phone = "91$contact";
//       await _dio.post(
//         "/method/tqerp_bd.api.send_whatsapp_estimate",
//         queryParameters: {"docname": docname, "phone": phone},
//         options: Options(headers: headers),
//       );
//       debugPrint("WhatsApp sent to $phone");
//
//       return {"success": true, "docname": docname};
//     } catch (e) {
//       debugPrint("submitEstimate Error: $e");
//       return {"success": false, "error": e.toString()};
//     }
//   }

  Future<Map<String, dynamic>> submitEstimate({
    required String docname,
    required String contact,
  }) async {
    final cookies = await _sharedPrefService.getCookies();
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    };

    try {
      // ── Submit ────────────────────────────────────────────
      final submitResponse = await _dio.put(
        "/resource/Tq Estimate/$docname",
        data: {"docstatus": 1},
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (submitResponse.statusCode != 200) {
        return {
          "success": false,
          "error": "Submission failed (${submitResponse.statusCode})"
        };
      }
      debugPrint("Submitted: $docname");

      // ── WhatsApp (non-critical) ───────────────────────────
      try {
        final phone = "91$contact";
        final whatsappResponse = await _dio.post(
          "/method/tqerp_mobibiz_serv.api.send_whatsapp_estimate",
          queryParameters: {"docname": docname, "phone": phone},
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (whatsappResponse.statusCode == 200) {
          debugPrint("WhatsApp sent to $phone");
        } else {
          debugPrint(
              "WhatsApp failed with ${whatsappResponse.statusCode} (non-critical)");
        }
      } catch (e) {
        // ✅ WhatsApp failure must never block the success result
        debugPrint("WhatsApp error (non-critical): $e");
      }

      return {"success": true, "docname": docname};
    } catch (e) {
      debugPrint("submitEstimate Error: $e");
      return {"success": false, "error": e.toString()};
    }
  }
  //estimate preparation

// appointments

  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final response = await _dio.get(
        "/resource/Patient Appointment",
        queryParameters: {
          "fields": jsonEncode([
            "name",
            "title",
            "status",
            "patient",
            "patient_name",
            "patient_sex",
            "appointment_type",
            "duration",
            "practitioner_name",
            "service_unit",
            "appointment_date",
            "appointment_time",
          ]),
          "order_by": "appointment_date desc, appointment_time desc",
        },
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("fetchAppointments Error: $e");
    }
    return [];
  }


  //appointments
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

  // Future<CustomerList?> customerSearch(
  //     String customer,
  //     BuildContext context,
  //     ) async {
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final filterBySalesPerson =
  //     await _sharedPrefService.getCustomerFilterBySalesPerson();
  //
  //     String? salesPerson;
  //     if (filterBySalesPerson) {
  //       salesPerson = await getSalesPersonWithCache();
  //       debugPrint("Sales Person for filtering: $salesPerson");
  //     }
  //
  //     // ✅ Normalize: lowercase + remove special chars (matches ERPNext normalization)
  //     final normalizedSearch = customer
  //         .toLowerCase()
  //         .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
  //         .trim();
  //
  //     debugPrint("Search raw       : $customer");
  //     debugPrint("Search normalized: $normalizedSearch");
  //
  //     final fields = jsonEncode([
  //       "name",
  //       "customer_name",
  //       "normalized_customer_name",
  //       "tax_id",
  //       "gstin",
  //       "territory",
  //       "customer_primary_contact",
  //       "customer_primary_address",
  //       "primary_address",
  //       "mobile_no",
  //       "email_id",
  //       "tax_category",
  //       "customer_group",
  //       "_liked_by",
  //     ]);
  //
  //     final options = Options(
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Cookie": cookies,
  //       },
  //       validateStatus: (status) => status != null && status < 500,
  //     );
  //
  //     // ✅ Sales person base filter (shared by both calls)
  //     List salesPersonFilter = [];
  //     if (filterBySalesPerson && salesPerson != null) {
  //       salesPersonFilter = [["Sales Team", "sales_person", "=", salesPerson]];
  //     }
  //
  //     // ✅ Two parallel calls: one by name, one by normalized_customer_name
  //     final results = await Future.wait([
  //       _dio.get(
  //         "/resource/Customer",
  //         queryParameters: {
  //           "fields": fields,
  //           "filters": jsonEncode([
  //             ...salesPersonFilter,
  //             ["Customer", "name", "like", "%$customer%"],
  //           ]),
  //         },
  //         options: options,
  //       ),
  //       _dio.get(
  //         "/resource/Customer",
  //         queryParameters: {
  //           "fields": fields,
  //           "filters": jsonEncode([
  //             ...salesPersonFilter,
  //             ["Customer", "normalized_customer_name", "like", "%$normalizedSearch%"],
  //           ]),
  //         },
  //         options: options,
  //       ),
  //     ]);
  //
  //     final nameResponse = results[0];
  //     final normalizedResponse = results[1];
  //
  //     debugPrint("Name search status      : ${nameResponse.statusCode}");
  //     debugPrint("Normalized search status: ${normalizedResponse.statusCode}");
  //     debugPrint("Name search data        : ${nameResponse.data}");
  //     debugPrint("Normalized search data  : ${normalizedResponse.data}");
  //
  //     // ✅ Merge both lists and deduplicate by 'name' field
  //     final List<dynamic> nameResults =
  //     nameResponse.statusCode == 200 ? (nameResponse.data['data'] ?? []) : [];
  //     final List<dynamic> normalizedResults =
  //     normalizedResponse.statusCode == 200 ? (normalizedResponse.data['data'] ?? []) : [];
  //
  //     final seen = <String>{};
  //     final merged = [...nameResults, ...normalizedResults]
  //         .where((c) => seen.add(c['name'] as String))
  //         .toList();
  //
  //     debugPrint("Name results count      : ${nameResults.length}");
  //     debugPrint("Normalized results count: ${normalizedResults.length}");
  //     debugPrint("Merged unique count     : ${merged.length}");
  //
  //     // ✅ Wrap merged list into the same shape CustomerList.fromJson expects
  //     return CustomerList.fromJson({"data": merged});
  //   } catch (e) {
  //     debugPrint("Customer Search Error: $e");
  //     throw Exception("Failed to search customer");
  //   }
  // }
  // Future<CustomerList?> customerSearch(
  //     String customer,
  //     BuildContext context,
  //     ) async {
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final filterBySalesPerson =
  //     await _sharedPrefService.getCustomerFilterBySalesPerson();
  //
  //     String? salesPerson;
  //     if (filterBySalesPerson) {
  //       salesPerson = await getSalesPersonWithCache();
  //       debugPrint("Sales Person for filtering: $salesPerson");
  //     }
  //
  //     final normalizedSearch = customer
  //         .toLowerCase()
  //         .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
  //         .trim();
  //
  //     debugPrint("Search raw       : $customer");
  //     debugPrint("Search normalized: $normalizedSearch");
  //
  //     // ✅ Fields without normalized_customer_name (base, always safe)
  //     final baseFields = [
  //       "name",
  //       "customer_name",
  //       "tax_id",
  //       "gstin",
  //       "territory",
  //       "customer_primary_contact",
  //       "customer_primary_address",
  //       "primary_address",
  //       "mobile_no",
  //       "email_id",
  //       "tax_category",
  //       "customer_group",
  //       "_liked_by",
  //     ];
  //
  //     final options = Options(
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Cookie": cookies,
  //       },
  //       validateStatus: (status) => status != null && status < 500,
  //     );
  //
  //     List salesPersonFilter = [];
  //     if (filterBySalesPerson && salesPerson != null) {
  //       salesPersonFilter = [["Sales Team", "sales_person", "=", salesPerson]];
  //     }
  //
  //     // ── Call 1: search by name (always runs) ────────────────────────────
  //     final nameResponse = await _dio.get(
  //       "/resource/Customer",
  //       queryParameters: {
  //         "fields": jsonEncode(baseFields),
  //         "filters": jsonEncode([
  //           ...salesPersonFilter,
  //           ["Customer", "name", "like", "%$customer%"],
  //         ]),
  //       },
  //       options: options,
  //     );
  //
  //     debugPrint("Name search status: ${nameResponse.statusCode}");
  //     debugPrint("Name search data  : ${nameResponse.data}");
  //
  //     final List<dynamic> nameResults =
  //     nameResponse.statusCode == 200
  //         ? (nameResponse.data['data'] ?? [])
  //         : [];
  //
  //     // ── Call 2: search by normalized_customer_name (optional) ────────────
  //     List<dynamic> normalizedResults = [];
  //
  //     try {
  //       final normalizedResponse = await _dio.get(
  //         "/resource/Customer",
  //         queryParameters: {
  //           "fields": jsonEncode([...baseFields, "normalized_customer_name"]),
  //           "filters": jsonEncode([
  //             ...salesPersonFilter,
  //             ["Customer", "normalized_customer_name", "like", "%$normalizedSearch%"],
  //           ]),
  //         },
  //         options: options,
  //       );
  //
  //       debugPrint("Normalized search status: ${normalizedResponse.statusCode}");
  //       debugPrint("Normalized search data  : ${normalizedResponse.data}");
  //
  //       // ✅ Check if ERPNext returned a field error — treat as unsupported
  //       final isFieldError = normalizedResponse.data is Map &&
  //           (normalizedResponse.data['exc_type'] == 'DataError' ||
  //               (normalizedResponse.data['exception']
  //                   ?.toString()
  //                   .contains('normalized_customer_name') ??
  //                   false));
  //
  //       if (normalizedResponse.statusCode == 200 && !isFieldError) {
  //         normalizedResults = normalizedResponse.data['data'] ?? [];
  //         debugPrint("Normalized results count: ${normalizedResults.length}");
  //       } else {
  //         debugPrint(
  //             "normalized_customer_name not available on this ERPNext instance — skipping");
  //       }
  //     } catch (e) {
  //       // ✅ Field not supported — silently skip, name search result is enough
  //       debugPrint("normalized_customer_name search skipped: $e");
  //     }
  //
  //     // ── Merge & deduplicate ──────────────────────────────────────────────
  //     final seen = <String>{};
  //     final merged = [...nameResults, ...normalizedResults]
  //         .where((c) => seen.add(c['name'] as String))
  //         .toList();
  //
  //     debugPrint("Name results count : ${nameResults.length}");
  //     debugPrint("Normalized count   : ${normalizedResults.length}");
  //     debugPrint("Merged unique count: ${merged.length}");
  //
  //     return CustomerList.fromJson({"data": merged});
  //   } catch (e) {
  //     debugPrint("Customer Search Error: $e");
  //     throw Exception("Failed to search customer");
  //   }
  // }
  // ✅ Cache allowed fields so we only probe once per app session
  static Set<String>? _allowedCustomerFields;

  Future<Set<String>> _getAllowedCustomerFields(
      String cookies, List<String> candidates) async {
    if (_allowedCustomerFields != null) {
      debugPrint("Using cached allowed fields: $_allowedCustomerFields");
      return _allowedCustomerFields!;
    }

    final allowed = <String>{};

    for (final field in candidates) {
      try {
        final response = await _dio.get(
          "/resource/Customer",
          queryParameters: {
            "fields": jsonEncode([field]),
            "filters": jsonEncode([["Customer", "name", "=", "__probe__"]]),
            "limit": "1",
          },
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Cookie": cookies,
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        final isError = response.data is Map &&
            (response.data['exc_type'] == 'DataError' ||
                response.data['exception']?.toString().contains(field) == true);

        if (!isError) {
          allowed.add(field);
          debugPrint("Field allowed  : $field");
        } else {
          debugPrint("Field rejected : $field");
        }
      } catch (e) {
        debugPrint("Field probe error for $field: $e");
      }
    }

    _allowedCustomerFields = allowed;
    debugPrint("Allowed customer fields cached: $allowed");
    return allowed;
  }

  Future<CustomerList?> customerSearch(
      String customer,
      BuildContext context,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final filterBySalesPerson =
      await _sharedPrefService.getCustomerFilterBySalesPerson();

      String? salesPerson;
      if (filterBySalesPerson) {
        salesPerson = await getSalesPersonWithCache();
        debugPrint("Sales Person for filtering: $salesPerson");
      }

      final normalizedSearch = customer
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
          .trim();

      debugPrint("Search raw       : $customer");
      debugPrint("Search normalized: $normalizedSearch");

      // ✅ All fields we want — probe once to see which are permitted
      final candidates = [
        "name",
        "customer_name",
        "normalized_customer_name",
        "tax_id",
        "gstin",
        "territory",
        "customer_primary_contact",
        "customer_primary_address",
        "primary_address",
        "mobile_no",
        "email_id",
        "tax_category",
        "customer_group",
        "_liked_by",
      ];

      final allowedFields = await _getAllowedCustomerFields(cookies, candidates);

      // ✅ Always keep these core fields regardless
      final requiredFields = {"name", "customer_name"};
      final safeFields = [
        ...requiredFields,
        ...allowedFields.where((f) => !requiredFields.contains(f)),
      ].toList();

      final hasNormalized = allowedFields.contains("normalized_customer_name");

      debugPrint("Safe fields      : $safeFields");
      debugPrint("Has normalized   : $hasNormalized");

      final options = Options(
        headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        },
        validateStatus: (status) => status != null && status < 500,
      );

      List salesPersonFilter = [];
      if (filterBySalesPerson && salesPerson != null) {
        salesPersonFilter = [["Sales Team", "sales_person", "=", salesPerson]];
      }

      // ── Call 1: search by name (always runs) ────────────────────────────
      final nameResponse = await _dio.get(
        "/resource/Customer",
        queryParameters: {
          "fields": jsonEncode(safeFields),
          "filters": jsonEncode([
            ...salesPersonFilter,
            ["Customer", "name", "like", "%$customer%"],
          ]),
        },
        options: options,
      );

      debugPrint("Name search status: ${nameResponse.statusCode}");

      final isNameError = nameResponse.data is Map &&
          nameResponse.data['exc_type'] != null;

      final List<dynamic> nameResults =
      nameResponse.statusCode == 200 && !isNameError
          ? (nameResponse.data['data'] ?? [])
          : [];

      debugPrint("Name results count: ${nameResults.length}");

      // ── Call 2: normalized search (only if field exists) ─────────────────
      List<dynamic> normalizedResults = [];

      if (hasNormalized) {
        try {
          final normalizedResponse = await _dio.get(
            "/resource/Customer",
            queryParameters: {
              "fields": jsonEncode(safeFields),
              "filters": jsonEncode([
                ...salesPersonFilter,
                ["Customer", "normalized_customer_name", "like",
                  "%$normalizedSearch%"],
              ]),
            },
            options: options,
          );

          debugPrint(
              "Normalized search status: ${normalizedResponse.statusCode}");

          final isNormError = normalizedResponse.data is Map &&
              normalizedResponse.data['exc_type'] != null;

          if (normalizedResponse.statusCode == 200 && !isNormError) {
            normalizedResults = normalizedResponse.data['data'] ?? [];
            debugPrint(
                "Normalized results count: ${normalizedResults.length}");
          } else {
            // ✅ Field became unavailable — clear cache so next search re-probes
            _allowedCustomerFields = null;
            debugPrint("Normalized search failed — cache cleared");
          }
        } catch (e) {
          debugPrint("Normalized search skipped: $e");
        }
      } else {
        debugPrint("normalized_customer_name not available — skipping");
      }

      // ── Merge & deduplicate ──────────────────────────────────────────────
      final seen = <String>{};
      final merged = [...nameResults, ...normalizedResults]
          .where((c) => seen.add(c['name'] as String))
          .toList();

      debugPrint("Merged unique count: ${merged.length}");

      return CustomerList.fromJson({"data": merged});
    } catch (e) {
      debugPrint("Customer Search Error: $e");
      throw Exception("Failed to search customer");
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

  // sales Order


  Future<String?> fetchDefaultSalesTaxTemplate(String company) async {
    final url =
        '/resource/Sales Taxes and Charges Template'
        '?filters=[["company","=","$company"],["is_default","=",1]]'
        '&fields=["name"]'
        '&limit=1';

    final cookies = await _sharedPrefService.getCookies();

    final response = await _dio.get(
      url,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Cookie': cookies,
      }),
    );

    final data = response.data['data'];
    if (data != null && data.isNotEmpty) {
      return data.first['name'];
    }
    return null;
  }
  //
  // Future<SalesOrderResponse?> salesOrder(
  //     String customerName,
  //     String deliveryDate,
  //     List items,
  //     BuildContext context, {
  //       Map<String, dynamic>? customerDetails,
  //       String? setWarehouse,
  //       // String? quotation,
  //     }) async {
  //   const url = '/resource/Sales Order';
  //
  //   // 🔹 Fetch user branch + warehouse (may be null)
  //   final userBranchData = await fetchUserBranch(context);
  //
  //   final String? branch = userBranchData?['branch'];
  //   final String? defaultWarehouse = userBranchData?['default_warehouse'];
  //   final company = await _sharedPrefService.getCompany();
  //
  //   if (company == null || company.isEmpty) {
  //     throw Exception("Company not selected");
  //   }
  //   // 🔹 Build request payload safely
  //   final Map<String, dynamic> request = {
  //     "company": company,
  //     "customer": customerName,
  //     "delivery_date": deliveryDate,
  //     "items": items,
  //   };
  //   // 🔹 Add branch ONLY if available
  //   if (branch != null && branch.isNotEmpty) {
  //     request["branch"] = branch;
  //   }
  //
  //   // 🔹 Warehouse priority:
  //   // 1. Explicit warehouse
  //   // 2. User default warehouse
  //   if (setWarehouse != null && setWarehouse.isNotEmpty) {
  //     request["set_warehouse"] = setWarehouse;
  //   } else if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
  //     request["set_warehouse"] = defaultWarehouse;
  //   }
  //
  //   // 🔹 Merge customer details last (optional)
  //   if (customerDetails != null) {
  //     request.addAll(customerDetails);
  //   }
  //   final taxTemplate = await fetchDefaultSalesTaxTemplate(company);
  //
  //   if (taxTemplate != null) {
  //     request["taxes_and_charges"] = taxTemplate;
  //   }
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final response = await _dio.post(
  //       url,
  //       data: request,
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
  //       return SalesOrderResponse.fromJson(response.data);
  //     }
  //
  //     final data = response.data;
  //     if (data is Map && data.containsKey('exception')) {
  //       final raw = data['exception'];
  //       throw Exception(raw.replaceAll(RegExp(r'<[^>]*>'), ''));
  //     }
  //
  //     throw Exception('Failed to create Sales Order');
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  Future<SalesOrderResponse?> salesOrder(
      String customerName,
      String deliveryDate,
      List items,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
        String? setWarehouse,
        String applyDiscountOn = 'Net Total',       // 👇 new
        double additionalDiscountPercentage = 0.0,    // 👇 new
        double discountAmount = 0.0,                  // 👇 new
      }) async {
    const url = '/resource/Sales Order';

    final userBranchData = await fetchUserBranch(context);
    final String? branch = userBranchData?['branch'];
    final String? defaultWarehouse = userBranchData?['default_warehouse'];
    final company = await _sharedPrefService.getCompany();

    if (company == null || company.isEmpty) {
      throw Exception("Company not selected");
    }

    final Map<String, dynamic> request = {
      "company": company,
      "customer": customerName,
      "delivery_date": deliveryDate,
      "items": items,
      // 👇 Always send apply_discount_on; ERPNext needs it to interpret the others
      "apply_discount_on": applyDiscountOn,
      if (additionalDiscountPercentage > 0)
        "additional_discount_percentage": additionalDiscountPercentage,
      if (discountAmount > 0) "discount_amount": discountAmount,
    };

    if (branch != null && branch.isNotEmpty) request["branch"] = branch;

    if (setWarehouse != null && setWarehouse.isNotEmpty) {
      request["set_warehouse"] = setWarehouse;
    } else if (defaultWarehouse != null && defaultWarehouse.isNotEmpty) {
      request["set_warehouse"] = defaultWarehouse;
    }

    if (customerDetails != null) request.addAll(customerDetails);

    final taxTemplate = await fetchDefaultSalesTaxTemplate(company);
    if (taxTemplate != null) request["taxes_and_charges"] = taxTemplate;

    try {
      final cookies = await _sharedPrefService.getCookies();
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

      if (response.statusCode == 200) {
        return SalesOrderResponse.fromJson(response.data);
      }

      final data = response.data;
      if (data is Map && data.containsKey('exception')) {
        final raw = data['exception'];
        throw Exception(raw.replaceAll(RegExp(r'<[^>]*>'), ''));
      }

      throw Exception('Failed to create Sales Order');
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesOrderResponse?> updateSalesOrder(
      String name,
      String customerName,
      String deliveryDate,
      String? setWarehouse,
      List items,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
        String applyDiscountOn = 'Net Total',       // 👇 new
        double additionalDiscountPercentage = 0.0,    // 👇 new
        double discountAmount = 0.0,                  // 👇 new
      }) async {
    final url = '/resource/Sales Order/$name';

    try {
      final cookies = await _sharedPrefService.getCookies();

      final request = {
        if (setWarehouse != null && setWarehouse.isNotEmpty)
          "set_warehouse": setWarehouse,
        "delivery_date": deliveryDate,
        "items": items,
        // 👇 Include discount fields in update payload
        "apply_discount_on": applyDiscountOn,
        if (additionalDiscountPercentage > 0)
          "additional_discount_percentage": additionalDiscountPercentage,
        if (discountAmount > 0) "discount_amount": discountAmount,
      };

      debugPrint('Updating sales order at: $name');
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

      if (response.statusCode == 200) {
        return SalesOrderResponse.fromJson(response.data);
      }

      final data = response.data;
      if (data is Map && data.containsKey('exception')) {
        throw Exception(
            (data['exception'] as String).replaceAll(RegExp(r'<[^>]*>'), ''));
      }
      throw Exception('Failed to update sales order');
    } on DioException catch (e) {
      debugPrint('DioException (PUT): ${e.message}');
      final data = e.response?.data;
      if (data is Map && data.containsKey('exception')) {
        throw Exception(
            (data['exception'] as String).replaceAll(RegExp(r'<[^>]*>'), ''));
      }
      throw Exception('Failed to update sales order');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  //
  // Future<SalesOrderResponse?> updateSalesOrder(
  //     String name,
  //     String customerName,
  //     String deliveryDate,
  //     String? setWarehouse,
  //     List items,
  //     BuildContext context, {
  //       Map<String, dynamic>? customerDetails,
  //     }) async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //   const baseUrlPath = '/resource/Sales Order/';
  //   final url = '$baseUrlPath$name';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final request = {
  //       if (setWarehouse != null && setWarehouse.isNotEmpty)
  //         "set_warehouse": setWarehouse,
  //       "delivery_date": deliveryDate,
  //       "items": items,
  //     };
  //
  //     debugPrint('Updating sales order at: ${baseUrl + url}');
  //     final response = await _dio.put(
  //       url,
  //       data: request,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     debugPrint('PUT Response status: ${response.statusCode}');
  //     debugPrint('PUT Response data: ${response.data}');
  //     debugPrint('PUT Request data: $request');
  //
  //     if (response.statusCode == 200) {
  //       // provider.clearItem();
  //       return SalesOrderResponse.fromJson(response.data);
  //     } else {
  //       final data = response.data;
  //       if (data is Map && data.containsKey('exception')) {
  //         final rawMessage = data['exception'] as String;
  //         final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
  //         throw Exception(formattedMessage);
  //       }
  //       throw Exception('Failed to update sales order');
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException (PUT): ${e.message}');
  //     if (e.response != null) {
  //       final data = e.response?.data;
  //       debugPrint('Response data: $data');
  //       if (data is Map && data.containsKey('exception')) {
  //         final rawMessage = data['exception'] as String;
  //         final formattedMessage = rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
  //         throw Exception(formattedMessage);
  //       }
  //     }
  //     throw Exception('Failed to update sales order');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception(e.toString());
  //   }
  // }
  Future<bool> submitSalesOrder(String salesOrderName) async {
    final url = '/resource/Sales Order/$salesOrderName';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.put(
        url,
        data: {
          "data": {
            "docstatus": 1   // ✅ KEY FIELD
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint("📤 SALES ORDER SUBMIT RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        debugPrint("✅ Sales Order submitted successfully");
        return true;
      } else {
        debugPrint("❌ Failed to submit Sales Order: ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error submitting Sales Order: $e");
      return false;
    }
  }
  Future<Map<String, dynamic>?> createSalesOrderFromQuotation({
    required String quotationName,
  }) async {
    final url =
        '/method/frappe.model.mapper.make_mapped_doc'
        '?method=erpnext.selling.doctype.quotation.quotation.make_sales_order'
        '&source_name=$quotationName';

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

      debugPrint("📦 Mapper Response: ${response.data}");

      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception("Failed to map quotation to sales order");
      }
    } catch (e) {
      debugPrint("❌ Mapper API Error: $e");
      return null;
    }
  }
  Future<List<String>> fetchPrintFormats() async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url =
          '/method/frappe.desk.search.search_link'
          '?txt='
          '&doctype=Print Format'
          '&filters={"doc_type":"Sales Order"}';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // 🔥 Extract only "value"
        final List formats = data['message'];

        return formats.map<String>((e) => e['value'].toString()).toList();
      } else {
        throw Exception("Failed to fetch print formats");
      }
    } catch (e) {
      debugPrint("Fetch formats error: $e");
      throw Exception("Error fetching print formats");
    }
  }
  // Future<void> downloadSalesOrderPdf(
  //     String salesOrderName,
  //     String format,
  //     BuildContext context,
  //     ) async {
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     final url =
  //         '/method/frappe.utils.print_format.download_pdf'
  //         '?doctype=Sales Order'
  //         '&name=$salesOrderName'
  //         '&format=$format';
  //
  //     final response = await _dio.get(
  //       url,
  //       options: Options(
  //         responseType: ResponseType.bytes,
  //         headers: {
  //           'Cookie': cookies,
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final bytes = response.data;
  //
  //       final dir = await getApplicationDocumentsDirectory();
  //       final filePath = '${dir.path}/$salesOrderName-$format.pdf';
  //       final file = File(filePath);
  //
  //       await file.writeAsBytes(bytes);
  //
  //       await OpenFilex.open(filePath);
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Opened $format")),
  //       );
  //     } else {
  //       throw Exception("Download failed");
  //     }
  //   } catch (e) {
  //     debugPrint("Error: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Failed to open PDF")),
  //     );
  //   }
  // }
  Future<String?> downloadSalesOrderPdf(
      String salesOrderName,
      String format,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url =
          '/method/frappe.utils.print_format.download_pdf'
          '?doctype=Sales Order'
          '&name=$salesOrderName'
          '&format=$format';

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Cookie': cookies},
        ),
      );

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Headers: ${response.headers}");

      final contentType =
          response.headers['content-type']?.toString() ?? '';

      /// ✅ Validate PDF
      if (!contentType.contains('pdf')) {
        debugPrint("❌ Not a PDF response");

        try {
          final text = String.fromCharCodes(response.data);
          debugPrint("Response: $text");
        } catch (_) {}

        return null;
      }

      final dir = await getApplicationDocumentsDirectory();

      final safeName = salesOrderName.replaceAll('/', '_');
      final safeFormat = format.replaceAll(' ', '_');

      final filePath = '${dir.path}/${safeName}_$safeFormat.pdf';

      final file = File(filePath);

      await file.writeAsBytes(response.data, flush: true);

      debugPrint("✅ Saved at: $filePath");

      return filePath;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
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
  
  // Future<Map<String, dynamic>> fetchCustomerDetails(
  //     BuildContext context,
  //     String customerName,
  //     ) async {
  //   try {
  //     // Get company name from SharedPreferences
  //     final company = await _sharedPrefService.getCompany();
  //
  //     if (company == null || company.isEmpty) {
  //       throw Exception("Company not found in SharedPreferences");
  //     }
  //
  //     final url =
  //         '/method/erpnext.accounts.party.get_party_details?company=${Uri.encodeComponent(company)}&party=$customerName&doctype=Sales Order';
  //
  //     print("Fetching customer details with URL: $url");
  //
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     // Debugging output
  //     debugPrint('Requesting data from URL: ${baseUrl + url}');
  //
  //     // Sending POST request using Dio
  //     final response = await _dio.post(
  //       url,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) {
  //           return status! < 500; // Accepts status less than 500
  //         },
  //       ),
  //     );
  //
  //     debugPrint('Response status: ${response.statusCode}');
  //     debugPrint('Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return response.data;
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       throw Exception('Failed to fetch customer details');
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch customer details due to DioException');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch customer details');
  //   }
  // }
  Future<Map<String, dynamic>> fetchCustomerDetails(
      BuildContext context,
      String customerName,
      ) async {
    try {
      final company = await _sharedPrefService.getCompany();

      if (company == null || company.isEmpty) {
        throw Exception("Company not found in SharedPreferences");
      }

      // ✅ Encode both company and customerName to handle special chars like &
      final encodedCompany = Uri.encodeComponent(company);
      final encodedCustomer = Uri.encodeComponent(customerName);

      final url =
          '/method/erpnext.accounts.party.get_party_details?company=$encodedCompany&party=$encodedCustomer&doctype=Sales Order';

      debugPrint('┌─ [fetchCustomerDetails] REQUEST ───────────────');
      debugPrint('│ raw customerName : $customerName');
      debugPrint('│ encoded customer : $encodedCustomer');
      debugPrint('│ raw company      : $company');
      debugPrint('│ encoded company  : $encodedCompany');
      debugPrint('│ full URL         : ${baseUrl + url}');
      debugPrint('└────────────────────────────────────────────────');

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
      );

      debugPrint('┌─ [fetchCustomerDetails] RESPONSE ──────────────');
      debugPrint('│ status : ${response.statusCode}');
      debugPrint('│ data   : ${response.data}');
      debugPrint('└────────────────────────────────────────────────');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('[fetchCustomerDetails] ❌ status ${response.statusCode}');
        apiErrorHandler.handleHttpError(context, response);
        throw Exception('Failed to fetch customer details');
      }
    } on DioException catch (e) {
      debugPrint('┌─ [fetchCustomerDetails] DIO ERROR ─────────────');
      debugPrint('│ type    : ${e.type}');
      debugPrint('│ status  : ${e.response?.statusCode}');
      debugPrint('│ message : ${e.message}');
      debugPrint('│ response: ${e.response?.data}');
      debugPrint('└────────────────────────────────────────────────');
      throw Exception('Failed to fetch customer details due to DioException');
    } catch (e, stack) {
      debugPrint('┌─ [fetchCustomerDetails] ERROR ─────────────────');
      debugPrint('│ error : $e');
      debugPrint('│ stack : $stack');
      debugPrint('└────────────────────────────────────────────────');
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

  Future<GetSalesOrderResponse?> getSalesOrder(
      context,
      int limitStart,
      int pageLength,
      ) async {

    final salesPerson = await resolveLoggedInSalesPerson();
    if (salesPerson == null) {
      throw Exception("Unable to resolve logged-in Sales Person");
    }

    final url =
        '/resource/Sales Order'
        '?fields=["name","customer_name","customer","delivery_date","creation","grand_total","rounded_total","status","transaction_date"]'
        '&filters=['
        '["Sales Team","sales_person","=","$salesPerson"],'
        '["Sales Order","status","!=","Cancelled"]'
        ']'
        '&limit_start=$limitStart'
        '&limit_page_length=$pageLength'
        '&order_by=transaction_date desc';


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
        return GetSalesOrderResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint("getSalesOrder Error: $e");
      throw Exception("Failed to fetch Sales Orders");
    }
    return null;
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

  Future<GetSalesOrderResponse?> getSalesOrdersWithFilters(
      context, {
        String? startDate,
        String? endDate,
        String? salesId,
        String? customerId,
        String? customerName,
      }) async {

    final salesPerson = await resolveLoggedInSalesPerson();

    List<String> filters = [
      '["Sales Team","sales_person","=","$salesPerson"]',
      '["Sales Order","status","!=","Cancelled"]',
    ];

    // ✅ Apply date filters ONLY if present
    if (startDate != null && startDate.isNotEmpty &&
        endDate != null && endDate.isNotEmpty) {
      filters.add('["delivery_date",">=","$startDate"]');
      filters.add('["delivery_date","<=","$endDate"]');
    }

    if (salesId != null && salesId.isNotEmpty) {
      filters.add('["Sales Order","name","Like","%$salesId%"]');
    }

    if (customerId != null && customerId.isNotEmpty) {
      filters.add('["Sales Order","customer","Like","%$customerId%"]');
    }

    if (customerName != null && customerName.isNotEmpty) {
      filters.add('["Sales Order","customer_name","Like","%$customerName%"]');
    }

    final url =
        '/resource/Sales Order'
        '?fields=["name","customer_name","customer","delivery_date","creation","grand_total","rounded_total","status","transaction_date"]'
        '&filters=[${filters.join(",")}]'
        '&order_by=transaction_date desc';

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
        return GetSalesOrderResponse.fromJson(response.data);
      } else {
        apiErrorHandler.handleHttpError(context, response);
      }
    } catch (e) {
      debugPrint("SalesOrder Filter Error: $e");
      throw Exception("Failed to fetch Sales Orders");
    }

    return null;
  }


//S ordr
  // Sales Quotation
  // Future<GetQuotationResponse?> getQuotationList(
  //     BuildContext context,
  //     int limitStart,
  //     int pageLength,
  //     ) async {
  //   final url =
  //       '/resource/Quotation'
  //       '?fields=["name","title","transaction_date","valid_till","status"]'
  //       '&limit_start=$limitStart'
  //       '&limit_page_length=$pageLength'
  //       '&order_by=creation desc';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     debugPrint('Requesting Quotation data from URL: ${baseUrl + url}');
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
  //
  //     debugPrint('Quotation Response status: ${response.statusCode}');
  //     debugPrint('Quotation Response data: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return GetQuotationResponse.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       return null;
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     if (e.response != null) {
  //       debugPrint('Response data: ${e.response?.data}');
  //     }
  //     throw Exception('Failed to fetch Quotation list');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch Quotation list');
  //   }
  // }
  Future<GetQuotationResponse?> getQuotationList(
      BuildContext context,
      int limitStart,
      int pageLength,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      Future<Response> fetchQuotation(bool includeTitle) {
        final fields = includeTitle
            ? '["name","title","transaction_date","valid_till","status"]'
            : '["name","transaction_date","valid_till","status"]';

        final url =
            '/resource/Quotation'
            '?fields=$fields'
            '&limit_start=$limitStart'
            '&limit_page_length=$pageLength'
            '&order_by=creation desc';

        return _dio.get(
          url,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookies,
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }

      Response response = await fetchQuotation(true);

      /// Retry without title field
      if (response.data.toString().contains(
          'Field not permitted in query: title')) {
        debugPrint('Removing title field and retrying...');
        response = await fetchQuotation(false);
      }

      if (response.statusCode == 200) {
        return GetQuotationResponse.fromJson(response.data);
      }

      apiErrorHandler.handleHttpError(context, response);
      return null;
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch quotation list');
    }
  }

  Future<CreateQuotationResponse?> createQuotation(
      String partyName,
      String transactionDate,
      String validTill,
      List<Map<String, dynamic>> items,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
        List<Map<String, dynamic>>? itemDetails,
      }) async {
    const url = '/resource/Quotation';

    try {
      final cookies = await _sharedPrefService.getCookies();

      // ✅ Dynamically fetch selling price list for the given customer
      final sellingPriceList = await _getSellingPriceList(partyName);

      // ✅ Build the request dynamically
      final request = {
        "data": {
          "docstatus": 0,
          "quotation_to": "Customer",
          "party_name": partyName,
          "transaction_date": transactionDate,
          "valid_till": validTill,
          "order_type": "Sales",
          "selling_price_list": sellingPriceList,

          // ✅ Prefill from customerDetails
          if (customerDetails != null) ...{
            "customer_address": customerDetails["customer_address"],
            "shipping_address_name": customerDetails["shipping_address_name"],
            "currency": customerDetails["currency"] ?? "INR",
            "taxes_and_charges": customerDetails["taxes_and_charges"],
            "taxes": customerDetails["taxes"], // if ERPNext provides this
          },

          // ✅ Items with item-level info
          "items": items.map((i) {
            final uiDiscount = (i["discount_percentage"] ?? 0).toDouble();

            return {
              "item_code": i["item_code"],
              "qty": i["qty"],
              "uom": i["uom"] ?? "Nos",

              /// 🔑 SEND BOTH
              "price_list_rate": i["price_list_rate"],
              "rate": i["rate"],

              if (uiDiscount > 0)
                "discount_percentage": uiDiscount,
            };
          }).toList(),

        }
      };

      debugPrint('🧾 Requesting data from URL: ${baseUrl + url}');
      debugPrint('📦 Request Body: $request');

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

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('✅ Response data: ${response.data}');

      if (response.statusCode == 200) {
        return CreateQuotationResponse.fromJson(response.data);
      } else {
        // 🧩 Handle ERPNext errors
        final data = response.data;
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage =
          rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
        throw Exception('Failed to create quotation');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.message}');
      if (e.response != null) {
        final data = e.response?.data;
        debugPrint('Response data: $data');
        if (data is Map && data.containsKey('exception')) {
          final rawMessage = data['exception'] as String;
          final formattedMessage =
          rawMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          throw Exception(formattedMessage);
        }
      }
      throw Exception('Failed to create quotation');
    } catch (e) {
      debugPrint('❌ Exception: $e');
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getCustomerDetails(String customerName, BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final company = await _sharedPrefService.getCompany();

      // Fetch selling price list first
      final priceList = await _getSellingPriceList(customerName);

      final encodedCustomer = Uri.encodeComponent(customerName);
      final encodedCompany = Uri.encodeComponent(company!);
      final encodedPriceList = Uri.encodeComponent(priceList);

      final url =
          '/method/erpnext.accounts.party.get_party_details'
          '?party=$encodedCustomer'
          '&party_type=Customer'
          '&price_list=$encodedPriceList'
          '&company=$encodedCompany'
          '&doctype=Quotation';

      debugPrint('Fetching customer details: ${baseUrl + url}');

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
        final data = response.data["message"];
        debugPrint('Customer Details Response: $data');
        return data; // Contains full customer info (addresses, taxes, etc.)
      } else {
        apiErrorHandler.handleHttpError(context, response);
        throw Exception('Failed to fetch customer details');
      }
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getItemDetails({
    required BuildContext context,
    required String itemCode,
    required String currency,
    required double quantity,
    required String company,
    required String priceList,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final url = '/method/erpnext.stock.get_item_details.get_item_details';
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      /// -----------------------------
      /// FIRST TRY -> USING args
      /// -----------------------------
      final argsBody = {
        "args": {
          "item_code": itemCode,
          "company": company,
          "selling_price_list": priceList,
          "currency": currency,
          "transaction_date": today,
          "qty": quantity,
          "doctype": "Quotation",
        }
      };

      debugPrint('Fetching item details using args: ${baseUrl + url}');
      debugPrint('Args Request Body: $argsBody');

      Response response;

      try {
        response = await _dio.post(
          url,
          data: argsBody,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookies,
            },
            /// Prevent Dio from throwing automatically on 500
            validateStatus: (status) => status != null,
          ),
        );

        /// SUCCESS WITH args
        if (response.statusCode == 200 && response.data != null) {
          debugPrint('Item Details Response (args): ${response.data}');
          return response.data;
        }

        /// IF 500 -> FALLBACK TO ctx
        if (response.statusCode != 500) {
          apiErrorHandler.handleHttpError(context, response);
          return null;
        }

        debugPrint(
            'args method failed with 500. Retrying using ctx...');
      } catch (e) {
        debugPrint('args method exception: $e');
        debugPrint('Retrying using ctx...');
      }

      /// -----------------------------
      /// SECOND TRY -> USING ctx
      /// -----------------------------
      final ctxBody = {
        "ctx": {
          "item_code": itemCode,
          "company": company,
          "price_list": priceList,
          "currency": currency,
          "transaction_date": today,
          "qty": quantity,
          "doctype": "Quotation",
        }
      };

      debugPrint('Fetching item details using ctx: ${baseUrl + url}');
      debugPrint('Ctx Request Body: $ctxBody');

      final ctxResponse = await _dio.post(
        url,
        data: ctxBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status != null,
        ),
      );

      if (ctxResponse.statusCode == 200 && ctxResponse.data != null) {
        debugPrint('Item Details Response (ctx): ${ctxResponse.data}');
        return ctxResponse.data;
      } else {
        apiErrorHandler.handleHttpError(context, ctxResponse);
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching item details: $e');
      return null;
    }
  }

  Future<double?> getLastPurchaseRate({
    required String itemCode,
  }) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      final encodedItemCode = Uri.encodeComponent(itemCode);

      final response = await _dio.get(
        '/resource/Item/$encodedItemCode',
        queryParameters: {
          "fields": jsonEncode(["last_purchase_rate"]),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return (data['last_purchase_rate'] as num?)?.toDouble() ?? 0.0;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching last purchase rate: $e');
      return null;
    }
  }
  Future<Map<String, dynamic>?> getQuotationDetails(String quotationName, BuildContext context) async {
    try {
      final cookies = await _sharedPrefService.getCookies();
      final url = '/resource/Quotation/$quotationName';

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
        final data = response.data["data"];
        debugPrint('Fetched Quotation Details: $data');
        return data;
      } else {
        apiErrorHandler.handleHttpError(context, response);
        throw Exception('Failed to fetch quotation details');
      }
    } catch (e) {
      debugPrint('Error fetching quotation details: $e');
      return null;
    }
  }

  Future<bool> updateQuotation(
      String quotationName,
      String partyName,
      String transactionDate,
      String validTill,
      List<Map<String, dynamic>> items,
      BuildContext context, {
        Map<String, dynamic>? customerDetails,
        List<Map<String, dynamic>>? itemDetails,
      }) async {
    final url = '/resource/Quotation/$quotationName';
    try {
      final cookies = await _sharedPrefService.getCookies();

      final request = {
        "data": {
          "party_name": partyName,
          "transaction_date": transactionDate,
          "valid_till": validTill,
          "items": items.map((i) {
            final discount = (i["discount_percentage"] ?? 0).toDouble();

            return {
              "name": i["name"],            // REQUIRED
              "item_code": i["item_code"],  // REQUIRED
              "qty": i["qty"],

              /// 🔑 SEND BOTH
              "price_list_rate": i["price_list_rate"],
              "rate": i["rate"],

              if (discount > 0)
                "discount_percentage": discount,
            };
          }).toList(),


        }
      };

      debugPrint('🛠 Updating Quotation: $quotationName');
      debugPrint('📦 Request Body: $request');

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

      debugPrint('✅ Update Response: ${response.statusCode} ${response.data}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating quotation: $e');
      return false;
    }
  }
  // Future<GetQuotationResponse?> getQuotationDateFilter(
  //     BuildContext context,
  //     String startDate,
  //     String endDate,
  //     ) async {
  //   final url =
  //       '/resource/Quotation?fields=["name","title","transaction_date","valid_till","status"]'
  //       '&filters=[["transaction_date", ">=", "$startDate"], ["transaction_date", "<=", "$endDate"]]'
  //       '&order_by=transaction_date desc';
  //
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
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
  //     debugPrint('Quotation Date Filter Response: ${response.data}');
  //     if (response.statusCode == 200) {
  //       return GetQuotationResponse.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       return null;
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     throw Exception('Failed to fetch quotation data');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch quotation data');
  //   }
  // }
  Future<GetQuotationResponse?> getQuotationDateFilter(
      BuildContext context,
      String startDate,
      String endDate,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      Future<Response> fetchQuotation(bool includeTitle) {
        final fields = includeTitle
            ? '["name","title","transaction_date","valid_till","status"]'
            : '["name","transaction_date","valid_till","status"]';

        final url =
            '/resource/Quotation'
            '?fields=$fields'
            '&filters=[["transaction_date",">=","$startDate"],'
            '["transaction_date","<=","$endDate"]]'
            '&order_by=transaction_date desc';

        return _dio.get(
          url,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookies,
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }

      Response response = await fetchQuotation(true);

      if (response.data.toString().contains(
          'Field not permitted in query: title')) {
        debugPrint('Retrying without title...');
        response = await fetchQuotation(false);
      }

      if (response.statusCode == 200) {
        return GetQuotationResponse.fromJson(response.data);
      }

      apiErrorHandler.handleHttpError(context, response);
      return null;
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('Failed to fetch quotation data');
    }
  }
  // Future<GetQuotationResponse?> getSearchQuotation(
  //     BuildContext context,
  //     String quotationName,
  //     String partyName,
  //     ) async {
  //   try {
  //     final cookies = await _sharedPrefService.getCookies();
  //
  //     // 🧠 Build filters list
  //     List<List<String>> filters = [];
  //     if (quotationName.isNotEmpty) {
  //       filters.add(["name", "like", "%$quotationName%"]);
  //     }
  //     if (partyName.isNotEmpty) {
  //       filters.add(["party_name", "like", "%$partyName%"]);
  //     }
  //
  //     if (filters.isEmpty) {
  //       throw Exception("Please enter at least one search field.");
  //     }
  //
  //     // 🧩 Build query parameters safely
  //     final Map<String, dynamic> queryParams = {
  //       "fields": '["name","title","transaction_date","valid_till","status","party_name"]',
  //       "filters": jsonEncode(filters),
  //       "order_by": "transaction_date desc"
  //     };
  //
  //     final response = await _dio.get(
  //       '/resource/Quotation',
  //       queryParameters: queryParams,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Cookie': cookies,
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     debugPrint('Quotation Search URL: /resource/Quotation');
  //     debugPrint('Quotation Search Filters: ${jsonEncode(filters)}');
  //     debugPrint('Quotation Search Response: ${response.data}');
  //
  //     if (response.statusCode == 200) {
  //       return GetQuotationResponse.fromJson(response.data);
  //     } else {
  //       apiErrorHandler.handleHttpError(context, response);
  //       return null;
  //     }
  //   } on DioException catch (e) {
  //     debugPrint('DioException: ${e.message}');
  //     throw Exception('Failed to fetch quotation search results');
  //   } catch (e) {
  //     debugPrint('Exception: $e');
  //     throw Exception('Failed to fetch quotation search results');
  //   }
  // }
  Future<GetQuotationResponse?> getSearchQuotation(
      BuildContext context,
      String quotationName,
      String partyName,
      ) async {
    try {
      final cookies = await _sharedPrefService.getCookies();

      List<List<String>> filters = [];

      if (quotationName.isNotEmpty) {
        filters.add(["name", "like", "%$quotationName%"]);
      }

      if (partyName.isNotEmpty) {
        filters.add(["party_name", "like", "%$partyName%"]);
      }

      if (filters.isEmpty) {
        throw Exception(
            "Please enter at least one search field.");
      }

      Future<Response> fetchQuotation(bool includeTitle) {
        final fields = includeTitle
            ? '["name","title","transaction_date","valid_till","status","party_name"]'
            : '["name","transaction_date","valid_till","status","party_name"]';

        return _dio.get(
          '/resource/Quotation',
          queryParameters: {
            "fields": fields,
            "filters": jsonEncode(filters),
            "order_by": "transaction_date desc"
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Cookie': cookies,
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }

      Response response = await fetchQuotation(true);

      if (response.data.toString().contains(
          'Field not permitted in query: title')) {
        debugPrint('Retry search without title...');
        response = await fetchQuotation(false);
      }

      if (response.statusCode == 200) {
        return GetQuotationResponse.fromJson(response.data);
      }

      apiErrorHandler.handleHttpError(context, response);
      return null;
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception(
          'Failed to fetch quotation search results');
    }
  }
  Future<bool> submitQuotationToERP(String quotationName) async {
    final url = '/resource/Quotation/$quotationName';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.put(
        url,
        data: {
          "data": {"docstatus": 1}
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Quotation submitted successfully");
        return true;
      } else {
        debugPrint("❌ Failed to submit quotation: ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error submitting quotation: $e");
      return false;
    }
  }
  Future<bool> checkServerConnection() async {
    const url = '/method/ping';
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

      if (response.statusCode == 200 && response.data['message'] == 'pong') {
        debugPrint("✅ Server connection successful");
        return true;
      } else {
        debugPrint("❌ Server connection failed: ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error checking server connection: $e");
      return false;
    }
  }

  Future<void> downloadQuotationPdf(
      String quotationName,
      BuildContext context, {
        required String formatName,
      }) async {
    final url =
        '/method/frappe.utils.print_format.download_pdf?doctype=Quotation&name=$quotationName&format=$formatName';
    final cookies = await _sharedPrefService.getCookies();

    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes, // For binary data
          headers: {
            'Cookie': cookies,
          },
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/Quotation_${quotationName}_$formatName.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF downloaded successfully! Opening file...')),
        );

        await OpenFilex.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error downloading PDF')),
      );
    }
  }

  Future<List<String>> getQuotationPrintFormats(BuildContext context) async {
    const url = '/resource/Print Format?filters=[["doc_type","=","Quotation"],["disabled","=","0"]]';

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

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        // Extract names of formats
        final formats = data.map((item) => item['name'].toString()).toList();
        return formats;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load print formats')),
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching print formats: $e');
      return [];
    }
  }

  //Sales Quotation


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
