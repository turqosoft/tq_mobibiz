// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sales_ordering_app/provider/provider.dart';
// import 'package:sales_ordering_app/utils/common/common_widgets.dart';
// import 'package:sales_ordering_app/utils/sharedpreference.dart';
// import 'package:table_calendar/table_calendar.dart';

// class AttendanceCalendar extends StatefulWidget {
//   @override
//   _AttendanceCalendarState createState() => _AttendanceCalendarState();
// }

// class _AttendanceCalendarState extends State<AttendanceCalendar> {
//   late Map<DateTime, String> _attendance;
//   final SharedPrefService _sharedPrefService = SharedPrefService();

//   @override
//   void initState() {
//     super.initState();
//     _attendance = {};
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       attendanceDetails();
//     });
//   }

//   Future<void> attendanceDetails() async {
//     final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//         String? employeeId = await _sharedPrefService.getEmployeeId();

//     try {
//       await provider.attendanceDetails(employeeId!);
//       final attendanceModel = provider.attendanceModel;
//       if (attendanceModel != null && attendanceModel.data != null) {
//         setState(() {
//           _attendance = {
//             for (var data in attendanceModel.data!)
//               DateTime.parse(data.attendanceDate!): data.status!
//           };
//         });
//       }
//     } catch (e) {
//       print('Error fetching attendance details: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: 'Attendance',
//         onBackTap: () {
//           Navigator.pop(context);
//         },
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Column(
//           children: [
//             TableCalendar(
//               firstDay: DateTime.utc(2023, 1, 1),
//               lastDay: DateTime.utc(2025, 12, 31),
//               focusedDay: DateTime.now(),

//               calendarBuilders: CalendarBuilders(
//                 defaultBuilder: (context, day, focusedDay) {
//                   return _buildAttendanceMarker(day);
//                 },
//                 todayBuilder: (context, day, focusedDay) {
//                   return _buildAttendanceMarker(day);
//                 },
//                 selectedBuilder: (context, day, focusedDay) {
//                   return _buildAttendanceMarker(day, isSelected: true);
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Container(
//                   height: 30,
//                   width: 30,
//                   color:  Colors.green,
//                 ),
//                 const SizedBox(width: 10),
//                 const Text("Present"),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Container(
//                   height: 30,
//                   width: 30,
//                   color: Colors.red,
//                 ),
//                 const SizedBox(width: 10),
//                 const Text("Absent"),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Container(
//                   height: 30,
//                   width: 30,
//                   color: Colors.orange,
//                 ),
//                 const SizedBox(width: 10),
//                 const Text("Work From Home"),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Container(
//                   height: 30,
//                   width: 30,
//                   color: Colors.yellow,
//                 ),
//                 const SizedBox(width: 10),
//                 const Text("Half Day"),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceMarker(DateTime day, {bool isSelected = false}) {
//     String? status = _attendance[DateTime(day.year, day.month, day.day)];
//     Color markerColor;

//     switch (status) {
//       case 'Present':
//         markerColor =  Colors.green;
//         break;
//       case 'Absent':
//         markerColor = Colors.red;
//         break;
//       case 'Work From Home':
//         markerColor = Colors.orange;
//         break;
//       case 'Half Day':
//         markerColor = Colors.yellow;
//         break;
//       default:
//         markerColor = Colors.transparent;
//     }

//     return Container(
//       margin: const EdgeInsets.all(4.0),
//       decoration: BoxDecoration(
//         color: markerColor,
//         shape: BoxShape.circle,
//         border: isSelected ? Border.all(color: Colors.blue, width: 2.0) : null,
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         '${day.day}',
//         style: TextStyle(
//           color: status != null ? Colors.white : Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/utils/sharedpreference.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendar extends StatefulWidget {
  @override
  _AttendanceCalendarState createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late Map<DateTime, String> _attendance;
  final SharedPrefService _sharedPrefService = SharedPrefService();

  @override
  void initState() {
    super.initState();
    _attendance = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attendanceDetails();
    });
  }

  // Future<void> attendanceDetails() async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   String? employeeId = await _sharedPrefService.getEmployeeId();
  //
  //   try {
  //     await provider.attendanceDetails(employeeId!, context);
  //     final attendanceModel = provider.attendanceModel;
  //     if (attendanceModel != null && attendanceModel.data != null) {
  //       setState(() {
  //         _attendance = {
  //           for (var data in attendanceModel.data!)
  //             DateTime.parse(data.attendanceDate!): data.status!
  //         };
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching attendance details: $e');
  //   }
  // }

  Future<void> attendanceDetails() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    debugPrint('ATTENDANCE UI FETCH STARTED');

    await provider.fetchAttendanceForLoggedInUser(context);

    final attendanceModel = provider.attendanceModel;

    debugPrint(
      'ATTENDANCE UI MODEL NULL? => ${attendanceModel == null}',
    );
    debugPrint(
      'ATTENDANCE UI DATA COUNT => ${attendanceModel?.data?.length}',
    );

    if (attendanceModel?.data == null) return;

    final Map<DateTime, String> temp = {};

    for (final record in attendanceModel!.data!) {
      debugPrint(
        'ATTENDANCE RECORD => date: ${record.attendanceDate}, status: ${record.status}',
      );

      if (record.attendanceDate == null || record.status == null) continue;

      final parsedDate = DateTime.tryParse(record.attendanceDate!);
      debugPrint('PARSED DATE => $parsedDate');

      if (parsedDate == null) continue;

      final normalizedDate =
      DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      debugPrint(
        'NORMALIZED DATE => $normalizedDate | STATUS => ${record.status}',
      );

      temp[normalizedDate] = record.status!;
    }

    debugPrint('ATTENDANCE MAP SIZE => ${temp.length}');
    debugPrint('ATTENDANCE MAP CONTENT => $temp');

    setState(() {
      _attendance = temp;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Attendance',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // TableCalendar(
              //   firstDay: DateTime.utc(2023, 1, 1),
              //   lastDay: DateTime.utc(2025, 12, 31),
              //   focusedDay: DateTime.now(),
              //   calendarBuilders: CalendarBuilders(
              //     defaultBuilder: (context, day, focusedDay) {
              //       return _buildAttendanceMarker(day);
              //     },
              //     todayBuilder: (context, day, focusedDay) {
              //       return _buildAttendanceMarker(day);
              //     },
              //     selectedBuilder: (context, day, focusedDay) {
              //       return _buildAttendanceMarker(day, isSelected: true);
              //     },
              //   ),
              //   headerStyle: HeaderStyle(
              //     formatButtonVisible: false,
              //     titleCentered: true,
              //   ),
              //   daysOfWeekStyle: DaysOfWeekStyle(
              //     weekdayStyle: TextStyle(color: Colors.transparent),
              //     weekendStyle: TextStyle(color: Colors.transparent),
              //   ),
              // ),
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: DateTime.now(),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _buildAttendanceMarker(day),
                  todayBuilder: (context, day, focusedDay) =>
                      _buildAttendanceMarker(day),
                  selectedBuilder: (context, day, focusedDay) =>
                      _buildAttendanceMarker(day, isSelected: true),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),

              const SizedBox(height: 20),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildAttendanceMarker(DateTime day, {bool isSelected = false}) {
  //   String? status = _attendance[DateTime(day.year, day.month, day.day)];
  //   Color markerColor;
  //
  //   switch (status) {
  //     case 'Present':
  //       markerColor = Colors.green;
  //       break;
  //     case 'Absent':
  //       markerColor = Colors.red;
  //       break;
  //     case 'Work From Home':
  //       markerColor = Colors.orange;
  //       break;
  //     case 'Half Day':
  //       markerColor = Colors.yellow;
  //       break;
  //     default:
  //       markerColor = Colors.transparent;
  //   }
  //
  //   return Container(
  //     margin: const EdgeInsets.all(4.0),
  //     decoration: BoxDecoration(
  //       color: markerColor,
  //       shape: BoxShape.circle,
  //       border: isSelected ? Border.all(color: Colors.blue, width: 2.0) : null,
  //     ),
  //     alignment: Alignment.center,
  //     child: Text(
  //       '${day.day}',
  //       style: TextStyle(
  //         color: status != null ? Colors.white : Colors.black,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   );
  // }
  Widget _buildAttendanceMarker(DateTime day, {bool isSelected = false}) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final String? status = _attendance[normalizedDay];

    debugPrint(
      'CALENDAR DAY => $normalizedDay | STATUS FOUND => $status',
    );

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;

    switch (status) {
      case 'Present':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'Absent':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'Work From Home':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      case 'Half Day':
        backgroundColor = Colors.yellow;
        textColor = Colors.black;
        break;
      case 'On Leave':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }



  Widget _buildLegend() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            const Text("Present"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            const Text("Absent"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.orange,
            ),
            const SizedBox(width: 10),
            const Text("Work From Home"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.yellow,
            ),
            const SizedBox(width: 10),
            const Text("Half Day"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              height: 30,
              width: 30,
              color: Colors.blue,
            ),
            const SizedBox(width: 10),
            const Text("On Leave"),
          ],
        ),

        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: IconButton(
                onPressed: () {
                  attendanceDetails();
                },
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                )),
          ),
        )
      ],
    );
  }
}
