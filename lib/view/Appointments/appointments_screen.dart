import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../provider/provider.dart';
import '../../utils/common/common_widgets.dart';
import 'package:table_calendar/table_calendar.dart';


enum AppointmentViewType {
  list,
  calendar,
}

const List<String> appointmentStatuses = [
  "Scheduled",
  "Open",
  "Closed",
  "Cancelled",
];

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  AppointmentViewType _currentView = AppointmentViewType.list;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showCalendar = true;
  bool _showFilters = false;

  // Filter variables
  String? _selectedStatus = "Scheduled";
  String? _selectedType;
  DateTimeRange? _dateRange;
  String _selectedDateFilter = "All Time";

  final List<String> _dateFilterOptions = [
    "All Time",
    "Today",
    "Yesterday",
    "This Week",
    "Last Week",
    "This Month",
    "Last Month",
    "Custom Range",
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.microtask(() {
      context.read<SalesOrderProvider>().fetchAppointments();
    });
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
  final List<Color> cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];
  Color statusColor(String status) {
    switch (status) {
      case "Scheduled":
        return Colors.blue;
      case "Open":
        return Colors.orange;
      case "Closed":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Filter Logic
  DateTimeRange? _getDateRangeFromFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case "Today":
        return DateTimeRange(start: today, end: today);
      case "Yesterday":
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case "This Week":
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: weekStart, end: today);
      case "Last Week":
        final lastWeekEnd = today.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeekStart, end: lastWeekEnd);
      case "This Month":
        final monthStart = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: monthStart, end: today);
      case "Last Month":
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: lastMonth, end: lastMonthEnd);
      case "Custom Range":
        return _dateRange;
      default:
        return null;
    }
  }

  void _onDateFilterChanged(String filter) {
    setState(() {
      _selectedDateFilter = filter;
      if (filter == "Custom Range") {
        _pickDateRange();
      } else {
        _dateRange = _getDateRangeFromFilter(filter);
      }
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _selectedDateFilter = "Custom Range";
      });
    } else if (_selectedDateFilter == "Custom Range" && _dateRange == null) {
      setState(() {
        _selectedDateFilter = "All Time";
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = "Scheduled";
      _selectedType = null;
      _dateRange = null;
      _selectedDateFilter = "All Time";
    });
  }

  List<Map<String, dynamic>> _getFilteredAppointments(SalesOrderProvider provider) {
    List<Map<String, dynamic>> filtered = List.from(provider.appointmentList);

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((apt) => apt["status"] == _selectedStatus).toList();
    }

    // Filter by appointment type
    if (_selectedType != null) {
      filtered = filtered.where((apt) => apt["appointment_type"] == _selectedType).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((apt) {
        if (apt["appointment_date"] == null) return false;
        try {
          final aptDate = DateTime.parse(apt["appointment_date"]);
          return aptDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              aptDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupAppointmentsByDate(
      List<Map<String, dynamic>> appointments) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (final apt in appointments) {
      final dateStr = apt["appointment_date"];
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);
          grouped.putIfAbsent(dateKey, () => []).add(apt);
        } catch (e) {
          print('Error parsing date: $dateStr');
        }
      }
    }

    return grouped;
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(
      DateTime day, Map<DateTime, List<Map<String, dynamic>>> groupedAppointments) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return groupedAppointments[dateKey] ?? [];
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedStatus != null) count++;
    if (_selectedType != null) count++;
    if (_currentView != AppointmentViewType.calendar && _selectedDateFilter != "All Time") {
      count++;
    }
    return count;
  }

  IconData _getDateFilterIcon(String filter) {
    switch (filter) {
      case "Today":
        return Icons.today;
      case "Yesterday":
        return Icons.calendar_today;
      case "This Week":
      case "Last Week":
        return Icons.date_range;
      case "This Month":
      case "Last Month":
        return Icons.calendar_month;
      case "Custom Range":
        return Icons.event_note;
      default:
        return Icons.all_inclusive;
    }
  }

  void _showViewSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _viewTile(
                  icon: Icons.view_list,
                  label: "List View",
                  view: AppointmentViewType.list,
                ),
                _viewTile(
                  icon: Icons.calendar_month,
                  label: "Calendar View",
                  view: AppointmentViewType.calendar,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // void _showStatusSelectionSheet(
  //     BuildContext context, {
  //       required String currentStatus,
  //       required int index,
  //     }) {
  //   showModalBottomSheet(
  //     context: context,
  //     useSafeArea: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return SafeArea(
  //         bottom: true,
  //         child: Padding(
  //           padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 "Update Status",
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               ...appointmentStatuses.map((status) {
  //                 return ListTile(
  //                   contentPadding: EdgeInsets.zero,
  //                   leading: Icon(
  //                     Icons.circle,
  //                     size: 12,
  //                     color: statusColor(status),
  //                   ),
  //                   title: Text(status),
  //                   trailing: status == currentStatus
  //                       ? const Icon(Icons.check, color: Colors.green)
  //                       : null,
  //                   // onTap: () {
  //                   //   Navigator.pop(context);
  //                   //   if (status != currentStatus) {
  //                   //     // Call your provider method to update appointment status
  //                   //     context.read<SalesOrderProvider>().updateAppointmentStatus(
  //                   //       index: index,
  //                   //       newStatus: status,
  //                   //     );
  //                   //   }
  //                   // },
  //                 );
  //               }),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _viewTile({
    required IconData icon,
    required String label,
    required AppointmentViewType view,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: _currentView == view
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() => _currentView = view);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesOrderProvider>();

    return Scaffold(
      appBar: CommonAppBar(
        title: "Appointments",
        actions: IconButton(
          icon: Icon(
            _currentView == AppointmentViewType.list
                ? Icons.view_list
                : Icons.calendar_month,
            color: Colors.white,
          ),
          onPressed: () => _showViewSelectionSheet(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(provider),
          Expanded(
            child: provider.isLoadingAppointments
                ? const Center(child: CircularProgressIndicator())
                : provider.appointmentList.isEmpty
                ? const Center(child: Text("No Appointments Found"))
                : _buildCurrentView(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(SalesOrderProvider provider) {
    final hasActiveFilters = _selectedStatus != null ||
        _selectedType != null ||
        (_currentView != AppointmentViewType.calendar && _selectedDateFilter != "All Time");

    // Get unique appointment types
    final appointmentTypes = provider.appointmentList
        .map((apt) => apt["appointment_type"] as String?)
        .where((type) => type != null && type.isNotEmpty)
        .toSet()
        .toList();

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Filters",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (hasActiveFilters)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_getActiveFilterCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _showFilters ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showFilters)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  // Status filter
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text("Status:", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(
                                label: "All",
                                isSelected: _selectedStatus == null,
                                onTap: () => setState(() => _selectedStatus = null),
                              ),
                              ...appointmentStatuses.map((status) => _filterChip(
                                label: status,
                                isSelected: _selectedStatus == status,
                                onTap: () => setState(() => _selectedStatus = status),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Type filter
                  // if (appointmentTypes.isNotEmpty)
                  //   Row(
                  //     children: [
                  //       const SizedBox(
                  //         width: 80,
                  //         child: Text("Type:", style: TextStyle(fontWeight: FontWeight.w500)),
                  //       ),
                  //       Expanded(
                  //         child: SingleChildScrollView(
                  //           scrollDirection: Axis.horizontal,
                  //           child: Row(
                  //             children: [
                  //               _filterChip(
                  //                 label: "All",
                  //                 isSelected: _selectedType == null,
                  //                 onTap: () => setState(() => _selectedType = null),
                  //               ),
                  //               ...appointmentTypes.map((type) => _filterChip(
                  //                 label: type!,
                  //                 isSelected: _selectedType == type,
                  //                 onTap: () => setState(() => _selectedType = type),
                  //               )),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // if (appointmentTypes.isNotEmpty) const SizedBox(height: 8),
                  // Date filter - ONLY show if NOT in calendar view
                  if (_currentView != AppointmentViewType.calendar) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text("Date:", style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedDateFilter != "All Time" ? Colors.blue.shade50 : Colors.white,
                              border: Border.all(
                                color: _selectedDateFilter != "All Time" ? Colors.blue : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDateFilter,
                                isExpanded: true,
                                isDense: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: _selectedDateFilter != "All Time" ? Colors.blue : Colors.grey,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedDateFilter != "All Time" ? Colors.blue : Colors.grey.shade700,
                                ),
                                items: _dateFilterOptions.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getDateFilterIcon(option),
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(option),
                                        if (option == "Custom Range" && _dateRange != null) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "(${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)})",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _onDateFilterChanged(newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_selectedDateFilter != "All Time")
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedDateFilter = "All Time";
                                _dateRange = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text("Clear All"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(SalesOrderProvider provider) {
    return SafeArea(
      bottom: true,
      child: _getCurrentViewWidget(provider),
    );
  }

  Widget _getCurrentViewWidget(SalesOrderProvider provider) {
    switch (_currentView) {
      case AppointmentViewType.calendar:
        return _buildCalendarView(provider);
      case AppointmentViewType.list:
      default:
        return _buildListView(provider);
    }
  }

  Widget _buildListView(SalesOrderProvider provider) {
    final filteredAppointments = _getFilteredAppointments(provider);

    return filteredAppointments.isEmpty
        ? const Center(child: Text("No matching appointments"))
        : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final item = filteredAppointments[index];
        final globalIndex = provider.appointmentList.indexOf(item);
        return _buildAppointmentCard(provider, item, globalIndex);
      },
    );
  }

  Widget _buildCalendarView(SalesOrderProvider provider) {
    final filteredAppointments = _getFilteredAppointments(provider);
    final groupedAppointments = _groupAppointmentsByDate(filteredAppointments);
    final appointmentsForSelectedDay = _getAppointmentsForDay(_selectedDay!, groupedAppointments);

    return Column(
      children: [
        _buildCalendarToggleBar(),
        if (_showCalendar)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markersAlignment: Alignment.bottomCenter,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return _getAppointmentsForDay(day, groupedAppointments);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                formatDate(_selectedDay.toString().split(' ')[0]),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${appointmentsForSelectedDay.length} ${appointmentsForSelectedDay.length == 1 ? 'appointment' : 'appointments'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: appointmentsForSelectedDay.isEmpty
              ? const Center(
            child: Text(
              'No appointments for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: appointmentsForSelectedDay.length,
            itemBuilder: (context, index) {
              final item = appointmentsForSelectedDay[index];
              final globalIndex = provider.appointmentList.indexOf(item);
              return _buildAppointmentCard(provider, item, globalIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarToggleBar() {
    return InkWell(
      onTap: () {
        setState(() {
          _showCalendar = !_showCalendar;
        });
      },
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _showCalendar ? Icons.calendar_month : Icons.calendar_today_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "Calendar",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(
              _showCalendar ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

// Updated UI Card with new fields
  Widget _buildAppointmentCard(
      SalesOrderProvider provider,
      Map<String, dynamic> item,
      int index,
      ) {
    return Card(
      elevation: 2,
      color: cardColors[index % cardColors.length],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item["title"] ?? "Appointment",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  // onTap: () {
                  //   _showStatusSelectionSheet(
                  //     context,
                  //     currentStatus: item["status"] ?? "",
                  //     index: index,
                  //   );
                  // },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(item["status"] ?? ""),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item["status"] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Patient Info Row (Name and Sex)
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Patient: ${item["patient_name"] ?? "-"}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (item["patient_sex"] != null && item["patient_sex"].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSexColor(item["patient_sex"]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item["patient_sex"],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Practitioner Info
            if (item["practitioner_name"] != null && item["practitioner_name"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Practitioner: ${item["practitioner_name"]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Service Unit Info
            if (item["service_unit"] != null && item["service_unit"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Service Unit: ${item["service_unit"]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Date and Time Row
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formatDate(item["appointment_date"]),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item["appointment_time"] ?? "-",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Type and Duration Row
            Row(
              children: [
                // Appointment Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        item["appointment_type"] ?? "-",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Duration (if available)
                if (item["duration"] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "${item["duration"]} mins",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper method to get color for patient sex
  Color _getSexColor(String? sex) {
    if (sex == null) return Colors.grey;

    switch (sex.toLowerCase()) {
      case 'male':
      case 'm':
        return Colors.blue;
      case 'female':
      case 'f':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }
}