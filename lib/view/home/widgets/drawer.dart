import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/home/profile_view.dart';
import 'package:sales_ordering_app/view/home/widgets/settings_screen.dart';
import 'package:sales_ordering_app/view/login.dart';
import 'package:sales_ordering_app/view/privacy_policy.dart';
import 'package:provider/provider.dart';

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String _fullName = 'Name';
   String _emailId = 'emailId';
  String _appVersion = '';
  String _domain = '';


  @override
  void initState() {
    super.initState();
    // _loadFullName();
    _loadAppVersion();
    _loadUserInfo();

  }
  Future<void> _loadUserInfo() async {
    final fullName = await _sharedPrefService.getFullName();
    final emailId = await _sharedPrefService.getEmailId();
    final domainData = await _sharedPrefService.getDomainName();

    setState(() {
      _fullName = fullName ?? 'Name';
      _emailId = emailId ?? 'email';
      _domain = domainData['domain'] ?? '';
    });
  }

  // Future<void> _loadFullName() async {
  //   String? fullName = await _sharedPrefService.getFullName();
  //    String? emailId = await _sharedPrefService.getEmailId();
  //   setState(() {
  //     _fullName = fullName ?? 'Name';
  //       _emailId = emailId ?? 'emailId';
  //   });
  // }

  Future<void> _logout(BuildContext context) async {
    await _sharedPrefService.clearLoginDetails();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Drawer(
  //     child: ListView(
  //       padding: EdgeInsets.zero,
  //       children: <Widget>[
  //         DrawerHeader(
  //           decoration: const BoxDecoration(
  //             color: AppColors.primaryColor,
  //           ),
  //           child: SingleChildScrollView(
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       const CircleAvatar(
  //                         radius: 40,
  //                         child: Icon(Icons.person),
  //                       ),
  //                       const SizedBox(height: 10),
  //                       Text(
  //                         _fullName,
  //                         style: const TextStyle(color: Colors.white, fontSize: 20),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         _emailId,
  //                         style: const TextStyle(color: Colors.white70, fontSize: 14),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   'v$_appVersion',
  //                   style: const TextStyle(
  //                     color: Colors.white60,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //         // ListTile(
  //         //   leading: const Icon(Icons.person),
  //         //   title: const Text('Edit Profile'),
  //         //   onTap: () {
  //         //    Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen()));
  //         //   },
  //         // ),
  //         ListTile(
  //           leading: const Icon(Icons.person),
  //           title: const Text('Profile'),
  //           onTap: () {
  //          //   Navigator.pop(context);
  //         Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfilePage()));
  //           },
  //         ),
  //         ListTile(
  //           leading: const Icon(Icons.privacy_tip),
  //           title: const Text('Privacy and policies'),
  //           onTap: () {
  //          //   Navigator.pop(context);
  //          _showPrivacyPolicy(context);
  //
  //           },
  //         ),
  //                   ListTile(
  //           leading: const Icon(Icons.settings),
  //           title: const Text("Settings"),
  //           onTap: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (context) => const SettingsScreen()),
  //             );
  //           },
  //         ),
  //         Consumer<SalesOrderProvider>(
  //             builder: (context, provider, child) {
  //             return ListTile(
  //               leading: const Icon(Icons.logout),
  //               title: const Text('Logout'),
  //               onTap: () {
  //                // provider.logout(_emailId,context);
  //                 _logout(context);
  //                 Navigator.pop(context);
  //               },
  //             );
  //             }),
  //       ],
  //     ),
  //   );
  // }
   void _showPrivacyPolicy(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
             TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close,color: Colors.black,),
          ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: PrivacyPolicyPage(),
        ),

      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // HEADER
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'v$_appVersion',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),


          // MENU ITEMS (SCROLLABLE)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy and policies'),
                  onTap: () {
                    _showPrivacyPolicy(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                Consumer<SalesOrderProvider>(
                  builder: (context, provider, child) {
                    return ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () {
                        _logout(context);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // DOMAIN FOOTER (FIXED AT BOTTOM)
          if (_domain.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  'Domain: $_domain.turqosoft.cloud',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

}
// class DrawerWidget extends StatefulWidget {
//   @override
//   _DrawerWidgetState createState() => _DrawerWidgetState();
// }
//
// class _DrawerWidgetState extends State<DrawerWidget> {
//   final SharedPrefService _sharedPrefService = SharedPrefService();
//   String _fullName = 'Name';
//   String _emailId = 'emailId';
//   String _appVersion = '';
//   String? _printerName; // show current printer if saved
//
//   @override
//   void initState() {
//     super.initState();
//     _loadFullName();
//     _loadAppVersion();
//     _loadPrinter();
//   }
//
//   Future<void> _loadFullName() async {
//     String? fullName = await _sharedPrefService.getFullName();
//     String? emailId = await _sharedPrefService.getEmailId();
//     setState(() {
//       _fullName = fullName ?? 'Name';
//       _emailId = emailId ?? 'emailId';
//     });
//   }
//
//   Future<void> _loadAppVersion() async {
//     final packageInfo = await PackageInfo.fromPlatform();
//     setState(() {
//       _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
//     });
//   }
//
//   Future<void> _loadPrinter() async {
//     String? address = await _sharedPrefService.getPrinterAddress();
//     setState(() {
//       _printerName = address != null ? "Saved Printer ($address)" : null;
//     });
//   }
//
//   Future<void> _configurePrinter(BuildContext context) async {
//     // open printer picker
//     final device = await FlutterBluetoothPrinter.selectDevice(context);
//     if (device != null) {
//       await _sharedPrefService.savePrinterAddress(device.address);
//       setState(() {
//         _printerName = device.name ?? device.address;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("✅ Printer set to ${device.name ?? device.address}"),
//         ),
//       );
//     }
//   }
//
//   Future<void> _logout(BuildContext context) async {
//     await _sharedPrefService.clearLoginDetails();
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => LoginScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: const BoxDecoration(
//               color: AppColors.primaryColor,
//             ),
//             child: SingleChildScrollView(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const CircleAvatar(
//                           radius: 40,
//                           child: Icon(Icons.person),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           _fullName,
//                           style: const TextStyle(color: Colors.white, fontSize: 20),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           _emailId,
//                           style: const TextStyle(color: Colors.white70, fontSize: 14),
//                         ),
//                         const SizedBox(height: 8),
//                         if (_printerName != null)
//                           Text(
//                             "Printer: $_printerName",
//                             style: const TextStyle(color: Colors.white60, fontSize: 12),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Text(
//                     'v$_appVersion',
//                     style: const TextStyle(
//                       color: Colors.white60,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           ListTile(
//             leading: const Icon(Icons.person),
//             title: const Text('Profile'),
//             onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.privacy_tip),
//             title: const Text('Privacy and policies'),
//             onTap: () {
//               _showPrivacyPolicy(context);
//             },
//           ),
//           // ListTile(
//           //   leading: const Icon(Icons.settings),
//           //   title: const Text("Settings"),
//           //   subtitle: _printerName != null ? Text(_printerName!) : null,
//           //   onTap: () => _configurePrinter(context),
//           // ),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text("Settings"),
//             // subtitle: _printerName != null ? Text(_printerName!) : null,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const SettingsScreen()),
//               );
//             },
//           ),
//
//           Consumer<SalesOrderProvider>(builder: (context, provider, child) {
//             return ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Logout'),
//               onTap: () {
//                 _logout(context);
//                 Navigator.pop(context);
//               },
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   void _showPrivacyPolicy(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Privacy Policy',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Icon(Icons.close, color: Colors.black),
//               ),
//             ],
//           ),
//           content: Container(
//             width: double.maxFinite,
//             child: PrivacyPolicyPage(),
//           ),
//         );
//       },
//     );
//   }
// }


//API integration
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sales_ordering_app/service/apiservices.dart';
// import 'package:sales_ordering_app/utils/app_colors.dart';
// import 'package:sales_ordering_app/utils/sharedpreference.dart';
// import 'package:sales_ordering_app/view/login.dart';
// import 'package:sales_ordering_app/provider/provider.dart';

// class DrawerWidget extends StatefulWidget {
//   @override
//   _DrawerWidgetState createState() => _DrawerWidgetState();
// }

// class _DrawerWidgetState extends State<DrawerWidget> {
//   final SharedPrefService _sharedPrefService = SharedPrefService();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//    //   provider.fetchCustomerDetails();
//     });
//   }

//   Future<void> _logout(BuildContext context) async {
//     await _sharedPrefService.clearLoginDetails();
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => LoginScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Consumer<SalesOrderProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (provider.errorMessage != null) {
//             return Center(child: Text('Error: ${provider.errorMessage}'));
//           }

//           if (provider.customerModel == null || provider.customerModel?.data == null) {
//             return Center(child: Text('No user data available'));
//           }

//           final user = provider.customerModel!.data!;
//           return ListView(
//             padding: EdgeInsets.zero,
//             children: <Widget>[
//               DrawerHeader(
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryColor,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       child: user.fullName == null ? Icon(Icons.person) : null,
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       user.fullName ?? 'Name',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               ListTile(
//                 leading: Icon(Icons.privacy_tip),
//                 title: Text('Privacy and policies'),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.logout),
//                 title: Text('Logout'),
//                 onTap: () {
//                   _logout(context);
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
