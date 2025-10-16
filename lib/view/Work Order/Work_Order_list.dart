import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class WorkOrderListScreen extends StatefulWidget {
  @override
  _WorkOrderListScreenState createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();



@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
  _scrollController.addListener(_scrollListener);

  // Fetch initial data
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    provider.fetchWorkOrders(context);
    provider.fetchWorkOrderCount(context);
  });
}


  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      Provider.of<SalesOrderProvider>(context, listen: false)
          .fetchWorkOrders(context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final provider = Provider.of<SalesOrderProvider>(context);

  return Scaffold(
    appBar: CommonAppBar(
      title: 'Work Orders',
      onBackTap: () {
        Navigator.pop(context);
      },
      backgroundColor: AppColors.primaryColor,
      actions: Row(
        children: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String searchQuery = '';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _focusNode.requestFocus();
                  });
                  return AlertDialog(
                    title: Text('Search Work Orders'),
                    content: TextField(
                      focusNode: _focusNode,
                      onChanged: (value) {
                        searchQuery = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Item Name/Production Item',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (searchQuery.isNotEmpty) {
                            provider.searchWorkOrders(context, searchQuery);
                            provider.fetchWorkOrderCount(context, searchQuery: searchQuery);

                          }
                          Navigator.pop(context);
                        },
                        child: Text('Search'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              provider.refreshWorkOrders(context);
              provider.fetchWorkOrderCount(context);
            },
          ),
        ],
      ),
    ),
    body: provider.isWorkOrdersLoading && provider.workOrders == null
        ? Center(child: CircularProgressIndicator())
        : provider.hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load work orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => provider.refreshWorkOrders(context),
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Work Orders: ${provider.workOrderCount}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => provider.refreshWorkOrders(context),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: provider.workOrders!.length +
                            (provider.isWorkOrdersLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.workOrders!.length) {
                            return provider.isWorkOrdersLoading
                                ? Center(child: CircularProgressIndicator())
                                : provider.hasMoreData
                                    ? SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'No more work orders to show.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                          }
                          final workOrder = provider.workOrders![index];
                          return _buildWorkOrderCard(workOrder, index);
                        },
                      ),
                    ),
                  ),
                ],
              ),
  );
}

  Widget _buildWorkOrderCard(Map<String, dynamic> workOrder, int index) {
    final cardColors = [
      Color.fromARGB(255, 205, 227, 225),
      Color.fromARGB(255, 205, 213, 221),
    ];
    final cardColor = cardColors[index % cardColors.length];

    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workOrder['name'] ?? 'No Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            _buildDetailText('Production Item', workOrder['production_item']),
            _buildDetailText('Item Name', workOrder['item_name']),
            _buildStatusText(workOrder['status']),
            _buildDetailText('Creation Date', workOrder['creation'], true),
          ],
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              displayValue,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(String? status) {
    final statusText = status ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                color: _getStatusColor(statusText),
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'not started':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      case 'in process':
        return const Color.fromARGB(235, 6, 46, 247);
      case 'completed':
        return const Color.fromARGB(255, 0, 214, 7);
      default:
        return Colors.black;
    }
  }
}

