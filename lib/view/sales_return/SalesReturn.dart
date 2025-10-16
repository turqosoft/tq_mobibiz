import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:sales_ordering_app/view/sales_return/ReturnItemScreen.dart';


class SalesReturnScreen extends StatefulWidget {
  @override
  _SalesReturnScreenState createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  int _deliveryNotesCount = 0;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now();
    _toDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  Future<void> _fetchDeliveryNotesCount() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      final count = await provider.fetchDeliveryNotesCount(
        context,
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
      );
      setState(() {
        _deliveryNotesCount = count;
      });
    } catch (e) {
      debugPrint('Error fetching delivery notes count: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = pickedDate;
        } else {
          _toDate = pickedDate;
        }
      });
      _applyFilters();
    }
  }

  Future<void> _applyFilters({bool clearFilters = false}) async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      final fromDateStr = clearFilters ? null : (_fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null);
      final toDateStr = clearFilters ? null : (_toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null);

      await provider.fetchDeliveryNotes(
        context,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      final count = await provider.fetchDeliveryNotesCount(
        context,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      setState(() {
        _deliveryNotesCount = count;
      });
    } catch (e) {
      debugPrint('Error applying filters: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // Helper function to get color based on status
  Color getStatusColor(String status) {
    switch (status) {
      case "Draft":
        return Colors.orange;
      case "To Bill":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      case "Return Issued":
        return Colors.purple;
      case "Cancelled":
        return Colors.red;
      case "Closed":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Sales Return",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () {
          Navigator.pop(context);
        },
        isAction: false,
      ),
      body: Column(
        children: [
          Column(
            children: [
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      onPressed: () {
        setState(() {
          _fromDate = null;
          _toDate = null;
        });
        _applyFilters(clearFilters: true);
      },
      icon: const Icon(Icons.clear, color: Colors.black),
      tooltip: "Clear Filters",
    ),
  ],
),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Total Delivery Notes: $_deliveryNotesCount",
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _applyFilters,
              child: Consumer<SalesOrderProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredNotes = provider.deliveryNotes.toList();

                  if (filteredNotes.isEmpty) {
                    return const Center(child: Text("No Delivery Notes Found"));
                  } else {
                    return ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return _buildDeliveryNoteCard(context, note, index);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNoteCard(
      BuildContext context, Map<String, dynamic> note, int index) {
    final cardColors = [
      const Color.fromARGB(255, 205, 227, 225),
      const Color.fromARGB(255, 205, 213, 221),
    ];
    final cardColor = cardColors[index % cardColors.length];

    String postingDate = 'Unknown';
    if (note['posting_date'] != null) {
      try {
        final date = DateTime.parse(note['posting_date']);
        postingDate = DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        postingDate = 'Invalid Date';
      }
    }

    final status = note['is_return'] == 1 ? "Return Issued" : note['status'] ?? 'Unknown';
    final statusColor = getStatusColor(status);

    return Card(
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
                  note['name'] ?? 'Unnamed Delivery Note',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (status == "To Bill")
                  IconButton(
                    icon: const Icon(
                      Icons.assignment_return_rounded,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnItemScreen(note: note),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text("Title: ${note['title'] ?? 'N/A'}"),
            Text(
              "Status: $status",
              style: TextStyle(color: statusColor),
            ),
            Text("Posted: $postingDate"),
            Text("Grand Total: ${note['grand_total'] ?? 'N/A'}"),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}
