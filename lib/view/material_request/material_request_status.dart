import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/view/material_request/MaterialRequestScreen.dart';

final List<Color> cardColors = [
  Color.fromARGB(255, 205, 227, 225),
  Color.fromARGB(255, 205, 213, 221),
];

class MaterialRequestStatusScreen extends StatefulWidget {
  @override
  _MaterialRequestStatusScreenState createState() =>
      _MaterialRequestStatusScreenState();
}

class _MaterialRequestStatusScreenState
    extends State<MaterialRequestStatusScreen> {
  late ScrollController _scrollController;

String? _selectedFromDate;
String? _selectedToDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMaterialRequests();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchMaterialRequests();
    }
  }

Future<void> _fetchMaterialRequests() async {
  if (mounted) {
    await Provider.of<SalesOrderProvider>(context, listen: false)
        .fetchMaterialRequests(context, fromDate: _selectedFromDate, toDate: _selectedToDate);
  }
}


Future<void> _refreshMaterialRequests() async {
  if (mounted) {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
    });
    await Provider.of<SalesOrderProvider>(context, listen: false)
        .refreshMaterialRequests(context);
  }
}

Future<void> _selectToDate(BuildContext context) async {
  if (_selectedFromDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select From Date first")),
    );
    return;
  }

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedFromDate != null
        ? DateFormat('yyyy-MM-dd').parse(_selectedFromDate!) // Use selected From Date
        : DateTime.now(),
    firstDate: _selectedFromDate != null
        ? DateFormat('yyyy-MM-dd').parse(_selectedFromDate!) // Ensure To Date is after From Date
        : DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    setState(() {
      _selectedToDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    });

    if (_selectedFromDate != null && _selectedToDate != null) {
      await Provider.of<SalesOrderProvider>(context, listen: false)
          .refreshMaterialRequestsWithDateRange(context, _selectedFromDate!, _selectedToDate!);
    }
  }
}

Future<void> _selectFromDate(BuildContext context) async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    setState(() {
      _selectedFromDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      _selectedToDate = null; // Reset "To Date" when "From Date" changes
    });

    // Automatically prompt the user to select "To Date"
    Future.delayed(Duration(milliseconds: 300), () => _selectToDate(context));
  }
}


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
Widget build(BuildContext context) {
  final provider = Provider.of<SalesOrderProvider>(context);

  return Scaffold(
    body: provider.hasError
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 80),
                SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 8),
                Text(
                  'Unable to fetch material requests. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refreshMaterialRequests,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Filter Section with Spacing
Padding(
  padding: const EdgeInsets.all(8.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Text(
      //   "Filter Requests",
      //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      // ),
      // SizedBox(height: 8),

      // Date Filters in Wrap Layout
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: <Widget>[
          // FIXED: Calls _selectFromDate for "From Date"
          TextButton(
            onPressed: () => _selectFromDate(context),
            child: Text(
              'From: ${_selectedFromDate != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(_selectedFromDate!)) : 'Select'}',
              style: TextStyle(fontSize: 14),
            ),
          ),
          // "To Date" should only be selectable after "From Date" is selected
          TextButton(
            onPressed: () => _selectToDate(context),
            child: Text(
              'To: ${_selectedToDate != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(_selectedToDate!)) : 'Select'}',
              style: TextStyle(fontSize: 14),
            ),
          ),
TextButton(
  onPressed: _refreshMaterialRequests,
  child: Text(
    'Clear Filter',
    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  ),


          ),
        ],
      ),

    ],
  ),
),


              // Display Total Requests
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Total Requests: ${provider.totalMaterialRequests}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Material Requests List
              Expanded(
                child: provider.isMaterialRequestsLoading && provider.materialRequests!.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _refreshMaterialRequests,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: provider.materialRequests!.length +
                                (provider.isMaterialRequestsLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.materialRequests!.length) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final request = provider.materialRequests![index];
                              final cardColor = cardColors[index % cardColors.length];

                              return Card(
                                color: cardColor,
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              request['name'] ?? 'No Name',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                          if (request['status'] == 'Draft')
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () => _editMaterialRequest(request),
                                            ),
                                          IconButton(
                                            icon: Icon(Icons.remove_red_eye),
                                            onPressed: () => _showDetailsDialog(request['name']),
                                          ),
                                        ],
                                      ),
                                      _buildDetailText('Type', request['material_request_type']),
                                      _buildStatusText(request['status']),
                                      _buildDetailText('Warehouse', request['set_warehouse']),
                                      _buildDetailText('Transaction Date', request['transaction_date'], true),
                                      _buildDetailText('Schedule Date', request['schedule_date'], true),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
  );
}



  Widget _buildDetailText(String title, String? value, [bool isDate = false]) {
    String displayValue;
    if (isDate && value != null) {
      try {
        final date = DateTime.parse(value);
        displayValue = DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        displayValue = 'Invalid Date';
      }
    } else {
      displayValue = value ?? 'Unknown';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(displayValue),
        ],
      ),
    );
  }

  Widget _buildStatusText(String? status) {
    final statusText = status ?? 'Unknown'; 
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            'Status: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              color: _getStatusColor(statusText), 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
void _showDetailsDialog(String requestName) async {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);

  try {
    final details = await provider.getMaterialRequestDetails(context, requestName);

    if (details != null) {
      final items = details['items'] ?? [];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text( '${details['name']}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Date: ${details['transaction_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(details['transaction_date'])) : 'Unknown'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Loop through items to display their details
                  ...items.map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Code: ${item['item_code']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Item Name: ${item['item_name']}'),
                          Text('Quantity: ${item['qty']}'),
                          Text('UOM: ${item['uom']}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch material request details.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
  void _editMaterialRequest(Map<String, dynamic> request) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    try {
      final details = await provider.getMaterialRequestDetails(context, request['name']);
      if (details != null) {
        debugPrint('Material Request Details: $details');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialRequestScreen(materialRequest: details),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch material request details.')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching material request details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
