import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:sales_ordering_app/utils/common/common_widgets.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../utils/app_colors.dart';
import '../maintenance_visit/maintenanceVistScreen.dart';

enum ToDoViewType {
  list,
  calendar,
  gantt,
}

const List<String> todoStatuses = [
  "Open",
  "Closed",
  "Cancelled",
];
const double dayWidth = 40;
const double rowHeight = 56;
const int visibleDays = 28;

class ToDosScreen extends StatefulWidget {
  const ToDosScreen({super.key});

  @override
  State<ToDosScreen> createState() => _ToDosScreenState();
}

class _ToDosScreenState extends State<ToDosScreen> {

  // String? _selectedStatus;
  bool _showCalendar = true;
  String? _selectedStatus = "Open";
  String? _selectedPriority;
  DateTimeRange? _dateRange;
  bool _showFilters = false;
  final List<String> _priorities = ["Low", "Medium", "High"];
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
    // Initialize calendar dates
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    Future.microtask(() {
      context.read<SalesOrderProvider>().fetchToDoList();
    });
  }
  ToDoViewType _currentView = ToDoViewType.list;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String formatToDDMMYYYY(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      final parsedDate = DateTime.parse(date); // yyyy-MM-dd
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date; // fallback in case of unexpected format
    }
  }


  String parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text.trim() ?? '';
  }
  final List<Color> cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];
  Color statusColor(String status) {
    switch (status) {
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

  void _showStatusSelectionSheet(
      BuildContext context, {
        required String currentStatus,
        required int index,
      }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true, // ✅ Flutter 3.7+
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Update Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                ...todoStatuses.map((status) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.circle,
                      size: 12,
                      color: statusColor(status),
                    ),
                    title: Text(status),
                    trailing: status == currentStatus
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.pop(context);

                      if (status != currentStatus) {
                        context.read<SalesOrderProvider>().updateToDoStatus(
                          index: index,
                          newStatus: status,
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String truncateText(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) return text;
    return '${words.take(wordLimit).join(' ')}...';
  }


  void _showFullDescriptionDialog(
      BuildContext context,
      String htmlDescription,
      String baseUrl, {
        String? referenceType,
        String? referenceName,
        String? completionStatus,

      }) async {

    bool showButton = false;

    if (referenceType == "Sales Order" && referenceName != null) {
      final provider = context.read<SalesOrderProvider>();

      // final exists =
      // await provider.maintenanceVisitExistsForSalesOrder(referenceName);
      //
      // showButton = !exists; // 🔥 only show if NOT exists
      if (referenceType == "Sales Order" && referenceName != null) {
        final provider = context.read<SalesOrderProvider>();

        completionStatus =
        await provider.fetchMaintenanceVisitStatusForSalesOrder(referenceName);

        if (completionStatus == null) {
          // No Maintenance Visit exists
          showButton = true;
        } else if (completionStatus == "Partially Completed") {
          // Exists but not fully completed
          showButton = true;
        } else {
          // Fully Completed
          showButton = false;
        }}
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Description'),
          content: SingleChildScrollView(
            child: Html(
              data: htmlDescription,
              style: {
                "body": Style(
                  fontSize: FontSize(14),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 8),
                ),
                "img": Style(
                  width: Width.auto(),
                ),
              },
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (extensionContext) {
                    final src = extensionContext.attributes['src'] ?? '';
                    final imageUrl =
                    src.startsWith('http') ? src : '$baseUrl$src';

                    return Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (showButton)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                icon: const Icon(Icons.build_outlined, size: 18),
                label: const Text("Create Maintenance Visit"),
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaintenanceVisitScreen(
                        salesOrderName: referenceName,
                      ),
                    ),
                  );
                },
              ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  void _showViewSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true, // ✅ important
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
                  view: ToDoViewType.list,
                ),
                _viewTile(
                  icon: Icons.calendar_month,
                  label: "Calendar View",
                  view: ToDoViewType.calendar,
                ),
                // _viewTile(
                //   icon: Icons.bar_chart,
                //   label: "Gantt View",
                //   view: ToDoViewType.gantt,
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
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
        return _dateRange; // Keep existing custom range

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
      // If user cancels custom range selection and no range was set
      setState(() {
        _selectedDateFilter = "All Time";
      });
    }
  }

  void _clearFilters() {
    setState(() {
      // _selectedStatus = null;
      _selectedStatus = "Open";
      _selectedPriority = null;
      _dateRange = null;
      _selectedDateFilter = "All Time";
    });
  }
// Filter todos based on selected filters
  List<Map<String, dynamic>> _getFilteredTodos(SalesOrderProvider provider) {
    List<Map<String, dynamic>> filtered = List.from(provider.toDoList);

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((todo) => todo["status"] == _selectedStatus).toList();
    }

    // Filter by priority
    if (_selectedPriority != null) {
      filtered = filtered.where((todo) => todo["priority"] == _selectedPriority).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((todo) {
        if (todo["date"] == null) return false;
        try {
          final todoDate = DateTime.parse(todo["date"]);
          return todoDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              todoDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  Widget _viewTile({
    required IconData icon,
    required String label,
    required ToDoViewType view,
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
        title: "ToDos",
        actions: IconButton(
          icon: Icon(
            _currentView == ToDoViewType.list
                ? Icons.view_list
                : _currentView == ToDoViewType.calendar
                ? Icons.calendar_month
                : Icons.bar_chart,
            color: Colors.white,
          ),
          onPressed: () => _showViewSelectionSheet(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Add filter bar here

          Expanded(
            child: provider.isLoadingToDos
                ? const Center(child: CircularProgressIndicator())
                : provider.toDoList.isEmpty
                ? const Center(child: Text("No ToDos Found"))
                : _buildCurrentView(provider),
          ),
        ],
      ),
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
  int _getActiveFilterCount() {
    int count = 0;

    if (_selectedStatus != null) count++;
    if (_selectedPriority != null) count++;

    // Only count date filter if NOT in calendar view
    if (_currentView != ToDoViewType.calendar && _selectedDateFilter != "All Time") {
      count++;
    }

    return count;
  }
  Widget _buildFilterBar() {
    final hasActiveFilters = _selectedStatus != null ||
        _selectedPriority != null ||
        (_currentView != ToDoViewType.calendar && _selectedDateFilter != "All Time");

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Toggle button
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

          // Filter options
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
                              ...todoStatuses.map((status) => _filterChip(
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

                  // Priority filter
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text("Priority:", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(
                                label: "All",
                                isSelected: _selectedPriority == null,
                                onTap: () => setState(() => _selectedPriority = null),
                              ),
                              ..._priorities.map((priority) => _filterChip(
                                label: priority,
                                isSelected: _selectedPriority == priority,
                                onTap: () => setState(() => _selectedPriority = priority),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Date filter - ONLY show if NOT in calendar view
                  if (_currentView != ToDoViewType.calendar) ...[
                    const SizedBox(height: 8),
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

                  // Clear all button
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
  Widget _buildTodoCard(
      SalesOrderProvider provider,
      Map<String, dynamic> todo,
      int index,
      ) {
    final htmlDescription = todo["description"] ?? "";
    final plainTextDescription = parseHtmlString(htmlDescription);
    final referenceType = todo["reference_type"];
    final referenceName = todo["reference_name"];
    final bool canNavigate =
        referenceType == "Sales Order" && referenceName != null;
    // Replace with your actual ERP base URL
    const String baseUrl = 'https://ccnttest.turqosoft.cloud';

    return GestureDetector(
      // onTap: () => _showFullDescriptionDialog(
      //   context,
      //   htmlDescription,
      //   baseUrl,
      // ),
      // onTap: () {
      //   if (canNavigate) {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (_) => MaintenanceVisitScreen(
      //           salesOrderName: referenceName,
      //         ),
      //       ),
      //     );
      //   } else {
      //     _showFullDescriptionDialog(
      //       context,
      //       htmlDescription,
      //       baseUrl,
      //     );
      //   }
      // },
      onTap: () {
        _showFullDescriptionDialog(
          context,
          htmlDescription,
          baseUrl,
          referenceType: referenceType,
          referenceName: referenceName,
        );
      },
      child: Card(
        elevation: 2,
        color: cardColors[index % cardColors.length],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Truncated Description (plain text)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      truncateText(plainTextDescription, 8),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (plainTextDescription.split(' ').length > 8)
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Meta Info
              Row(
                children: [
                  if (provider.updatingIndex == index)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),

                  GestureDetector(
                    onTap: () {
                      _showStatusSelectionSheet(
                        context,
                        currentStatus: todo["status"],
                        index: index,
                      );
                    },
                    child: _infoChip(
                      label: todo["status"] ?? "Unknown",
                      color: statusColor(todo["status"]),
                    ),
                  ),

                  const SizedBox(width: 6),

                  _infoChip(
                    label: "Priority: ${todo["priority"] ?? "-"}",
                    color: Colors.blueGrey,
                  ),

                  const Spacer(),

                  Text(
                    formatToDDMMYYYY(todo["date"]),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildListView(SalesOrderProvider provider) {
    final filteredTodos = _getFilteredTodos(provider);

    return SafeArea(
      bottom: true,
      child: filteredTodos.isEmpty
          ? const Center(child: Text("No matching ToDos"))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: filteredTodos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          final globalIndex = provider.toDoList.indexOf(todo);
          return _buildTodoCard(provider, todo, globalIndex);
        },
      ),
    );
  }

  // // Group todos by date
  // Map<DateTime, List<Map<String, dynamic>>> _groupTodosByDate(
  //     SalesOrderProvider provider) {
  //   final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
  //
  //   for (final todo in provider.toDoList) {
  //     final dateStr = todo["date"];
  //     if (dateStr != null && dateStr.isNotEmpty) {
  //       try {
  //         final date = DateTime.parse(dateStr);
  //         final dateKey = DateTime(date.year, date.month, date.day);
  //         grouped.putIfAbsent(dateKey, () => []).add(todo);
  //       } catch (e) {
  //         print('Error parsing date: $dateStr');
  //       }
  //     }
  //   }
  //
  //   return grouped;
  // }

  // Get todos for a specific day
  List<Map<String, dynamic>> _getTodosForDay(
      DateTime day, Map<DateTime, List<Map<String, dynamic>>> groupedTodos) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return groupedTodos[dateKey] ?? [];
  }
// Helper for calendar view
  Map<DateTime, List<Map<String, dynamic>>> _groupTodosByDateFiltered(
      List<Map<String, dynamic>> todos) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (final todo in todos) {
      final dateStr = todo["date"];
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);
          grouped.putIfAbsent(dateKey, () => []).add(todo);
        } catch (e) {
          print('Error parsing date: $dateStr');
        }
      }
    }

    return grouped;
  }
  Widget _buildCalendarView(SalesOrderProvider provider) {
    final filteredTodos = _getFilteredTodos(provider);
    // final groupedTodos = _groupTodosByDate(provider);
    final groupedTodos = _groupTodosByDateFiltered(filteredTodos);

    final todosForSelectedDay = _getTodosForDay(_selectedDay!, groupedTodos);
    final selectedDay = _selectedDay;

    return Column(
      children: [
        // Calendar toggle header
        _buildCalendarToggleBar(),

// Calendar widget (collapsible)
        if (_showCalendar)
        // Calendar widget
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
              return _getTodosForDay(day, groupedTodos);
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

        // Selected date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                formatToDDMMYYYY(_selectedDay.toString().split(' ')[0]),
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
                  '${todosForSelectedDay.length} ${todosForSelectedDay.length == 1 ? 'task' : 'tasks'}',
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

        // List of todos for selected day
        Expanded(
          child: todosForSelectedDay.isEmpty
              ? const Center(
            child: Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: todosForSelectedDay.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final todo = todosForSelectedDay[index];
              final globalIndex = provider.toDoList.indexOf(todo);
              return _buildTodoCard(provider, todo, globalIndex);
            },
          ),
        ),
      ],
    );
  }
  DateTime _parseDate(String date) {
    return DateTime.parse(date);
  }

  DateTime _startOfTimeline() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 4);
  }
  Widget _buildGanttHeader(DateTime startDate) {
    return Row(
      children: List.generate(visibleDays, (index) {
        final date = startDate.add(Duration(days: index));
        return Container(
          width: dayWidth,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 12),
          ),
        );
      }),
    );
  }
  Widget _buildGanttRow(
      Map<String, dynamic> todo,
      DateTime startDate,
      ) {
    final taskDate = _parseDate(todo["date"]);
    final offsetDays = taskDate.difference(startDate).inDays;

    if (offsetDays < 0 || offsetDays >= visibleDays) {
      return const SizedBox(height: rowHeight);
    }

    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          // Grid lines
          Row(
            children: List.generate(
              visibleDays,
                  (_) => Container(
                width: dayWidth,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
          ),

          // Task bar
          Positioned(
            left: offsetDays * dayWidth + 4,
            top: 12,
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: dayWidth - 8,
                  decoration: BoxDecoration(
                    color: statusColor(todo["status"]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  todo["name"] ?? todo["id"] ?? "",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanttView(SalesOrderProvider provider) {
    final startDate = _startOfTimeline();
    final filteredTodos = _getFilteredTodos(provider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: visibleDays * dayWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month label
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                DateFormat('MMMM').format(startDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Header
            _buildGanttHeader(startDate),

            const Divider(height: 1),

            // Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.toDoList.length,
              itemBuilder: (_, index) {
                return _buildGanttRow(
                  provider.toDoList[index],
                  startDate,
                );
              },
            ),
          ],
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
      case ToDoViewType.calendar:
        return _buildCalendarView(provider);
      case ToDoViewType.gantt:
        return _buildGanttView(provider);
      case ToDoViewType.list:
      default:
        return _buildListView(provider);
    }
  }

  Widget _infoChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
