import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../model/customer_list_model.dart';
import '../../../provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/common/common_widgets.dart';
import 'CheckinScreen.dart';
import 'ReportScreen.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';


class ExecutiveTrackerScreen extends StatefulWidget {
  // const ExpenseTrackerScreen({super.key});
  final Map<String, dynamic>? eemData;
  final bool isEditMode;

  const ExecutiveTrackerScreen({
    super.key,
    this.eemData,
    this.isEditMode = false,
  });
  @override
  State<ExecutiveTrackerScreen> createState() => _ExecutiveTrackerScreenState();
}

class _ExecutiveTrackerScreenState extends State<ExecutiveTrackerScreen> {
  int _currentIndex = 2;

  // List<Map<String, TextEditingController>> expenseRows = [];
  List<Map<String, dynamic>> expenseRows = [];

  String? eemName;
  DateTime? eemDate;

  bool _canSave = false;    // Show Save button
  bool _canSubmit = false; // Show Submit button

  DateTime? startTime;
  double? startLat;
  double? startLong;

  DateTime? endTime;
  double? endLat;
  double? endLong;

  // --- Bottom navigation screens ---
  final List<Widget> pages = [];

  List<TextEditingController> distanceControllers = [];

  double? _startOdometer;
  double? _endOdometer;

  @override
  void initState() {
    super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       Provider.of<SalesOrderProvider>(context, listen: false)
//           .fetchTodaySiteVisits();
//       final provider =
//       Provider.of<SalesOrderProvider>(context, listen: false);
//
//       if (widget.isEditMode && widget.eemData != null) {
//         _restoreFromEEM(provider, widget.eemData!);
//       } else {
//         provider.restoreTrackingState(context);
//         _addExpenseRow();
//
//         // ── Restore unsubmitted EEM if exists ──────────────
//         final savedExpenses = await provider.restoreUnsubmittedEEM();
//
//         if (savedExpenses != null) {
//           // ── Always restore odometer regardless of expenses ──
//           final eem = await provider.apiService
//               ?.fetchLatestUnsubmittedEEM(provider.eemEmployee!);
//
//           if (eem != null) {
//             setState(() {
//               // Restore start odometer
// // Restore start odometer
//               final startRaw = eem["start_odometerkm"]?.toString() ?? "";
//               final startParsed = startRaw.isNotEmpty ? double.tryParse(startRaw) : null;
// // Treat 0.0 as not set
//               _startOdometer = (startParsed != null && startParsed > 0) ? startParsed : null;
//
//               // Restore end odometer
// // Restore end odometer
//               final endRaw = eem["end_odometerkm"]?.toString() ?? "";
//               final endParsed = endRaw.isNotEmpty ? double.tryParse(endRaw) : null;
// // Treat 0.0 as not set
//               _endOdometer = (endParsed != null && endParsed > 0) ? endParsed : null;
//             });
//           }
//
//           // ── Restore expense rows if any ─────────────────────
//           if (savedExpenses.isNotEmpty) {
//             setState(() {
//               expenseRows.clear();
//               for (final e in savedExpenses) {
//                 expenseRows.add({
//                   "name": e["name"],
//                   "type": TextEditingController(
//                       text: e["expense_type"] ?? ""),
//                   "amount": TextEditingController(
//                       text: e["amount"]?.toString() ?? ""),
//                   "attachment": e["attachment"],
//                   "attachmentFile": null,
//                 });
//               }
//               // Always keep one empty row at the end
//               expenseRows.add({
//                 "name": null,
//                 "type": TextEditingController(),
//                 "amount": TextEditingController(),
//                 "attachment": null,
//                 "attachmentFile": null,
//               });
//             });
//           }
//         }
//       }
//     });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);

      if (widget.isEditMode && widget.eemData != null) {
        // Edit mode — restore from passed EEM data directly
        // Site visits are restored inside _restoreFromEEM
        _restoreFromEEM(provider, widget.eemData!);
      } else {
        // Normal mode — fetch today's site visits
        provider.fetchTodaySiteVisits();
        provider.restoreTrackingState(context);
        _addExpenseRow();

        final savedExpenses = await provider.restoreUnsubmittedEEM();

        if (savedExpenses != null) {
          final eem = await provider.apiService
              ?.fetchLatestUnsubmittedEEM(provider.eemEmployee!);

          if (eem != null) {
            setState(() {
              final startRaw =
                  eem["start_odometerkm"]?.toString() ?? "";
              final startParsed = startRaw.isNotEmpty
                  ? double.tryParse(startRaw)
                  : null;
              _startOdometer = (startParsed != null && startParsed > 0)
                  ? startParsed
                  : null;

              final endRaw =
                  eem["end_odometerkm"]?.toString() ?? "";
              final endParsed =
              endRaw.isNotEmpty ? double.tryParse(endRaw) : null;
              _endOdometer =
              (endParsed != null && endParsed > 0) ? endParsed : null;
            });
          }

          if (savedExpenses.isNotEmpty) {
            setState(() {
              expenseRows.clear();
              for (final e in savedExpenses) {
                expenseRows.add({
                  "name": e["name"],
                  "type": TextEditingController(
                      text: e["expense_type"] ?? ""),
                  "amount": TextEditingController(
                      text: e["amount"]?.toString() ?? ""),
                  "attachment": e["attachment"],
                  "attachmentFile": null,
                });
              }
              expenseRows.add({
                "name": null,
                "type": TextEditingController(),
                "amount": TextEditingController(),
                "attachment": null,
                "attachmentFile": null,
              });
            });
          }
        }
      }
    });

    pages.addAll([
      _wrapSwipe(ReportScreen(), 0),
      _wrapSwipe(CheckinScreen(), 1),
      const SizedBox(),
    ]);

    _addExpenseRow();
  }
  @override
  void dispose() {
    super.dispose();
  }

  // void _restoreFromEEM(
  //     SalesOrderProvider provider,
  //     Map<String, dynamic> eem,
  //     ) {
  //   /// Store EEM meta
  //   eemName = eem["name"]?.toString();
  //   eemDate = DateTime.tryParse(eem["date"] ?? "");
  //
  //   /// Restore times
  //   startTime = DateTime.tryParse(eem["start_time"] ?? "");
  //   endTime = DateTime.tryParse(eem["end_time"] ?? "");
  //
  //   /// Restore site visits
  //   provider.setSiteVisits(
  //     List<Map<String, dynamic>>.from(
  //       eem["employee_site_tracking"] ?? [],
  //     ),
  //   );
  //
  //   /// Restore expenses
  //   expenseRows.clear();
  //   for (final e in (eem["employee_expense_tracking"] ?? [])) {
  //     expenseRows.add({
  //       "type": TextEditingController(text: e["expense_type"] ?? ""),
  //       "amount": TextEditingController(
  //         text: e["amount"]?.toString() ?? "",
  //       ),
  //       "attachment": e["attachment"], // ✅ Restore attachment URL
  //       "attachmentFile": null, // ✅ No file object when restoring
  //     });
  //   }
  //
  //   if (expenseRows.isEmpty) {
  //     _addExpenseRow();
  //   }
  //
  //   setState(() {
  //     _canSave = true;
  //     _canSubmit = eem["docstatus"] == 0;
  //   });
  // }

  void _restoreFromEEM(
      SalesOrderProvider provider,
      Map<String, dynamic> eem,
      ) {
    /// Store EEM meta
    eemName = eem["name"]?.toString();
    eemDate = DateTime.tryParse(eem["date"] ?? "");

    /// Restore times
    startTime = DateTime.tryParse(eem["start_time"] ?? "");
    endTime = DateTime.tryParse(eem["end_time"] ?? "");

    /// ── Restore odometer ─────────────────────────────────
    final startRaw = eem["start_odometerkm"]?.toString() ?? "";
    final startParsed =
    startRaw.isNotEmpty ? double.tryParse(startRaw) : null;
    _startOdometer =
    (startParsed != null && startParsed > 0) ? startParsed : null;

    final endRaw = eem["end_odometerkm"]?.toString() ?? "";
    final endParsed =
    endRaw.isNotEmpty ? double.tryParse(endRaw) : null;
    _endOdometer =
    (endParsed != null && endParsed > 0) ? endParsed : null;

    /// ── Restore provider EEM state so site visits load correctly ──
    provider.eemDocName = eem["name"];
    provider.eemCreated = true;
    provider.eemEmployee = eem["employee"];
    provider.eemEmployeeName = eem["employee_name"];
    provider.eemDate = eem["date"];

    /// ── Restore site visits from EEM child table ──────────
    final siteRows = eem["employee_site_tracking"];
    if (siteRows is List) {
      provider.setTodaySiteVisitsFromEEM(
        siteRows
            .map((r) => {
          ...Map<String, dynamic>.from(r),
          "_eem_name": eem["name"],
        })
            .toList(),
      );
    }

    /// Restore expenses
    expenseRows.clear();
    for (final e in (eem["employee_expense_tracking"] ?? [])) {
      expenseRows.add({
        "name": e["name"],
        "type": TextEditingController(text: e["expense_type"] ?? ""),
        "amount": TextEditingController(
          text: e["amount"]?.toString() ?? "",
        ),
        "attachment": e["attachment"],
        "attachmentFile": null,
      });
    }

    if (expenseRows.isEmpty) {
      _addExpenseRow();
    }

    setState(() {
      _canSave = true;
      _canSubmit = eem["docstatus"] == 0;
    });
  }

  void _addExpenseRow() {
    setState(() {
      expenseRows.add({
        "name": null, // ERPNext row name
        "type": TextEditingController(),
        "amount": TextEditingController(),
        "attachment": null,
        "attachmentFile": null,
      });
    });
  }

  void _removeExpenseRow(int index) {
    setState(() {
      expenseRows.removeAt(index);
    });
  }
  Future<double?> _showOdometerInputDialog({
    required String title,
    required String hint,
    double? initialValue,
  }) async {
    final controller = TextEditingController(
      text: initialValue?.toString() ?? "",
    );

    return await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.speed, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.speed,
                color: Colors.grey.shade500, size: 18),
            suffixText: "km",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              final value =
              double.tryParse(controller.text.trim());
              if (value == null) {
                Fluttertoast.showToast(
                    msg: "Please enter a valid odometer reading.");
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text("Confirm",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<bool> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "No",
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission permanently denied");
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  List<Map<String, dynamic>> _collectExpenses() {
    List<Map<String, dynamic>> list = [];

    for (var row in expenseRows) {
      final type = row["type"]!.text.trim();
      final amountString = row["amount"]!.text.trim();

      if (type.isEmpty || amountString.isEmpty) continue;

      final amount = double.tryParse(amountString) ?? 0.0;

      list.add({
        "expense_type": type,
        "amount": amount,
        "attachment": row["attachment"], // ✅ Include attachment URL
      });
    }

    return list;
  }
  // ✅ Method to clear all expense data
  void _resetExpenseData() {
    // Dispose all existing controllers
    for (var row in expenseRows) {
      row['expense']?.dispose();
      row['amount']?.dispose();
      row['remarks']?.dispose();
    }

    for (var controller in distanceControllers) {
      controller.dispose();
    }

    // Clear all state
    setState(() {
      expenseRows.clear();
      distanceControllers.clear();
      eemName = null;
      eemDate = null;
      _canSave = false;
      _canSubmit = false;
      startTime = null;
      startLat = null;
      startLong = null;
      endTime = null;
      endLat = null;
      endLong = null;
    });

    // Add fresh row
    _addExpenseRow();
  }

  Future<void> _showCreateSiteVisitDialog({
    Map<String, dynamic>? existingVisit,
  }) async {
    // ── Determine edit vs create mode ──────────────────
    final bool isEditMode = existingVisit != null;
    final String? docName = existingVisit?["name"];

    // ── Pre-fill controllers ────────────────────────────
    final customerController = TextEditingController(
      text: isEditMode ? (existingVisit["customer"] ?? "") : "",
    );
    final siteController = TextEditingController(
      text: isEditMode ? (existingVisit["site"] ?? "") : "",
    );
// ── Distance fields ───────────────────────────────
// actual_distance controller
    final actualDistanceController = TextEditingController(
      text: isEditMode
          ? (existingVisit["actual_distance"]?.toString() ?? "")
          : "",
    );
    // Strip HTML tags from remarks for display
    String rawRemarks = isEditMode
        ? (existingVisit["remarks"] ?? "")
        : "";
    rawRemarks = rawRemarks
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    if (rawRemarks.isEmpty) rawRemarks = "";

    final remarksController = TextEditingController(text: rawRemarks);

// Parse existing date & time if editing
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    if (isEditMode) {
      final timeString = (existingVisit["checkin_time"] ?? "").toString().trim();
      debugPrint("checkin_time from visit: $timeString");

      if (timeString.isNotEmpty) {
        try {
          // Format is "HH:mm:s.microseconds" — split by : and .
          final parts = timeString.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final secondParts = parts[2].split('.');
            final second = int.tryParse(secondParts[0]) ?? 0;

            selectedTime = TimeOfDay(hour: hour, minute: minute);
            // Keep selectedDate as today since only time is stored
            selectedDate = DateTime.now();
          }
        } catch (e) {
          debugPrint("checkin_time parse error: $e");
        }
      }
    }
    Position? fetchedPosition;
    bool isFetchingLocation = !isEditMode; // skip auto-fetch in edit mode
    String locationStatus = isEditMode
        ? (existingVisit["latitude"] != null
        ? "📍 ${existingVisit["latitude"]}, ${existingVisit["longitude"]}"
        : "⚠️ No location saved")
        : "Fetching your location...";
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // Auto-fetch location only in create mode
            if (isFetchingLocation && fetchedPosition == null && !isEditMode) {
              _getCurrentPosition().then((pos) {
                setStateSheet(() {
                  fetchedPosition = pos;
                  isFetchingLocation = false;
                  locationStatus = pos != null
                      ? "📍 ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}"
                      : "⚠️ Could not fetch location";
                });
              });
            }

            final displayDate = DateFormat('dd MMM yyyy').format(selectedDate);
            final apiDate = DateFormat('yyyy-MM-dd').format(selectedDate);
            final apiTime =
                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";
            final displayTime = selectedTime.format(context);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Drag handle ───────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 2),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // ── Header ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEditMode
                                  ? Icons.edit_location_alt
                                  : Icons.add_location_alt,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditMode
                                      ? "Edit Site Visit"
                                      : "Create Site Visit",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  isEditMode
                                      ? docName ?? ""
                                      : "Fill in the details below",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // ── Date chip ─────────────────────────────
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: ColorScheme.light(
                                        primary: AppColors.primaryColor),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setStateSheet(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                AppColors.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_calendar_outlined,
                                      size: 13,
                                      color: AppColors.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Divider(height: 1, thickness: 0.8),
                    ),

                    // ── Scrollable form ───────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            if (isEditMode) ...[
                                  () {
                                final double? lat = double.tryParse(
                                    existingVisit["latitude"]?.toString() ?? "");
                                final double? lng = double.tryParse(
                                    existingVisit["longitude"]?.toString() ?? "");

                                if (lat == null || lng == null || (lat == 0 && lng == 0)) {
                                  // No valid coordinates — show plain grey card
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_off,
                                            size: 16, color: Colors.grey.shade400),
                                        const SizedBox(width: 8),
                                        Text(
                                          "No location saved",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Valid coordinates — show map snippet
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        height: 140,
                                        child: FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(lat, lng),
                                            initialZoom: 15,
                                            // interactionOptions: const InteractionOptions(
                                            //   flags: InteractiveFlag.none, // fully locked, no gestures
                                            // ),
                                            interactionOptions: const InteractionOptions(
                                              flags: InteractiveFlag.pinchZoom |
                                              InteractiveFlag.scrollWheelZoom |
                                              InteractiveFlag.doubleTapZoom,
                                            ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                              userAgentPackageName: 'com.example.sales_ordering_app',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(lat, lng),
                                                  width: 36,
                                                  height: 36,
                                                  child: Icon(
                                                    Icons.location_pin,
                                                    color: AppColors.primaryColor,
                                                    size: 36,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ── "Location locked" badge overlaid top-right ──
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.lock_outline,
                                                  size: 11, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                "Location locked",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // ── Coordinates badge overlaid bottom-left ──────
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }(),
                            ] else ...[
                              // Live fetch card in create mode
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: fetchedPosition != null
                                      ? Colors.green.shade50
                                      : isFetchingLocation
                                      ? Colors.blue.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: fetchedPosition != null
                                        ? Colors.green.shade200
                                        : isFetchingLocation
                                        ? Colors.blue.shade200
                                        : Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (isFetchingLocation)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blue.shade600),
                                        ),
                                      )
                                    else
                                      Icon(
                                        fetchedPosition != null
                                            ? Icons.my_location
                                            : Icons.location_off,
                                        size: 16,
                                        color: fetchedPosition != null
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        locationStatus,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: fetchedPosition != null
                                              ? Colors.green.shade800
                                              : isFetchingLocation
                                              ? Colors.blue.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                    // Retry button if location failed
                                    if (!isFetchingLocation && fetchedPosition == null)
                                      GestureDetector(
                                        onTap: () {
                                          setStateSheet(() {
                                            isFetchingLocation = true;
                                            locationStatus = "Fetching your location...";
                                            fetchedPosition = null;
                                          });
                                        },
                                        child: Icon(Icons.refresh,
                                            size: 18, color: Colors.red.shade700),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // ── Customer search ───────────────────────
                            _buildCompactLabel("Customer "),
                            const SizedBox(height: 5),
                            _CustomerSearchField(
                              initialValue: isEditMode
                                  ? (existingVisit["customer"] ?? "")
                                  : "",
                              onSelected: (name) {
                                customerController.text = name;
                              },
                            ),
                            const SizedBox(height: 12),

                            // ── Site ──────────────────────────────────
                            _buildCompactLabel("Site "),
                            const SizedBox(height: 5),
                            _buildInputField(
                              controller: siteController,
                              hint: "Enter site name",
                              icon: Icons.map_outlined,
                            ),
                            const SizedBox(height: 12),

                            // ── Remarks ───────────────────────────────
                            _buildCompactLabel("Remarks (Optional)"),
                            const SizedBox(height: 5),
                            _buildInputField(
                              controller: remarksController,
                              hint: "Add a note...",
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
// ── Distance Travelled (read-only, edit mode only) ─
                            if (isEditMode) ...[
                              const SizedBox(height: 12),
                              _buildCompactLabel("Distance Travelled"),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.route,
                                        size: 18, color: Colors.grey.shade500),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${existingVisit["distance_travelled"] ?? "0"} km",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Auto",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

// ── Actual Distance (editable) ────────────────────
                            const SizedBox(height: 12),
                            _buildCompactLabel(
                                isEditMode ? "Actual Distance" : "Actual Distance (optional)"),
                            const SizedBox(height: 5),
                            _buildInputField(
                              controller: actualDistanceController,
                              hint: "Enter actual distance",
                              icon: Icons.straighten_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              suffixText: "km",
                              selectAllOnFocus: true,   // ← add this
                            ),
                            // ── Time picker ───────────────────────────
                            _buildCompactLabel("Time"),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: ColorScheme.light(
                                          primary: AppColors.primaryColor),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setStateSheet(() => selectedTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 18,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 10),
                                    Text(
                                      displayTime,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.edit_outlined,
                                        size: 15,
                                        color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Action buttons ────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(sheetContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10)),
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: const Text("Cancel",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: StatefulBuilder(
                                    builder: (btnCtx, setBtnState) {
                                      return ElevatedButton(

                                        onPressed: isSubmitting
                                            ? null
                                            : () async {

                                          // ── Validation: at least one of customer or site required ──
                                          final customerEmpty = customerController.text.trim().isEmpty;
                                          final siteEmpty = siteController.text.trim().isEmpty;

                                          if (customerEmpty && siteEmpty) {
                                            Fluttertoast.showToast(
                                              msg: "Please enter at least a Customer or Site.",
                                              toastLength: Toast.LENGTH_LONG,
                                              backgroundColor: Colors.red.shade600,
                                              textColor: Colors.white,
                                            );
                                            return;
                                          }

                                          // ── Location check (create mode only) ──────────
                                          if (!isEditMode && fetchedPosition == null) {
                                            Fluttertoast.showToast(
                                                msg: "Location unavailable. Tap retry.");
                                            return;
                                          }

                                          setBtnState(() => isSubmitting = true);

                                          // rest of your existing code unchanged from here...
                                          Position? finalPos;
                                          if (isEditMode && fetchedPosition == null) {
                                            finalPos = null;
                                          } else {
                                            finalPos = await _getCurrentPosition() ?? fetchedPosition;
                                          }


                                          // Replace the finalLat/finalLng calculation with:
                                          final double finalLat = isEditMode
                                              ? (double.tryParse(
                                              existingVisit?["latitude"]?.toString() ?? "0") ??
                                              0.0)
                                              : (finalPos?.latitude ?? 0.0);

                                          final double finalLng = isEditMode
                                              ? (double.tryParse(
                                              existingVisit?["longitude"]?.toString() ?? "0") ??
                                              0.0)
                                              : (finalPos?.longitude ?? 0.0);

                                          final provider =
                                          Provider.of<SalesOrderProvider>(context, listen: false);

                                          bool success;

                                          // ── In the submit onPressed, replace the createSiteVisit / updateSiteVisit calls ──

                                          if (isEditMode) {
                                            success = await provider.updateSiteVisit(
                                              docName: docName!,           // child row name
                                              customer: customerController.text.trim(),
                                              site: siteController.text.trim(),
                                              latitude: finalLat,
                                              longitude: finalLng,
                                              remarks: remarksController.text.trim().isEmpty
                                                  ? ""
                                                  : remarksController.text.trim(),
                                              time: "$apiDate $apiTime",   // kept for signature compat
                                              actualDistance: double.tryParse(        // ← add this
                                                  actualDistanceController.text.trim()),
                                            );
                                          } else {
                                            success = await provider.createSiteVisit(
                                              context: context,
                                              customer: customerController.text.trim(),
                                              site: siteController.text.trim(),
                                              latitude: finalLat,
                                              longitude: finalLng,
                                              remarks: remarksController.text.trim().isEmpty
                                                  ? ""
                                                  : remarksController.text.trim(),
                                              time: "$apiDate $apiTime",
                                              actualDistance: double.tryParse(        // ← add this
                                                  actualDistanceController.text.trim()),
                                            );
                                          }

                                          setBtnState(() => isSubmitting = false);
                                          Navigator.of(sheetContext).pop();
                                          Fluttertoast.showToast(
                                            msg: success
                                                ? isEditMode
                                                ? "Site Visit updated successfully!"
                                                : "Site Visit created successfully!"
                                                : isEditMode
                                                ? "Failed to update Site Visit"
                                                : "Failed to create Site Visit",
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          AppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        child: isSubmitting
                                            ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                            : Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isEditMode
                                                  ? Icons.save_outlined
                                                  : Icons.check_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isEditMode
                                                  ? "Update"
                                                  : "Submit",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildCompactLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.2,
      ),
    );
  }

  // Widget _buildInputField({
  //   required TextEditingController controller,
  //   required String hint,
  //   required IconData icon,
  //   TextInputType keyboardType = TextInputType.text,
  //   int maxLines = 1,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: TextField(
  //       controller: controller,
  //       keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType, // ✅ multiline keyboard
  //       maxLines: null,        // ✅ unlimited lines — grows with content
  //       minLines: maxLines,    // ✅ starts at the specified height
  //       textInputAction: maxLines > 1
  //           ? TextInputAction.newline  // ✅ Enter key adds new line instead of submitting
  //           : TextInputAction.done,
  //       style: const TextStyle(fontSize: 13),
  //       decoration: InputDecoration(
  //         hintText: hint,
  //         hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
  //         prefixIcon: Padding(
  //           padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20 : 0), // ✅ align icon to top for multiline
  //           child: Icon(icon, size: 18, color: Colors.grey[500]),
  //         ),
  //         border: InputBorder.none,
  //         contentPadding:
  //         const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? suffixText,
    bool selectAllOnFocus = false,  // ← add this
  }) {
    final focusNode = selectAllOnFocus ? FocusNode() : null;

    if (focusNode != null) {
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        maxLines: null,
        minLines: maxLines,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.done,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
                bottom: maxLines > 1 ? (maxLines - 1) * 20 : 0),
            child: Icon(icon, size: 18, color: Colors.grey[500]),
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesOrderProvider>();

    return Scaffold(
      appBar: CommonAppBar(
        title: "Visit Log",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        actions: Consumer<SalesOrderProvider>(
          builder: (context, provider, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Save icon ───────────────────────────────────
                IconButton(
                  tooltip: provider.eemCreated ? "Update Expenses" : "Save Expenses",
                  onPressed: provider.isEEMSaveLoading || provider.isEEMSubmitLoading
                      ? null
                      : () async {
                    // ── Check in validation ───────────────────────
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                    );

                    final canSave = await provider.canCreateSiteVisit();

                    if (mounted)
                      Navigator.of(context, rootNavigator: true).pop();

                    if (!canSave) {
                      Fluttertoast.showToast(
                        msg: "Please check in today before saving.",
                        toastLength: Toast.LENGTH_LONG,
                        backgroundColor: Colors.red.shade600,
                        textColor: Colors.white,
                      );
                      return;
                    }

                    // ── Start odometer validation ─────────────────
                    final startOdometer = _startOdometer;
                    if (startOdometer == null) {
                      Fluttertoast.showToast(
                        msg: "Please enter start odometer reading before saving.",
                        toastLength: Toast.LENGTH_LONG,
                        backgroundColor: Colors.red.shade600,
                        textColor: Colors.white,
                      );
                      return;
                    }

                    // ── Proceed with save ─────────────────────────
                    final expenses = _collectExpenses();

                    if (!provider.eemCreated) {
                      final pos = await _getCurrentPosition();
                      final ok = await provider.saveEEMExpenses(
                        expenses,
                        startOdometer: startOdometer,
                        endOdometer: _endOdometer,
                        startLat: pos?.latitude,
                        startLong: pos?.longitude,
                      );
                      Fluttertoast.showToast(
                        msg: ok
                            ? "Expenses saved successfully!"
                            : "Failed to save expenses.",
                      );
                    } else {
                      final ok = await provider.saveEEMExpenses(
                        expenses,
                        startOdometer: startOdometer,
                        endOdometer: _endOdometer
                      );
                      Fluttertoast.showToast(
                        msg: ok
                            ? "Expenses saved successfully!"
                            : "Failed to save expenses.",
                      );
                    }
                  },
                  icon: provider.isEEMSaveLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(
                    provider.eemCreated
                        ? Icons.save_rounded
                        : Icons.save_outlined,
                    color: Colors.white,
                  ),
                ),

                // ── Submit icon — only after save ───────────────
                if (provider.eemCreated)
                  IconButton(
                    tooltip: "Submit Expenses",

                    // onPressed: provider.isEEMSubmitLoading || provider.isEEMSaveLoading
                    //     ? null
                    //     : () async {
                    //   // ── Checkout validation ───────────────────────
                    //   showDialog(
                    //     context: context,
                    //     barrierDismissible: false,
                    //     builder: (_) =>
                    //     const Center(child: CircularProgressIndicator()),
                    //   );
                    //
                    //   final canStop = await provider.canStopTracking();
                    //
                    //   if (mounted)
                    //     Navigator.of(context, rootNavigator: true).pop();
                    //
                    //   if (!canStop) {
                    //     Fluttertoast.showToast(
                    //       msg: "Please checkout before submitting.",
                    //       toastLength: Toast.LENGTH_LONG,
                    //       backgroundColor: Colors.red.shade600,
                    //       textColor: Colors.white,
                    //     );
                    //     return;
                    //   }
                    //
                    //   // ── End odometer validation ───────────────────
                    //   final endOdometer = _endOdometer;
                    //   if (endOdometer == null) {
                    //     Fluttertoast.showToast(
                    //       msg: "Please enter end odometer reading before submitting.",
                    //       toastLength: Toast.LENGTH_LONG,
                    //       backgroundColor: Colors.red.shade600,
                    //       textColor: Colors.white,
                    //     );
                    //     return;
                    //   }
                    //
                    //   // ── Start odometer sanity check ───────────────
                    //   final startOdometer = _startOdometer;
                    //   if (startOdometer != null && endOdometer <= startOdometer) {
                    //     Fluttertoast.showToast(
                    //       msg: "End odometer must be greater than start odometer.",
                    //       toastLength: Toast.LENGTH_LONG,
                    //       backgroundColor: Colors.red.shade600,
                    //       textColor: Colors.white,
                    //     );
                    //     return;
                    //   }
                    //
                    //   // ── Confirm dialog ────────────────────────────
                    //   final confirm = await _showConfirmDialog(
                    //     context: context,
                    //     title: "Submit Expenses",
                    //     message:
                    //     "Once submitted, this cannot be edited.\n\nDo you want to continue?",
                    //     confirmText: "Submit",
                    //     cancelText: "Cancel",
                    //   );
                    //   if (!confirm) return;
                    //
                    //   final expenses = _collectExpenses();
                    //   final ok = await provider.submitEEMExpenses(
                    //     expenses,
                    //     startOdometer: startOdometer,
                    //     endOdometer: endOdometer,
                    //   );
                    //
                    //   if (ok) {
                    //     setState(() {
                    //       expenseRows.clear();
                    //       _addExpenseRow();
                    //       _startOdometer = null;
                    //       _endOdometer = null;
                    //     });
                    //     Fluttertoast.showToast(
                    //         msg: "Expenses submitted successfully!");
                    //   } else {
                    //     Fluttertoast.showToast(msg: "Failed to submit expenses.");
                    //   }
                    // },
                    onPressed: provider.isEEMSubmitLoading || provider.isEEMSaveLoading
                        ? null
                        : () async {
                      // ── Checkout validation (only for today's EEM) ────
                      final eemDateStr = provider.eemDate ?? "";
                      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final isToday = eemDateStr == today;

                      if (isToday) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                        );

                        final canStop = await provider.canStopTracking();

                        if (mounted)
                          Navigator.of(context, rootNavigator: true).pop();

                        if (!canStop) {
                          Fluttertoast.showToast(
                            msg: "Please checkout before submitting.",
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.red.shade600,
                            textColor: Colors.white,
                          );
                          return;
                        }
                      }

                      // ── End odometer validation ───────────────────────
                      if (_endOdometer == null) {
                        Fluttertoast.showToast(
                          msg: "Please enter end odometer reading before submitting.",
                          toastLength: Toast.LENGTH_LONG,
                          backgroundColor: Colors.red.shade600,
                          textColor: Colors.white,
                        );
                        return;
                      }

                      // ── Start odometer sanity check ───────────────────
                      if (_startOdometer != null && _endOdometer! <= _startOdometer!) {
                        Fluttertoast.showToast(
                          msg: "End odometer must be greater than start odometer.",
                          toastLength: Toast.LENGTH_LONG,
                          backgroundColor: Colors.red.shade600,
                          textColor: Colors.white,
                        );
                        return;
                      }

                      // ── Confirm dialog ────────────────────────────────
                      final confirm = await _showConfirmDialog(
                        context: context,
                        title: "Submit Expenses",
                        message:
                        "Once submitted, this cannot be edited.\n\nDo you want to continue?",
                        confirmText: "Submit",
                        cancelText: "Cancel",
                      );
                      if (!confirm) return;

                      final expenses = _collectExpenses();
                      final ok = await provider.submitEEMExpenses(
                        expenses,
                        startOdometer: _startOdometer,
                        endOdometer: _endOdometer,
                      );

                      if (ok) {
                        setState(() {
                          expenseRows.clear();
                          _addExpenseRow();
                          _startOdometer = null;
                          _endOdometer = null;
                        });
                        Fluttertoast.showToast(msg: "Expenses submitted successfully!");
                      } else {
                        Fluttertoast.showToast(msg: "Failed to submit expenses.");
                      }
                    },
                    icon: provider.isEEMSubmitLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                    ),
                  ),

                // ── Create Site Visit ───────────────────────────
                IconButton(
                  icon: const Icon(Icons.add_location_alt, color: Colors.white),
                  tooltip: "Create Site Visit",
                  onPressed: () async {
                    final provider =
                    Provider.of<SalesOrderProvider>(context, listen: false);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                    );

                    final canCreate = await provider.canCreateSiteVisit();

                    if (mounted)
                      Navigator.of(context, rootNavigator: true).pop();

                    if (!canCreate) {
                      Fluttertoast.showToast(
                        msg:
                        "Please check in today before creating a site visit.",
                        toastLength: Toast.LENGTH_LONG,
                        backgroundColor: Colors.red.shade600,
                        textColor: Colors.white,
                      );
                      return;
                    }

                    _showCreateSiteVisitDialog();
                  },
                ),
              ],
            );
          },
        ),
      ),

      // --- MAIN BODY ---
      body: (_currentIndex == 0 || _currentIndex == 1)
          ? pages[_currentIndex]
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          double velocity = details.primaryVelocity ?? 0;
          // Visit Log → Swipe Right → Report
          if (velocity > 0) setState(() => _currentIndex = 0);
          // Visit Log → Swipe Left → Checkin Log
          if (velocity < 0) setState(() => _currentIndex = 1);
        },
        child: _buildExpenseTrackerMainUI(),
      ),

      // ---- BOTTOM NAVIGATION ----
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bottomNavItem(Icons.receipt_long, "Visits Report", 0),
              _bottomNavItem(Icons.location_on_outlined, "Visit Log", 2),
              _bottomNavItem(Icons.person, "Checkin Log", 1),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Widget _buildExpenseTrackerMainUI() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Odometer Section ──────────────────────────────────────────
          Consumer<SalesOrderProvider>(
            builder: (context, provider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: AppColors.primaryColor),
                        const SizedBox(width: 6),
                        const Text(
                          "Odometer Readings",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [

                        // ── Start chip (shown after start is set) ──
                        if (_startOdometer != null) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final value = await _showOdometerInputDialog(
                                  title: "Edit Start Odometer",
                                  hint: "e.g. 12500",
                                  initialValue: _startOdometer,
                                );
                                if (value != null) {
                                  setState(() => _startOdometer = value);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.trip_origin,
                                        size: 14, color: Colors.green.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Start",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "${_startOdometer!.toStringAsFixed(0)} km",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.edit_outlined,
                                        size: 13, color: Colors.green.shade400),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward,
                              size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 10),
                        ],

                        // ── End chip (shown after end is set) ──────
                        if (_endOdometer != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final value = await _showOdometerInputDialog(
                                  title: "Edit End Odometer",
                                  hint: "e.g. 12800",
                                  initialValue: _endOdometer,
                                );
                                if (value != null) {
                                  if (_startOdometer != null &&
                                      value <= _startOdometer!) {
                                    Fluttertoast.showToast(
                                      msg: "End must be greater than start odometer.",
                                      backgroundColor: Colors.red.shade600,
                                      textColor: Colors.white,
                                    );
                                    return;
                                  }
                                  setState(() => _endOdometer = value);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                  Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.outlined_flag,
                                        size: 14, color: Colors.orange.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Finish",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "${_endOdometer!.toStringAsFixed(0)} km",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.edit_outlined,
                                        size: 13, color: Colors.orange.shade400),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // ── Single Start/End button ─────────────────
                        if (_endOdometer == null)
                          Expanded(
                            child: ElevatedButton.icon(
                              // onPressed: provider.isEEMSaveLoading
                              //     ? null
                              //     : () async {
                              onPressed: (provider.isEEMSaveLoading || provider.isEEMEndLoading)
                                  ? null
                                  : () async {
                                final isStart = _startOdometer == null;

                                // ── Check in validation ───────
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );
                                final canProceed =
                                await provider.canCreateSiteVisit();
                                if (mounted)
                                  Navigator.of(context,
                                      rootNavigator: true)
                                      .pop();

                                if (!canProceed) {
                                  Fluttertoast.showToast(
                                    msg: isStart
                                        ? "Please check in today before starting."
                                        : "Please check out before ending.",
                                    toastLength: Toast.LENGTH_LONG,
                                    backgroundColor: Colors.red.shade600,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }

                                // ── Odometer input ────────────
                                final value = await _showOdometerInputDialog(
                                  title: isStart
                                      ? "Start Odometer"
                                      : "End Odometer",
                                  hint: isStart
                                      ? "e.g. 12500"
                                      : "e.g. 12800",
                                  initialValue: isStart
                                      ? null
                                      : _startOdometer,
                                );

                                if (value == null) return;

                                if (!isStart && _startOdometer != null &&
                                    value <= _startOdometer!) {
                                  Fluttertoast.showToast(
                                    msg: "End must be greater than start odometer.",
                                    backgroundColor: Colors.red.shade600,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }

                                if (isStart) {
                                  setState(() => _startOdometer = value);

                                  // ── Create EEM on Start ───────
                                  final pos = await _getCurrentPosition();
                                  final expenses = _collectExpenses();
                                  final ok = await provider.saveEEMExpenses(
                                    expenses,
                                    startOdometer: value,
                                    startLat: pos?.latitude,
                                    startLong: pos?.longitude,
                                  );

                                  Fluttertoast.showToast(
                                    msg: ok
                                        ? "Started successfully!"
                                        : "Failed to start. Please try again.",
                                    backgroundColor: ok
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                    textColor: Colors.white,
                                  );

                                  if (!ok) {
                                    setState(() => _startOdometer = null);
                                  }
                                // } else {
                                //   setState(() => _endOdometer = value);
                                // }
                                } else {
                                  // ── End odometer confirmed ────────────────────
                                  // Fetch current location
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                        child: CircularProgressIndicator()),
                                  );

                                  final pos = await _getCurrentPosition();

                                  if (mounted)
                                    Navigator.of(context, rootNavigator: true).pop();

                                  if (pos == null) {
                                    Fluttertoast.showToast(
                                      msg: "Could not fetch location. Please try again.",
                                      backgroundColor: Colors.red.shade600,
                                      textColor: Colors.white,
                                    );
                                    return;
                                  }

                                  final ok = await provider.updateEEMEnd(
                                    endOdometer: value,
                                    endLat: pos.latitude,
                                    endLong: pos.longitude,
                                  );

                                  if (ok) {
                                    setState(() => _endOdometer = value);
                                    Fluttertoast.showToast(
                                      msg: "End recorded successfully!",
                                      backgroundColor: Colors.green.shade600,
                                      textColor: Colors.white,
                                    );
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Failed to record end. Please try again.",
                                      backgroundColor: Colors.red.shade600,
                                      textColor: Colors.white,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _startOdometer == null
                                    ? AppColors.primaryColor
                                    : Colors.orange.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              // icon: provider.isEEMSaveLoading
                              //     ? const SizedBox(
                              //   width: 16,
                              //   height: 16,
                              //   child: CircularProgressIndicator(
                              //       strokeWidth: 2, color: Colors.white),
                              // )
                              //     : Icon(
                              //   _startOdometer == null
                              //       ? Icons.trip_origin
                              //       : Icons.outlined_flag,
                              //   size: 16,
                              //   color: Colors.white,
                              // ),
                              icon: (provider.isEEMSaveLoading || provider.isEEMEndLoading)
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                                  : Icon(
                                _startOdometer == null
                                    ? Icons.trip_origin
                                    : Icons.outlined_flag,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                _startOdometer == null ? "Start" : "End",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ── Total distance ──────────────────────────────
                    if (_startOdometer != null && _endOdometer != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.route, size: 13, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            "Total: ${(_endOdometer! - _startOdometer!).toStringAsFixed(1)} km",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          /// SITE VISITS HEADER
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Site Visits",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  // ── Count badge ──────────────────────────────
                  Consumer<SalesOrderProvider>(
                    builder: (context, provider, _) {
                      final count = provider.todaySiteVisits.length;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$count",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Refresh button — existing code unchanged
                  Consumer<SalesOrderProvider>(
                    builder: (context, provider, _) =>
                    provider.isSiteVisitsLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      icon: Icon(Icons.refresh,
                          size: 20, color: AppColors.primaryColor),
                      onPressed: () => provider.fetchTodaySiteVisits(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  if (widget.isEditMode && eemDate != null)
                    Text(
                      _formatDate(eemDate!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (widget.isEditMode && eemName != null) ...[
                const SizedBox(height: 4),
                Text(
                  eemName!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ✅ THIS BLOCK WAS MISSING — add it back
          Expanded(
            flex: 6,
            child: Consumer<SalesOrderProvider>(
              builder: (context, provider, _) {
                if (provider.isSiteVisitsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.todaySiteVisits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        const Text(
                          "No site visits today",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.todaySiteVisits.length,
                  itemBuilder: (context, index) =>
                      _todaySiteVisitCard(provider.todaySiteVisits[index]),
                );
              },
            ),
          ),

          // ── Other Expense divider ─────────────────────────────────────────────

          const SizedBox(height: 15),
          Row(
            children: [

              Expanded(
                  child: Divider(thickness: 1, color: Colors.grey.shade400)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("Expenses",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                  child: Divider(thickness: 1, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 8),

// ── Expense rows ──────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: expenseRows.length,
              itemBuilder: (context, index) => _expenseRow(index),
            ),
          ),

          const SizedBox(height: 4),

// ── Add row + Save/Submit icons in one compact row ────────────────────
          Consumer<SalesOrderProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  // Add row button
                  IconButton(
                    icon: Icon(Icons.add_circle,
                        color: AppColors.primaryColor, size: 28),
                    onPressed: _addExpenseRow,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Widget _todaySiteVisitCard(Map<String, dynamic> visit) {
  //   final customer =
  //       visit["customer"]?.toString().trim() ?? "";
  //   final site = visit["site"]?.toString().trim() ??
  //       visit["site_lat"]?.toString() ??
  //       "";
  //   final eemName = visit["_eem_name"] ??
  //       Provider.of<SalesOrderProvider>(context, listen: false).eemDocName ??
  //       "";
  //   // ── Actual distance ─────────────────────────────
  //   final actualDistance =
  //       visit["actual_distance"]?.toString().trim() ?? "";
  //   final distanceTravelled =
  //       visit["distance_travelled"]?.toString().trim() ?? "";
  //   // ── Parse checkin_time ──────────────────────────────
  //   String displayTime = "";
  //   try {
  //     final rawTime = visit["checkin_time"]?.toString().trim() ?? "";
  //     if (rawTime.isNotEmpty) {
  //       final parsed = DateFormat('yyyy-MM-dd HH:mm:ss').parse(rawTime);
  //       displayTime = DateFormat('hh:mm a').format(parsed);
  //     }
  //   } catch (_) {}
  //   // Format lat/long as location display
  //   final double? lat = double.tryParse(
  //       visit["site_lat"]?.toString() ?? "");
  //   final double? lng = double.tryParse(
  //       visit["site_long"]?.toString() ?? "");
  //
  //   return InkWell(
  //     onTap: () => _showCreateSiteVisitDialog(existingVisit: {
  //       ...visit,
  //       // Map child table fields to dialog expected fields
  //       "latitude": lat,
  //       "longitude": lng,
  //       "name": visit["name"],
  //       "checkin_time": visit["checkin_time"],
  //     }),
  //     borderRadius: BorderRadius.circular(10),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
  //       margin: const EdgeInsets.symmetric(vertical: 5),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border.all(color: Colors.grey.shade200),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.04),
  //             blurRadius: 6,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           // Icon
  //           Container(
  //             width: 36,
  //             height: 36,
  //             decoration: BoxDecoration(
  //               color: AppColors.primaryColor.withOpacity(0.1),
  //               shape: BoxShape.circle,
  //             ),
  //             child: Icon(Icons.location_on,
  //                 color: AppColors.primaryColor, size: 18),
  //           ),
  //           const SizedBox(width: 12),
  //
  //           // Customer + Site
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   customer.isNotEmpty ? customer : site,
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                   style: const TextStyle(
  //                     fontWeight: FontWeight.w600,
  //                     fontSize: 13,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 if (customer.isNotEmpty && site.isNotEmpty) ...[
  //                   const SizedBox(height: 3),
  //                   Row(
  //                     children: [
  //                       Icon(Icons.map_outlined,
  //                           size: 11, color: Colors.grey.shade500),
  //                       const SizedBox(width: 4),
  //                       Expanded(
  //                         child: Text(
  //                           site,
  //                           maxLines: 1,
  //                           overflow: TextOverflow.ellipsis,
  //                           style: TextStyle(
  //                             fontSize: 11,
  //                             color: Colors.grey.shade600,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ],
  //
  //             ),
  //           ),
  //
  //           const SizedBox(width: 8),
  //
  //           // Delete icon
  //           // GestureDetector(
  //           //   onTap: () async {
  //           //     final rowName = visit["name"];
  //           //     if (rowName == null) return;
  //           //
  //           //     final confirm = await showDialog<bool>(
  //           //       context: context,
  //           //       builder: (ctx) => AlertDialog(
  //           //         shape: RoundedRectangleBorder(
  //           //             borderRadius: BorderRadius.circular(14)),
  //           //         title: const Text("Delete Site Visit"),
  //           //         content: Text(
  //           //           "Are you sure you want to delete this site visit"
  //           //               "${customer.isNotEmpty ? ' for $customer' : ''}?",
  //           //         ),
  //           //         actions: [
  //           //           TextButton(
  //           //             onPressed: () => Navigator.pop(ctx, false),
  //           //             child: const Text("Cancel"),
  //           //           ),
  //           //           ElevatedButton(
  //           //             style: ElevatedButton.styleFrom(
  //           //               backgroundColor: Colors.red,
  //           //               shape: RoundedRectangleBorder(
  //           //                   borderRadius: BorderRadius.circular(8)),
  //           //             ),
  //           //             onPressed: () => Navigator.pop(ctx, true),
  //           //             child: const Text("Delete",
  //           //                 style: TextStyle(color: Colors.white)),
  //           //           ),
  //           //         ],
  //           //       ),
  //           //     );
  //           //
  //           //     if (confirm != true) return;
  //           //
  //           //     final provider = Provider.of<SalesOrderProvider>(
  //           //         context,
  //           //         listen: false);
  //           //     final success =
  //           //     await provider.deleteSiteVisit(rowName);
  //           //     Fluttertoast.showToast(
  //           //       msg: success
  //           //           ? "Site Visit deleted successfully!"
  //           //           : "Failed to delete Site Visit.",
  //           //     );
  //           //   },
  //           //   child: Container(
  //           //     padding: const EdgeInsets.all(6),
  //           //     decoration: BoxDecoration(
  //           //       color: Colors.red.shade50,
  //           //       borderRadius: BorderRadius.circular(8),
  //           //     ),
  //           //     child: Icon(
  //           //       Icons.delete_outline_rounded,
  //           //       size: 18,
  //           //       color: Colors.red.shade400,
  //           //     ),
  //           //   ),
  //           // ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _todaySiteVisitCard(Map<String, dynamic> visit) {
    final customer = visit["customer"]?.toString().trim() ?? "";
    final site = visit["site"]?.toString().trim() ??
        visit["site_lat"]?.toString() ??
        "";
    final eemName = visit["_eem_name"] ??
        Provider.of<SalesOrderProvider>(context, listen: false).eemDocName ??
        "";

    // ── Actual distance + distance travelled ─────────────
    final actualDistance = visit["actual_distance"]?.toString().trim() ?? "";
    final distanceTravelled =
        visit["distance_travelled"]?.toString().trim() ?? "";

    // ── Parse checkin_time ────────────────────────────────
    String displayTime = "";
    try {
      final rawTime = visit["checkin_time"]?.toString().trim() ?? "";
      if (rawTime.isNotEmpty) {
        final parts = rawTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final tod = TimeOfDay(hour: hour, minute: minute);
          final now = DateTime.now();
          final dt = DateTime(
              now.year, now.month, now.day, tod.hour, tod.minute);
          displayTime = DateFormat('hh:mm a').format(dt);
        }
      }
    } catch (_) {}

    // ── Coordinates ───────────────────────────────────────
    final double? lat =
    double.tryParse(visit["site_lat"]?.toString() ?? "");
    final double? lng =
    double.tryParse(visit["site_long"]?.toString() ?? "");

    return InkWell(
      onTap: () => _showCreateSiteVisitDialog(existingVisit: {
        ...visit,
        "latitude": lat,
        "longitude": lng,
        "name": visit["name"],
        "checkin_time": visit["checkin_time"],
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon ───────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on,
                  color: AppColors.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),

            // ── Customer + Site + Time + Distance ──────────
// ── Customer + Site + Time + Distance ──────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary text
                  Text(
                    customer.isNotEmpty ? customer : site,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Single compact info row ───────────────
                  Row(
                    children: [
                      // Site
                      if (customer.isNotEmpty && site.isNotEmpty) ...[
                        Icon(Icons.map_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            site,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (displayTime.isNotEmpty ||
                            (actualDistance.isNotEmpty &&
                                actualDistance != "0" &&
                                actualDistance != "0.0"))
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            child: Text("·",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11)),
                          ),
                      ],

                      // Checkin time
                      if (displayTime.isNotEmpty) ...[
                        Icon(Icons.access_time,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          displayTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (actualDistance.isNotEmpty &&
                            actualDistance != "0" &&
                            actualDistance != "0.0")
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            child: Text("·",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11)),
                          ),
                      ],

                      // Actual distance
                      if (actualDistance.isNotEmpty &&
                          actualDistance != "0" &&
                          actualDistance != "0.0") ...[
                        Icon(Icons.straighten_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          "$actualDistance km",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // // ── Delete icon ────────────────────────────────
            // GestureDetector(
            //   onTap: () async {
            //     final rowName = visit["name"];
            //     if (rowName == null) return;
            //
            //     final confirm = await showDialog<bool>(
            //       context: context,
            //       builder: (ctx) => AlertDialog(
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(14)),
            //         title: const Text("Delete Site Visit"),
            //         content: Text(
            //           "Are you sure you want to delete this site visit"
            //               "${customer.isNotEmpty ? ' for $customer' : ''}?",
            //         ),
            //         actions: [
            //           TextButton(
            //             onPressed: () => Navigator.pop(ctx, false),
            //             child: const Text("Cancel"),
            //           ),
            //           ElevatedButton(
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.red,
            //               shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(8)),
            //             ),
            //             onPressed: () => Navigator.pop(ctx, true),
            //             child: const Text("Delete",
            //                 style: TextStyle(color: Colors.white)),
            //           ),
            //         ],
            //       ),
            //     );
            //
            //     if (confirm != true) return;
            //
            //     final provider = Provider.of<SalesOrderProvider>(
            //         context,
            //         listen: false);
            //     final success =
            //     await provider.deleteSiteVisit(rowName);
            //     Fluttertoast.showToast(
            //       msg: success
            //           ? "Site Visit deleted successfully!"
            //           : "Failed to delete Site Visit.",
            //     );
            //   },
            //   child: Container(
            //     padding: const EdgeInsets.all(6),
            //     decoration: BoxDecoration(
            //       color: Colors.red.shade50,
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Icon(
            //       Icons.delete_outline_rounded,
            //       size: 18,
            //       color: Colors.red.shade400,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
  // --- CUSTOMER CARD ---

  String formatCheckInDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "";

    try {
      final parsed = DateTime.parse(rawDate);

      // dd-MM-yyyy HH:mm (24-hour format)
      return DateFormat('dd-MM-yyyy HH:mm').format(parsed);
    } catch (e) {
      return rawDate;
    }
  }


  Future<void> _handleFileAttachment(
      int index,
      SalesOrderProvider provider,
      ) async {
    try {
      final rowName = expenseRows[index]["name"];

      // ⛔ Must have ERP child row name
      if (rowName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Save expense before attaching file"),
          ),
        );
        return;
      }

      // 1️⃣ Choose source
      final source = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery (Image)'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Document'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;
      // 2️⃣ Pick file

      File? file;

      if (source == 'camera') {
        file = await provider.pickFile(fromCamera: true);
      } else if (source == 'gallery') {
        file = await provider.pickFile(fromCamera: false);
      } else if (source == 'pdf') {
        file = await provider.pickDocument(); // 🔴 PDF support
      }

      if (file == null) return;

      setState(() {
        expenseRows[index]["attachmentFile"] = file;
      });

      // 3️⃣ Upload file (CORRECT)
      final fileUrl = await provider.uploadExpenseFile(
        file,
        expenseRowName: rowName,
      );

      if (fileUrl != null) {
        setState(() {
          expenseRows[index]["attachment"] = fileUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Upload failed
        setState(() {
          expenseRows[index]["attachmentFile"] = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File upload failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling file attachment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


// Helper method to get attachment name
  String _getAttachmentName(int index) {
    if (expenseRows[index]["attachmentFile"] != null) {
      final file = expenseRows[index]["attachmentFile"] as File;
      return file.path.split('/').last;
    } else if (expenseRows[index]["attachment"] != null) {
      final url = expenseRows[index]["attachment"] as String;
      return url.split('/').last;
    }
    return '';
  }
  Widget _expenseRow(int index) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Expense Type Dropdown
              Expanded(
                flex: 1,
                child: FutureBuilder<List<String>>(
                  future: provider.fetchExpenseTypes(""),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                          height: 30,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 1)));
                    }

                    var list = snapshot.data!;

                    return DropdownButtonFormField<String>(
                      isDense: true,
                      value: expenseRows[index]["type"]!.text.isNotEmpty
                          ? expenseRows[index]["type"]!.text
                          : null,
                      items: list.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: "Type:",
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (v) {
                        expenseRows[index]["type"]?.text = v ?? "";
                        setState(() {});
                      },
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Amount Input
              Expanded(
                flex: 1,
                child: TextField(
                  controller: expenseRows[index]["amount"],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: "₹:",
                    hintStyle: TextStyle(fontSize: 13),
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // File Attachment Icon
              Consumer<SalesOrderProvider>(
                builder: (context, provider, _) {
                  final hasAttachment = expenseRows[index]["attachment"] != null ||
                      expenseRows[index]["attachmentFile"] != null;

                  return InkWell(
                    onTap: provider.isUploadingFile
                        ? null
                        : () async {
                      await _handleFileAttachment(index, provider);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: provider.isUploadingFile
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(
                        hasAttachment
                            ? Icons.attach_file
                            : Icons.attach_file_outlined,
                        size: 20,
                        color: hasAttachment
                            ? AppColors.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 2),

              // Delete Icon
              InkWell(
                onTap: () {
                  if (expenseRows.length > 1) {
                    _removeExpenseRow(index);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),

          // Show attachment name if exists
          if (expenseRows[index]["attachmentFile"] != null ||
              expenseRows[index]["attachment"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getAttachmentName(index),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        expenseRows[index]["attachment"] = null;
                        expenseRows[index]["attachmentFile"] = null;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppColors.primaryColor : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  // Widget _wrapSwipe(Widget screen, int index) {
  //   return GestureDetector(
  //     behavior: HitTestBehavior.opaque, // 👈 ensures it covers full screen
  //     onHorizontalDragEnd: (details) {
  //       double velocity = details.primaryVelocity ?? 0;
  //
  //       if (index == 0 && velocity < 0) {
  //         // Report Screen → Swipe Left → Go to Expense screen
  //         setState(() => _currentIndex = 2);
  //       }
  //
  //       if (index == 1 && velocity > 0) {
  //         // Checkin Screen → Swipe Right → Go to Expense screen
  //         setState(() => _currentIndex = 2);
  //       }
  //     },
  //
  //     child: Container(
  //       width: double.infinity,
  //       height: double.infinity,
  //       child: screen, // 👈 Important: screen now fills full area
  //     ),
  //   );
  // }
  Widget _wrapSwipe(Widget screen, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        double velocity = details.primaryVelocity ?? 0;

        if (index == 0) {
          // Report → Swipe Left → Visit Log
          if (velocity < 0) setState(() => _currentIndex = 2);
        }

        if (index == 1) {
          // Checkin Log → Swipe Right → Visit Log
          if (velocity > 0) setState(() => _currentIndex = 2);
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: screen,
      ),
    );
  }
}

class _CustomerSearchField extends StatefulWidget {
  final ValueChanged<String> onSelected;
  final String initialValue;
  const _CustomerSearchField({
    required this.onSelected,
    this.initialValue = "",
  });

  @override
  State<_CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<_CustomerSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Data> _results = [];
  List<Data> _nearbyCustomers = [];
  bool _isSearching = false;
  bool _showDropdown = false;
  String? _selectedCustomer;
  Timer? _debounce;

  // Filter mode
  bool _isNearbyMode = false;
  bool _isFetchingNearby = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue.isNotEmpty) {
      _searchController.text = widget.initialValue;
      _selectedCustomer = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Nearby filter ─────────────────────────────────────────────────────
  List<Data> _filterNearbyCustomers(
      List<Data> allCustomers,
      double userLat,
      double userLon, {
        double radiusInMeters = 150,
      }) {
    return allCustomers.where((c) {
      final lat = double.tryParse(c.latitude ?? '');
      final lon = double.tryParse(c.longitude ?? '');
      if (lat == null || lon == null) return false;
      final distance =
      Geolocator.distanceBetween(userLat, userLon, lat, lon);
      return distance <= radiusInMeters;
    }).toList();
  }

  Future<void> _loadNearbyCustomers() async {
    setState(() {
      _isFetchingNearby = true;
      _showDropdown = false;
      _results = [];
    });

    try {
      // Get user location
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {}

      if (pos == null) {
        Fluttertoast.showToast(
          msg: "Could not fetch your location for nearby search.",
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
        );
        setState(() {
          _isNearbyMode = false;
          _isFetchingNearby = false;
        });
        return;
      }

      _userPosition = pos;

      // Fetch all customers then filter
      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);
      await provider.fetchCustomers(context);
      final allCustomers = provider.customerr;

      final nearby = _filterNearbyCustomers(
        allCustomers,
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _nearbyCustomers = nearby;
        _results = nearby;
        _showDropdown = true;
        _isFetchingNearby = false;
      });
    } catch (e) {
      debugPrint('_loadNearbyCustomers Error: $e');
      setState(() {
        _isFetchingNearby = false;
        _isNearbyMode = false;
      });
    }
  }

  // ── Search ────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        // In nearby mode show nearby list, else hide
        _results = _isNearbyMode ? _nearbyCustomers : [];
        _showDropdown = _isNearbyMode && _nearbyCustomers.isNotEmpty;
      });
      return;
    }

    if (_isNearbyMode) {
      // Filter already-loaded nearby list locally
      final filtered = _nearbyCustomers
          .where((c) =>
      (c.name ?? "")
          .toLowerCase()
          .contains(query.trim().toLowerCase()) ||
          (c.customerName ?? "")
              .toLowerCase()
              .contains(query.trim().toLowerCase()))
          .toList();
      setState(() {
        _results = filtered;
        _showDropdown = true;
      });
      return;
    }

    // All mode — API search with debounce
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);

      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);
      final result = await provider.searchCustomer(query.trim(), context);

      if (mounted) {
        setState(() {
          _results = result?.data ?? [];
          _isSearching = false;
          _showDropdown = true;
        });
      }
    });
  }

  void _selectCustomer(Data customer) {
    final name = customer.name ?? "";
    setState(() {
      _selectedCustomer = name;
      _searchController.text = name;
      _showDropdown = false;
      _results = [];
    });
    _focusNode.unfocus();
    widget.onSelected(name);
  }

  void _clearSelection() {
    setState(() {
      _selectedCustomer = null;
      _searchController.clear();
      _showDropdown = _isNearbyMode && _nearbyCustomers.isNotEmpty;
      _results = _isNearbyMode ? _nearbyCustomers : [];
    });
    widget.onSelected("");
  }

  // ── Toggle nearby / all ───────────────────────────────────────────────
  Future<void> _toggleMode(bool nearbyMode) async {
    if (_selectedCustomer != null) return; // don't toggle if selected

    setState(() => _isNearbyMode = nearbyMode);

    if (nearbyMode) {
      await _loadNearbyCustomers();
    } else {
      // Switch back to all — re-run current query or clear
      final query = _searchController.text.trim();
      setState(() {
        _nearbyCustomers = [];
        _results = [];
        _showDropdown = false;
      });
      if (query.isNotEmpty) _onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Nearby / All toggle ───────────────────────────
        if (_selectedCustomer == null)
          Row(
            children: [
              _ModeChip(
                label: "All",
                icon: Icons.people_outline,
                selected: !_isNearbyMode,
                onTap: () => _toggleMode(false),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: "Nearby",
                icon: Icons.near_me,
                selected: _isNearbyMode,
                onTap: () => _toggleMode(true),
                isLoading: _isFetchingNearby,
              ),
            ],
          ),

        if (_selectedCustomer == null) const SizedBox(height: 8),

        // ── Search Input ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _selectedCustomer != null
                ? AppColors.primaryColor.withOpacity(0.05)
                : Colors.grey.shade50,
            border: Border.all(
              color: _selectedCustomer != null
                  ? AppColors.primaryColor.withOpacity(0.4)
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  _selectedCustomer != null
                      ? Icons.business
                      : Icons.search_rounded,
                  size: 18,
                  color: _selectedCustomer != null
                      ? AppColors.primaryColor
                      : Colors.grey.shade500,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  readOnly: _selectedCustomer != null,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedCustomer != null
                        ? AppColors.primaryColor
                        : Colors.black87,
                    fontWeight: _selectedCustomer != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: _isNearbyMode
                        ? "Filter nearby customers..."
                        : "Search customer...",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              // Loading / Clear
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _isSearching
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor),
                  ),
                )
                    : _selectedCustomer != null
                    ? GestureDetector(
                  onTap: _clearSelection,
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Nearby empty state ────────────────────────────
        if (_isNearbyMode &&
            !_isFetchingNearby &&
            _nearbyCustomers.isEmpty &&
            _selectedCustomer == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_searching,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No customers found within 150m of your location.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Dropdown Results ──────────────────────────────
        if (_showDropdown && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.6,
                indent: 14,
                endIndent: 14,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (_, i) {
                final c = _results[i];

                // Calculate distance if in nearby mode
                String? distanceLabel;
                if (_isNearbyMode && _userPosition != null) {
                  final lat = double.tryParse(c.latitude ?? '');
                  final lon = double.tryParse(c.longitude ?? '');
                  if (lat != null && lon != null) {
                    final dist = Geolocator.distanceBetween(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                      lat,
                      lon,
                    );
                    distanceLabel = dist >= 1000
                        ? "${(dist / 1000).toStringAsFixed(1)} km"
                        : "${dist.toStringAsFixed(0)} m";
                  }
                }

                return InkWell(
                  onTap: () => _selectCustomer(c),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                            AppColors.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (c.name ?? "?")[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name ?? "",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((c.customerName ?? "").isNotEmpty &&
                                  c.customerName != c.name)
                                Text(
                                  c.customerName ?? "",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Distance badge in nearby mode
                        if (distanceLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border:
                              Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              distanceLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // ── No results (All mode) ─────────────────────────
        if (_showDropdown && _results.isEmpty && !_isSearching && !_isNearbyMode)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                "No customers found",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Mode Chip ─────────────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isLoading;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    selected ? Colors.white : AppColors.primaryColor,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}