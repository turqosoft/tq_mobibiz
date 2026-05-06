import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoiceCreateScreen.dart';
import 'package:sales_ordering_app/view/sales_invoice.dart/SalesInvoiceListScreen.dart';



// class SalesInvoicePage extends StatefulWidget {
//   const SalesInvoicePage({super.key});
class SalesInvoicePage extends StatefulWidget {
  final String? initialInvoice; // 👈 optional invoice to open

  const SalesInvoicePage({
    super.key,
    this.initialInvoice,
  });
  @override
  State<SalesInvoicePage> createState() => _SalesInvoicePageState();
}

class _SalesInvoicePageState extends State<SalesInvoicePage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  Future<void> Function()? _onSave;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 👇 If an invoice was passed, start on the list tab (index 1)
    if (widget.initialInvoice != null) {
      _tabController.index = 1;
    }
    _tabController.addListener(() {
      setState(() {}); // rebuild AppBar when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Sales Invoice',
            style: TextStyle(color: Colors.white),
          ),

          /// 🔥 SHOW SAVE ONLY ON CREATE TAB
          actions: _tabController.index == 0
              ? [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () async {
                if (_onSave != null) {
                  await _onSave!();
                }
              },
            ),
          ]
              : null,

          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Sales Invoice'),
              Tab(text: 'Sales Invoice List'),
            ],
          ),
        ),

        body: TabBarView(
          controller: _tabController,
          children: [
            SalesInvoiceCreateScreen(
              onSave: (saveFn) {
                _onSave = saveFn;
              },
            ),
            // SalesInvoiceScreen(),
            SalesInvoiceScreen(
              highlightInvoice: widget.initialInvoice, // 👈 pass it down
            ),
          ],
        ),

      ),
    );
  }
}
