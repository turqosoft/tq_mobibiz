import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/view/splash_screen.dart';
import 'package:provider/provider.dart';






void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => SalesOrderProvider()),

   // ChangeNotifierProvider(create: (context) => AttendanceProvider()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
