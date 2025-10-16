// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/Home/home.dart';
import 'package:provider/provider.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextStyle style = const TextStyle(fontSize: 20.0);
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  bool _isPasswordVisible = false;//pwd visibility

  @override
  void initState() {
    super.initState();
    _loadDomain();
  }

  Future<void> _loadDomain() async {
    Map<String, String?> domainData = await _sharedPrefService.getDomainName();
      String? emailId = await _sharedPrefService.getEmailId();
    if (domainData['domain'] != null) {
      _domainController.text = domainData['domain']!;
    }
    if (emailId != null) {
      _userNameController.text = emailId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height / 2.6,
              child: Image.asset(
                "assets/images/logo.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 15.0),
            CommonTextField(
              controller: _userNameController,
              hintText: "Email",
              style: style,
              obscureText: false,
            ),
            const SizedBox(height: 25.0),
            CommonTextField(
              controller: _passwordController,
              hintText: "Password",
              style: style,
              //pwd passwd  start....
              obscureText: !_isPasswordVisible,

              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Color(0xFF40E0D0),

                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              //.....pwd passwd  start end

            ),
            const SizedBox(height: 25.0),
            CommonTextField(
              controller: _domainController,
              hintText: "Domain",
              style: style,
              obscureText: false,
            ),
            const SizedBox(height: 35.0),
            // CommonButton(
            //   onTap: () {
            //     print("Test 111");
            //             Navigator.of(context).pushReplacement(
            //     MaterialPageRoute(builder: (context) => HomeScreen()),
            //     );
            //   },
            //   buttonText: "Login",
            // ),
            Consumer<SalesOrderProvider>(
              builder: (context, provider, child) {
                return provider.isLoading
                    ? const CircularProgressIndicator()
                    : CommonButton(
                        onTap: () async {
                          // await _sharedPrefService.saveLoginDetails(
                          //     "", "", _domainController.text);
                          // Api integration
                          String trimmedDomain = _domainController.text.trim();
                          _domainController.text = trimmedDomain;

                          provider.setDomain(trimmedDomain);

                          await provider.login(
                            _userNameController.text.trim(),
                            _passwordController.text.trim(),
                            trimmedDomain,
                          );

                          //     provider.setDomain(_domainController.text);
                          //  //   Timer(const Duration(seconds: 3), () async {
                          //       await provider.login(
                          //         _userNameController.text,
                          //         _passwordController.text,
                          //         _domainController.text,
                          //       );
                          //  });

                          if (provider.loginModel != null) {
                            await _sharedPrefService
                                .saveDomainName(trimmedDomain);

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login failed')),
                            );
                          }
                        },
                        buttonText: "Login",
                      );
              },
            ),
            const SizedBox(height: 15.0),
          ],
        ),
      ),
    );
  }
}
