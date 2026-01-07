import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/provider.dart';
import '../../../utils/app_colors.dart';

class ExecutiveReportScreen extends StatefulWidget {
  const ExecutiveReportScreen({super.key});

  @override
  State<ExecutiveReportScreen> createState() => _ExecutiveReportScreenState();
}
//demo change
class _ExecutiveReportScreenState extends State<ExecutiveReportScreen> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  final DateTime today = DateTime.now();
  final DateTime oneYearAgo = DateTime.now().subtract(const Duration(days: 365));


  // @override
  // void initState() {
  //   super.initState();
  //
  //   // load logged user when entering screen
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     Provider.of<SalesOrderProvider>(context, listen: false).loadLoggedUser();
  //   });
  // }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);

      provider.clearData();      // 👈 IMPORTANT
      provider.loadLoggedUser(); // existing logic
    });
  }

  DateTime subtractMonths(DateTime date, int months) {
    final int newMonth = date.month - months;
    final int newYear = date.year + ((newMonth - 1) ~/ 12);
    final int adjustedMonth = ((newMonth - 1) % 12) + 1;

    final int day = date.day;
    final int lastDayOfMonth = DateTime(newYear, adjustedMonth + 1, 0).day;

    return DateTime(newYear, adjustedMonth, day > lastDayOfMonth ? lastDayOfMonth : day);
  }

  Future<void> pickFromDate() async {
    final DateTime today = DateTime.now();
    final DateTime fiveMonthsAgo = subtractMonths(today, 5);

    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: fiveMonthsAgo,   // Limit moved to last 5 months
      lastDate: today,            // Cannot go beyond today
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;

        // Ensure toDate is always >= fromDate
        if (toDate.isBefore(fromDate)) {
          toDate = fromDate;
        }
      });
    }
  }


  Future<void> pickToDate() async {
    final DateTime today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: fromDate,   // To date cannot be earlier than from date
      lastDate: today,       // To date cannot be after today
    );

    if (picked != null) {
      setState(() => toDate = picked);
    }
  }

  String formatForApi(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  String format(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();

    return "$day-$month-$year";
  }
  String formatDouble(dynamic val) {
    if (val == null) return "0.00";

    final numValue = double.tryParse(val.toString());
    if (numValue == null) return val.toString();

    return numValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            leading: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Executive Report",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: "Download Report",
                onPressed: () async {
                  final provider = Provider.of<SalesOrderProvider>(context, listen: false);

                  final html = provider.buildHtmlReport(
                    rows: provider.reportData,
                    columns: provider.reportColumns,
                    totalRow: provider.totalRow,
                  );

                  await provider.downloadAndOpenReportPdf(
                    context: context,
                    html: html,
                  );
                },
              ),
            ],
          ),

          body: Column(
            children: [
              const SizedBox(height: 16),

              // ===== Date Pickers =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: pickFromDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("From: ${format(fromDate)}"),
                    ),
                  ),
                  GestureDetector(
                    onTap: pickToDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("To: ${format(toDate)}"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Fetch Button =====
              ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () {
                  provider.fetchReport(
                    context,
                    formatForApi(fromDate),
                    formatForApi(toDate),
                  );
                },
                child: const Text("Fetch Report"),
              ),

              const SizedBox(height: 12),

              // ===== Main Content =====
              Expanded(
                child: Builder(
                  builder: (_) {
                    // ---------- 1) SHOW LOADER ----------
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // ---------- 2) SHOW EMPTY STATE ----------
                    if (provider.reportData.isEmpty) {
                      return const Center(
                        child: Text(
                          "No report available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    // ---------- 3) SHOW DATA ----------
                    return Column(
                      children: [
                        // ===== List of Rows =====
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.reportData.length,
                            itemBuilder: (_, index) {
                              final row = provider.reportData[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ===== Customer Name =====
                                      Text(
                                        row["customer"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // ===== Total =====
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Total:",
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            formatDouble(row["total"]?.toString() ?? "0"),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // ===== Total Summary Card =====
                        if (provider.totalRow != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "SUMMARY",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Grand Total:"),
                                    Text(formatDouble(provider.totalRow!["total"]?.toString() ?? "0")),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 35),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ===== PDF Loading Overlay =====
        if (provider.pdfLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }


}