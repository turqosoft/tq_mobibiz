// import 'package:flutter/material.dart';
// import 'package:sales_ordering_app/utils/common/common_widgets.dart';

// class ProfileView extends StatefulWidget {
//   const ProfileView({super.key});

//   @override
//   State<ProfileView> createState() => _ProfileViewState();
// }

// class _ProfileViewState extends  State<ProfileView> {
//   @override
//   Widget build(BuildContext context) {
//     return  Scaffold(
//        appBar: CommonAppBar(
//         title: 'Profile',
//         onBackTap: () {
//           Navigator.pop(context);
//         },
//       ),
//       body: Column(children: [

//       ],),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String? emailId;

  @override
  void initState() {
    super.initState();
    _userDetails();
  }

  Future<void> _userDetails() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    emailId = await _sharedPrefService.getEmailId();
    print("Email:::$emailId");
    try {
      Future.microtask(() async {
        await provider.userDetails(emailId!,context);
      });
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Profile',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          } else if (provider.userDetailsModel == null ||
              provider.userDetailsModel!.data == null ||
              provider.userDetailsModel!.data!.isEmpty) {
            return const Center(child: Text('No items available'));
          } else {
            final user = provider.userDetailsModel!.data!.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person),
                      ),
                      SizedBox(height: 10),
                      Text(
                        user.fullName ?? 'Full Name',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      // SizedBox(height: 5),
                      // Text(
                      //   'Role',
                      //   style: TextStyle(fontSize: 18, color: Colors.grey),
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.email),
                    title: Text(user.email ?? 'Email'),
                    onTap: () {
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}