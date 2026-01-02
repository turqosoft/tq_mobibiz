import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

class CheckinScreen extends StatefulWidget {
  @override
  _CheckinDemoScreenState createState() => _CheckinDemoScreenState();
}

class _CheckinDemoScreenState extends State<CheckinScreen> {
  late Future<List<dynamic>> _checkinFuture;

  final cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    _checkinFuture = provider.fetchCheckinsAfterEEMStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _checkinFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error loading checkins"));
        }

        final checkins = snapshot.data ?? [];

        if (checkins.isEmpty) {
          return Center(child: Text("No employee checkins found"));
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Heading
        Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
        children: [
        const Expanded(
        child: Text(
        "Employee Checkin/Checkout",
        style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        ),
        ),
        ),
        ],
        ),
        ),

        // const Divider(height: 1),

        // List
        Expanded(
        child: ListView.builder(

          itemCount: checkins.length,
          itemBuilder: (context, index) {
            final item = checkins[index];

            final logType = item["log_type"];
            final isIn = logType == "IN";

            return Card(
              color: cardColors[index % cardColors.length],
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8), // 🔹 Reduced padding
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isIn ? Icons.login : Icons.logout,
                      color: Colors.blue,
                      size: 22, // 🔹 Smaller icon
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Checkin: ${item['name']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13, // 🔹 Smaller text
                            ),
                          ),

                          const SizedBox(height: 4),
                          Text(
                            "Employee: ${item['employee_name']}",
                            style: TextStyle(fontSize: 12),
                          ),
                          // 🔥 Highlighted Log Type Badge (smaller)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isIn
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Log Type: $logType",
                              style: TextStyle(
                                fontSize: 12,
                                color: isIn
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Lat: ${item['latitude']}",
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            "Long: ${item['longitude']}",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

          },
        ))]);
      },
    );
  }
}
