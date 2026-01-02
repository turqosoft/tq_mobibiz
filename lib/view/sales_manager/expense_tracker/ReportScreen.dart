import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

class ReportScreen extends StatefulWidget {
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override

  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SalesOrderProvider>().fetchEEMList();
    });
  }

  String _getDisplayStatus(Map<String, dynamic> eem) {
    final int docstatus = eem["docstatus"] ?? 0;

    if (docstatus == 0) {
      return "Draft";
    }

    if (docstatus == 2) {
      return "Cancelled";
    }

    return eem["expense_claim_status"] ?? "";
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date; // fallback if parsing fails
    }
  }
  final cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];

  Color _statusColor(String status) {
    switch (status) {
      case "Not Created":
        return Colors.grey;

      case "Processing":
        return Colors.blue;

      case "Submitted":
        return Colors.indigo;

      case "Approved":
        return Colors.green;

      case "Draft":
        return Colors.orange;

      case "Paid":
        return Colors.teal;

      case "Rejected":
        return Colors.red;

      case "Cancelled":
        return Colors.brown;

      default:
        return Colors.black;
    }
  }
  Future<void> _openDateFilter(BuildContext context) async {
    final provider = context.read<SalesOrderProvider>();

    DateTime tempFrom = provider.fromDate;
    DateTime tempTo = provider.toDate;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text("From Date"),
                subtitle: Text(_formatDate(
                    DateFormat('yyyy-MM-dd').format(tempFrom))),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempFrom,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) tempFrom = picked;
                },
              ),

              ListTile(
                title: const Text("To Date"),
                subtitle: Text(_formatDate(
                    DateFormat('yyyy-MM-dd').format(tempTo))),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempTo,
                    firstDate: tempFrom,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) tempTo = picked;
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.fetchEEMList(
                      from: tempFrom,
                      to: tempTo,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Apply Filter"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesOrderProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading (ALWAYS visible)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Executive Expense Reports",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () => _openDateFilter(context),
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: Builder(
            builder: (_) {
              if (provider.isLoadingEEM) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.eemList.isEmpty) {
                return const Center(
                  child: Text(
                    "No Expense Reports Found",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.eemList.length,
                itemBuilder: (context, index) {
                  final eem = provider.eemList[index];
                  final status = _getDisplayStatus(eem);

                  // return Card(
                  return InkWell(
                      borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                  await provider.fetchEEMDetails(eem["name"]);
                  _showEEMDetailsDialog(context);
                  },
                  child: Card(
                    color: cardColors[index % cardColors.length],
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Name + Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  eem["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Employee
                          Text(
                            eem["employee_name"],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Date + Amount
                          Row(
                            children: [
                              Text(
                                _formatDate(eem["date"]),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "₹ ${eem["total_expense"]}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _siteVisitTitle(Map? site) {
    final customer = site?["customer"]?.toString().trim();
    final remarks = site?["remarks"]?.toString().trim();

    final isCustomerValid =
        customer != null &&
            customer.isNotEmpty &&
            customer.toLowerCase() != "unknown" &&
            customer.toLowerCase() != "unknown customer";

    if (isCustomerValid) {
      return customer;
    }

    if (remarks != null && remarks.isNotEmpty) {
      return remarks;
    }

    return "Site Visit";
  }

  void _showEEMDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Consumer<SalesOrderProvider>(
          builder: (_, provider, __) {
            if (provider.isLoadingEEMDetails) {
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final data = provider.eemDetails;
            if (data == null) {
              return const AlertDialog(
                content: Text("Failed to load details"),
              );
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              title: const Text(
                "Expense Details",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// SUMMARY CARD
                      _summaryCard(data),

                      const SizedBox(height: 12),

                      /// BASIC INFO
                      _infoTile("Date", _formatDate(data["date"])),
                      _infoTile("Start Time", data["start_time"]),
                      _infoTile("End Time", data["end_time"]),
                      _infoTile(
                        "Distance",
                        data["total_distance"] != null
                            ? "${data["total_distance"]} km"
                            : "-",
                      ),

                      const Divider(),

                      /// EXPENSE BREAKDOWN
                      ExpansionTile(
                        title: const Text(
                          "Expense Breakdown",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        children: (data["employee_expense_tracking"] is List &&
                            data["employee_expense_tracking"].isNotEmpty)
                            ? (data["employee_expense_tracking"] as List)
                            .map<Widget>(
                              (e) => _compactRow(
                            e?["expense_type"] ?? "Unknown",
                            e?["amount"] != null
                                ? "₹ ${e["amount"]}"
                                : "-",
                          ),
                        )
                            .toList()
                            : [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "No expense breakdown available",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                      ),

                      /// SITE VISITS
            //           ExpansionTile(
            //             title: const Text(
            //               "Site Visits",
            //               style: TextStyle(fontWeight: FontWeight.w600),
            //             ),
            //             childrenPadding:
            //             const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //             children: (data["employee_site_tracking"] is List &&
            //                 data["employee_site_tracking"].isNotEmpty)
            //                 ? (data["employee_site_tracking"] as List)
            //                 .map<Widget>(
            //                   (s) => Card(
            //                 elevation: 0,
            //                 margin: const EdgeInsets.only(bottom: 8),
            //
            //                 child: Padding(
            //                   padding: const EdgeInsets.all(8),
            //                   child: Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       // Text(
            //                       //   s?["customer"] ?? "Unknown Customer",
            //                       //   style: const TextStyle(
            //                       //     fontWeight: FontWeight.w600,
            //                       //   ),
            //                       // ),
            //                       Text(
            //                         _siteVisitTitle(s),
            //                         style: const TextStyle(
            //                           fontWeight: FontWeight.w600,
            //                         ),
            //                       ),
            //
            //                       const SizedBox(height: 4),
            //                       _compactRow(
            //                         "Distance",
            //                         s?["distance_travelled"] != null
            //                             ? "${s["distance_travelled"]} km"
            //                             : "-",
            //                       ),
            //                       _compactRow(
            //                         "Actual",
            //                         s?["actual_distance"] != null
            //                             ? "${s["actual_distance"]} km"
            //                             : "-",
            //                       ),
            //                       // if ((s?["remarks"] ?? "").isNotEmpty)
            //                       //   Padding(
            //                       //     padding: const EdgeInsets.only(top: 4),
            //                       //     child: Text(
            //                       //       s["remarks"],
            //                       //       style: const TextStyle(
            //                       //         color: Colors.grey,
            //                       //         fontSize: 12,
            //                       //       ),
            //                       //     ),
            //                       //   ),
            //
            //
            //               if (isCustomerValid && (s?["remarks"] ?? "").isNotEmpty)
            //       Padding(
            //   padding: const EdgeInsets.only(top: 4),
            //   child: Text(
            //     s["remarks"],
            //     style: const TextStyle(
            //       color: Colors.grey,
            //       fontSize: 12,
            //     ),
            //   ),
            // ),
            //
            // ],
            //                   ),
            //                 ),
            //               ),
            //             )
            //                 .toList()
            //                 : [
            //               const Padding(
            //                 padding: EdgeInsets.all(8.0),
            //                 child: Text(
            //                   "No site visits available",
            //                   style: TextStyle(color: Colors.grey),
            //                 ),
            //               )
            //             ],
            //           ),
                      /// SITE VISITS
                      ExpansionTile(
                        title: const Text(
                          "Site Visits",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        children: (data["employee_site_tracking"] is List &&
                            data["employee_site_tracking"].isNotEmpty)
                            ? (data["employee_site_tracking"] as List).map<Widget>((s) {
                          final customer = s?["customer"]?.toString().trim();

                          final isCustomerValid =
                              customer != null &&
                                  customer.isNotEmpty &&
                                  customer.toLowerCase() != "unknown" &&
                                  customer.toLowerCase() != "unknown customer";

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// TITLE: Customer OR Remarks
                                  Text(
                                    _siteVisitTitle(s),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  _compactRow(
                                    "Distance",
                                    s?["distance_travelled"] != null
                                        ? "${s["distance_travelled"]} km"
                                        : "-",
                                  ),
                                  _compactRow(
                                    "Actual",
                                    s?["actual_distance"] != null
                                        ? "${s["actual_distance"]} km"
                                        : "-",
                                  ),

                                  /// Show remarks only if customer is valid
                                  if (isCustomerValid && (s?["remarks"] ?? "").isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        s["remarks"],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList()
                            : const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "No site visits available",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                      ),

                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _summaryCard(Map data) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total Expense",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              data["total_expense"] != null
                  ? "₹ ${data["total_expense"]}"
                  : "-",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _compactRow(
              "Travel",
              data["total_travel_expense"] != null
                  ? "₹ ${data["total_travel_expense"]}"
                  : "-",
            ),
            _compactRow(
              "Other",
              data["total_other_expenses"] != null
                  ? "₹ ${data["total_other_expenses"]}"
                  : "-",
            ),
          ],
        ),
      ),
    );
  }
  Widget _infoTile(String title, String? value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      trailing: Text(value ?? "-", style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _compactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

}
