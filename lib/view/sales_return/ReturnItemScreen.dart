import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
// import 'package:sales_ordering_app/view/sales_return/ReturnSummaryScreen.dart';
import 'package:sales_ordering_app/view/sales_return/SalesReturn.dart';

class ReturnItemScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  const ReturnItemScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<ReturnItemScreen> createState() => _ReturnItemScreenState();
}

class _ReturnItemScreenState extends State<ReturnItemScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  Map<String, double> _returnQuantities = {};
  String? _customer;
  String? _companyAddress;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryNoteDetails();
  }

  Future<void> _fetchDeliveryNoteDetails() async {
    try {
      final noteDetails = await context
          .read<SalesOrderProvider>()
          .fetchDeliveryNoteItems(context, widget.note['name']);
      setState(() {
        _customer = noteDetails['customer'];
        _companyAddress = noteDetails['company_address'];
        _items = noteDetails['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching delivery note details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _returnItems() async {
  final List<Map<String, dynamic>> returnItems = [];
  bool hasInvalidQuantity = false;

  for (var item in _items) {
    double? returnQty = _returnQuantities[item['item_code']];
    if (returnQty != null && returnQty > 0) {
      if (returnQty > item['qty']) {
        hasInvalidQuantity = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Return quantity for ${item['item_name']} exceeds available quantity"),
            backgroundColor: Colors.red,
          ),
        );
        break;
      } else {
        returnItems.add({
          'item_code': item['item_code'],
          'item_name': item['item_name'],
          'qty': -returnQty,
        });
      }
    }
  }

  if (hasInvalidQuantity) return;

  if (returnItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No items selected for return"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_companyAddress == null || _customer == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Company Address and Customer are required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Extract the selling_price_list from widget.note
  final String? sellingPriceListVariable = widget.note['selling_price_list'];

  // Check if selling_price_list is present
  if (sellingPriceListVariable == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Selling Price List not found for this delivery note"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Return"),
      content: const Text("Are you sure you want to return the selected items?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Confirm"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final provider = context.read<SalesOrderProvider>();

    // Call returnItems and check if it was successful
    final bool success = await provider.returnItems(
      context,
      _companyAddress!,
      _customer!,
      widget.note['name'],
      sellingPriceListVariable,  // Pass the fetched value here
      returnItems,
    );

    if (success) {
      // Show dialog box with the return summary instead of navigating to a new screen
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Return Summary"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${widget.note['name']}"),
              Text("Customer: ${_customer ?? 'N/A'}"),
              const SizedBox(height: 16),
              const Text(
                "Items Returned:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...returnItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "${item['item_name']} (Code: ${item['item_code']}), Qty: ${-item['qty']}",
                ),
              )),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog first
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SalesReturnScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Show error message if the return fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Return Items",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Note Details Section
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivery Note: ${widget.note['name'] ?? 'Unnamed'}",
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          "Title: ${widget.note['title'] ?? 'No Title'}",
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 8.0),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0), // Spacing before item list

                  // Items List Section
                  _items.isEmpty
                      ? const Center(
                          child: Text("No items found for this Delivery Note"))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              return _buildDeliveryNoteCard(
                                  context, _items[index]);
                            },
                          ),
                        ),

                  const SizedBox(height: 16.0), // Spacing before button

                  // Return Items Button
                  ElevatedButton(
                    onPressed: _returnItems,
                    child: const Text("Return Selected Items"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  Widget _buildDeliveryNoteCard(BuildContext context, Map<String, dynamic> item) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Item Name: ${item['item_name']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("Item Code: ${item['item_code']}"),
          Text("Quantity: ${item['qty']} ${item['uom']}"),
          Text("Rate: ${item['rate']}"),
          Text("Amount: ${item['amount']}"),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Return Quantity:"),
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final qty = double.tryParse(value);
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please enter a valid positive quantity."),
                        ),
                      );
                      _returnQuantities.remove(item['item_code']);
                    } else if (qty > item['qty']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Return quantity for ${item['item_name']} cannot exceed ${item['qty']}"),
                        ),
                      );
                      _returnQuantities.remove(item['item_code']);
                    } else {
                      _returnQuantities[item['item_code']] = qty;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Enter Qty",
                    border: OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 8.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

}
