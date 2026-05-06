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
  String _company = '';

  @override
  void initState() {
    super.initState();
    // _loadFullName();
    _loadAppVersion();
    _loadUserInfo();
    _loadCompany();
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
  Future<void> _loadCompany() async {
    final company = await _sharedPrefService.getCompany();

    if (!mounted) return;

    setState(() {
      _company = company ?? '';
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
  Future<void> _showCompanyPicker() async {
    final provider = context.read<SalesOrderProvider>();
    final companies = await provider.fetchCompanies();

    if (companies.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];

              return ListTile(
                title: Text(company),
                trailing: company == _company
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);

                  await provider.changeCompanyLocally(company);

                  if (!mounted) return;

                  setState(() {
                    _company = company;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Company changed to $company'),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

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

  //         // DOMAIN FOOTER (FIXED AT BOTTOM)
  //         if (_domain.isNotEmpty)
  //           SafeArea(
  //             top: false,
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //               decoration: BoxDecoration(
  //                 border: Border(
  //                   top: BorderSide(color: Colors.grey.shade300),
  //                 ),
  //               ),
  //               child: Text(
  //                 'Domain: $_domain.turqosoft.cloud',
  //                 style: const TextStyle(
  //                   fontSize: 13,
  //                   color: Colors.black54,
  //                 ),
  //               ),
  //             ),
  //           ),
  //
  //       ],
  //     ),
  //   );
  // }
          // ✅ COMPANY + DOMAIN FOOTER (FIXED AT BOTTOM)
          if (_company.isNotEmpty || _domain.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_company.isNotEmpty)
                      // Text(
                      //   _company,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      InkWell(
                        onTap: _showCompanyPicker,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _company,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),

                    if (_company.isNotEmpty && _domain.isNotEmpty)
                      const SizedBox(height: 4),
                    if (_domain.isNotEmpty)
                      Text(
                        '$_domain.frappe.cloud',
                        //     '$_domain.m.frappe.cloud',

    style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
