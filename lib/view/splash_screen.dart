import 'package:flutter/material.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/home/home.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import 'package:sales_ordering_app/view/login.dart';

// ignore: use_key_in_widget_constructors
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SharedPrefService _sharedPrefService = SharedPrefService();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    final loginDetails = await _sharedPrefService.getLoginDetails();
    if (loginDetails['email'] != null &&
        loginDetails['password'] != null &&
        loginDetails['domain'] != null) {
      provider.initialize();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white,
              Color.fromARGB(255, 37, 241, 231),
            ],
          ),
        ),
        child: Center(
          child: Image.asset("assets/images/logo.png"),
        ),
      ),
    );
  }
}
