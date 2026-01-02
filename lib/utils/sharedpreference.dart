import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String _keyEmail = 'email';
  static const String _keyPassword = 'password';
  static const String _keyDomain = 'domain';
  static const String _keyDomainName = 'domainName';
  static const String _keyCompany = 'company';
  static const String _keyPrinterAddress = 'printer_address';
  static const String _keyPrinterName = "printer_name";




  Future<void> saveLoginDetails(
      String email, String password, String domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyDomain, domain);
  }
  Future<void> saveCompany(String company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompany, company);
  }
  Future<String?> getCompany() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCompany);
  }
  Future<void> saveDomainName(String domainName) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyDomainName, domainName);
  }

  Future<Map<String, String?>> getLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);
    final domain = prefs.getString(_keyDomain);
    return {
      'email': email,
      'password': password,
      'domain': domain,
    };
  }
  Future<void> saveAutoSubmitPickList(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("auto_submit_picklist", value);
  }

  Future<bool> getAutoSubmitPickList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("auto_submit_picklist") ?? false;
  }

  Future<Map<String, String?>> getDomainName() async {
    final prefs = await SharedPreferences.getInstance();

    final domainName = prefs.getString(_keyDomainName);
    return {
      'domain': domainName,
    };
  }

  Future<void> clearLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
   // await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove('cookies');
    //await prefs.remove(_keyDomain);
  }

  Future<void> printLoginDetails() async {
    final details = await getLoginDetails();
    debugPrint('Stored Login Details:');
    debugPrint('Email: ${details['email']}');
    debugPrint('Password: ${details['password']}');
    debugPrint('Domain: ${details['domain']}');
  }

  Future<void> saveCookies(String cookies) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookies', cookies);
  }

  Future<String> getCookies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookies') ?? '';
  }

  Future<void> saveFullName(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
  }

  Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('full_name');
  }

  Future<void> saveEmailId(String emailId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emailId', emailId);
  }

  Future<String?> getEmailId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emailId');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveEmployeeId(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employee_Id', employeeId);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employee_Id');
  }

  // // 🖨️ --- Printer Helpers ---
  // Future<void> savePrinterAddress(String address) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_keyPrinterAddress, address);
  // }
  //
  // Future<String?> getPrinterAddress() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString(_keyPrinterAddress);
  // }
  //
  // Future<void> clearPrinterAddress() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(_keyPrinterAddress);
  // }

  // Save both printer name & address
  Future<void> savePrinter(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrinterName, name);
    await prefs.setString(_keyPrinterAddress, address);
  }

  // Get printer name
  Future<String?> getPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterName);
  }

  // Get printer address
  Future<String?> getPrinterAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrinterAddress);
  }

  // Clear both name & address
  Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrinterName);
    await prefs.remove(_keyPrinterAddress);
  }
}
