import 'package:flutter/material.dart';

import 'POSInvoiceCreateScreen.dart';
import 'POSInvoiceListScreen.dart';


class PosInvoicePage extends StatefulWidget {
  final String userEmail;

  const PosInvoicePage({super.key, required this.userEmail});

  @override
  State<PosInvoicePage> createState() => _PosInvoicePageState();
}

class _PosInvoicePageState extends State<PosInvoicePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          PosInvoiceScreen(userEmail: widget.userEmail), // ✅ pass email down
          PosInvoiceListScreen(userEmail: widget.userEmail), // ✅ now const
        ],
      ),
    );
  }
}