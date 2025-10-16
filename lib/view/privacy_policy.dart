import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Privacy Policy'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   'Privacy Policy',
              //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              // ),
              // SizedBox(height: 16),
              Text(
                'Turqosoft Pvt Ltd',
                style: TextStyle(fontSize: 16),
              ),
             
            ],
          ),
        ),
      ),
    );
  }
}
