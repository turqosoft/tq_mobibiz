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
  bool _isSubmitting = false;
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
  //
  // @override
  // Widget build(BuildContext context) {
  //   return DefaultTabController(
  //     length: 2,
  //     child: Scaffold(
  //       appBar: AppBar(
  //         backgroundColor: AppColors.primaryColor,
  //         leading: IconButton(
  //           icon: const Icon(Icons.arrow_back, color: Colors.white),
  //           onPressed: () => Navigator.pop(context),
  //         ),
  //         title: const Text(
  //           'Sales Invoice',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //
  //         /// 🔥 SHOW SAVE ONLY ON CREATE TAB
  //         actions: _tabController.index == 0
  //             ? [
  //           IconButton(
  //             icon: const Icon(Icons.save, color: Colors.white),
  //             onPressed: () async {
  //               if (_onSave != null) {
  //                 await _onSave!();
  //               }
  //             },
  //           ),
  //         ]
  //             : null,
  //
  //         bottom: TabBar(
  //           controller: _tabController,
  //           tabs: const [
  //             Tab(text: 'Sales Invoice'),
  //             Tab(text: 'Sales Invoice List'),
  //           ],
  //         ),
  //       ),
  //
  //       body: TabBarView(
  //         controller: _tabController,
  //         children: [
  //           SalesInvoiceCreateScreen(
  //             onSave: (saveFn) {
  //               _onSave = saveFn;
  //             },
  //           ),
  //           // SalesInvoiceScreen(),
  //           SalesInvoiceScreen(
  //             highlightInvoice: widget.initialInvoice, // 👈 pass it down
  //           ),
  //         ],
  //       ),
  //
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                // 👇 Block back navigation during save
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                  // 👇 Disable save button during submission
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                    if (_onSave != null) {
                      await _onSave!();
                    }
                  },
                ),
              ]
                  : null,

              bottom: TabBar(
                controller: _tabController,
                // 👇 Disable tab switching during save
                onTap: _isSubmitting ? (_) {} : null,
                tabs: const [
                  Tab(text: 'Sales Invoice'),
                  Tab(text: 'Sales Invoice List'),
                ],
              ),
            ),

            body: TabBarView(
              controller: _tabController,
              // 👇 Disable swipe between tabs during save
              physics: _isSubmitting
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              children: [
                SalesInvoiceCreateScreen(
                  onSave: (saveFn) {
                    _onSave = saveFn;
                  },
                  // 👇 Pass callbacks so child can control parent's overlay
                  onSubmitStart: () {
                    if (mounted) setState(() => _isSubmitting = true);
                  },
                  onSubmitEnd: () {
                    if (mounted) setState(() => _isSubmitting = false);
                  },
                ),
                SalesInvoiceScreen(
                  highlightInvoice: widget.initialInvoice,
                ),
              ],
            ),
          ),

          // 👇 Full-screen overlay — covers AppBar + TabBar + body
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Creating Invoice...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please wait',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
