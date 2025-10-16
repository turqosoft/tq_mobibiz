import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/purchase_receipt_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/purchase_receipt/CreatePurchaseReceipt.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PurchaseReceiptScreen extends StatefulWidget {
  @override
  _PurchaseReceiptScreenState createState() => _PurchaseReceiptScreenState();
}

class _PurchaseReceiptScreenState extends State<PurchaseReceiptScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<SalesOrderProvider>(context, listen: false)
          .fetchPurchaseReceipts(context);
    });
  }
Future<bool> _isPending(String purchaseOrderName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('pending_status_$purchaseOrderName') ?? false;
}

  Color getStatusColor(String status) {
    switch (status) {
      case "Draft":
        return Colors.orange;
      case "To Receive":
        return Colors.blue;
      case "To Receive and Bill":
        return Colors.purple;
      default:
        return const Color.fromARGB(255, 245, 70, 70);
    }
  }
  // ✅ Add this method to refresh data
Future<void> _refreshData() async {
  await Provider.of<SalesOrderProvider>(context, listen: false)
      .fetchPurchaseReceipts(context);
}

Widget _buildPurchaseReceiptCard(
    BuildContext context, Map<String, dynamic> receipt, int index) {
  final cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];
  final cardColor = cardColors[index % cardColors.length];

  String postingDate = 'Unknown';
  if (receipt['schedule_date'] != null) {
    try {
      final date = DateTime.parse(receipt['schedule_date']);
      postingDate = DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      postingDate = 'Invalid Date';
    }
  }

  final status = receipt['status'] ?? 'Unknown';
  final statusColor = getStatusColor(status);

  return FutureBuilder<bool>(
    future: _isPending(receipt['name'] ?? ''),
    builder: (context, snapshot) {
      bool isPending = snapshot.data ?? false;

      return GestureDetector(
        onTap: () async {
          String purchaseOrderName = receipt['name'] ?? '';
          if (purchaseOrderName.isNotEmpty) {
            final provider = Provider.of<SalesOrderProvider>(context, listen: false);
            final orderDetails =
                await provider.fetchPurchaseOrderDetails(purchaseOrderName);

            if (orderDetails != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseReceiptCreateScreen(
                    supplier: orderDetails['supplier'] ?? '',
                    warehouse: orderDetails['set_warehouse'] ?? '',
                    rejectedWarehouse: orderDetails['rejected_warehouse'] ?? '',
                    purchaseOrderName: purchaseOrderName,
                    items: (orderDetails['items'] as List<dynamic>?)?.map((item) {
                          return PurchaseItem.fromJson(item);
                        }).toList() ??
                        [],
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to fetch order details")),
              );
            }
          }
        },
        child: Card(
          margin: const EdgeInsets.all(8.0),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      receipt['name'] ?? 'Unnamed Purchase Receipt',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "In Progress",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text("Supplier: ${receipt['supplier'] ?? 'N/A'}"),
                Text(
                  "Status: $status",
                  style:
                      TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
                Text("Required By: $postingDate"),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
      );
    },
  );
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CommonAppBar(
      title: "Purchase Orders",
      automaticallyImplyLeading: true,
      backgroundColor: AppColors.primaryColor,
      onBackTap: () {
        Navigator.pop(context);
      },
      isAction: false,
    ),
    body: RefreshIndicator(  // ✅ Add pull-to-refresh
      onRefresh: _refreshData, 
      child: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // ✅ Filter purchase receipts based on status
          final filteredReceipts = provider.purchaseReceipts.where((receipt) {
            final status = receipt['status'] ?? '';
            return status == "Draft" || status == "To Receive" || status == "To Receive and Bill";
          }).toList();

          if (filteredReceipts.isEmpty) {
            return Center(child: Text('No relevant Purchase Receipts available'));
          }

          return ListView.builder(
            itemCount: filteredReceipts.length,
            itemBuilder: (context, index) {
              final receipt = filteredReceipts[index];
              return _buildPurchaseReceiptCard(context, receipt, index);
            },
          );
        },
      ),
    ),
  );
}

}


