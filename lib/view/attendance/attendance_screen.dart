// import 'package:flutter/material.dart';
// import 'package:sales_ordering_app/model/attendance_model.dart';
// import 'package:sales_ordering_app/service/apiservices.dart';


// class AttendancePage extends StatefulWidget {
//   @override
//   _AttendancePageState createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage> {
//   ApiService apiService = ApiService(baseUrl: 'https://demov15.turqosoft.com/api');
//   bool isLoading = true;
//   AttendanceDetails? attendanceDetails;

//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }

//   void fetchData() async {
//     await apiService.attendance();
//     setState(() {
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Attendance Details'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: attendanceDetails?.data?.length ?? 0,
//               itemBuilder: (context, index) {
//                 Data? data = attendanceDetails?.data?[index];
//                 return ListTile(
//                   title: Text(data?.employeeName ?? 'No Name'),
//                   subtitle: Text('${data?.status} on ${data?.attendanceDate}'),
//                 );
//               },
//             ),
//     );
//   }
// }
