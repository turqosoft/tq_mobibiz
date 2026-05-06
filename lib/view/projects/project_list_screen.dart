import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/provider.dart';
import '../../utils/common/common_widgets.dart';
import '../task/task_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _showFilters = false;

  String _selectedStatus = "All";
  String? _selectedProjectType;
  String _selectedPriority = "All";
  final TextEditingController _searchController = TextEditingController();

  List<String> _projectTypes = [];

  @override
  void initState() {
    super.initState();
    _loadProjectTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesOrderProvider>().fetchProjectList();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "open":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      case "overdue":
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Color priorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case "urgent":
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  Future<void> _loadProjectTypes() async {
    final provider = context.read<SalesOrderProvider>();

    final types =
    await provider.apiService!.fetchProjectTypes();

    setState(() {
      _projectTypes = types;
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "—";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }
  // List<Map<String, dynamic>> _getFilteredProjects(
  //     SalesOrderProvider provider) {
  //   var filtered = provider.projectList;
  //
  //   // Status filter
  //   if (_selectedStatus != "All") {
  //     filtered = filtered
  //         .where((p) =>
  //     (p["status"] ?? "").toString().toLowerCase() ==
  //         _selectedStatus.toLowerCase())
  //         .toList();
  //   }
  //
  //   // Project Type filter
  //   if (_selectedProjectType != null) {
  //     filtered = filtered
  //         .where((p) =>
  //     (p["project_type"] ?? "") == _selectedProjectType)
  //         .toList();
  //   }
  //
  //   // Priority filter
  //   if (_selectedPriority != "All") {
  //     filtered = filtered
  //         .where((p) =>
  //     (p["priority"] ?? "").toString().toLowerCase() ==
  //         _selectedPriority.toLowerCase())
  //         .toList();
  //   }
  //
  //   return filtered;
  // }

  List<Map<String, dynamic>> _getFilteredProjects(
      SalesOrderProvider provider) {

    var filtered = provider.projectList;

    // ✅ SEARCH FILTER
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        final projectName =
        (p["project_name"] ?? "").toString().toLowerCase();
        final name =
        (p["name"] ?? "").toString().toLowerCase();
        final customerName =
        (p["customer"] ?? "").toString().toLowerCase();

        return projectName.contains(query) ||
            name.contains(query) || customerName.contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedStatus != "All") {
      filtered = filtered
          .where((p) =>
      (p["status"] ?? "")
          .toString()
          .toLowerCase() ==
          _selectedStatus.toLowerCase())
          .toList();
    }

    // Project Type filter
    if (_selectedProjectType != null) {
      filtered = filtered
          .where((p) =>
      (p["project_type"] ?? "") ==
          _selectedProjectType)
          .toList();
    }

    // Priority filter
    if (_selectedPriority != "All") {
      filtered = filtered
          .where((p) =>
      (p["priority"] ?? "")
          .toString()
          .toLowerCase() ==
          _selectedPriority.toLowerCase())
          .toList();
    }

    return filtered;
  }

  int _getActiveFilterCount() {
    int count = 0;

    if (_searchController.text.isNotEmpty) count++;
    if (_selectedStatus != "All") count++;
    if (_selectedProjectType != null) count++;
    if (_selectedPriority != "All") count++;

    return count;
  }

  Widget _buildFilterBar() {
    final hasActiveFilters = _getActiveFilterCount() > 0;

    const statuses = ["All", "Open", "Completed", "Cancelled"];
    const priorities = ["All", "High", "Medium", "Low"];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    "Filters",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getActiveFilterCount().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (hasActiveFilters)
                    GestureDetector(
                      onTap: () => setState(() {
                        _searchController.clear();
                        _selectedStatus = "All";
                        _selectedProjectType = null;
                        _selectedPriority = "All";
                      }),
                      child: Text(
                        "Clear all",
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (hasActiveFilters) const SizedBox(width: 10),
                  Icon(
                    _showFilters ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable filter content ────────────────────────────────
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Search projects…",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: Colors.grey.shade400),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 15, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status row
                  _inlineChipRow(
                    label: "Status",
                    items: statuses,
                    selected: _selectedStatus,
                    colorFn: statusColor,
                    onSelect: (v) => setState(() => _selectedStatus = v),
                  ),
                  const SizedBox(height: 10),
                  // Project Type dropdown — slim
                  DropdownButtonFormField<String>(
                    value: _selectedProjectType,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: "Project Type",
                      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All")),
                      ..._projectTypes.map(
                            (type) => DropdownMenuItem(value: type, child: Text(type)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedProjectType = value),
                  ),
                  const SizedBox(height: 10),

// Priority row
                  _inlineChipRow(
                    label: "Priority",
                    items: priorities,
                    selected: _selectedPriority,
                    colorFn: priorityColor,
                    onSelect: (v) => setState(() => _selectedPriority = v),
                  ),


                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _inlineChipRow({
    required String label,
    required List<String> items,
    required String selected,
    required Color Function(String) colorFn,
    required void Function(String) onSelect,
  }) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1, // +1 for the label
        separatorBuilder: (_, index) => SizedBox(width: index == 0 ? 10 : 5),
        itemBuilder: (context, index) {
          // First item is the label
          if (index == 0) {
            return Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }

          final item = items[index - 1];
          final isSelected = selected == item;
          final color = colorFn(item);

          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
// ── Helpers ──────────────────────────────────────────────────────────────────

  // Widget _filterLabel(String text) {
  //   return Text(
  //     text,
  //     style: TextStyle(
  //       fontSize: 11,
  //       fontWeight: FontWeight.w600,
  //       color: Colors.grey.shade500,
  //       letterSpacing: 0.4,
  //     ),
  //   );
  // }

  // Widget _chipRow({
  //   required List<String> items,
  //   required String selected,
  //   required Color Function(String) colorFn,
  //   required void Function(String) onSelect,
  // }) {
  //   return SizedBox(
  //     height: 30,
  //     child: ListView.separated(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: items.length,
  //       separatorBuilder: (_, __) => const SizedBox(width: 5),
  //       itemBuilder: (context, index) {
  //         final item = items[index];
  //         final isSelected = selected == item;
  //         final color = colorFn(item);
  //         return GestureDetector(
  //           onTap: () => onSelect(item),
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 150),
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //             decoration: BoxDecoration(
  //               color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
  //               borderRadius: BorderRadius.circular(6),
  //               border: Border.all(
  //                 color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
  //                 width: 1,
  //               ),
  //             ),
  //             child: Text(
  //               item,
  //               style: TextStyle(
  //                 fontSize: 11,
  //                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
  //                 color: isSelected ? color : Colors.grey.shade600,
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _compactChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  final List<Color> cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
    const Color.fromARGB(255, 255, 235, 205),
    const Color.fromARGB(255, 255, 220, 220),
  ];

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    final projectName = project["project_name"] ?? "Unnamed Project";
    final name = project["name"] ?? "";
    final status = project["status"] ?? "Unknown";
    final priority = project["priority"] ?? "—";
    final startDate = project["expected_start_date"];
    final endDate = project["expected_end_date"];
    final projectType = project["project_type"];
    final department = project["department"];
    final isActive = project["is_active"];
    final customer = project["customer"];
    final percentComplete = (project["percent_complete"] ?? 0.0).toDouble();

    // return Card(
    return InkWell(
        borderRadius: BorderRadius.circular(12),
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => TaskScreen(
    initialProjectId: name, // PASS PROJECT ID
    ),
    ),
    );
    },
    child: Card(
      elevation: 2,
      color: cardColors[index % cardColors.length],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name + ID
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active badge
                if (isActive == 1 || isActive == "Yes" || isActive == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 0.5),
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Meta info
            // Wrap(
            //   spacing: 8,
            //   runSpacing: 2,
            //   children: [
            //     if (projectType != null && projectType.toString().isNotEmpty)
            //       _infoItem(Icons.folder_outlined, projectType.toString()),
            //     if (department != null && department.toString().isNotEmpty)
            //       _infoItem(Icons.business_outlined, department.toString()),
            //     if (startDate != null || endDate != null)
            //       _infoItem(
            //         Icons.date_range,
            //         "${_formatDate(startDate)}  →  ${_formatDate(endDate)}",
            //       ),
            //   ],
            // ),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                if (customer != null && customer.toString().isNotEmpty)
                  _infoItem(Icons.person_outline, customer.toString()),

                if (projectType != null && projectType.toString().isNotEmpty)
                  _infoItem(Icons.folder_outlined, projectType.toString()),

                if (department != null && department.toString().isNotEmpty)
                  _infoItem(Icons.business_outlined, department.toString()),

                if (startDate != null || endDate != null)
                  _infoItem(
                    Icons.date_range,
                    "${_formatDate(startDate)}  →  ${_formatDate(endDate)}",
                  ),
              ],
            ),


            const SizedBox(height: 8),

            // Progress bar
            Row(
              children: [
                Text(
                  "Progress",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percentComplete / 100,
                      minHeight: 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentComplete >= 100
                            ? Colors.green
                            : percentComplete >= 50
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "${percentComplete.round()}%",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Status + Priority chips
            Row(
              children: [
                _compactChip(label: status, color: statusColor(status)),
                const SizedBox(width: 5),
                _compactChip(label: priority, color: priorityColor(priority)),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Projects",
        actions: Consumer<SalesOrderProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: provider.isLoadingProjects
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: provider.isLoadingProjects
                  ? null
                  : () => provider.fetchProjectList(),
            );
          },
        ),
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          final filteredProjects = _getFilteredProjects(provider);

          if (provider.isLoadingProjects && provider.projectList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.projectList.isEmpty) {
            return const Center(
              child: Text(
                "No projects found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // return Column(
          //   children: [
          //     // Count bar
          //     Padding(
          //       padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          //       child: Row(
          //         children: [
          //           Text(
          //             // "${provider.projectList.length} project(s)",
          //       "${filteredProjects.length} project(s)",
          //
          //         style: TextStyle(
          //               fontSize: 13,
          //               color: Colors.grey[600],
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //
          //     const SizedBox(height: 8),
          //
          //     // List
          //     Expanded(
          //       child: ListView.separated(
          //         padding: const EdgeInsets.all(12),
          //         // itemCount: provider.projectList.length,
          //         itemCount: filteredProjects.length,
          //
          //         separatorBuilder: (_, __) => const SizedBox(height: 10),
          //         itemBuilder: (context, index) {
          //           // return _buildProjectCard(provider.projectList[index], index);
          //           return _buildProjectCard(filteredProjects[index], index);
          //
          //         },
          //       ),
          //     ),
          //   ],
          // );
          return Column(
            children: [
              // ✅ FILTER BAR (ADD THIS)
              _buildFilterBar(),

              // Count bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Text(
                      "${filteredProjects.length} project(s)",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: filteredProjects.isEmpty
                    ? const Center(
                  child: Text(
                    "No projects match selected filters",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredProjects.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildProjectCard(
                        filteredProjects[index], index);
                  },
                ),
              ),
            ],
          );

        },
      ),
    );
  }
}