import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:sales_ordering_app/view/Job%20card/Job_Card_List';
import 'package:sales_ordering_app/view/attendance/attendance.dart';
import 'package:sales_ordering_app/view/current_stock/current_stock_list.dart';
import 'package:sales_ordering_app/view/customers/customers_list_screen.dart';
import 'package:sales_ordering_app/view/home/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/view/items/item_list_screen.dart';
import 'package:sales_ordering_app/view/material_demand/MaterialDemandScreen.dart';
import 'package:sales_ordering_app/view/new_Transcation/get_sales_order.dart';
import 'package:sales_ordering_app/view/new_Transcation/payment_recipt_list.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_ordering_app/view/material_request/material_request.dart';
import 'package:sales_ordering_app/view/pick_list/PickList.dart';
import 'package:sales_ordering_app/view/purchase_receipt/PurchaseReceipt.dart';
import 'package:sales_ordering_app/view/purchase_request/PurchaseRequestScreen.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoice.dart';
import 'package:sales_ordering_app/view/sales_return/SalesReturn.dart';
import 'package:sales_ordering_app/view/stock_updates/StockReconciliationScreen.dart';
import 'package:sales_ordering_app/view/supplier_pricing/SupplierPricing.dart';
import 'package:sales_ordering_app/model/customer_list_model.dart' as customer;

// import '../../model/customer_list_model.dart';
import '../../main.dart';
import '../Appointments/appointments_screen.dart';
import '../PickItems/pickScreen.dart';
import '../ToDo/todos_screen.dart';
import '../Work Order/Work_Order_list.dart';
import '../estimatePreparation/create_estimate_screen.dart';
import '../estimatePreparation/estimate_tab_screen.dart';
import '../maintenance_visit/maintenanceVistScreen.dart';
import '../maintenance_visit/maintenance_visit_list_screen.dart';
import '../member_registration/memberRegistrationScreen.dart';
import '../pos_invoice/POSInvoiceCreateScreen.dart';
import '../pos_invoice/PosInvoice.dart';
import '../pos_invoice/PosOpeningEntry.dart';
import '../projects/project_list_screen.dart';
import '../sales_manager/SalesManagerScreen.dart';
import '../sales_quotation/SalesQuotation.dart';
import '../task/task_screen.dart';


// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  bool isLoading = false;
  List<GridItem> gridItems = [];
  Timer? _pollingTimer;
  String? _lastPickListName;
  bool _isInitialLoad = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDialogShowing = false; // ✅ Single declaration here

  @override
  void initState() {
    super.initState();
    // _startPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _homeDetails();
      await _loadUserInfo();
      _printStoredLoginDetails();
      _employeeDetails();

      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      await provider.checkIfUserIsEmployee(context);

      // 🔹 Fetch picklist for initial load
      // int newCount = await provider.fetchPickList(context);

      // 🔹 Show "Pending Picklists" ONLY on first load
      // if (_isInitialLoad && newCount > 0) {
      //   _showNotification(
      //     "Pending Picklists",
      //     "$newCount pending picklists available",
      //   );
      // }

      // 🔹 Initial load completed
      _isInitialLoad = false;
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
  String _fullName = '';
  String _company = '';

  Future<void> _loadUserInfo() async {
    final fullName = await _sharedPrefService.getFullName();
    final company = await _sharedPrefService.getCompany();

    setState(() {
      _fullName = fullName ?? '';
      _company = company ?? '';
    });
  }

  // void _startPolling() {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //   _pollingTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
  //     int newCount = await provider.fetchPickList(context);
  //
  //     // if (newCount > 0) {
  //     if (!_isInitialLoad && newCount > 0) {
  //
  //       _showNotification(
  //         "New Picklists Added",
  //         "$newCount pending picklists available",
  //       );
  //     }
  //   });
  // }

  // Future<void> _showNotification(String title, String body) async {
  //   const AndroidNotificationDetails androidDetails =
  //   AndroidNotificationDetails(
  //     "picklist_channel",
  //     "Pick List Alerts",
  //     importance: Importance.high,
  //     priority: Priority.high,
  //   );
  //
  //   const NotificationDetails notificationDetails =
  //   NotificationDetails(android: androidDetails);
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     title,
  //     body,
  //     notificationDetails,
  //     payload: "open_picklist", // <-- ADD PAYLOAD
  //   );
  // }

  Future<void> _printStoredLoginDetails() async {
    await _sharedPrefService.printLoginDetails();
  }

  Future<void> _homeDetails() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    setState(() => isLoading = true);

    try {
      final homeData = await provider.homeDetails(context);
      if (homeData != null && homeData.message != null) {
        setState(() {
          gridItems = homeData.message!.map((msg) => GridItem(
            icon: _getIconForMenu(msg.tqMenuItem),
            title: msg.tqMenuItem ?? "Unknown",
            navigateTo: (context) => _navigateToScreen(msg.tqMenuItem, context),
          )).toList();
        });
      }
    } catch (e) {
      print('Error fetching home tiles: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  // GridItem _appointmentsTile() {
  //   return GridItem(
  //     icon: Icons.takeout_dining,
  //     title: 'Pick',
  //     navigateTo: (context) =>
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => PickItemsPage()),
  //         ),
  //   );
  // }
  //
  // Future<void> _homeDetails() async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final homeData = await provider.homeDetails(context);
  //
  //     final List<GridItem> items = [];
  //
  //     if (homeData != null && homeData.message != null) {
  //       items.addAll(
  //         homeData.message!.map(
  //               (msg) => GridItem(
  //             icon: _getIconForMenu(msg.tqMenuItem),
  //             title: msg.tqMenuItem ?? "Unknown",
  //             navigateTo: (context) =>
  //                 _navigateToScreen(msg.tqMenuItem, context),
  //           ),
  //         ),
  //       );
  //     }
  //
  //     // ✅ Ensure Appointments tile is ALWAYS present
  //     final alreadyExists = items.any(
  //           (item) => item.title == 'Appointments',
  //     );
  //
  //     if (!alreadyExists) {
  //       items.insert(0, _appointmentsTile()); // top position
  //     }
  //
  //     setState(() {
  //       gridItems = items;
  //     });
  //   } catch (e) {
  //     debugPrint('Error fetching home tiles: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  Future<void> _employeeDetails() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    String? emailId = await _sharedPrefService.getEmailId();
    try {
      await provider.employeeDetails(emailId!, context);
    } catch (e) {
      print('Error fetching employee details: $e');
    }
  }
  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildNotificationContent(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Optional: mark all as read
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForMenu(String? menuItem) {
    switch (menuItem) {
      case 'Checkin': return Icons.person;
      case 'Attendance': return Icons.calendar_month;
      case 'Sales Order': return Icons.add_box_rounded;
      case 'Receipts': return Icons.inventory;
      case 'Supplier Pricing': return Icons.price_change_outlined;
      case 'Sales Return': return Icons.assignment_return_outlined;
      case 'Products': return Icons.library_books;
      case 'Purchase Request': return Icons.find_in_page;
      case 'Pick List': return Icons.whatshot_sharp;
      case 'Customers': return Icons.group;
      case 'Stock': return Icons.card_travel;
      case 'Stock Updates': return Icons.system_update_alt_outlined;
      case 'Material Request': return Icons.request_quote;
      case 'Material Demand': return Icons.accessibility_new;
      case 'Work Order': return Icons.build_circle;
      case 'Job Card': return Icons.work;
      case 'Purchase Receipt': return Icons.receipt_sharp;
      case 'Sales Invoice': return Icons.receipt_long_sharp;
      case 'POS Invoice': return Icons.computer_rounded;
      case 'Sales Quotation': return Icons.quora;
      case 'Member Registration': return Icons.new_label_outlined;
      case 'Sales Manager': return Icons.person_sharp;
      case 'ToDos': return Icons.format_list_numbered;
      case 'Tasks': return Icons.task;
      case 'Projects': return Icons.work;
      case 'Estimate': return Icons.co_present_outlined;
      case 'Maintenance Visit': return Icons.workspace_premium;
      case 'Patient Appointment': return Icons.local_hospital_sharp;
      case 'Pick': return Icons.takeout_dining;

      default: return Icons.help_outline;
    }
  }

  // void _navigateToScreen(String? menuItem, BuildContext context) async {
  //   if (menuItem == null) return;
  //
  //   switch (menuItem) {
  //     case 'Checkin':
  //     // Initialize check-in status from server before showing dialog
  //       await Provider.of<SalesOrderProvider>(context, listen: false)
  //           .initializeCheckinStatus();
  //
  //       // Now show the dialog with accurate status
  //       _showPopupDialog(context);
  //       break;
  // void _navigateToScreen(String? menuItem, BuildContext context) async {
  //   if (menuItem == null) return;
  //
  //   switch (menuItem) {
  //     case 'Checkin':
  //       final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //       // ✅ Check if user is an employee
  //       if (!provider.isEmployee) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Only employees can use the Checkin module.")),
  //         );
  //         return; // stop navigation
  //       }
  //
  //       // Initialize check-in status from server before showing dialog
  //       await provider.initializeCheckinStatus();
  //
  //       // Now show the dialog with accurate status
  //       _showPopupDialog(context);
  //       break;
  void _navigateToScreen(String? menuItem, BuildContext context) async {
    if (menuItem == null) return;

    switch (menuItem) {
      case 'Checkin':
      // 🛑 Block if dialog is already open or loading
        if (_isDialogShowing) return;

        final provider = Provider.of<SalesOrderProvider>(context, listen: false);

        if (!provider.isEmployee) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only employees can use the Checkin module.")),
          );
          return;
        }

        // 🛑 Block if already fetching (concurrent taps during API call)
        if (provider.isInitializing) return;

        // ✅ Lock immediately before async gap
        setState(() => _isDialogShowing = true);

        try {
          await provider.initializeCheckinStatus();
        } catch (e) {
          setState(() => _isDialogShowing = false);
          return;
        }

        if (!context.mounted) {
          setState(() => _isDialogShowing = false);
          return;
        }

        _showPopupDialog(context);
        break;
      case 'Attendance': Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceCalendar())); break;
      case 'Sales Order': Navigator.push(context, MaterialPageRoute(builder: (_) => SalesOrderPage())); break;
      case 'Receipts': Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentReciptScreen())); break;
      case 'Supplier Pricing': Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierPricingScreen())); break;
      case 'Sales Return': Navigator.push(context, MaterialPageRoute(builder: (_) => SalesReturnScreen())); break;
      case 'Products': Navigator.push(context, MaterialPageRoute(builder: (_) => ItemListScreen())); break;
      case 'Purchase Request': Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseRequestListScreen())); break;
      case 'Pick List': Navigator.push(context, MaterialPageRoute(builder: (_) => PickListPage())); break;
      // case 'Customers': Navigator.push(context, MaterialPageRoute(builder: (_) => CustomersListScreen())); break;
      case 'Customers':
      // ✅ Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading customers...'),
                  ],
                ),
              ),
            ),
          ),
        );

        try {
          // ✅ Preload customer data
          final provider = Provider.of<SalesOrderProvider>(context, listen: false);
          await provider.customerList(context);

          // ✅ Close loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          // ✅ Navigate to customer screen
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomersListScreen()),
            );
          }
        } catch (e) {
          // ✅ Close loading dialog on error
          if (context.mounted) {
            Navigator.pop(context);
          }

          // ✅ Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load customers: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;

      case 'Stock': Navigator.push(context, MaterialPageRoute(builder: (_) => CurrentStockList())); break;
      case 'Stock Updates': Navigator.push(context, MaterialPageRoute(builder: (_) => StockReconciliationScreen())); break;
      case 'Material Request': Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialRequest())); break;
      case 'Material Demand': Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDemandScreen())); break;
      case 'Work Order': Navigator.push(context, MaterialPageRoute(builder: (_) => WorkOrderListScreen())); break;
      case 'Job Card': Navigator.push(context, MaterialPageRoute(builder: (_) => JobCardListScreen())); break;
      case 'Purchase Receipt': Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseReceiptScreen())); break;
      case 'Sales Invoice': Navigator.push(context, MaterialPageRoute(builder: (_) => SalesInvoicePage())); break;
      case 'Sales Quotation': Navigator.push(context, MaterialPageRoute(builder: (_) => SalesQuotationPage())); break;
      case 'Member Registration': Navigator.push(context, MaterialPageRoute(builder: (_) => MemberRegistrationScreen())); break;
      case 'Sales Manager': Navigator.push(context, MaterialPageRoute(builder: (_) => SalesManagerScreen())); break;
      case 'ToDos': Navigator.push(context, MaterialPageRoute(builder: (_) => ToDosScreen())); break;
      case 'Tasks': Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen())); break;
      case 'Projects': Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectListScreen())); break;
      case 'Maintenance Visit': Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceVisitListScreen())); break;
      case 'Estimate': Navigator.push(context, MaterialPageRoute(builder: (_) => EstimateTabScreen())); break;
      case 'Patient Appointment': Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsScreen())); break;
      case 'Pick': Navigator.push(context, MaterialPageRoute(builder: (_) => PickItemsPage())); break;
      case 'POS Invoice':
        final provider = Provider.of<SalesOrderProvider>(context, listen: false);

        final userEmail = await provider.getLoggedInUserIdentifier();
        if (userEmail == null) {
          debugPrint("User email not found");
          return;
        }

        final hasOpeningEntry = await provider.checkOpeningEntry(userEmail);

        if (hasOpeningEntry) {
          Navigator.push(
            context,
            MaterialPageRoute(
              // builder: (_) => PosInvoiceScreen(userEmail: userEmail),
              builder: (_) => PosInvoicePage(userEmail: userEmail),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PosOpeningScreen(userEmail: userEmail),
            ),
          );
        }
        break;

    }
  }
  void _showPopupDialog(BuildContext context) {
    final String formattedDateTime =
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<SalesOrderProvider>(
          builder: (context, provider, child) {
            return CustomDialog(
              onCheckIn: () async {
                Future.microtask(() async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  if (provider.errorMessage != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(provider.errorMessage!)),
                    );
                  } else {
                    final message = provider.isCheckedIn
                        ? 'Check-out successful!'
                        : 'Check-in successful!';
                    _showMessagePopup(context, message);
                  }
                });
              },
              isCheckedIn: provider.isCheckedIn,
              formattedDateTime: formattedDateTime,
            );
          },
        );
      },
    ).whenComplete(() {
      // ✅ Reset lock when dialog is dismissed
      if (mounted) {
        setState(() => _isDialogShowing = false);
      }
    });
  }

  void _showMessagePopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrompt() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Text(
        "What do you want to do today?",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesOrderProvider>();
    final isEmployee = provider.isEmployee;

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 206, 251, 246),
        appBar: AppBar(
          automaticallyImplyLeading: false, // ❗ remove hamburger
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          toolbarHeight: 120, // 🔑 makes it look like image
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row (App name + icons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MobiBizz',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // IconButton(
                      //   icon: const Icon(Icons.settings, color: Colors.white),
                      //   onPressed: () {
                      //     // settings navigation if needed
                      //   },
                      // ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () => _showNotificationDialog(context),
                      ),
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer(); // ✅ OPEN DRAWER
                        },
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Greeting
              Text(
                'HELLO, ${_fullName.toUpperCase()}!',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (_company.isNotEmpty)
                Text(
                  _company,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),

        drawer: DrawerWidget(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        _buildPrompt(),
        Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: gridItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = gridItems[index];
                  final isCheckin = item.title == 'Checkin';
                  final disabled = isCheckin && !isEmployee;

                  return GestureDetector(
                    onTap: disabled ? null : () => item.navigateTo?.call(context),
                    child: Opacity(
                      opacity: disabled ? 0.5 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 26,
                              color: disabled ? Colors.grey : Colors.black,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: disabled ? Colors.grey : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // child: GridView.builder(
              //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              //     crossAxisCount: 2,
              //     crossAxisSpacing: 16.0,
              //     mainAxisSpacing: 10.0,
              //   ),
              //   itemCount: gridItems.length,
              //   itemBuilder: (context, index) {
              //     final item = gridItems[index];
              //     final isCheckin = item.title == 'Checkin';
              //     // return GestureDetector(
              //     //   onTap: () => gridItems[index].navigateTo?.call(context),
              //     //   child: Container(
              //     //     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
              //     //     child: Column(
              //     //       mainAxisAlignment: MainAxisAlignment.center,
              //     //       children: [
              //     //         Icon(gridItems[index].icon, size: 40, color: Colors.black),
              //     //         SizedBox(height: 10),
              //     //         Text(gridItems[index].title, style: TextStyle(fontSize: 16)),
              //     //       ],
              //     //     ),
              //     //   ),
              //     // );
              //     return GestureDetector(
              //       onTap: () {
              //         // ✅ If Checkin and not employee, show message instead of navigation
              //         if (isCheckin && !isEmployee) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //                 content: Text(
              //                     "Only employees can use the Checkin module.")),
              //           );
              //           return;
              //         }
              //         item.navigateTo?.call(context);
              //       },
              //       child: Opacity(
              //         opacity: (isCheckin && !isEmployee) ? 0.5 : 1.0,
              //         child: Container(
              //           decoration: BoxDecoration(
              //             color: Colors.white,
              //             borderRadius: BorderRadius.circular(8.0),
              //           ),
              //           child: Column(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               Icon(item.icon,
              //                   size: 40,
              //                   color: (isCheckin && !isEmployee)
              //                       ? Colors.grey
              //                       : Colors.black),
              //               const SizedBox(height: 10),
              //               Text(
              //                 item.title,
              //                 style: TextStyle(
              //                   fontSize: 16,
              //                   color: (isCheckin && !isEmployee)
              //                       ? Colors.grey
              //                       : Colors.black,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // ),
            ),
    ]));
  }
  Widget _buildNotificationContent() {
    return const Center(
      child: Text(
        'No notifications available',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

}

class GridItem {
  final IconData icon;
  final String title;
  final void Function(BuildContext)? navigateTo;
  GridItem({required this.icon, required this.title, this.navigateTo});
}


// void _showPopupDialog(BuildContext context) {
//   final DateTime now = DateTime.now();
//   final String formattedDateTime =
//       DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
//
//   showDialog(
//     context: context,
//     barrierDismissible: false, // 🔒 Prevent closing on outside tap
//
//     builder: (BuildContext context) {
//       return Consumer<SalesOrderProvider>(
//         builder: (context, provider, child) {
//           return CustomDialog(
//             onCheckIn: () async {
//               // Use Future.microtask to defer state changes
//               Future.microtask(() async {
//                 final scaffoldMessenger = ScaffoldMessenger.of(context);
//                 if (provider.errorMessage != null) {
//                   scaffoldMessenger.showSnackBar(
//                     SnackBar(content: Text(provider.errorMessage!)),
//                   );
//                 } else {
//                   final message = provider.isCheckedIn
//                       ? 'Check-out successful!'
//                       : 'Check-in successful!';
//
//                   _showMessagePopup(context, message);
//                 }
//               });
//             },
//             isCheckedIn: provider.isCheckedIn,
//             formattedDateTime: formattedDateTime,
//           );
//         },
//       );
//     },
//   );
// }
//
// void _showMessagePopup(BuildContext context, String message) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.check_circle,
//               color: Colors.green,
//               size: 100, // ✅ Big success icon
//             ),
//             const SizedBox(height: 20),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.primaryColor,
//                 fontSize: 20,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: const Text(
//               'Close',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }


class CustomDialog extends StatefulWidget {
  final Function onCheckIn;
  final bool isCheckedIn;
  final String formattedDateTime;

  const CustomDialog({
    Key? key,
    required this.onCheckIn,
    required this.isCheckedIn,
    required this.formattedDateTime,
  }) : super(key: key);

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  double latitude = 0.0;
  double longitude = 0.0;
  static const platform = MethodChannel('com.example/location');
  String _currentLocation = 'Fetching location...';
  String city = '';
  String state = '';
  String area = '';
  Map<String, String>? _cachedPlace;
  double? _lastLatitude;
  double? _lastLongitude;
  bool _isLoading = false; // <-- Loading state
  String _loadingText = "";
  bool _isFetchingData = true; // 👈 new flag
  customer.Data? _selectedCustomer;
  List<customer.Data> _nearbyCustomers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initData();

    Future.microtask(() async {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      // await provider.fetchCustomers(context);
      await provider.initializeCheckinStatus();

      // ✅ Auto-select last checked-in customer if available
      // if (provider.isCheckedIn && provider.lastCheckedInCustomer != null) {
      //   final customers = provider.customerr;
      //   try {
      //     final foundCustomer = customers.firstWhere(
      //           (c) => c.name == provider.lastCheckedInCustomer,
      //     );
      //     setState(() => _selectedCustomer = foundCustomer);
      //   } catch (_) {
      //     setState(() => _selectedCustomer = null);
      //   }
      // }

      // ✅ Auto-fill last remarks if available
      if (provider.isCheckedIn && provider.lastRemarks != null) {
        _remarkController.text = provider.lastRemarks!;
      }

      setState(() => _isFetchingData = false);
    });
  }


  // List<customer.Data> _filterNearbyCustomers(
  //     List<customer.Data> allCustomers, double userLat, double userLon,
  //     {double radiusInMeters = 100}) { // 5 km radius
  //   return allCustomers.where((c) {
  //     final lat = double.tryParse(c.latitude ?? '');
  //     final lon = double.tryParse(c.longitude ?? '');
  //     if (lat == null || lon == null) return false;
  //     final distance = Geolocator.distanceBetween(userLat, userLon, lat, lon);
  //     debugPrint('Customer: ${c.name}, Distance: ${distance.toStringAsFixed(2)} meters');
  //
  //     return distance <= radiusInMeters;
  //   }).toList();
  // }

  Future<void> _initData() async {
    setState(() {
      _isFetchingData = true;
      _loadingText = "Fetching location...";
    });

    await _getCurrentLocation();
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    await provider.fetchCustomers(context);

    // Filter nearby customers
    // final nearbyCustomers = _filterNearbyCustomers(
    //   provider.customerr,
    //   latitude,
    //   longitude,
    // );


    setState(() {
      _isFetchingData = false;
      _loadingText = "";
      // _nearbyCustomers = nearbyCustomers;
    });
  }

  // Future<void> _getCurrentLocation() async {
  //   setState(() => _isLoading = true); // Show loader
  //
  //   try {
  //     bool serviceEnabled;
  //     LocationPermission permission;
  //
  //     // Check if location services are enabled
  //     serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       setState(() {
  //         _currentLocation = "Location services are disabled.";
  //         _isLoading = false;
  //       });
  //       return;
  //     }
  //
  //     // Request permission if not granted
  //     permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         setState(() {
  //           _currentLocation = "Location permissions are denied.";
  //           _isLoading = false;
  //         });
  //         return;
  //       }
  //     }
  //
  //     if (permission == LocationPermission.deniedForever) {
  //       setState(() {
  //         _currentLocation = "Location permissions are permanently denied.";
  //         _isLoading = false;
  //       });
  //       return;
  //     }
  //
  //     // Retry logic for getting valid coordinates
  //     Position position;
  //     int retries = 0;
  //     do {
  //       position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high,
  //       );
  //       retries++;
  //       if (position.latitude == 0.0 && position.longitude == 0.0) {
  //         await Future.delayed(const Duration(seconds: 1));
  //       }
  //     } while (
  //     (position.latitude == 0.0 && position.longitude == 0.0) &&
  //         retries < 5);
  //
  //     latitude = position.latitude;
  //     longitude = position.longitude;
  //
  //     setState(() {
  //       _currentLocation = 'Lat: $latitude, Lon: $longitude';
  //     });
  //
  //     // Fetch place name if cache is empty or moved significantly
  //     if (_cachedPlace == null ||
  //         _lastLatitude == null ||
  //         _lastLongitude == null ||
  //         Geolocator.distanceBetween(
  //           _lastLatitude!,
  //           _lastLongitude!,
  //           latitude,
  //           longitude,
  //         ) > 50) {
  //       _cachedPlace = await _getPlaceName(latitude, longitude);
  //       _lastLatitude = latitude;
  //       _lastLongitude = longitude;
  //     }
  //
  //     setState(() {
  //       city = _cachedPlace!['city'] ?? '';
  //       state = _cachedPlace!['state'] ?? '';
  //       area = _cachedPlace!['area'] ?? '';
  //     });
  //   } catch (e) {
  //     debugPrint("Error fetching location: $e");
  //     setState(() {
  //       _currentLocation = "Error fetching location.";
  //     });
  //   } finally {
  //     setState(() => _isLoading = false); // Hide loader
  //   }
  // }
  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentLocation = "Location permissions denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentLocation = "Location permissions permanently denied");
        return;
      }

      // ✅ Get last known position first (instant)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null &&
          lastPosition.latitude != 0.0 &&
          lastPosition.longitude != 0.0) {
        latitude = lastPosition.latitude;
        longitude = lastPosition.longitude;
        setState(() {
          _currentLocation = 'Lat: $latitude, Lon: $longitude';
        });

        // Fetch place name in background
        _fetchPlaceNameInBackground(latitude, longitude);
      }

      // ✅ Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for speed
        timeLimit: const Duration(seconds: 5), // Add timeout
      );

      // Update if we got better coordinates
      if (position.latitude != 0.0 && position.longitude != 0.0) {
        latitude = position.latitude;
        longitude = position.longitude;

        setState(() {
          _currentLocation = 'Lat: $latitude, Lon: $longitude';
        });

        // Only fetch place name if moved significantly
        if (_shouldFetchPlaceName(latitude, longitude)) {
          await _fetchPlaceNameInBackground(latitude, longitude);
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      setState(() => _currentLocation = "Error fetching location");
    }
  }
  Future<void> _fetchPlaceNameInBackground(double lat, double lon) async {
    try {
      final place = await _getPlaceName(lat, lon).timeout(
        const Duration(seconds: 5),
        onTimeout: () => {
          'city': city.isEmpty ? 'Unknown' : city,
          'state': state.isEmpty ? 'Unknown' : state,
          'area': area.isEmpty ? 'Unknown' : area,
        },
      );

      _cachedPlace = place;
      _lastLatitude = lat;
      _lastLongitude = lon;

      if (mounted) {
        setState(() {
          city = place['city'] ?? '';
          state = place['state'] ?? '';
          area = place['area'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching place name: $e");
    }
  }
  bool _shouldFetchPlaceName(double lat, double lon) {
    if (_cachedPlace == null || _lastLatitude == null || _lastLongitude == null) {
      return true;
    }

    final distance = Geolocator.distanceBetween(
      _lastLatitude!,
      _lastLongitude!,
      lat,
      lon,
    );

    return distance > 50; // Only fetch if moved more than 50 meters
  }

  Future<Map<String, String>> _getPlaceName(
      double latitude, double longitude) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MyFlutterApp/1.0 (your_email@example.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        return {
          'city': address['city'] ??
              address['town'] ??
              address['village'] ??
              'Unknown city',
          'state': address['state'] ?? 'Unknown state',
          'area': address['neighbourhood'] ??
              address['suburb'] ??
              address['city_district'] ??
              'Unknown area',
        };
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return {
          'city': 'Failed to fetch city',
          'state': 'Failed to fetch state',
          'area': 'Failed to fetch area',
        };
      }
    } catch (e) {
      print('Exception while fetching place name: $e');
      return {
        'city': 'Failed to fetch city',
        'state': 'Failed to fetch state',
        'area': 'Failed to fetch area',
      };
    }
  }

  // void _showSearchableDialog(BuildContext context) {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //
  //   List<customer.Data> customers = _nearbyCustomers; // 👈 start with nearby only
  //   final searchController = TextEditingController();
  //   bool showingAll = false; // 👈 track current view mode
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setDialogState) {
  //           final keyword = searchController.text.toLowerCase();
  //
  //           // ✅ Apply search filtering
  //           final filteredCustomers = customers.where((c) {
  //             final name = (c.customerName ?? c.name ?? "").toLowerCase();
  //             return name.contains(keyword);
  //           }).toList();
  //
  //           return AlertDialog(
  //             title: const Text("Select Customer"),
  //             content: SizedBox(
  //               width: double.maxFinite,
  //               height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
  //               child: Column(
  //                 children: [
  //                   TextField(
  //                     controller: searchController,
  //                     decoration: const InputDecoration(
  //                       hintText: "Search customer...",
  //                       prefixIcon: Icon(Icons.search),
  //                       border: OutlineInputBorder(),
  //                     ),
  //                     onChanged: (value) {
  //                       setDialogState(() {}); // refresh list when searching
  //                     },
  //                   ),
  //                   const SizedBox(height: 10),
  //
  //                   // 👇 Add a button to toggle between nearby and all customers
  //                   Align(
  //                     alignment: Alignment.centerRight,
  //                     child: TextButton.icon(
  //                       icon: Icon(
  //                         showingAll ? Icons.location_on_outlined : Icons.list,
  //                         color: Colors.blue,
  //                       ),
  //                       label: Text(
  //                         showingAll ? "Show Nearby Only" : "Show All Customers",
  //                         style: const TextStyle(color: Colors.blue),
  //                       ),
  //                       onPressed: () {
  //                         setDialogState(() {
  //                           if (showingAll) {
  //                             // Switch back to nearby
  //                             customers = _nearbyCustomers;
  //                           } else {
  //                             // Show all customers from provider
  //                             customers = provider.customerr;
  //                           }
  //                           showingAll = !showingAll;
  //                         });
  //                       },
  //                     ),
  //                   ),
  //
  //                   Expanded(
  //                     child: filteredCustomers.isEmpty
  //                         ? const Center(child: Text("No customers found"))
  //                         : ListView.builder(
  //                       itemCount: filteredCustomers.length,
  //                       itemBuilder: (context, index) {
  //                         final c = filteredCustomers[index];
  //                         return ListTile(
  //                           title: Text(c.customerName ?? c.name ?? ""),
  //                           subtitle: (c.latitude != null &&
  //                               c.longitude != null &&
  //                               c.latitude != 0 &&
  //                               c.longitude != 0)
  //                               ? Text(
  //                             "(${c.latitude}, ${c.longitude})",
  //                             style: const TextStyle(fontSize: 12),
  //                           )
  //                               : null,
  //                           onTap: () {
  //                             setState(() {
  //                               _selectedCustomer = c;
  //                             });
  //                             Navigator.pop(context);
  //                           },
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text("Cancel"),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  final TextEditingController _remarkController = TextEditingController();
  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // final DateTime now = DateTime.now();
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // final String formattedTime = DateFormat('h:mm a').format(now);
    // final String formattedDate = DateFormat('EEEE, d MMMM').format(now);
    final lastDateTime = provider.lastCheckinDateTime;

    final displayTime = lastDateTime != null
        ? DateFormat('hh:mm a').format(lastDateTime)
        : "N/A";

    final displayDate = lastDateTime != null
        ? DateFormat('dd/MM/yyyy').format(lastDateTime)
        : "N/A";
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, child) {
        final isCheckedIn = provider.isCheckedIn; // ✅ always read latest status
        return AlertDialog(
          // title: const Center(
          //   child: Text(
          //     'Check In / Check Out',
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       color: Color.fromARGB(255, 3, 28, 48),
          //     ),
          //   ),
          // ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Check In / Out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color.fromARGB(255, 3, 28, 48),
                  ),
                ),
              ),
              InkWell(
                onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 22, color: Colors.grey),
                ),
              ),
            ],
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0), // ✅ less right padding so icon sits closer to edge
          // ✅ Make content scrollable and keyboard-safe
          content: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: SizedBox(
                        height: 150,
                        width: 150,
                        child: Lottie.asset('assets/images/checkin.json'),
                      ),
                    ),
                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.errorMessage != null)
                      Text(
                        "Error: ${provider.errorMessage!}",
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     const Text(
                      //       "Select Customer:",
                      //       style: TextStyle(
                      //           fontWeight: FontWeight.bold, fontSize: 18),
                      //     ),
                      //     const SizedBox(height: 6),
                      //     InkWell(
                      //       onTap: () => _showSearchableDialog(context),
                      //       child: Container(
                      //         padding: const EdgeInsets.symmetric(
                      //             horizontal: 10, vertical: 12),
                      //         decoration: BoxDecoration(
                      //           border: Border.all(color: Colors.grey),
                      //           borderRadius: BorderRadius.circular(8),
                      //         ),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //           children: [
                      //             Expanded(
                      //               child: Text(
                      //                 _selectedCustomer != null
                      //                     ? (_selectedCustomer!.customerName ??
                      //                     _selectedCustomer!.name ??
                      //                     "")
                      //                     : "Choose a customer",
                      //                 overflow: TextOverflow.ellipsis,
                      //                 style: TextStyle(
                      //                   color: _selectedCustomer != null
                      //                       ? Colors.black
                      //                       : Colors.grey[600],
                      //                 ),
                      //               ),
                      //             ),
                      //             const Icon(Icons.arrow_drop_down),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),

                    const SizedBox(height: 12),
                    const Text(
                      "Remarks:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        hintText: "Enter a note or remark",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      maxLines: 1,
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          "Status: ",
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          isCheckedIn ? "Checked In" : "Checked Out",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row(
                    //   children: [
                    //     const Text("Time: ",
                    //         style: TextStyle(
                    //             fontWeight: FontWeight.bold, fontSize: 18)),
                    //     Text(formattedTime, style: const TextStyle(fontSize: 18)),
                    //   ],
                    // ),
                    // const SizedBox(height: 10),
                    // Row(
                    //   children: [
                    //     const Text("Date: ",
                    //         style: TextStyle(
                    //             fontWeight: FontWeight.bold, fontSize: 18)),
                    //     Flexible(
                    //       child: Text(
                    //         formattedDate,
                    //         style: const TextStyle(fontSize: 18),
                    //         overflow: TextOverflow.ellipsis,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Row(
                      children: [
                        const Text("Time: ",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(displayTime, style: const TextStyle(fontSize: 18)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text("Date: ",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Flexible(
                          child: Text(
                            displayDate,
                            style: const TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (city.isNotEmpty)
                      Row(
                        children: [
                          const Text("City: ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Flexible(
                              child: Text(city,
                                  style: const TextStyle(fontSize: 18))),
                        ],
                      ),
                    if (state.isNotEmpty)
                      Row(
                        children: [
                          const Text("State: ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Flexible(
                              child: Text(state,
                                  style: const TextStyle(fontSize: 18))),
                        ],
                      ),
                    if (area.isNotEmpty)
                      Row(
                        children: [
                          const Text("Area: ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Flexible(
                              child: Text(area,
                                  style: const TextStyle(fontSize: 18))),
                        ],
                      ),
                  ],
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.transparent,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          actions: [
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () async {
                await _handleCheckInOut(context, provider, isCheckedIn);
              },
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: (_isFetchingData || _isLoading)
                        ? Colors.grey
                        // : (isCheckedIn ? Colors.red : Colors.green),
                              : Theme.of(context).primaryColor,

        borderRadius: BorderRadius.circular(6),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Text(
                    _isFetchingData
                        ? "Fetching data..."
                        : _isLoading
                        ? _loadingText
                        : (isCheckedIn ? "Check Out" : "Check In"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _handleCheckInOut(
  //     BuildContext context, SalesOrderProvider provider, bool isCheckedIn) async {
  //   setState(() {
  //     _isLoading = true;
  //     _loadingText = isCheckedIn ? "Checking out..." : "Checking in...";
  //   });
  //
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     _showSnack('Please enable location services');
  //     _stopLoading();
  //     return;
  //   }
  //
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied ||
  //       permission == LocationPermission.deniedForever) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied ||
  //         permission == LocationPermission.deniedForever) {
  //       _showSnack('Location permission required');
  //       _stopLoading();
  //       return;
  //     }
  //   }
  //
  //   await _getCurrentLocation();
  //   if (latitude == 0.0 || longitude == 0.0) {
  //     _showSnack('Fetching location... Please try again');
  //     _stopLoading();
  //     return;
  //   }
  //
  //   await provider.checkinOrCheckout(
  //     widget.formattedDateTime,
  //     longitude.toString(),
  //     latitude.toString(),
  //     city,
  //     state,
  //     area,
  //     _selectedCustomer?.name ?? "",
  //     _remarkController.text.trim(),
  //     context,
  //   );
  //
  //   _stopLoading();
  //   Navigator.of(context).pop();
  //   await widget.onCheckIn();
  // }
  Future<void> _handleCheckInOut(
      BuildContext context,
      SalesOrderProvider provider,
      bool isCheckedIn,
      ) async {
    setState(() {
      _isLoading = true;
      _loadingText = isCheckedIn ? "Checking out..." : "Checking in...";
    });

    // ✅ Don't re-fetch location if we already have it
    if (latitude == 0.0 || longitude == 0.0) {
      await _getCurrentLocation();
    }

    if (latitude == 0.0 || longitude == 0.0) {
      _showSnack('Unable to get location. Please try again.');
      _stopLoading();
      return;
    }

    // ✅ Use cached place name if available, or use "Unknown" temporarily
    final checkInCity = city.isEmpty ? 'Fetching...' : city;
    final checkInState = state.isEmpty ? 'Fetching...' : state;
    final checkInArea = area.isEmpty ? 'Fetching...' : area;

    await provider.checkinOrCheckout(
      widget.formattedDateTime,
      longitude.toString(),
      latitude.toString(),
      checkInCity,
      checkInState,
      checkInArea,
      _selectedCustomer?.name ?? "",
      _remarkController.text.trim(),
      context,
    );

    _stopLoading();

    if (mounted) {
      Navigator.of(context).pop();
      await widget.onCheckIn();
    }
  }
  void _stopLoading() {
    setState(() {
      _isLoading = false;
      _loadingText = "";
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
