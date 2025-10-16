// ignore_for_file: unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextStyle style = const TextStyle(fontSize: 20.0);
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phonoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _phone;
  String? _address;

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      // Save the profile information
      // You can call your API or update your provider here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved')),
      );
    }
  }

  void _changeProfilePicture() {
    // Implement functionality to change profile picture
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Edit Profile',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Icon(
                    Icons.person,
                    size: 40,
                  ),
                ),
              ),
              SizedBox(height: 20),
              CommonTextField(
                controller: _nameController,
                hintText: "Name :",
                style: style,
                obscureText: false,
              ),
              SizedBox(height: 20),
              CommonTextField(
                controller: _userNameController,
                hintText: "Email",
                style: style,
                obscureText: false,
              ),
              // SizedBox(height: 20),
              // CommonTextField(
              //   controller: _phonoController,
              //   hintText: "Phone Number",
              //   style: style,
              //   obscureText: true,
              // ),
              SizedBox(height: MediaQuery.of(context).size.height / 13),
              CommonButton(
                onTap: () async {},
                buttonText: "Save",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
