import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import 'maintenanceVistScreen.dart';

class MaintenanceVisitListScreen extends StatefulWidget {
  const MaintenanceVisitListScreen({super.key});

  @override
  State<MaintenanceVisitListScreen> createState() =>
      _MaintenanceVisitListScreenState();
}

class _MaintenanceVisitListScreenState
    extends State<MaintenanceVisitListScreen> {
  final List<Color> cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];

  String _searchQuery = '';
  String? _selectedCompletionStatus;
  String? _selectedMaintenanceType;

  final List<String> completionStatuses = [
    'Fully Completed',
    'Partially Completed',
    'Not Started',
  ];

  final List<String> maintenanceTypes = [
    'Scheduled',
    'Unscheduled',
    'Breakdown',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesOrderProvider>().fetchMaintenanceVisitList();
    });
  }

  // List<Map<String, dynamic>> _filteredList(
  //     List<Map<String, dynamic>> list) {
  //   return list.where((item) {
  //     final matchesSearch = _searchQuery.isEmpty ||
  //         (item['name'] ?? '')
  //             .toString()
  //             .toLowerCase()
  //             .contains(_searchQuery.toLowerCase()) ||
  //         (item['customer'] ?? '')
  //             .toString()
  //             .toLowerCase()
  //             .contains(_searchQuery.toLowerCase());
  //
  //     final matchesCompletion = _selectedCompletionStatus == null ||
  //         item['completion_status'] == _selectedCompletionStatus;
  //
  //     final matchesType = _selectedMaintenanceType == null ||
  //         item['maintenance_type'] == _selectedMaintenanceType;
  //
  //     return matchesSearch && matchesCompletion && matchesType;
  //   }).toList();
  // }

  List<Map<String, dynamic>> _filteredList(List<Map<String, dynamic>> list) {
    return list.where((item) {
      // Exclude submitted records
      if ((item['status'] ?? '').toString().toLowerCase() == 'submitted') {
        return false;
      }

      final matchesSearch = _searchQuery.isEmpty ||
          (item['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (item['customer'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCompletion = _selectedCompletionStatus == null ||
          item['completion_status'] == _selectedCompletionStatus;

      final matchesType = _selectedMaintenanceType == null ||
          item['maintenance_type'] == _selectedMaintenanceType;

      return matchesSearch && matchesCompletion && matchesType;
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 0, 0, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Color _completionStatusColor(String? status) {
    switch (status) {
      case 'Fully Completed':
        return Colors.green;
      case 'Partially Completed':
        return Colors.orange;
      case 'Not Started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text("Completion Status"),
                  Wrap(
                    spacing: 8,
                    children: completionStatuses.map((s) {
                      final selected = _selectedCompletionStatus == s;
                      return FilterChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            _selectedCompletionStatus = val ? s : null;
                          });
                          setState(() {
                            _selectedCompletionStatus = val ? s : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Maintenance Type"),
                  Wrap(
                    spacing: 8,
                    children: maintenanceTypes.map((t) {
                      final selected = _selectedMaintenanceType == t;
                      return FilterChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            _selectedMaintenanceType = val ? t : null;
                          });
                          setState(() {
                            _selectedMaintenanceType = val ? t : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCompletionStatus = null;
                          _selectedMaintenanceType = null;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black),
                      child: const Text("Clear Filters"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final color = cardColors[index % cardColors.length];
    return GestureDetector(
        onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaintenanceVisitScreen(
            maintenanceVisitName: item['name'],
          ),
        ),
      );
    },
    child: Card(
    // return Card(
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '--',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.black54),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item['customer'] ?? '--',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.black54),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(item['mntc_date']),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 13, color: Colors.black54),
                      const SizedBox(width: 3),
                      Text(
                        _formatTime(item['mntc_time']),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _completionStatusColor(item['completion_status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['completion_status'] ?? '--',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.build_outlined,
                        size: 13, color: Colors.black54),
                    const SizedBox(width: 3),
                    Text(
                      item['maintenance_type'] ?? '--',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesOrderProvider>();
    final filtered = _filteredList(provider.maintenanceVisitList);

    return Scaffold(
      appBar: CommonAppBar(
        title: "Maintenance Visits",
        actions: IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilterSheet(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name or customer...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Active filter chips
          if (_selectedCompletionStatus != null ||
              _selectedMaintenanceType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (_selectedCompletionStatus != null)
                    Chip(
                      label: Text(_selectedCompletionStatus!),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(
                              () => _selectedCompletionStatus = null),
                    ),
                  const SizedBox(width: 8),
                  if (_selectedMaintenanceType != null)
                    Chip(
                      label: Text(_selectedMaintenanceType!),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(
                              () => _selectedMaintenanceType = null),
                    ),
                ],
              ),
            ),

          // List
          Expanded(
            child: provider.isLoadingMaintenanceVisits
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
                child: Text("No Maintenance Visits Found"))
                : RefreshIndicator(
              onRefresh: () =>
                  provider.fetchMaintenanceVisitList(),
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildCard(filtered[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}