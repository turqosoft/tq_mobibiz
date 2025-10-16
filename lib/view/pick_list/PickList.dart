import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/pick_list/PickListDetails.dart';


// class PickListPage extends StatefulWidget {
//   @override
//   _PickListPageState createState() => _PickListPageState();
// }

// class _PickListPageState extends State<PickListPage> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() => Provider.of<SalesOrderProvider>(context, listen: false).fetchPickList(context));
//   }

//   Color getStatusColor(String status) {
//     switch (status) {
//       case 'Open':
//         return const Color.fromARGB(255, 65, 211, 237);
//       case 'Draft':
//         return const Color.fromARGB(255, 244, 77, 31);
//       case 'Completed':
//         return const Color.fromARGB(255, 143, 234, 113);
//       case 'Cancelled':
//         return Colors.redAccent;
//       default:
//         return Colors.white;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: "Pick List",
//         automaticallyImplyLeading: true,
//         backgroundColor: AppColors.primaryColor,
//         onBackTap: () {
//           Navigator.pop(context);
//         },
//         isAction: false,
//       ),
//       body: Consumer<SalesOrderProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return Center(child: CircularProgressIndicator());
//           } else if (provider.hasError) {
//             return Center(child: Text(provider.errorMessage ?? "Error loading data"));
//           } else if (provider.pickList.isEmpty) {
//             return Center(child: Text("No Pick List data available"));
//           }

//           // Filter pick list where status is "Draft"
//           final draftPickList = provider.pickList.where((item) {
//             return item["status"]?.toLowerCase() == "draft";
//           }).toList();

//           if (draftPickList.isEmpty) {
//             return Center(child: Text("No Pick List data available"));
//           }

//           final cardColors = [
//             const Color.fromARGB(255, 205, 227, 225),
//             const Color.fromARGB(255, 205, 213, 221),
//           ];

//           return ListView.builder(
//             itemCount: draftPickList.length,
//             itemBuilder: (context, index) {
//               final pickItem = draftPickList[index];
//               final cardColor = cardColors[index % cardColors.length];
//               final statusColor = getStatusColor(pickItem["status"] ?? "");

//               return GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PickListDetailsPage(pickListName: pickItem["name"]),
//                     ),
//                   );
//                 },
//                 child: Card(
//                   color: cardColor,
//                   margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: ListTile(
//                     title: Text(
//                       pickItem["name"] ?? "Unknown",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text.rich(
//                           TextSpan(
//                             text: "Status: ",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                             children: [
//                               TextSpan(
//                                 text: pickItem["status"] ?? "N/A",
//                                 style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Text("Customer: ${pickItem["customer"] ?? "N/A"}"),
//                         Text("Picked By: ${pickItem["employee_name"] ?? "Not Available"}"),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

class PickListPage extends StatefulWidget {
  @override
  _PickListPageState createState() => _PickListPageState();
}

class _PickListPageState extends State<PickListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<SalesOrderProvider>(context, listen: false).fetchPickList(context));
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color.fromARGB(255, 65, 211, 237);
      case 'Draft':
        return const Color.fromARGB(255, 244, 77, 31);
      case 'Completed':
        return const Color.fromARGB(255, 143, 234, 113);
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Pick List",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.hasError) {
            return Center(child: Text(provider.errorMessage ?? "Error loading data"));
          } else if (provider.pickList.isEmpty) {
            return Center(child: Text("No Pick List data available"));
          }

          // Filter pick list where status is "Draft"
          final draftPickList = provider.pickList.where((item) {
            return item["status"]?.toLowerCase() == "draft";
          }).toList();

          // Count of draft pick lists displayed
          final draftPickListCount = draftPickList.length;

          if (draftPickList.isEmpty) {
            return Center(child: Text("No Draft Pick List data available"));
          }

          final cardColors = [
            const Color.fromARGB(255, 205, 227, 225),
            const Color.fromARGB(255, 205, 213, 221),
          ];

          return Column(
            children: [
              // Display draft count as plain text
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Total Pick Lists: $draftPickListCount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
              // List of Draft Pick Lists
              Expanded(
                child: ListView.builder(
                  itemCount: draftPickList.length,
                  itemBuilder: (context, index) {
                    final pickItem = draftPickList[index];
                    final cardColor = cardColors[index % cardColors.length];
                    final statusColor = getStatusColor(pickItem["status"] ?? "");

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickListDetailsPage(pickListName: pickItem["name"]),
                          ),
                        );
                      },
                      child: Card(
                        color: cardColor,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            pickItem["name"] ?? "Unknown",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: "Status: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: pickItem["status"] ?? "N/A",
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Text("Customer: ${pickItem["customer"] ?? "N/A"}"),
                              Text("Picked By: ${pickItem["employee_name"] ?? "Not Available"}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
