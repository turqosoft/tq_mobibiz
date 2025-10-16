import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/model/material_demand_model.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/view/home/home.dart';
import 'package:sales_ordering_app/view/material_demand/MaterialDemandScreen.dart';

class MaterialDemandStatusScreen extends StatefulWidget {
  @override
  _MaterialDemandStatusScreenState createState() =>
      _MaterialDemandStatusScreenState();
}

class _MaterialDemandStatusScreenState
    extends State<MaterialDemandStatusScreen> {
  DateTime? _fromDate = DateTime.now().subtract(Duration(days: 30));
  DateTime? _toDate = DateTime.now();
  int _materialDemandCount = 0;

  final List<dynamic> _materialDemands = [];
  bool _isLoading = false;
  int _currentOffset = 0;
  final int _pageSize = 60;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchMaterialDemands();
  }

  Future<void> _fetchMaterialDemandCount() async {
    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      final count = await provider.fetchMaterialDemandCount(
        context,
        _fromDate,
        _toDate,
      );
      setState(() {
        _materialDemandCount = count;
      });
    } catch (e) {
      debugPrint('Error fetching material demand count: $e');
    }
  }

  Future<void> _fetchMaterialDemands() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      final newDemands = await provider.fetchMaterialDemands(
        context,
        _fromDate,
        _toDate,
        offset: _currentOffset,
        limit: _pageSize,
      );

      if (newDemands != null && newDemands.isNotEmpty) {
        setState(() {
          _materialDemands.addAll(newDemands);
          _currentOffset += _pageSize;
          _materialDemandCount = _materialDemands.length; // Update the count
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more material demands: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        _resetData();
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
        _resetData();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _resetData();
    });
  }

  void _resetData() {
    _materialDemands.clear();
    _currentOffset = 0;
    _hasMoreData = true;
    _fetchMaterialDemandCount(); // Fetch updated count
    _fetchMaterialDemands();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text('Material Demand Status'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
         actions: [
    IconButton(
      icon: Icon(Icons.home, color: Colors.white),
      tooltip: 'Go to Home',
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()), 
          (route) => false, // Removes all previous routes (makes HomeScreen the new root)
        );
      },
    ),
  ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: <Widget>[
                TextButton(
                  onPressed: () => _selectFromDate(context),
                  child: Text(
                      'From: ${_fromDate != null ? DateFormat('dd-MM-yyyy').format(_fromDate!) : 'Select'}'),
                ),
                TextButton(
                  onPressed: () => _selectToDate(context),
                  child: Text(
                      'To: ${_toDate != null ? DateFormat('dd-MM-yyyy').format(_toDate!) : 'Select'}'),
                ),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: Text('Clear Filter'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Material Demands: $_materialDemandCount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    _hasMoreData &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _fetchMaterialDemands();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: _materialDemands.length + 1,
                itemBuilder: (context, index) {
                  if (index == _materialDemands.length) {
                    return _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox.shrink();
                  }

                  final demand = _materialDemands[index];
                  return _buildMaterialDemandCard(
                      context, provider, demand, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialDemandCard(BuildContext context,
      SalesOrderProvider provider, Map<String, dynamic> demand, int index) {
    final cardColors = [
      Color.fromARGB(255, 205, 227, 225),
      Color.fromARGB(255, 205, 213, 221),
    ];
    final cardColor = cardColors[index % cardColors.length];

    String creationDate = 'Unknown';
    if (demand['creation'] != null) {
      try {
        final date = DateTime.parse(demand['creation']);
        creationDate = DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        creationDate = 'Invalid Date';
      }
    }

    String documentStatus = demand['document_status'] ?? 'Unknown';

    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  demand['name']?.trim() ?? 'No Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                Row(
                  children: [
                    if (documentStatus == 'Released')
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () async {
                          final demandDetails =
                              await provider.getMaterialDemandDetails(
                                  context, demand['name']);
                          if (demandDetails != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MaterialDemandScreen(
                                  demandName: demand['name'],
                                  materialDemand:
                                      MaterialDemand.fromMap(demandDetails),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to fetch material demand details.')),
                            );
                          }
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.visibility, color: Colors.black),
                      onPressed: () =>
                          _showDemandDetails(context, provider, demand['name']),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatusText(demand['docstatus']),
            _buildDetailText('Document Status', documentStatus),
            _buildDetailText('Creation Date', creationDate),
            _buildDetailText('Schedule Date', demand['schedule_date'], true),
          ],
        ),
      ),
    );
  }

  Future<void> _showDemandDetails(BuildContext context,
      SalesOrderProvider provider, String demandName) async {
    try {
      final demandDetails =
          await provider.getMaterialDemandDetails(context, demandName);

      if (demandDetails != null) {
        final items = demandDetails['items'] ?? [];
        final deliveryStatus = demandDetails['delivery_status'] ?? 'Unknown';


        showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text(
        'Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.deepPurple,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Status Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Status: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$deliveryStatus',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey),
            SizedBox(height: 10),

            // Items Section
            ...items.asMap().entries.map<Widget>((entry) {
              final index = entry.key + 1;
              final item = entry.value;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index: ${item['item_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.code, size: 18, color: Colors.grey[600]),
                          SizedBox(width: 6),
                          Text(
                            'Code: ${item['item_code'] ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 18, color: Colors.grey[600]),
                          SizedBox(width: 6),
                          Text(
                            'Quantity: ${item['qty'] ?? 'Unknown'} ${item['uom'] ?? ''}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (item['notes'] != null && item['notes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note, size: 18, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Note: ${item['notes']}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Close',
            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  },
);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch material demand details.')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching demand details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching details.')),
      );
    }
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

Widget _buildStatusText(int status) {
  final statusText = status == 0
      ? 'Draft'
      : status == 1
          ? 'Submitted'
          : 'Status: $status';

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
              color: status == 0
                  ? Colors.orange
                  : status == 1
                      ? Colors.blue
                      : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
    }