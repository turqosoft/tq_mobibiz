import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

// class CheckinScreen extends StatefulWidget {
//   @override
//   _CheckinDemoScreenState createState() => _CheckinDemoScreenState();
// }
//
// class _CheckinDemoScreenState extends State<CheckinScreen> {
//   late Future<List<dynamic>> _checkinFuture;
//
//   final cardColors = [
//     const Color.fromARGB(255, 205, 227, 225),
//     const Color.fromARGB(255, 205, 213, 221),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//     _checkinFuture = provider.fetchCheckinsAfterEEMStart(context);
//   }
// // Option 1: Format time from DateTime string
//   String formatDateTime(String? timeString) {
//     if (timeString == null) return 'N/A';
//     try {
//       final dateTime = DateTime.parse(timeString);
//       final day = dateTime.day.toString().padLeft(2, '0');
//       final month = dateTime.month.toString().padLeft(2, '0');
//       final year = dateTime.year;
//       final hour = dateTime.hour.toString().padLeft(2, '0');
//       final minute = dateTime.minute.toString().padLeft(2, '0');
//
//       return "$day-$month-$year $hour:$minute";
//     } catch (e) {
//       return timeString;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<dynamic>>(
//       future: _checkinFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         if (snapshot.hasError) {
//           return Center(child: Text("Error loading checkins"));
//         }
//
//         final checkins = snapshot.data ?? [];
//
//         if (checkins.isEmpty) {
//           return Center(child: Text("No employee checkins found"));
//         }
//         return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//         // Heading
//         Padding(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//         child: Row(
//         children: [
//         const Expanded(
//         child: Text(
//         "Employee Checkin/Checkout",
//         style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         ),
//         ),
//         ),
//         ],
//         ),
//         ),
//
//         // const Divider(height: 1),
//
//         // List
//         Expanded(
//         child: ListView.builder(
//
//           itemCount: checkins.length,
//           itemBuilder: (context, index) {
//             final item = checkins[index];
//
//             final logType = item["log_type"];
//             final isIn = logType == "IN";
//             final customer = item["customer"];
//             final remarks = item["remarks"];
//
//             return Card(
//               color: cardColors[index % cardColors.length],
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//               elevation: 1,
//               child: Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Icon(
//                       isIn ? Icons.login : Icons.logout,
//                       color: Colors.blue,
//                       size: 22,
//                     ),
//                     const SizedBox(width: 10),
//
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Checkin: ${item['name']}",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                             ),
//                           ),
//
//                           const SizedBox(height: 4),
//                           Text(
//                             "Employee: ${item['employee_name']}",
//                             style: TextStyle(fontSize: 12),
//                           ),
//
//                           // const SizedBox(height: 4),
//                           if (customer != null && customer.toString().trim().isNotEmpty) ...[
//                             const SizedBox(height: 4),
//                             Text(
//                               "Customer: $customer",
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//
//                           if (remarks != null && remarks.toString().trim().isNotEmpty) ...[
//                             const SizedBox(height: 4),
//                             Text(
//                               "Remarks: $remarks",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade800,
//                               ),
//                             ),
//                           ],
//
//                           // 🕐 Time field added
// // Then use it in the Text widget:
//                           Text(
//                             "Date & Time: ${formatDateTime(item['time'])}",
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade700,
//                             ),
//                           ),
//
//                           const SizedBox(height: 6),
//
//                           // 🔥 Highlighted Log Type Badge
//                           Container(
//                             padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
//                             decoration: BoxDecoration(
//                               color: isIn
//                                   ? Colors.green.shade100
//                                   : Colors.red.shade100,
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: Text(
//                               "Log Type: $logType",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: isIn
//                                     ? Colors.green.shade900
//                                     : Colors.red.shade900,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(height: 6),
//
//                           Text(
//                             "Lat: ${item['latitude']}",
//                             style: TextStyle(fontSize: 12),
//                           ),
//                           Text(
//                             "Long: ${item['longitude']}",
//                             style: TextStyle(fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ))]);
//       },
//     );
//   }
// }

import 'package:geocoding/geocoding.dart';

import '../../../utils/app_colors.dart';

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

  String formatDateTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$day-$month-$year $hour:$minute";
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _checkinFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading checkins"));
        }

        final checkins = snapshot.data ?? [];

        if (checkins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text(
                  "No checkins today",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's Checkin / Checkout",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${checkins.length} record${checkins.length != 1 ? 's' : ''}",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                itemCount: checkins.length,
                itemBuilder: (context, index) {
                  final item = checkins[index];
                  final logType = item["log_type"];
                  final isIn = logType == "IN";
                  final customer = item["customer"];
                  final remarks = item["remarks"];

                  return _CheckinCard(
                    item: Map<String, dynamic>.from(item),
                    isIn: isIn,
                    logType: logType ?? "",
                    customer: customer,
                    remarks: remarks,
                    cardColor: cardColors[index % cardColors.length],
                    formatDateTime: formatDateTime,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Checkin Card Widget ───────────────────────────────────────────────────────

class _CheckinCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isIn;
  final String logType;
  final dynamic customer;
  final dynamic remarks;
  final Color cardColor;
  final String Function(String?) formatDateTime;

  const _CheckinCard({
    required this.item,
    required this.isIn,
    required this.logType,
    required this.customer,
    required this.remarks,
    required this.cardColor,
    required this.formatDateTime,
  });

  @override
  State<_CheckinCard> createState() => _CheckinCardState();
}

class _CheckinCardState extends State<_CheckinCard> {
  String? _placeName;
  bool _isLoadingPlace = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaceName();
  }

  Future<void> _fetchPlaceName() async {
    final lat = double.tryParse(
        widget.item['latitude']?.toString() ?? '');
    final lng = double.tryParse(
        widget.item['longitude']?.toString() ?? '');

    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      if (mounted) {
        setState(() {
          _placeName = null;
          _isLoadingPlace = false;
        });
      }
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s!.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _placeName = parts.isNotEmpty ? parts.join(', ') : null;
            _isLoadingPlace = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      if (mounted) {
        setState(() {
          _placeName = null;
          _isLoadingPlace = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Log type icon ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isIn
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isIn ? Icons.login : Icons.logout,
                color: widget.isIn
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Name + Log type badge in one row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item['name'] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(
                          color: widget.isIn
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.logType,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isIn
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Employee
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.item['employee_name'] ?? "",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ],
                  ),

                  // Date & Time
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.formatDateTime(widget.item['time']),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  // Customer (if present)
                  if (widget.customer != null &&
                      widget.customer.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.customer.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Remarks (if present)
                  if (widget.remarks != null &&
                      widget.remarks.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.remarks.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Place name
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isLoadingPlace
                            ? Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Fetching location...",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          _placeName ?? "Location unavailable",
                          style: TextStyle(
                            fontSize: 12,
                            color: _placeName != null
                                ? Colors.grey.shade800
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}