import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/view/pick_list/PickList.dart';
import 'package:sales_ordering_app/view/splash_screen.dart';
import 'package:provider/provider.dart';




final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  // await flutterLocalNotificationsPlugin.initialize(initSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == "open_picklist") {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => PickListPage()),
        );
      }
    },
  );
  // ✅ Request Notification Permission (Android 13+)
  await _requestNotificationPermission();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SalesOrderProvider()),
    ],
    child: const MyApp(),
  ));
}
Future<void> _requestNotificationPermission() async {
  var status = await Permission.notification.status;

  if (!status.isGranted) {
    await Permission.notification.request();
  }
}
// void main() {
//   runApp(MultiProvider(providers: [
//     ChangeNotifierProvider(create: (context) => SalesOrderProvider()),
//
//    // ChangeNotifierProvider(create: (context) => AttendanceProvider()),
//   ], child: const MyApp()));
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
