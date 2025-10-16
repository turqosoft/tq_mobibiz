import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';
import 'POSInvoiceCreateScreen.dart';

class PosOpeningScreen extends StatefulWidget {
  final String userEmail; // Logged in user's email

  const PosOpeningScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<PosOpeningScreen> createState() => _PosOpeningScreenState();
}

class _PosOpeningScreenState extends State<PosOpeningScreen> {
  final Map<String, TextEditingController> _controllers = {}; // controllers for each mode

  late String _periodStartDate;
  late String _periodStartDateDisplay;
  late String _postingDate;
  late String _postingDateDisplay;
  String? _loggedInUserEmail;
  final TextEditingController _cashierController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // ✅ Backend safe formats (don't touch)
    _periodStartDate =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    _postingDate =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // ✅ Display formats (UI only, using intl)
    _periodStartDateDisplay = DateFormat("dd-MM-yyyy, hh:mm:ss").format(now);
    _postingDateDisplay = DateFormat("dd-MM-yyyy").format(now);

    Future.microtask(() async {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      final email = await provider.apiService?.getLoggedInUserIdentifier();
      if (email != null) {
        setState(() {
          _loggedInUserEmail = email;
          _cashierController.text = email;
        });

        await provider.fetchPosProfile();

        if (provider.posProfile == null || provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? "❌ No POS Profile found"),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        } else {
          for (var mode in provider.modesOfPayment) {
            _controllers[mode] = TextEditingController();
          }
          setState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Could not fetch logged-in user email"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    });
  }
  Future<void> _createEntry() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // prepare balances
    final balances = _controllers.entries
        .map((e) => {
      "mode_of_payment": e.key,
      "opening_amount": double.tryParse(e.value.text) ?? 0.0,
    })
        .toList();
    final success = await provider.createPosOpeningEntry(
      balances: balances,
      periodStartDate: _periodStartDate,
    );


    // if (success) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text("✅ POS Opening Entry created successfully"),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    //   Navigator.pop(context);
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(provider.errorMessage ??
    //           "❌ Failed to create POS Opening Entry"),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ POS Opening Entry created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Navigate to POS Invoice screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PosInvoiceScreen(userEmail: '',)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              "❌ Failed to create POS Opening Entry"),
          backgroundColor: Colors.red,
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: CommonAppBar(
            title: "POS Opening Entry",
            automaticallyImplyLeading: true,
            backgroundColor: AppColors.primaryColor,
            onBackTap: () => Navigator.pop(context),
            isAction: false,
          ),
          body: provider.isLoading && provider.posProfile == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header Card (Dates + User + Profile) =====
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Row for Date Fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _periodStartDateDisplay,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.access_time),
                                    labelText: "Period Start Date",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _postingDateDisplay,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.calendar_today),
                                    labelText: "Posting Date",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cashierController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: "Cashier",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // POS Profile
                          TextFormField(
                            initialValue: provider.posProfile?["name"] ?? "",
                            readOnly: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.store),
                              labelText: "POS Profile",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== Opening Balance Card =====
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Opening Balances",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...provider.modesOfPayment.map((mode) {
                            return Padding(
                              padding:
                              const EdgeInsets.only(bottom: 16.0),
                              child: TextField(
                                controller: _controllers[mode],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixIcon:
                                  const Icon(Icons.payments_outlined),
                                  labelText: "Opening Balance ($mode)",
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== Submit Button =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: provider.isLoading ? null : _createEntry,
                      label: const Text(
                        "Create POS Opening Entry",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
