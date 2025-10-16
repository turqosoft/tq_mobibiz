import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:intl/intl.dart';

class PurchaseRequestListScreen extends StatefulWidget {
  @override
  _PurchaseRequestListScreenState createState() =>
      _PurchaseRequestListScreenState();
}

class _PurchaseRequestListScreenState extends State<PurchaseRequestListScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
void initState() {
  super.initState();
  _fromDate = DateTime.now(); // Default 'From Date' as today
  _toDate = DateTime.now(); // Default 'To Date' as today

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _applyFilter();  // This will load filtered data on startup
  });
}

  void _showPurchaseRequestDialog(BuildContext context, String purchaseRequestName, String supplierConfirmation) {
    final provider = context.read<SalesOrderProvider>();
    provider.fetchPurchaseRequestDetails(purchaseRequestName);

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<SalesOrderProvider>(
          builder: (context, provider, child) {
            if (provider.isDetailLoading) {
              return AlertDialog(
                title: Text("Loading..."),
                content: Center(child: CircularProgressIndicator()),
              );
            }

            final purchaseRequest = provider.selectedPurchaseRequest;
            if (purchaseRequest == null) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("Failed to load details"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"),
                  ),
                ],
              );
            }

           
            return AlertDialog(
  title: Text("Purchase Request: ${purchaseRequest['name']}"),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...purchaseRequest['items'].map<Widget>((item) {
        return ListTile(
          title: Text(item['item_name']),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Qty: ${item['qty']} ${item['uom']}"),
              Text("Rate: ${item['price_list_rate']}"),
            ],
          ),
        );
      }).toList(),
      const SizedBox(height: 10),
      Text(
        "Supplier Confirmation: $supplierConfirmation",
        style: TextStyle(
          color: supplierConfirmation == "Accepted"
              ? Colors.green
              : supplierConfirmation == "Rejected"
                  ? Colors.red
                  : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (supplierConfirmation == "Pending") ...[
        const SizedBox(height: 10),
        const Text(
          "Would you like to accept or reject this request?",
          textAlign: TextAlign.center,
        ),
      ],
    ],
  ),
  actions: [
    if (supplierConfirmation == "Pending") ...[
      TextButton(
        onPressed: () {
          provider.updateSupplierConfirmation(purchaseRequestName, "Rejected");
          Navigator.pop(context);
        },
        child: Text("Reject", style: TextStyle(color: Colors.red)),
      ),
      TextButton(
        onPressed: () {
          provider.updateSupplierConfirmation(purchaseRequestName, "Accepted");
          Navigator.pop(context);
        },
        child: Text("Accept", style: TextStyle(color: Colors.green)),
      ),
    ],
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text("Close"),
    ),
  ],
);

          },
        );
      },
    );
  }


void _selectDate(BuildContext context, bool isFromDate) async {
  DateTime initialDate = isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now();
  DateTime firstDate = DateTime(2000);
  DateTime lastDate = DateTime(2100);

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (pickedDate != null) {
    setState(() {
      if (isFromDate) {
        _fromDate = pickedDate;
        if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
          _toDate = _fromDate; // Ensure valid range
        }
      } else {
        _toDate = pickedDate;
        if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
          _fromDate = _toDate; // Ensure valid range
        }
      }
    });

    _applyFilter(); // Auto-update list
  }
}



void _applyFilter() {
  String? fromDateStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
  String? toDateStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;

  context.read<SalesOrderProvider>().fetchPurchaseRequests(fromDate: fromDateStr, toDate: toDateStr);
}


  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });

    context.read<SalesOrderProvider>().fetchPurchaseRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Purchase Requests",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: Column(
        children: [
          // Date Filter UI


Padding(
  padding: const EdgeInsets.all(16.0),
  child: Wrap(
    spacing: 10.0, // Space between buttons
    runSpacing: 10.0, // Space between wrapped lines
    alignment: WrapAlignment.center, // Center align when wrapping
    children: [
      ElevatedButton(
        onPressed: () => _selectDate(context, true),
        child: Text(
          _fromDate != null
              ? "From: ${DateFormat('dd-MM-yyyy').format(_fromDate!)}"
              : "Select From Date",
        ),
      ),
      ElevatedButton(
        onPressed: () => _selectDate(context, false),
        child: Text(
          _toDate != null
              ? "To: ${DateFormat('dd-MM-yyyy').format(_toDate!)}"
              : "Select To Date",
        ),
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _clearFilter,
        tooltip: "Clear Filter",
      ),
    ],
  ),
),

// Total Count Display
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Consumer<SalesOrderProvider>(
    builder: (context, provider, child) {
      return Text(
        "Total Purchase Requests: ${provider.totalCount}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    },
  ),
),
          // Purchase Request List
          Expanded(
            child: Consumer<SalesOrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(child: Text(provider.errorMessage!));
                }

                if (provider.purchaseRequests.isEmpty) {
                  return const Center(child: Text('No purchase requests found.'));
                }

                final cardColors = [
                  const Color.fromARGB(255, 205, 227, 225),
                  const Color.fromARGB(255, 205, 213, 221),
                ];

                return ListView.builder(
                  itemCount: provider.purchaseRequests.length,
                  itemBuilder: (context, index) {
                    final request = provider.purchaseRequests[index];
                    final cardColor = cardColors[index % cardColors.length];

                    String formatDate(String? date) {
                      if (date == null || date.isEmpty) return 'N/A';
                      try {
                        DateTime parsedDate = DateTime.parse(date);
                        return DateFormat('dd-MM-yyyy').format(parsedDate);
                      } catch (e) {
                        return 'Invalid Date';
                      }
                    }

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text(request['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Required By: ${formatDate(request['required_by'])}'),
                            Text.rich(
                              TextSpan(
                                text: 'Supplier Confirmation: ',
                                children: [
                                  TextSpan(
                                    text: request['supplier_confirmation'] ?? 'Pending',
                                    style: TextStyle(
                                      color: request['supplier_confirmation'] == "Accepted"
                                          ? Colors.green
                                          : request['supplier_confirmation'] == "Rejected"
                                              ? Colors.red
                                              : const Color.fromARGB(255, 4, 130, 247),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          request['docstatus'] == 0
                              ? 'Draft'
                              : request['docstatus'] == 1
                                  ? 'Submitted'
                                  : 'Cancelled',
                          style: TextStyle(
                            color: request['docstatus'] == 1 ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () {
                          _showPurchaseRequestDialog(context, request['name'], request['supplier_confirmation'] ?? "Pending");
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
floatingActionButton: FloatingActionButton(
  onPressed: () {
    if (_fromDate == null && _toDate == null) {
      // No filter applied, fetch all data
      context.read<SalesOrderProvider>().fetchPurchaseRequests();
    } else {
      // Apply the existing filter
      _applyFilter();
    }
  },
  backgroundColor: AppColors.primaryColor,
  child: const Icon(Icons.refresh),
),


    );
  }
}