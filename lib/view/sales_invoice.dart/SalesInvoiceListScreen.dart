import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

class SalesInvoiceScreen extends StatefulWidget {
  @override
  _SalesInvoiceScreenState createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();


int limitStart = 0;
final int pageLength = 10; // or any number you want per page

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
  bool isFromDate,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    // Display in dd-MM-yyyy format
    final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    controller.text = formatted;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });

    // Trigger filter only if both dates are selected
    if (_fromDate != null && _toDate != null) {
      _getFilteredInvoices();
    }
  }
}


Future<void> _getFilteredInvoices() async {
  final startDate = "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
  final endDate = "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";

  await Provider.of<SalesOrderProvider>(context, listen: false)
      .getSalesInvoiceDateFilter(context, startDate, endDate);
}


void _showSearchPopup(BuildContext context) {
  final _invoiceController = TextEditingController();
  final _customerController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Search Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _invoiceController,
              decoration: InputDecoration(
                hintText: 'Enter Invoice Name',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _customerController,
              decoration: InputDecoration(
                hintText: 'Enter Customer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _getSearchInvoiceList(
                _invoiceController.text,
                _customerController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      );
    },
  );
}


  // void _getSalesInvoiceList() {
  //   // Call provider method to fetch data
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   provider.getSalesInvoice(context, 0, 10); // You can use limit/page values
  // }
  Future<void> _getSalesInvoiceList() async {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  await provider.getSalesInvoice(context, limitStart, pageLength);
}


  Future<void> _getSearchInvoiceList(
    String? invoiceId, String? customerId) async {
  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  try {
    await provider.getSearchSalesInvoice(context, invoiceId, customerId);
  } catch (e) {
    print('Error searching invoice: $e');
  }
}

Future<void> _loadMoreInvoices({required bool next}) async {
  setState(() {
    if (next) {
      limitStart += pageLength;
    } else {
      limitStart = (limitStart - pageLength).clamp(0, limitStart);
    }
  });

  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  await provider.getSalesInvoice(context, limitStart, pageLength);
}



  @override
  void initState() {
    super.initState();
    _getSalesInvoiceList(); // Initial fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Date Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'From Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, _fromDateController, true),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _toDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, _toDateController, false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search and Refresh Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _showSearchPopup(context),
                  ),
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () {
    setState(() {
      _fromDateController.clear();
      _toDateController.clear();
      _fromDate = null;
      _toDate = null;
    });
    _getSalesInvoiceList();
  },
),

                ],
              ),
            ),
          ),
          
          // Invoice List (watch provider)
Expanded(
  child: Consumer<SalesOrderProvider>(
    builder: (context, provider, _) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (provider.errorMessage != null) {
        return Center(child: Text(provider.errorMessage!));
      }

      final invoices = provider.salesInvoiceList?.data ?? [];

      if (invoices.isEmpty) {
        return const Center(child: Text('No Sales Invoices found.'));
      }

      return ListView.builder(
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              constraints: const BoxConstraints(minHeight: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Invoice Name', invoice.name, Icons.receipt_long),
                  _buildRow('Customer', invoice.customer, Icons.person),
                  _buildRow('Posting Date', _formatDate(invoice.postingDate), Icons.date_range),
                  _buildRow('Due Date', _formatDate(invoice.dueDate), Icons.event),
                  _buildRow('Status', invoice.status, Icons.info_outline),
                  _buildRow('Grand Total', '₹ ${invoice.grandTotal?.toStringAsFixed(2) ?? "0.00"}', Icons.attach_money),
                ],
              ),
            ),
          );
        },
      );
    },
  ),
),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
  child: Consumer<SalesOrderProvider>(
    builder: (context, provider, _) {
      final invoices = provider.salesInvoiceList?.data ?? [];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: limitStart > 0
                ? () => _loadMoreInvoices(next: false)
                : null, // disables button when on first page
            child: Text('Previous'),
          ),
          ElevatedButton(
            onPressed: invoices.length < pageLength
                ? null // disables "Next" button if no more data
                : () => _loadMoreInvoices(next: true),
            child: Text('Next'),
          ),
        ],
      );
    },
  ),
),


],),);
    
  }
Widget _buildRow(String label, String? value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}


String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}'; // Format: DD/MM/YYYY
  } catch (e) {
    return dateStr; // If parsing fails, return as-is
  }
}

}
