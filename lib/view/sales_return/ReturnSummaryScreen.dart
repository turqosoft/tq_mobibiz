
// import 'package:flutter/material.dart';
// import 'package:sales_ordering_app/utils/app_colors.dart';
// // import 'package:sales_ordering_app/utils/common/common_widgets.dart';
// import 'package:sales_ordering_app/view/sales_return/SalesReturn.dart';  

// class ReturnSummaryScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> returnItems;
//   final String name;
//   final String? customer;

//   const ReturnSummaryScreen({
//     Key? key,
//     required this.returnItems,
//     required this.name,
//     required this.customer,
//   }) : super(key: key);


// AppBar returnSummaryAppBar(BuildContext context) {
//   return AppBar(
//     title: const Text(
//       "Return Summary",
//       style: TextStyle(
//         color: Colors.white, // Adjust this to match your CommonAppBar's text color
//       ),
//     ),
//     backgroundColor: AppColors.primaryColor,
//     automaticallyImplyLeading: false, // Disable default back button
//     leading: IconButton(
//       icon: const Icon(Icons.arrow_back, color: Colors.white),
//       onPressed: () {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => SalesReturnScreen()),
//         );
//       },
//     ),
//     elevation: 4, // Adjust the shadow to match CommonAppBar
//   );
// }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//   appBar: returnSummaryAppBar(context),

//     // appBar: CommonAppBar(
//     //   title: "Return Summary",
//     //   automaticallyImplyLeading: true,
//     //   backgroundColor: AppColors.primaryColor,
//     //   isAction: false,
//     // ),
//     body: Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [

//           Text("Name: $name",style:TextStyle(fontSize: 17, fontWeight:FontWeight.bold )),
//           Text("Customer: ${customer ?? 'N/A'}", style:TextStyle(fontSize: 17 )),
//           const SizedBox(height: 16.0),
//           const Text(
//             'Items Returned',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16.0),
//           Expanded(
//             child: ListView.builder(
//               itemCount: returnItems.length,
//               itemBuilder: (context, index) {
//                 final item = returnItems[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Item Code: ${item['item_code']}"),
//                         Text("Item Name: ${item['item_name']}"),
//                         Text("Return Quantity: ${-item['qty']}"),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//                       const SizedBox(height: 16.0),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SalesReturnScreen(),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primaryColor,
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: const Text("OK"),
//               ),
//             ),
//         ],
//       ),
//     ),
//   );
// }
// }

