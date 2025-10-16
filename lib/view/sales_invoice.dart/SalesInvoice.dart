import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoiceCreateScreen.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoiceListScreen.dart';


class SalesInvoicePage extends StatelessWidget {
  const SalesInvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          title: Text(
            'Sales Invoice',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Sales Invoice'),
              Tab(text: 'Sales Invoice List'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SalesInvoiceCreateScreen(), // Create new Sales Invoice screen
            SalesInvoiceScreen(),   // Sales Invoice List screen (already made earlier)
          ],
        ),
      ),
    );
  }
}
