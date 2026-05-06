// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
// import '../../../provider/provider.dart';
// import '../../../utils/app_colors.dart';
// import '../../../utils/common/common_widgets.dart';
// import 'CheckinScreen.dart';
// import 'ReportScreen.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
//
//
// class ExpenseTrackerScreen extends StatefulWidget {
//   // const ExpenseTrackerScreen({super.key});
//   final Map<String, dynamic>? eemData;
//   final bool isEditMode;
//
//   const ExpenseTrackerScreen({
//     super.key,
//     this.eemData,
//     this.isEditMode = false,
//   });
//   @override
//   State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
// }
//
// class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
//   int _currentIndex = 2;
//
//   // List<Map<String, TextEditingController>> expenseRows = [];
//   List<Map<String, dynamic>> expenseRows = [];
//
//   String? eemName;
//   DateTime? eemDate;
//
//   bool _canSave = false;    // Show Save button
//   bool _canSubmit = false; // Show Submit button
//
//   DateTime? startTime;
//   double? startLat;
//   double? startLong;
//
//   DateTime? endTime;
//   double? endLat;
//   double? endLong;
//
//   // --- Bottom navigation screens ---
//   final List<Widget> pages = [];
//
//   List<TextEditingController> distanceControllers = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Provider.of<SalesOrderProvider>(context, listen: false);
//           // .restoreTrackingState(context);
//       final provider =
//       Provider.of<SalesOrderProvider>(context, listen: false);
//       if (widget.isEditMode && widget.eemData != null) {
//         _restoreFromEEM(provider, widget.eemData!);
//       } else {
//         provider.restoreTrackingState(context);
//         _addExpenseRow();
//       }
//     });
//
//     pages.addAll([
//       _wrapSwipe(ReportScreen(), 0),
//       _wrapSwipe(CheckinScreen(), 1),
//       SizedBox(),
//     ]);
//
//     _addExpenseRow();
//   }
//
//   void _restoreFromEEM(
//       SalesOrderProvider provider,
//       Map<String, dynamic> eem,
//       ) {
//     /// Store EEM meta
//     eemName = eem["name"]?.toString();
//     eemDate = DateTime.tryParse(eem["date"] ?? "");
//
//     /// Restore times
//     startTime = DateTime.tryParse(eem["start_time"] ?? "");
//     endTime = DateTime.tryParse(eem["end_time"] ?? "");
//
//     /// Restore site visits
//     provider.setSiteVisits(
//       List<Map<String, dynamic>>.from(
//         eem["employee_site_tracking"] ?? [],
//       ),
//     );
//
//     /// Restore expenses
//     expenseRows.clear();
//     for (final e in (eem["employee_expense_tracking"] ?? [])) {
//       expenseRows.add({
//         "type": TextEditingController(text: e["expense_type"] ?? ""),
//         "amount": TextEditingController(
//           text: e["amount"]?.toString() ?? "",
//         ),
//         "attachment": e["attachment"], // ✅ Restore attachment URL
//         "attachmentFile": null, // ✅ No file object when restoring
//       });
//     }
//
//     if (expenseRows.isEmpty) {
//       _addExpenseRow();
//     }
//
//     setState(() {
//       _canSave = true;
//       _canSubmit = eem["docstatus"] == 0;
//     });
//   }
//
//   void _addExpenseRow() {
//     setState(() {
//       expenseRows.add({
//         "name": null, // ERPNext row name
//         "type": TextEditingController(),
//         "amount": TextEditingController(),
//         "attachment": null,
//         "attachmentFile": null,
//       });
//     });
//   }
//
//   void _removeExpenseRow(int index) {
//     setState(() {
//       expenseRows.removeAt(index);
//     });
//   }
//
//
//   void _toggleTracking() async {
//     final provider =
//     Provider.of<SalesOrderProvider>(context, listen: false);
//
//     // ⛔ BLOCK while loading
//     if (provider.isTrackingLoading) return;
//
//     // ⛔ BLOCK starting new tracking if current EEM is not saved
//     if (!provider.isTracking && _canSave) {
//       await _showWarningDialog(
//         context: context,
//         message: "Please save the current expense before starting a new tracking.",
//       );
//       return;
//     }
//
//     if (!provider.isTracking) {
//       // ===== CHECK IF CAN START (NEW) =====
//       final canStart = await provider.canStartTracking();
//       if (!canStart) {
//         await _showWarningDialog(
//           context: context,
//           message: "Please checkout first before starting expense tracking.",
//         );
//         return;
//       }
//
//       // ===== CONFIRM START =====
//       final confirm = await _showConfirmDialog(
//         context: context,
//         title: "Start Tracking",
//         message: "Do you want to start expense tracking?",
//         confirmText: "Start",
//       );
//
//       if (!confirm) return;
//
//       startTime = DateTime.now();
//       final pos = await _getCurrentPosition();
//       if (pos == null) return;
//
//       await provider.startTracking(
//         context: context,
//         startTime: _formatTime(startTime!),
//         startLat: pos.latitude,
//         startLong: pos.longitude,
//       );
//     } else {
//       // ===== CONFIRM STOP =====
//       final confirm = await _showConfirmDialog(
//         context: context,
//         title: "Stop Tracking",
//         message: "Do you want to stop expense tracking?",
//         confirmText: "Stop",
//       );
//
//       if (!confirm) return;
//
//       final canStop = await provider.canStopTracking();
//       if (!canStop) {
//         await _showWarningDialog(
//           context: context,
//           message: "Please checkout before ending tracking.",
//         );
//         return;
//       }
//
//       endTime = DateTime.now();
//       final pos = await _getCurrentPosition();
//       if (pos == null) return;
//
//       final expenses = _collectExpenses();
//
//       final ok = await provider.stopTracking(
//         endTime: _formatTime(endTime!),
//         endLat: pos.latitude,
//         endLong: pos.longitude,
//         expenses: expenses,
//       );
//
//       if (ok) {
//         setState(() {
//           _currentIndex = 2;
//           _canSave = true;
//           _canSubmit = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _showWarningDialog({
//     required BuildContext context,
//     required String message,
//   }) async {
//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         return AlertDialog(
//           title: const Text("Action Required"),
//           content: Text(message),
//           actions: [
//             ElevatedButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   Future<bool> _showConfirmDialog({
//     required BuildContext context,
//     required String title,
//     required String message,
//     String confirmText = "Yes",
//     String cancelText = "No",
//   }) async {
//     final result = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, false),
//               child: Text(cancelText),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(ctx, true),
//               child: Text(confirmText),
//             ),
//           ],
//         );
//       },
//     );
//
//     return result ?? false;
//   }
//
//   String _formatTime(DateTime time) {
//     return "${time.hour.toString().padLeft(2,'0')}:"
//         "${time.minute.toString().padLeft(2,'0')}:"
//         "${time.second.toString().padLeft(2,'0')}";
//   }
//
//   Future<Position?> _getCurrentPosition() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       await Geolocator.openLocationSettings();
//       return null;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         debugPrint("Location permission denied");
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       debugPrint("Location permission permanently denied");
//       return null;
//     }
//
//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//   }
//   void _resetTracking() {
//     setState(() {
//       startTime = null;
//       startLat = null;
//       startLong = null;
//       endTime = null;
//       endLat = null;
//       endLong = null;
//     });
//   }
//
//   List<Map<String, dynamic>> _collectExpenses() {
//     List<Map<String, dynamic>> list = [];
//
//     for (var row in expenseRows) {
//       final type = row["type"]!.text.trim();
//       final amountString = row["amount"]!.text.trim();
//
//       if (type.isEmpty || amountString.isEmpty) continue;
//
//       final amount = double.tryParse(amountString) ?? 0.0;
//
//       list.add({
//         "expense_type": type,
//         "amount": amount,
//         "attachment": row["attachment"], // ✅ Include attachment URL
//       });
//     }
//
//     return list;
//   }
//   // ✅ Method to clear all expense data
//   void _resetExpenseData() {
//     // Dispose all existing controllers
//     for (var row in expenseRows) {
//       row['expense']?.dispose();
//       row['amount']?.dispose();
//       row['remarks']?.dispose();
//     }
//
//     for (var controller in distanceControllers) {
//       controller.dispose();
//     }
//
//     // Clear all state
//     setState(() {
//       expenseRows.clear();
//       distanceControllers.clear();
//       eemName = null;
//       eemDate = null;
//       _canSave = false;
//       _canSubmit = false;
//       startTime = null;
//       startLat = null;
//       startLong = null;
//       endTime = null;
//       endLat = null;
//       endLong = null;
//     });
//
//     // Add fresh row
//     _addExpenseRow();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isTracking =
//         context.watch<SalesOrderProvider>().isTracking;
//     final provider = context.watch<SalesOrderProvider>();
//     final bool blockStart =
//         provider.isTrackingLoading ||
//             (!provider.isTracking && _canSave);
//
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: "Expense Tracker",
//         automaticallyImplyLeading: true,
//         backgroundColor: AppColors.primaryColor,
//         actions: Row(
//           // SAVE
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (_canSave)
//                 IconButton(
//                   onPressed: provider.isSaveLoading
//                       ? null
//                       : () async {
//                     if (provider.isTracking) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Stop tracking before saving"),
//                         ),
//                       );
//                       return;
//                     }
//
//                     final expenses = _collectExpenses();
//
//                     // 🔴 UPDATED: saveEEM now returns saved rows
//                     final savedExpenses = await provider.saveEEM(expenses);
//
//                     if (savedExpenses != null) {
//                       setState(() {
//                         for (int i = 0; i < savedExpenses.length; i++) {
//                           // 🔴 CRITICAL FIX: store ERP child row name
//                           expenseRows[i]["name"] = savedExpenses[i]["name"];
//                           expenseRows[i]["attachment"] =
//                           savedExpenses[i]["attachment"];
//                         }
//
//                         _canSubmit = true;
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                               "Saved successfully. You can now attach files or submit."),
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Save failed"),
//                         ),
//                       );
//                     }
//                   },
//                   icon: provider.isSaveLoading
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : const Icon(Icons.save_outlined, color: Colors.white),
//                 ),
//
//               // SUBMIT
//               if (_canSubmit)
//                 IconButton(
//                   onPressed: provider.isSubmitLoading
//                       ? null
//                       : () async {
//                     if (provider.isTracking) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Stop tracking before submitting"),
//                         ),
//                       );
//                       return;
//                     }
//
//                     final confirm = await _showConfirmDialog(
//                       context: context,
//                       title: "Submit Expense",
//                       message:
//                       "Once submitted, this expense cannot be edited.\n\nDo you want to continue?",
//                       confirmText: "Submit",
//                       cancelText: "Cancel",
//                     );
//
//                     if (!confirm) return;
//
//                     final expenses = _collectExpenses();
//                     final ok = await provider.submitEEM(expenses);
//
//                     if (ok) {
//                       // ✅ Clear all data after successful submission
//                       _resetExpenseData();
//                       // ✅ Clear provider state
//                       provider.clearTrackingData();
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Expense submitted successfully"),
//                         ),
//                       );
//                       Navigator.pop(context);
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Submission failed"),
//                         ),
//                       );
//                     }
//                   },
//                   icon: provider.isSubmitLoading
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : const Icon(Icons.check_circle_outline, color: Colors.white),
//                 ),
//
//
//             ],
//         ),
//       ),
//
//       // --- MAIN BODY ---
//       body: (_currentIndex == 0 || _currentIndex == 1)
//           ? pages[_currentIndex]
//           : _buildExpenseTrackerMainUI(),
//
//       // ---- BOTTOM NAVIGATION ----
//       bottomNavigationBar: SafeArea(
//         child: Container(
//           height: 70,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, -2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _bottomNavItem(Icons.receipt_long, "Report", 0),
//
//               // ==== ROUND START / STOP BUTTON ====
//               GestureDetector(
//                 onTap: blockStart ? null : _toggleTracking,
//                 child: Opacity(
//                   opacity: blockStart ? 0.5 : 1.0, // 🔹 visual feedback
//                   child: Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: provider.isTracking
//                           ? Colors.red
//                           : AppColors.primaryColor,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: provider.isTrackingLoading
//                           ? const SizedBox(
//                         width: 26,
//                         height: 26,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 3,
//                           valueColor:
//                           AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                           : Icon(
//                         provider.isTracking ? Icons.stop : Icons.play_arrow,
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//       _bottomNavItem(Icons.person, "Checkin", 1),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     return DateFormat('dd-MM-yyyy').format(date);
//   }
//
//
//   Widget _buildExpenseTrackerMainUI() {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//
//           /// SITE VISITS HEADER
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Text(
//                     "Site Visits",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (widget.isEditMode && eemDate != null)
//                     Text(
//                       _formatDate(eemDate!),
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                 ],
//               ),
//
//               if (widget.isEditMode && eemName != null) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   eemName!,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 8),
//
//           Expanded(
//             flex: 6,
//             child: Consumer<SalesOrderProvider>(
//               builder: (context, provider, _) {
//                 while (distanceControllers.length < provider.siteVisits.length) {
//                   distanceControllers.add(TextEditingController());
//                 }
//
//                 if (provider.siteVisits.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No site visits recorded",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   );
//                 }
//
//                 return ListView.builder(
//                   itemCount: provider.siteVisits.length,
//                   itemBuilder: (context, index) {
//                     return _siteVisitCard(
//                       provider.siteVisits[index],
//                       distanceControllers[index],
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//
//
//           const SizedBox(height: 15),
//
//           Row(
//             children: [
//               Expanded(child: Divider(thickness: 1, color: Colors.grey.shade400)),
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 8),
//                 child: Text("Other Expense",
//                     style: TextStyle(fontSize: 12, color: Colors.grey)),
//               ),
//               Expanded(child: Divider(thickness: 1, color: Colors.grey.shade400)),
//             ],
//           ),
//
//           const SizedBox(height: 8),
//
//           Expanded(
//             flex: 4,
//             child: ListView.builder(
//               itemCount: expenseRows.length,
//               itemBuilder: (context, index) => _expenseRow(index),
//             ),
//           ),
//
//           const SizedBox(height: 4),
//
//           Align(
//             alignment: Alignment.centerLeft,
//             child: IconButton(
//               icon: Icon(Icons.add_circle, color: AppColors.primaryColor, size: 28),
//               onPressed: _addExpenseRow,
//             ),
//           ),
//
//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }
//
//
//   // --- CUSTOMER CARD ---
//
//   String formatCheckInDateTime(String? rawDate) {
//     if (rawDate == null || rawDate.isEmpty) return "";
//
//     try {
//       final parsed = DateTime.parse(rawDate);
//
//       // dd-MM-yyyy HH:mm (24-hour format)
//       return DateFormat('dd-MM-yyyy HH:mm').format(parsed);
//     } catch (e) {
//       return rawDate;
//     }
//   }
//   Widget _siteVisitCard(
//       Map<String, dynamic> visit,
//       TextEditingController controller,
//       ) {
//     // final customer = visit["customer"] ?? "Unknown Customer";
//     final String customerRaw = visit["customer"]?.toString().trim() ?? "";
//     final String remarksRaw = visit["remarks"]?.toString().trim() ?? "";
//
//     final String displayTitle =
//     customerRaw.isNotEmpty
//         ? customerRaw
//         : (remarksRaw.isNotEmpty ? remarksRaw : "Unknown Customer");
//     // final location = visit["location_name"] ?? "Unknown Location";
//     final checkIn = formatCheckInDateTime(visit["checkin_time"]);
//
//
//     final distanceTravelled =
//         visit["distance_travelled"]?.toString() ?? "0";
//
//     // Initialize controller only once
//     if (controller.text.isEmpty) {
//       controller.text = visit["actual_distance"]?.toString() ??
//           distanceTravelled;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             radius: 16,
//             backgroundColor: AppColors.primaryColor,
//             child: Icon(Icons.location_on,
//                 color: Colors.white, size: 18),
//           ),
//
//           const SizedBox(width: 10),
//
//           Expanded(
//             flex: 3,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// CUSTOMER (HEADING)
//                 Text(
//                   displayTitle,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//
//
//                 const SizedBox(height: 2),
//
//
//                 const SizedBox(height: 2),
//
//                 /// DISTANCE TRAVELLED (READ ONLY)
//                 Text(
//                   "Distance: $distanceTravelled km",
//                   style: TextStyle(
//                       color: Colors.grey.shade700, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           /// ACTUAL DISTANCE INPUT
//           SizedBox(
//             width: 70,
//             child: TextField(
//               controller: controller,
//               keyboardType:
//               const TextInputType.numberWithOptions(decimal: true),
//               style: const TextStyle(fontSize: 13),
//               decoration: const InputDecoration(
//                 labelText: "Actual",
//                 suffixText: "km",
//                 isDense: true,
//                 border: OutlineInputBorder(),
//               ),
//               onTap: () {
//                 controller.selection = TextSelection(
//                   baseOffset: 0,
//                   extentOffset: controller.text.length,
//                 );
//               },
//               onChanged: (value) {
//                 visit["actual_distance"] =
//                     double.tryParse(value) ?? 0;
//               },
//             ),
//
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _handleFileAttachment(
//       int index,
//       SalesOrderProvider provider,
//       ) async {
//     try {
//       final rowName = expenseRows[index]["name"];
//
//       // ⛔ Must have ERP child row name
//       if (rowName == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Save expense before attaching file"),
//           ),
//         );
//         return;
//       }
//
//       // 1️⃣ Choose source
//       final source = await showModalBottomSheet<String>(
//         context: context,
//         builder: (_) => SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Gallery (Image)'),
//                 onTap: () => Navigator.pop(context, 'gallery'),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_camera),
//                 title: const Text('Camera'),
//                 onTap: () => Navigator.pop(context, 'camera'),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.picture_as_pdf),
//                 title: const Text('PDF Document'),
//                 onTap: () => Navigator.pop(context, 'pdf'),
//               ),
//             ],
//           ),
//         ),
//       );
//
//       if (source == null) return;
//       // 2️⃣ Pick file
//
//       File? file;
//
//       if (source == 'camera') {
//         file = await provider.pickFile(fromCamera: true);
//       } else if (source == 'gallery') {
//         file = await provider.pickFile(fromCamera: false);
//       } else if (source == 'pdf') {
//         file = await provider.pickDocument(); // 🔴 PDF support
//       }
//
//       if (file == null) return;
//
//       setState(() {
//         expenseRows[index]["attachmentFile"] = file;
//       });
//
//       // 3️⃣ Upload file (CORRECT)
//       final fileUrl = await provider.uploadExpenseFile(
//         file,
//         expenseRowName: rowName,
//       );
//
//       if (fileUrl != null) {
//         setState(() {
//           expenseRows[index]["attachment"] = fileUrl;
//         });
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('File uploaded successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         // Upload failed
//         setState(() {
//           expenseRows[index]["attachmentFile"] = null;
//         });
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('File upload failed'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('Error handling file attachment: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//
// // Helper method to get attachment name
//   String _getAttachmentName(int index) {
//     if (expenseRows[index]["attachmentFile"] != null) {
//       final file = expenseRows[index]["attachmentFile"] as File;
//       return file.path.split('/').last;
//     } else if (expenseRows[index]["attachment"] != null) {
//       final url = expenseRows[index]["attachment"] as String;
//       return url.split('/').last;
//     }
//     return '';
//   }
//   Widget _expenseRow(int index) {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Expense Type Dropdown
//               Expanded(
//                 flex: 1,
//                 child: FutureBuilder<List<String>>(
//                   future: provider.fetchExpenseTypes(""),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       return const SizedBox(
//                           height: 30,
//                           child: Center(child: CircularProgressIndicator(strokeWidth: 1)));
//                     }
//
//                     var list = snapshot.data!;
//
//                     return DropdownButtonFormField<String>(
//                       isDense: true,
//                       value: expenseRows[index]["type"]!.text.isNotEmpty
//                           ? expenseRows[index]["type"]!.text
//                           : null,
//                       items: list.map((type) {
//                         return DropdownMenuItem(
//                           value: type,
//                           child: Text(type, style: const TextStyle(fontSize: 13)),
//                         );
//                       }).toList(),
//                       decoration: const InputDecoration(
//                         hintText: "Type:",
//                         isDense: true,
//                         contentPadding: EdgeInsets.symmetric(vertical: 4),
//                         border: UnderlineInputBorder(),
//                       ),
//                       onChanged: (v) {
//                         expenseRows[index]["type"]?.text = v ?? "";
//                         setState(() {});
//                       },
//                     );
//                   },
//                 ),
//               ),
//
//               const SizedBox(width: 8),
//
//               // Amount Input
//               Expanded(
//                 flex: 1,
//                 child: TextField(
//                   controller: expenseRows[index]["amount"],
//                   keyboardType: TextInputType.number,
//                   style: const TextStyle(fontSize: 13),
//                   decoration: const InputDecoration(
//                     hintText: "₹:",
//                     hintStyle: TextStyle(fontSize: 13),
//                     border: UnderlineInputBorder(),
//                     isDense: true,
//                     contentPadding: EdgeInsets.symmetric(vertical: 4),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(width: 6),
//
//               // File Attachment Icon
//               Consumer<SalesOrderProvider>(
//                 builder: (context, provider, _) {
//                   final hasAttachment = expenseRows[index]["attachment"] != null ||
//                       expenseRows[index]["attachmentFile"] != null;
//
//                   return InkWell(
//                     onTap: provider.isUploadingFile
//                         ? null
//                         : () async {
//                       await _handleFileAttachment(index, provider);
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.all(4),
//                       child: provider.isUploadingFile
//                           ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                           : Icon(
//                         hasAttachment
//                             ? Icons.attach_file
//                             : Icons.attach_file_outlined,
//                         size: 20,
//                         color: hasAttachment
//                             ? AppColors.primaryColor
//                             : Colors.grey,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//
//               const SizedBox(width: 2),
//
//               // Delete Icon
//               InkWell(
//                 onTap: () {
//                   if (expenseRows.length > 1) {
//                     _removeExpenseRow(index);
//                   }
//                 },
//                 child: const Padding(
//                   padding: EdgeInsets.all(4),
//                   child: Icon(Icons.close, size: 16, color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//
//           // Show attachment name if exists
//           if (expenseRows[index]["attachmentFile"] != null ||
//               expenseRows[index]["attachment"] != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4, left: 4),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       _getAttachmentName(index),
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: Colors.grey,
//                         fontStyle: FontStyle.italic,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   InkWell(
//                     onTap: () {
//                       setState(() {
//                         expenseRows[index]["attachment"] = null;
//                         expenseRows[index]["attachmentFile"] = null;
//                       });
//                     },
//                     child: const Padding(
//                       padding: EdgeInsets.all(2),
//                       child: Icon(Icons.close, size: 12, color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _bottomNavItem(IconData icon, String label, int index) {
//     final isSelected = _currentIndex == index;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() => _currentIndex = index);
//       },
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: isSelected ? AppColors.primaryColor : Colors.grey),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: isSelected ? AppColors.primaryColor : Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _wrapSwipe(Widget screen, int index) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque, // 👈 ensures it covers full screen
//       onHorizontalDragEnd: (details) {
//         double velocity = details.primaryVelocity ?? 0;
//
//         if (index == 0 && velocity < 0) {
//           // Report Screen → Swipe Left → Go to Expense screen
//           setState(() => _currentIndex = 2);
//         }
//
//         if (index == 1 && velocity > 0) {
//           // Checkin Screen → Swipe Right → Go to Expense screen
//           setState(() => _currentIndex = 2);
//         }
//       },
//
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: screen, // 👈 Important: screen now fills full area
//       ),
//     );
//   }
// }
