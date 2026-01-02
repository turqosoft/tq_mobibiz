import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SalesOrderProvider>().fetchToDoList();
    });
  }
  ToDoViewType _currentView = ToDoViewType.list;

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
                      context
                          .read<SalesOrderProvider>()
                          .updateToDoStatus(
                        index: index,
                        newStatus: status,
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
  void _showViewSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
              _viewTile(
                icon: Icons.bar_chart,
                label: "Gantt View",
                view: ToDoViewType.gantt,
              ),
            ],
          ),
        );
      },
    );
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
      // appBar: CommonAppBar(title: "ToDos"),
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

      body: provider.isLoadingToDos
          ? const Center(child: CircularProgressIndicator())
          : provider.toDoList.isEmpty
          ? const Center(child: Text("No ToDos Found"))
          : _buildCurrentView(provider),
      //   : ListView.separated(
      //   padding: const EdgeInsets.all(12),
      //   itemCount: provider.toDoList.length,
      //   separatorBuilder: (_, __) =>
      //   const SizedBox(height: 8),
      //   itemBuilder: (context, index) {
      //     final todo = provider.toDoList[index];
      //
      //     final description = parseHtmlString(
      //       todo["description"] ?? "",
      //     );
      //
      //     return Card(
      //       elevation: 2,
      //       color: cardColors[index % cardColors.length],
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(10),
      //       ),
      //       child: Padding(
      //         padding: const EdgeInsets.all(12),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             // Description
      //             Text(
      //               description,
      //               style: const TextStyle(
      //                 fontSize: 14,
      //                 fontWeight: FontWeight.w600,
      //               ),
      //             ),
      //
      //             const SizedBox(height: 8),
      //
      //             // Meta Info
      //             Row(
      //
      //               children: [
      //                 if (provider.updatingIndex == index)
      //                   const SizedBox(
      //                     height: 16,
      //                     width: 16,
      //                     child: CircularProgressIndicator(strokeWidth: 2),
      //                   ),
      //
      //
      //                 // _infoChip(
      //                 //   label: todo["status"] ?? "Unknown",
      //                 //   color: todo["status"] == "Open"
      //                 //       ? Colors.orange
      //                 //       : Colors.green,
      //                 // ),
      //                 GestureDetector(
      //                   onTap: () {
      //                     _showStatusSelectionSheet(
      //                       context,
      //                       currentStatus: todo["status"],
      //                       index: index,
      //                     );
      //                   },
      //                   child: _infoChip(
      //                     label: todo["status"] ?? "Unknown",
      //                     color: statusColor(todo["status"]),
      //                   ),
      //                 ),
      //
      //
      //                 const SizedBox(width: 6),
      //                 _infoChip(
      //                   label: "Priority: ${todo["priority"] ?? "-"}",
      //                   color: Colors.blueGrey,
      //                 ),
      //                 const Spacer(),
      //                 Text(
      //                   formatToDDMMYYYY(todo["date"]),
      //                   style: const TextStyle(
      //                     fontSize: 12,
      //                     color: Colors.grey,
      //                   ),
      //                 ),
      //
      //               ],
      //             ),
      //           ],
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
  Widget _buildTodoCard(
      SalesOrderProvider provider,
      Map<String, dynamic> todo,
      int index,
      ) {
    final description = parseHtmlString(
      todo["description"] ?? "",
    );

    return Card(
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
            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
    );
  }

    Widget _buildListView(SalesOrderProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.toDoList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final todo = provider.toDoList[index];
        final description = parseHtmlString(todo["description"] ?? "");

        return _buildTodoCard(provider, todo, index);
      },
    );
  }
  Widget _buildCalendarView(SalesOrderProvider provider) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final todo in provider.toDoList) {
      final date = todo["date"] ?? "Unknown";
      grouped.putIfAbsent(date, () => []).add(todo);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatToDDMMYYYY(entry.key),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.value.map((todo) {
              final index = provider.toDoList.indexOf(todo);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTodoCard(
                  provider,
                  todo,
                  index,
                  // parseHtmlString(todo["description"] ?? ""),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
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

  // Widget _buildGanttView(SalesOrderProvider provider) {
  //   return ListView.builder(
  //     padding: const EdgeInsets.all(12),
  //     itemCount: provider.toDoList.length,
  //     itemBuilder: (context, index) {
  //       final todo = provider.toDoList[index];
  //
  //       return Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Timeline
  //           Column(
  //             children: [
  //               Container(
  //                 width: 12,
  //                 height: 12,
  //                 decoration: BoxDecoration(
  //                   color: statusColor(todo["status"]),
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               if (index != provider.toDoList.length - 1)
  //                 Container(
  //                   width: 2,
  //                   height: 60,
  //                   color: Colors.grey.shade400,
  //                 ),
  //             ],
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _buildTodoCard(
  //               provider,
  //               todo,
  //               index,
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  Widget _buildGanttView(SalesOrderProvider provider) {
    final startDate = _startOfTimeline();

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
