import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import 'CreateSalesQuotation.dart';
import 'ListSalesQuotation.dart';

class SalesQuotationPage extends StatefulWidget {
  const SalesQuotationPage({super.key});

  @override
  State<SalesQuotationPage> createState() => SalesQuotationPageState();
}

class SalesQuotationPageState extends State<SalesQuotationPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  bool _showSaveIcon = true; // 👈 Initially true for first tab

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.startConnectionCheck(); // 🟢 Start periodic connection check

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          _showSaveIcon = tabController.index == 0;
        });
      }
    });
  }

  @override
  void dispose() {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.stopConnectionCheck(); // 🔴 Stop periodic connection check
    tabController.dispose();
    super.dispose();
  }

  Future<void> _submitQuotation() async {
    await createQuotationTabKey.currentState?.submitQuotation();
    await quotationListTabKey.currentState?.refreshQuotationList();

    setState(() {});   // 👈 rebuild AFTER API finishes
  }

  final GlobalKey<QuotationListTabState> quotationListTabKey =
  GlobalKey<QuotationListTabState>();
  // 👇 Create a GlobalKey to access CreateQuotationTab’s state
  final GlobalKey<CreateQuotationTabState> createQuotationTabKey =
  GlobalKey<CreateQuotationTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Sales Quotation',
          style: TextStyle(color: Colors.white),
        ),

        actions: [
          Consumer<SalesOrderProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isServerConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.isServerConnected ? Colors.greenAccent : Colors.redAccent,
                ),
                tooltip: provider.isServerConnected
                    ? "Connected to Server"
                    : "Disconnected from Server",
                onPressed: () async {
                  // Manually recheck connection when tapped
                  await provider.startConnectionCheck();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.isServerConnected
                          ? "✅ Server is reachable"
                          : "❌ Server not reachable"),
                    ),
                  );
                },
              );
            },
          ),
          // if (_showSaveIcon) ...[
          if (_showSaveIcon) ...[
            // 🆕 PLUS ICON (Only in Edit Mode)
            if (createQuotationTabKey.currentState?.isEditMode == true)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: "Create New Quotation",
                onPressed: () {
                  final state = createQuotationTabKey.currentState;
                  state?.clearForm();        // 👈 reset form
                  setState(() {});           // 👈 rebuild appbar
                },
              ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: "Save Quotation",
              onPressed: _submitQuotation,
            ),
            // 🆕 Submit icon (visible only if quotation name exists)
            // if (createQuotationTabKey.currentState?.existingQuotationName != null)
            if (createQuotationTabKey.currentState?.isEditMode == true &&
                createQuotationTabKey.currentState?.existingQuotationName != null)

              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.white),
                tooltip: "Submit Quotation",
                onPressed: () async {
                  final quotationState = createQuotationTabKey.currentState;

                  // 🚨 Prevent submitting if there are unsaved changes
                  if (quotationState != null && quotationState.isFormDirty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please save the quotation before submitting.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    return;
                  }

                  final quotationName = quotationState?.existingQuotationName;
                  if (quotationName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save quotation before submitting')),
                    );
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Submission'),
                      content: const Text('Are you sure you want to submit this quotation?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
                    final success = await provider.submitQuotation(quotationName, context);
                    if (success) {
                      quotationState?.clearForm();
                      await quotationListTabKey.currentState?.refreshQuotationList();

                      setState(() {});
                    }
                  }
                },
              ),

          ],
        ],


        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.add_box_outlined), text: "Quotation"),
            Tab(icon: Icon(Icons.list_alt_outlined), text: "Quotation List"),
          ],
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: [
          // 👇 Pass the key to access submit method
          CreateQuotationTab(key: createQuotationTabKey),

          QuotationListTab(key: quotationListTabKey), // 🆕 Pass the key
        ],
      ),
    );
  }
}
