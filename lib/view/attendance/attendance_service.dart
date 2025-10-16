// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:sales_ordering_app/model/attendance_model.dart';
// import 'package:sales_ordering_app/model/checkin_checkout_model.dart';
// import 'package:sales_ordering_app/model/login_model.dart';
// import 'package:sales_ordering_app/utils/sharedpreference.dart';

// class ApiService {
//   final String baseUrl;
//   final Dio _dio;
//   final SharedPrefService _sharedPrefService = SharedPrefService();

//   ApiService({required this.baseUrl})
//       : _dio = Dio(BaseOptions(baseUrl: baseUrl));

//   // Login
//   Future<LoginModel?> login(
//       String username, String password, String domain) async {
//     try {
//       debugPrint('Base URL: $baseUrl');
//       debugPrint('Making login request with:');
//       debugPrint('Username: $username');
//       debugPrint('Password: $password');
//       debugPrint('Domain: $domain');

//       final response = await _dio.post(
//         '/method/login',
//         data: {
//           'usr': username,
//           'pwd': password,
//         },
//         options: Options(
//           headers: {'Content-Type': 'application/json'},
//           validateStatus: (status) {
//             return status! < 500;
//           },
//         ),
//       );

//       debugPrint('Response status: ${response.statusCode}');
//       debugPrint('Response data: ${response.data}');

//       if (response.statusCode == 200) {
//         // Save login details and cookies
//         await _sharedPrefService.saveLoginDetails(username, password, domain);
//         await _sharedPrefService
//             .saveCookies(response.headers.map['set-cookie']?.join('; ') ?? '');

//         return LoginModel.fromJson(response.data);
//       } else if (response.statusCode == 401) {
//         debugPrint('Unauthorized: Incorrect username, password, or domain.');
//         throw Exception(
//             'Unauthorized: Incorrect username, password, or domain.');
//       } else {
//         throw Exception('Failed to login');
//       }
//     } on DioException catch (e) {
//       debugPrint('DioException: ${e.message}');
//       if (e.response != null) {
//         debugPrint('Response data: ${e.response?.data}');
//       }
//       throw Exception('Failed to login');
//     } catch (e) {
//       debugPrint('Exception: $e');
//       throw Exception('Failed to login');
//     }
//   }

//   // Attendance
//   Future<AttendanceDetails?> attendance() async {
//     const url =
//         '/resource/Attendance?fields=["employee_name","status","attendance_date","employee"]';

//     try {
//       // Retrieve cookies from shared preferences
//       final cookies = await _sharedPrefService.getCookies();

//       debugPrint('Requesting attendance data from URL: ${baseUrl + url}');
//       final response = await _dio.get(
//         url,
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Cookie': cookies,
//           },
//           validateStatus: (status) {
//             return status! < 500;
//           },
//         ),
//       );

//       debugPrint('Response attendance status: ${response.statusCode}');
//       debugPrint('Response data: ${response.data}');

//       if (response.statusCode == 200) {
//         return AttendanceDetails.fromJson(response.data);
//       } else if (response.statusCode == 401) {
//         debugPrint('Unauthorized: Incorrect username, password, or domain.');
//         throw Exception(
//             'Unauthorized: Incorrect username, password, or domain.');
//       } else {
//         throw Exception('Failed to fetch attendance data');
//       }
//     } on DioException catch (e) {
//       debugPrint('DioException: ${e.message}');
//       if (e.response != null) {
//         debugPrint('Response data: ${e.response?.data}');
//       }
//       throw Exception('Failed to fetch attendance data');
//     } catch (e) {
//       debugPrint('Exception: $e');
//       throw Exception('Failed to fetch attendance data');
//     }
//   }

//   //checkin / checkout
//   Future<CheckInCheckOut?> checkinOrCheckout(String logType) async {
//     const url = '/resource/Employee Checkin';

//     try {
//       // Retrieve cookies from shared preferences
//       final cookies = await _sharedPrefService.getCookies();

//       debugPrint('Requesting attendance data from URL: ${baseUrl + url}');
//       final response = await _dio.post(
//         url,
//         data: {
//           "employee": "HR-EMP-00002",
//           "log_type":  logType,
//           "time": "2024-02-06 09:00:00",
//           "longitude": "longitude",
//           "latitude": "10.0958208"
//         },
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Cookie': cookies,
//           },
//           validateStatus: (status) {
//             return status! < 500;
//           },
//         ),
//       );

//       debugPrint('Response attendance status: ${response.statusCode}');
//       debugPrint('Response data: ${response.data}');

//       if (response.statusCode == 200) {
//         return CheckInCheckOut.fromJson(response.data);
//       } else if (response.statusCode == 401) {
//         debugPrint('Unauthorized: Incorrect username, password, or domain.');
//         throw Exception(
//             'Unauthorized: Incorrect username, password, or domain.');
//       } else {
//         throw Exception('Failed to fetch attendance data');
//       }
//     } on DioException catch (e) {
//       debugPrint('DioException: ${e.message}');
//       if (e.response != null) {
//         debugPrint('Response data: ${e.response?.data}');
//       }
//       throw Exception('Failed to fetch attendance data');
//     } catch (e) {
//       debugPrint('Exception: $e');
//       throw Exception('Failed to fetch attendance data');
//     }
//   }
// }
