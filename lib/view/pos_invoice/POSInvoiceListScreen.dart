import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import 'POSInvoiceCreateScreen.dart';

class PosInvoiceListScreen extends StatelessWidget {
  final String userEmail;
  const PosInvoiceListScreen({super.key, required this.userEmail});

  String _formatCurrency(double amount) {
    return "₹ ${amount.toStringAsFixed(2)}";
  }
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return date; // fallback if parsing fails
    }
  }
  // String _formatTime(String? time) {
  //   if (time == null || time.isEmpty) return "";
  //   try {
  //     final parsed = DateTime.parse("1970-01-01 $time"); // dummy date + time
  //     return DateFormat('hh:mm a').format(parsed); // e.g., 02:45 PM
  //   } catch (e) {
  //     return time; // fallback if parsing fails
  //   }
  // }
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return "";
    try {
      // ⏱ Ensure two-digit hours
      final parts = time.split(":");
      if (parts.isNotEmpty && parts[0].length == 1) {
        parts[0] = parts[0].padLeft(2, "0"); // e.g., "9" → "09"
        time = parts.join(":");
      }

      // ⏱ Trim microseconds if present (e.g., "09:44:45.946121" → "09:44:45")
      if (time.contains(".")) {
        time = time.split(".").first;
      }

      final parsed = DateTime.parse("1970-01-01 $time"); // dummy date + time
      return DateFormat('hh:mm a').format(parsed); // e.g., 09:44 AM
    } catch (e) {
      return time ?? ""; // fallback if parsing fails
    }
  }



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "POS Invoice List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: provider.getPosInvoiceList(userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) {
            return const Center(child: Text("No invoices found."));
          }
          // ✅ Calculate sum of grand_total
          final double totalSum = invoices.fold(
            0.0,
                (sum, item) => sum + (item["grand_total"] as num).toDouble(),
          );
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(invoice["name"].toString()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Customer: ${invoice["customer"] ?? "Unknown"}"),
                            Text(
                              "Date: ${_formatDate(invoice["posting_date"])} "
                                  "${_formatTime(invoice["posting_time"])}",
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatCurrency((invoice["grand_total"] as num).toDouble()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PosInvoiceScreen(
                                userEmail: userEmail, // ✅ pass userEmail
                                invoiceName: invoice["name"].toString(),
                                isSubmittedView: true,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // ✅ Bottom Total Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Grand Total:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalSum),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}
