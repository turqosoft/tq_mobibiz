import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import 'executive_report/ExecutiveReportScreen.dart';
import 'expense_tracker/ExpenseTrackerScreen.dart';

class SalesManagerScreen extends StatelessWidget {
  const SalesManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Sales Manager",
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // ---- Graph / Dashboard section ----
            // Expanded(
            //   child: Container(
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       color: Colors.blue.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: const Center(
            //       child: Text(
            //         "Dashboard Graphs & Stats",
            //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            //       ),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Demo Dashboard Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Bar Chart =====
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = ["Jan", "Feb", "Mar", "Apr", "May"];
                                  return Text(months[value.toInt()]);
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                              BarChartRodData(toY: 12, color: Colors.blue)
                            ]),
                            BarChartGroupData(x: 1, barRods: [
                              BarChartRodData(toY: 18, color: Colors.blue)
                            ]),
                            BarChartGroupData(x: 2, barRods: [
                              BarChartRodData(toY: 9, color: Colors.blue)
                            ]),
                            BarChartGroupData(x: 3, barRods: [
                              BarChartRodData(toY: 22, color: Colors.blue)
                            ]),
                            BarChartGroupData(x: 4, barRods: [
                              BarChartRodData(toY: 15, color: Colors.blue)
                            ]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Pie Chart =====
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: 40,
                              title: "Retail",
                              color: Colors.green,
                            ),
                            PieChartSectionData(
                              value: 30,
                              title: "Wholesale",
                              color: Colors.orange,
                            ),
                            PieChartSectionData(
                              value: 30,
                              title: "Online",
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Buttons Row ----
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    // Expense Tracker Button
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.track_changes, size: 36),
                          color: AppColors.primaryColor,
                          tooltip: "Expense Tracker",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpenseTrackerScreen(),
                              ),
                            );
                          },
                        ),
                        const Text("Expense Tracker", style: TextStyle(fontSize: 12)),
                      ],
                    ),

                    // Executive Report Button
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, size: 36),
                          color: AppColors.primaryColor,
                          tooltip: "Executive Report",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExecutiveReportScreen(),
                              ),
                            );
                          },
                        ),
                        const Text("Executive Report", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}