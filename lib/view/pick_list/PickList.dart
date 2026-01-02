import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/pick_list/PickListDetails.dart';


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
      case 'Draft':
        return const Color.fromARGB(255, 244, 77, 31);
      default:
        return Colors.black;
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
          // final latestPickList = provider.pickList.first;

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
          Expanded(
          child: RefreshIndicator(
          onRefresh: () async {
          await Provider.of<SalesOrderProvider>(context, listen: false)
              .fetchPickList(context);
          },
          child: ListView.builder(
                  itemCount: draftPickList.length,
                  itemBuilder: (context, index) {
                    final pickItem = draftPickList[index];
                    final alreadyOpened = provider.openedPickLists.contains(pickItem["name"]);
                    final salesOrder = pickItem["sales_order"];
                    final computedStatus =
                    provider.computePickListStatus(pickItem);

                    final statusColors =
                    provider.picklistStatusColor(computedStatus);

                    final cardColor = alreadyOpened
                        ? cardColors[index % cardColors.length]              // Normal card
                        : Colors.yellow.shade200;     // Highlight for untouched

                    final statusColor = getStatusColor(pickItem["status"] ?? "");

                    return GestureDetector(
                      onTap: () {
                        Provider.of<SalesOrderProvider>(context, listen: false)
                            .markPickListOpened(pickItem["name"]);    // 👈 Mark as opened

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickListDetailsPage(
                              pickListName: pickItem["name"],
                            ),
                          ),
                        ).then((_) {
                          Provider.of<SalesOrderProvider>(context, listen: false)
                              .fetchPickList(context);
                        });
                      },
                      child: Card(
                        color: cardColor,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Stack(
                          children: [
                            // MAIN CARD CONTENT
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // LEFT — Existing title
                                    Text(
                                      pickItem["name"] ?? "Unknown",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text("Customer: ${pickItem["customer"] ?? "N/A"}"),
                                    Text("Warehouse: ${pickItem["parent_warehouse"] ?? "Not Available"}"),
                                    if (salesOrder != null) Text("Sales Order: $salesOrder"),
                                  ],
                                ),
                              ),
                            ),
                            // ⭐ TOP-RIGHT STATUS BADGE (small) ⭐

                            if (alreadyOpened)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Builder(
                                  builder: (context) {
                                    final computedStatus = provider.computePickListStatus(pickItem);
                                    final progressColor = provider.picklistStatusColor(computedStatus);

                                    return Container(
                                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: progressColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: progressColor, width: 0.8),
                                      ),
                                      child: Text(
                                        computedStatus,
                                        style: TextStyle(
                                          color: progressColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,          // ⭐ Smaller text
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // ⭐ NEW ICON AT TOP RIGHT ⭐
                            if (!alreadyOpened)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Icon(
                                  Icons.fiber_new,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),

                    );
                  },
                ),
              ),),
            ],
          );
        },
      ),
    );
  }
}
