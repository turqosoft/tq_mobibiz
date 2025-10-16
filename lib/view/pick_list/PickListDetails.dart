import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';


class PickListDetailsPage extends StatefulWidget {
  final String pickListName;

  const PickListDetailsPage({required this.pickListName});

  @override
  _PickListDetailsPageState createState() => _PickListDetailsPageState();
}

class _PickListDetailsPageState extends State<PickListDetailsPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<SalesOrderProvider>(context, listen: false)
        .fetchPickListDetails(context, widget.pickListName));
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Pick List Details"),
      backgroundColor: AppColors.primaryColor,
    ),
    body: Consumer<SalesOrderProvider>(
      builder: (context, provider, child) {
        if (provider.isDetailsLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (provider.hasDetailsError) {
          return Center(child: Text(provider.detailsErrorMessage ?? "Error loading details"));
        } else if (provider.pickListDetails == null) {
          return Center(child: Text("No details available"));
        }

        final details = provider.pickListDetails!;
        final List<dynamic> locations = details["locations"] ?? [];

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem("Name", details["name"]),
              _buildDetailItem("Purpose", details["purpose"]),
              _buildDetailItem("Customer", details["customer"]),
              _buildDetailItem("Warehouse", details["parent_warehouse"]),
              _buildDetailItem("Employee Name", details["employee_name"]),

              SizedBox(height: 16),
              Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final item = locations[index];
                    final String itemKey = item["name"];
                    
                    if (!_controllers.containsKey(itemKey)) {
                      _controllers[itemKey] = TextEditingController(text: item["picked_qty"].toString());
                    }

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem("", "${item["item_name"]} (${item["item_code"]})"),
                            
                            // ✅ Display item_name_local if available
                            if (item["item_name_local"] != null)
                              _buildDetailItem("",item["item_name_local"]),

                            _buildDetailItem("Quantity:", "${item["qty"]} ${item["uom"]}"),
                            SizedBox(height: 8),
                            Text("Picked Qty:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            TextField(
                              controller: _controllers[itemKey],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  List<Map<String, dynamic>> updatedLocations = locations.map((item) {
                    String itemKey = item["name"];
                    double newPickedQty = double.tryParse(_controllers[itemKey]?.text ?? "") ?? item["picked_qty"];

                    return {
                      "name": itemKey,
                      "item_code": item["item_code"],
                      "item_name": item["item_name"],
                      "warehouse": item["warehouse"],
                      "qty": item["qty"],
                      "stock_qty": item["stock_qty"],
                      "picked_qty": newPickedQty,
                      "uom": item["uom"],
                    };
                  }).toList();

                  bool success = await provider.updatePickedQtyList(
                    context,
                    widget.pickListName,
                    updatedLocations,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("All picked quantities updated successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update picked quantities")),
                    );
                  }
                },
                child: Text("Update All"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  textStyle: TextStyle(fontSize: 16),
                  backgroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}



  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value ?? "N/A", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
