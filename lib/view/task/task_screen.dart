
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import '../../utils/common/common_widgets.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';

enum TaskViewType { list, calendar, gantt }

class TaskScreen extends StatefulWidget {
  // const TaskScreen({Key? key}) : super(key: key);
  final String? initialProjectId;

  const TaskScreen({
    Key? key,
    this.initialProjectId,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  TaskViewType _currentView = TaskViewType.list;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String? _selectedProjectId;
  // String? _selectedProjectLabel;
  List<Map<String, String>> _projects = [];
  bool _showFilters = false;
  bool _showCalendar = true;


  final List<Color> cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
    const Color.fromARGB(255, 255, 235, 205),
    const Color.fromARGB(255, 255, 220, 220),
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;

    _loadProjects();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);
      provider.fetchTaskList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadProjects() async {
    final provider = context.read<SalesOrderProvider>();

    final projects =
    await provider.apiService!.fetchProjectList();

    setState(() {
      _projects = projects;
    });
  }

  void _showViewSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomPadding =
            MediaQuery.of(context).viewPadding.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomPadding + 16, // ✅ prevents overlap
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                const Text(
                  "Select View",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _viewTile(
                  icon: Icons.view_list,
                  title: "List View",
                  type: TaskViewType.list,
                ),

                _viewTile(
                  icon: Icons.calendar_month,
                  title: "Calendar View",
                  type: TaskViewType.calendar,
                ),

                _viewTile(
                  icon: Icons.bar_chart,
                  title: "Gantt View",
                  type: TaskViewType.gantt,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _viewTile({
    required IconData icon,
    required String title,
    required TaskViewType type,
  }) {
    final isSelected = _currentView == type;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        setState(() => _currentView = type);
        Navigator.pop(context);
      },
    );
  }

  void _showTaskUpdateDialog(
      BuildContext context, {
        required String? currentStatus,
        required double? currentProgress,
        required int index,
      }) {
    String? selectedStatus = currentStatus;
    double selectedProgress = currentProgress ?? 0.0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Update Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Selection
                    const Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        "Open",
                        "Working",
                        "Pending Review",
                        "Overdue",
                        "Template",
                        "Completed",
                        "Cancelled",
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: statusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          // Store previous status BEFORE changing
                          final previousStatus = selectedStatus;

                          // Update selected status
                          selectedStatus = value;

                          // AUTO-SYNC: If status changes TO "Completed", set progress to 100%
                          if (value == "Completed" && selectedProgress != 100.0) {
                            selectedProgress = 100.0;
                          }
                          // AUTO-SYNC: If status changes FROM "Completed" to anything else
                          else if (previousStatus == "Completed" &&
                              value != "Completed" &&
                              selectedProgress == 100.0) {
                            selectedProgress = 75.0;  // Reduce to 75% when uncompleting
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Progress Slider
                    const Text(
                      "Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: selectedProgress,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: "${selectedProgress.round()}%",
                            onChanged: (value) {
                              setDialogState(() {
                                selectedProgress = value;

                                // AUTO-SYNC: If progress reaches 100%, set status to "Completed"
                                if (value == 100.0 && selectedStatus != "Completed") {
                                  selectedStatus = "Completed";
                                }
                                // AUTO-SYNC: If progress drops below 100% and status is "Completed"
                                else if (value < 100.0 && selectedStatus == "Completed") {
                                  selectedStatus = "Working";
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            "${selectedProgress.round()}%",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Progress bar preview
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: selectedProgress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(selectedProgress),
                        ),
                      ),
                    ),

                    // Info messages for auto-sync
                    const SizedBox(height: 12),

                    // Completed message
                    if (selectedStatus == "Completed" && selectedProgress == 100.0)
                      _syncInfoBox(
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        message: "Task marked as completed (100%)",
                      ),

                    // Progress reduced message
                    if (selectedStatus != "Completed" &&
                        currentStatus == "Completed" &&
                        selectedProgress < 100.0)
                      _syncInfoBox(
                        icon: Icons.info_outline,
                        color: Colors.orange,
                        message: "Status changed: Progress adjusted to ${selectedProgress.round()}%",
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Close dialog first
                    Navigator.pop(dialogContext);

                    // Capture the scaffold messenger context before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final provider = Provider.of<SalesOrderProvider>(
                      context,
                      listen: false,
                    );

                    String? completedBy;
                    String? completedOn;

// If marking as completed
                    if (selectedStatus == "Completed" && currentStatus != "Completed") {
                      final completionData = await _showCompletionDialog();
                      if (completionData == null) return; // User cancelled

                      completedBy = completionData["completed_by"];
                      completedOn = completionData["completed_on"];
                    }

                    final success = await provider.updateTask(
                      index: index,
                      newStatus: selectedStatus != currentStatus ? selectedStatus : null,
                      newProgress: selectedProgress != currentProgress ? selectedProgress : null,
                      completedBy: completedBy,
                      completedOn: completedOn,
                    );


                    // Use captured scaffold messenger
                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Task updated successfully"),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Failed to update task. Check permissions."),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  String _formatDateDMY(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day-$month-$year";
  }

  Future<Map<String, String>?> _showCompletionDialog() async {
    final loggedUser =
    await context.read<SalesOrderProvider>()
        .apiService!
        .getLoggedInUserIdentifier();

    DateTime selectedDate = DateTime.now();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 🔵 Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Mark as Completed",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 👤 Completed By (Styled Card)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Completed By",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loggedUser ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 📅 Completed On (Modern Date Tile)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Completed On",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateDMY(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_calendar,
                                size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔘 Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context, {
                                "completed_by":
                                loggedUser ?? "",
                                "completed_on":
                                selectedDate
                                    .toIso8601String()
                                    .split("T")
                                    .first,
                              });
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper widget for sync info boxes
  Widget _syncInfoBox({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Get progress color
  Color _getProgressColor(double progress) {
    if (progress >= 100) return Colors.green;
    if (progress >= 75) return Colors.lightGreen;
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) return Colors.amber;
    return Colors.red;
  }

  // Filter tasks based on status and search query
  List<Map<String, dynamic>> _getFilteredTasks(SalesOrderProvider provider) {
    var filtered = provider.taskList;
// Project filter
    if (_selectedProjectId != null) {
      filtered = filtered
          .where((task) => task["project"] == _selectedProjectId)
          .toList();
    }

    // Filter by status
    if (_selectedFilter != "All") {
      filtered = filtered
          .where((task) => task["status"] == _selectedFilter)
          .toList();
    }

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        final subject = (task["subject"] ?? "").toString().toLowerCase();
        final name = (task["name"] ?? "").toString().toLowerCase();
        return subject.contains(query) || name.contains(query);
      }).toList();
    }

    return filtered;
  }

  // Get tasks for a specific date (for calendar view)
  List<Map<String, dynamic>> _getTasksForDate(
      SalesOrderProvider provider,
      DateTime date,
      ) {
    final filtered = _getFilteredTasks(provider);
    return filtered.where((task) {
      final startDate = task["exp_start_date"];
      final endDate = task["exp_end_date"];

      if (startDate == null && endDate == null) return false;

      final start = startDate != null ? DateTime.parse(startDate) : null;
      final end = endDate != null ? DateTime.parse(endDate) : null;

      if (start != null && end != null) {
        return date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      } else if (start != null) {
        return isSameDay(date, start);
      } else if (end != null) {
        return isSameDay(date, end);
      }

      return false;
    }).toList();
  }

  // Get status color
  Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "open":
        return Colors.blue;
      case "working":
        return Colors.orange;
      case "pending review":
        return Colors.purple;
      case "overdue":
        return Colors.red.shade700;
      case "template":
        return Colors.teal;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get priority color
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

  bool _hasValidValue(dynamic value) {
    if (value == null) return false;
    if (value is String && value.trim().isEmpty) return false;
    return true;
  }

  bool _hasValidNumeric(dynamic value) {
    if (value == null) return false;

    final numValue = double.tryParse(value.toString());
    if (numValue == null) return false;
    if (numValue == 0) return false;

    return true;
  }

  // Future<void> _attachFile(String taskName) async {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => _AttachmentSheet(
  //       taskName: taskName,
  //       onUpload: () async {
  //         final result = await FilePicker.platform.pickFiles(type: FileType.any);
  //         if (result == null || result.files.single.path == null) return;
  //
  //         Navigator.pop(ctx); // close the sheet while uploading
  //
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (_) => const Center(child: CircularProgressIndicator()),
  //         );
  //
  //         final success = await context
  //             .read<SalesOrderProvider>()
  //             .apiService!
  //             .uploadTaskAttachment(
  //           taskName: taskName,
  //           filePath: result.files.single.path!,
  //         );
  //
  //         Navigator.pop(context);
  //
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               success
  //                   ? "Attachment uploaded successfully"
  //                   : "Failed to upload attachment",
  //             ),
  //           ),
  //         );
  //
  //         // Refresh task list so the green dot appears
  //         context.read<SalesOrderProvider>().fetchTaskList();
  //       },
  //       onDeleted: () {
  //         // Refresh the task list so the green dot updates
  //         context.read<SalesOrderProvider>().fetchTaskList();
  //       },
  //       apiService: context.read<SalesOrderProvider>().apiService!,
  //     ),
  //   );
  // }

  // UPDATED: Attachment functionality with camera support
// Add this to your pubspec.yaml:
// dependencies:
//   image_picker: ^1.0.4
//   file_picker: ^6.0.0

// Import at the top of your file:
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';

// REPLACE your _attachFile method with this:

  Future<void> _attachFile(String taskName) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  "Attach File",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Option 1: Take Photo
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text("Take Photo"),
              subtitle: const Text("Capture with camera"),
              onTap: () async {
                Navigator.pop(ctx);
                await _captureAndUploadPhoto(taskName, ImageSource.camera);
              },
            ),

            const Divider(),

            // Option 2: Choose from Gallery
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text("Choose Photo"),
              subtitle: const Text("Select from gallery"),
              onTap: () async {
                Navigator.pop(ctx);
                await _captureAndUploadPhoto(taskName, ImageSource.gallery);
              },
            ),

            const Divider(),

            // Option 3: Choose Any File
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insert_drive_file, color: Colors.orange),
              ),
              title: const Text("Choose File"),
              subtitle: const Text("Select any file type"),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndUploadFile(taskName);
              },
            ),

            const Divider(),

            // Option 4: View/Delete Attachments
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attachment, color: Colors.purple),
              ),
              title: const Text("View Attachments"),
              subtitle: const Text("Manage existing files"),
              onTap: () {
                Navigator.pop(ctx);
                _showAttachmentSheet(taskName);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

// NEW METHOD: Capture photo and upload
//   Future<void> _captureAndUploadPhoto(
//       String taskName,
//       ImageSource source,
//       ) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//
//       // Pick image from camera or gallery
//       final XFile? image = await picker.pickImage(
//         source: source,
//         imageQuality: 85, // Compress to reduce file size
//         maxWidth: 1920,   // Max width
//         maxHeight: 1080,  // Max height
//       );
//
//       if (image == null) return; // User cancelled
//
//       // Show uploading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text(
//                 "Uploading photo...",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//       );
//
//       // Upload the photo
//       final success = await context
//           .read<SalesOrderProvider>()
//           .apiService!
//           .uploadTaskAttachment(
//         taskName: taskName,
//         filePath: image.path,
//       );
//
//       // Close loading dialog
//       Navigator.pop(context);
//
//       // Show result
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             success
//                 ? "Photo uploaded successfully"
//                 : "Failed to upload photo",
//           ),
//           backgroundColor: success ? Colors.green : Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//
//       if (success) {
//         // Refresh task list to update attachment indicator
//         context.read<SalesOrderProvider>().fetchTaskList();
//       }
//     } catch (e) {
//       // Close loading dialog if open
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

  Future<void> _captureAndUploadPhoto(
      String taskName,
      ImageSource source,
      ) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pick image from camera or gallery
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return; // User cancelled

      // Show professional uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildUploadDialog(
          fileName: image.name,
          fileType: "photo",
        ),
      );

      // Upload the photo
      final success = await context
          .read<SalesOrderProvider>()
          .apiService!
          .uploadTaskAttachment(
        taskName: taskName,
        filePath: image.path,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Show result with custom snackbar
      _showUploadResult(success, "Photo");

      if (success) {
        context.read<SalesOrderProvider>().fetchTaskList();
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showUploadResult(false, "Photo", error: e.toString());
    }
  }

// EXISTING METHOD: Pick file and upload (updated)
//   Future<void> _pickAndUploadFile(String taskName) async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.any,
//         allowMultiple: false,
//       );
//
//       if (result == null || result.files.single.path == null) return;
//
//       // Show uploading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text(
//                 "Uploading file...",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//       );
//
//       final success = await context
//           .read<SalesOrderProvider>()
//           .apiService!
//           .uploadTaskAttachment(
//         taskName: taskName,
//         filePath: result.files.single.path!,
//       );
//
//       Navigator.pop(context);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             success
//                 ? "File uploaded successfully"
//                 : "Failed to upload file",
//           ),
//           backgroundColor: success ? Colors.green : Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//
//       if (success) {
//         context.read<SalesOrderProvider>().fetchTaskList();
//       }
//     } catch (e) {
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  Future<void> _pickAndUploadFile(String taskName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final file = result.files.single;

      // Show professional uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildUploadDialog(
          fileName: file.name,
          fileType: _getFileType(file.name),
          fileSize: file.size,
        ),
      );

      final success = await context
          .read<SalesOrderProvider>()
          .apiService!
          .uploadTaskAttachment(
        taskName: taskName,
        filePath: file.path!,
      );

      Navigator.pop(context);

      _showUploadResult(success, "File");

      if (success) {
        context.read<SalesOrderProvider>().fetchTaskList();
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showUploadResult(false, "File", error: e.toString());
    }
  }
  Widget _buildUploadDialog({
    required String fileName,
    required String fileType,
    int? fileSize,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated upload icon
            Stack(
              alignment: Alignment.center,
              children: [
                // Rotating circle
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                ),
                // File icon in center
                Icon(
                  _getFileIcon(fileType),
                  size: 32,
                  color: Colors.blue.shade600,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              "Uploading...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // File name
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // File size (if available)
            if (fileSize != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatFileSize(fileSize),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Progress message
            Text(
              "Please wait...",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showUploadResult(bool success, String fileType, {String? error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    success
                        ? "$fileType uploaded successfully!"
                        : "Upload failed",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!success && error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        error,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: success ? 2 : 3),
        action: success
            ? null
            : SnackBarAction(
          label: "Retry",
          textColor: Colors.white,
          onPressed: () {
            // Optionally add retry logic
          },
        ),
      ),
    );
  }

// HELPER: Get file icon based on type
  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case "photo":
      case "image":
        return Icons.photo;
      case "pdf":
        return Icons.picture_as_pdf;
      case "document":
      case "doc":
      case "docx":
        return Icons.description;
      case "spreadsheet":
      case "excel":
      case "xlsx":
        return Icons.table_chart;
      case "video":
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

// HELPER: Determine file type from extension
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return "image";
    } else if (extension == 'pdf') {
      return "pdf";
    } else if (['doc', 'docx'].contains(extension)) {
      return "document";
    } else if (['xls', 'xlsx'].contains(extension)) {
      return "spreadsheet";
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return "video";
    }

    return "file";
  }

// HELPER: Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return "$bytes B";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(1)} KB";
    } else if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } else {
      return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
    }
  }

// HELPER: String extension for capitalize
//   extension StringExtension on String {
//   String capitalize() {
//     if (isEmpty) return this;
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }


// NEW METHOD: Show existing attachments (if you have _AttachmentSheet)
  Future<void> _showAttachmentSheet(String taskName) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttachmentSheet(
        taskName: taskName,
        onUpload: () async {
          // Close the attachment sheet
          Navigator.pop(ctx);
          // Show the main attachment options again
          _attachFile(taskName);
        },
        onDeleted: () {
          // Refresh the task list
          context.read<SalesOrderProvider>().fetchTaskList();
        },
        apiService: context.read<SalesOrderProvider>().apiService!,
      ),
    );
  }
  void _showFullDescriptionDialog(
      BuildContext context,
      String htmlDescription,
      String baseUrl, // Your ERP base URL
      ) {
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
                    // Convert relative URLs to absolute
                    final imageUrl = src.startsWith('http')
                        ? src
                        : '$baseUrl$src';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Widget _buildTaskCard(
  //     SalesOrderProvider provider,
  //     Map<String, dynamic> task,
  //     int index, {
  //       bool showDates = false,
  //     }) {
  //   final subject = task["subject"] ?? "No Subject";
  //   final name = task["name"] ?? "";
  //   final status = task["status"] ?? "Unknown";
  //   final priority = task["priority"] ?? "-";
  //   final progress = (task["progress"] ?? 0.0).toDouble();
  //   final startDate = task["exp_start_date"];
  //   final endDate = task["exp_end_date"];
  //   final projectName = task["project_name"] ?? "";
  //   final projectId = task["project"] ?? "";
  //   final parentTask = task["parent_task"];
  //   final type = task["type"];
  //   final taskWeight = task["task_weight"];
  //   final issue = task["issue"];
  //   final expectedTime = task["expected_time"];
  //   final htmlDescription = task["description"] ?? "";
  //   final hasDescription =
  //       htmlDescription.toString().trim().isNotEmpty;
  //
  //   return Card(
  //     elevation: 2,
  //     color: cardColors[index % cardColors.length],
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //
  //     child: InkWell(
  //       onTap: () {
  //         _showTaskUpdateDialog(
  //           context,
  //           currentStatus: status,
  //           currentProgress: progress,
  //           index: index,
  //         );
  //       },
  //       borderRadius: BorderRadius.circular(12),
  //       child: Padding(
  //         padding: const EdgeInsets.all(10),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Task Subject and Edit Icon
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         subject,
  //                         style: const TextStyle(
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.black87,
  //                         ),
  //                         maxLines: 2,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const SizedBox(height: 2),
  //                       // Task ID and Project in one line
  //                       Row(
  //                         children: [
  //                           Text(
  //                             name,
  //                             style: TextStyle(
  //                               fontSize: 9,
  //                               color: Colors.grey[600],
  //                               fontStyle: FontStyle.italic,
  //                             ),
  //                           ),
  //
  //                           if (projectName.isNotEmpty && projectName != "No Project") ...[
  //                             Text(
  //                               " • ",
  //                               style: TextStyle(
  //                                 fontSize: 9,
  //                                 color: Colors.grey[600],
  //                               ),
  //                             ),
  //                             Flexible(
  //                               child: Text(
  //                                 projectId.isNotEmpty
  //                                     ? "$projectName ($projectId)"
  //                                     : projectName,
  //                                 style: TextStyle(
  //                                   fontSize: 9,
  //                                   color: Colors.grey[600],
  //                                 ),
  //                                 overflow: TextOverflow.ellipsis,
  //                               ),
  //                             ),
  //                           ],
  //
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 if (provider.updatingIndex == index)
  //                   const SizedBox(
  //                     height: 14,
  //                     width: 14,
  //                     child: CircularProgressIndicator(strokeWidth: 2),
  //                   )
  //                 else
  //                   Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //
  //                       // 📄 Description Icon
  //                       if (hasDescription)
  //                         IconButton(
  //                           icon: const Icon(Icons.description_outlined, size: 16),
  //                           padding: EdgeInsets.zero,
  //                           constraints: const BoxConstraints(),
  //                           onPressed: () => _showFullDescriptionDialog(
  //                             context,
  //                             htmlDescription,
  //                             provider.apiService!.baseUrl, // Ensure baseUrl exists
  //                           ),
  //                         ),
  //
  //                       // 📎 Attachment Icon
  //                       Stack(
  //                         alignment: Alignment.topRight,
  //                         children: [
  //                           IconButton(
  //                             icon: Icon(
  //                               Icons.attach_file,
  //                               size: 16,
  //                               color: task["has_attachment"] == true
  //                                   ? Colors.green
  //                                   : Colors.grey,
  //                             ),
  //                             padding: EdgeInsets.zero,
  //                             constraints: const BoxConstraints(),
  //                             onPressed: () => _attachFile(name),
  //                           ),
  //                           if (task["has_attachment"] == true)
  //                             Positioned(
  //                               right: 2,
  //                               top: 2,
  //                               child: Container(
  //                                 width: 6,
  //                                 height: 6,
  //                                 decoration: const BoxDecoration(
  //                                   color: Colors.green,
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //
  //                     ],
  //                   ),
  //
  //
  //               ],
  //             ),
  //
  //             const SizedBox(height: 6),
  //
  //             // Compact info grid using Wrap
  //             Wrap(
  //               spacing: 8,
  //               runSpacing: 2,
  //               children: [
  //                 // Parent Task
  //                 if (_hasValidValue(parentTask))
  //                   _compactInfo(Icons.subdirectory_arrow_right, parentTask.toString()),
  //
  //                 // Type
  //                 if (_hasValidValue(type))
  //                   _compactInfo(Icons.category_outlined, type.toString()),
  //
  //                 // Task Weight
  //                 if (_hasValidNumeric(taskWeight))
  //                   _compactInfo(Icons.fitness_center, "W:$taskWeight"),
  //
  //                 // Issue
  //                 if (_hasValidValue(issue))
  //                   _compactInfo(Icons.bug_report_outlined, issue.toString()),
  //
  //                 // Expected Time
  //                 if (_hasValidNumeric(expectedTime))
  //                   _compactInfo(Icons.schedule, "${expectedTime}h"),
  //
  //                 // Dates
  //   if (showDates && (startDate != null || endDate != null)) ...[
  //               const SizedBox(height: 8),
  //
  //
  //                   if (startDate != null) ...[
  //                     Icon(Icons.calendar_today,
  //                         size: 12, color: Colors.grey[600]),
  //                     const SizedBox(width: 4),
  //                     Text(
  //                       _formatDate(startDate),
  //                       style: TextStyle(fontSize: 11, color: Colors.grey[700]),
  //                     ),
  //                   ],
  //                   if (startDate != null && endDate != null)
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 4),
  //                       child: Icon(Icons.arrow_forward,
  //                           size: 12, color: Colors.grey[600]),
  //                     ),
  //                   if (endDate != null) ...[
  //                     Text(
  //                       _formatDate(endDate),
  //                       style: TextStyle(fontSize: 11, color: Colors.grey[700]),
  //                     ),
  //                   ],
  //                 ],
  //
  //
  //               ],
  //             ),
  //
  //             const SizedBox(height: 6),
  //
  //             // Compact Progress Bar
  //             Row(
  //               children: [
  //                 Text(
  //                   "Progress",
  //                   style: TextStyle(
  //                     fontSize: 9,
  //                     color: Colors.grey[600],
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Expanded(
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(2),
  //                     child: LinearProgressIndicator(
  //                       value: progress / 100,
  //                       minHeight: 4,
  //                       backgroundColor: Colors.grey[300],
  //                       valueColor: AlwaysStoppedAnimation<Color>(
  //                         _getProgressColor(progress),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   "${progress.round()}%",
  //                   style: TextStyle(
  //                     fontSize: 9,
  //                     color: Colors.grey[700],
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //
  //             const SizedBox(height: 6),
  //
  //             // Status and Priority chips
  //             Row(
  //               children: [
  //                 _compactChip(
  //                   label: status,
  //                   color: statusColor(status),
  //                 ),
  //                 const SizedBox(width: 5),
  //                 _compactChip(
  //                   label: priority,
  //                   color: priorityColor(priority),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
// UPDATED: Task card with overdue highlighting
// Replace your _buildTaskCard method with this

  Widget _buildTaskCard(
      SalesOrderProvider provider,
      Map<String, dynamic> task,
      int index, {
        bool showDates = false,
      }) {
    final subject = task["subject"] ?? "No Subject";
    final name = task["name"] ?? "";
    final status = task["status"] ?? "Unknown";
    final priority = task["priority"] ?? "-";
    final progress = (task["progress"] ?? 0.0).toDouble();
    final startDate = task["exp_start_date"];
    final endDate = task["exp_end_date"];
    final projectName = task["project_name"] ?? "";
    final projectId = task["project"] ?? "";
    final parentTask = task["parent_task"];
    final type = task["type"];
    final taskWeight = task["task_weight"];
    final issue = task["issue"];
    final expectedTime = task["expected_time"];
    final htmlDescription = task["description"] ?? "";
    final hasDescription = htmlDescription.toString().trim().isNotEmpty;

    // Check if task is overdue
    final isOverdue = status.toLowerCase() == "overdue";

    return Card(
      elevation: isOverdue ? 4 : 2, // Higher elevation for overdue
      color: isOverdue
          ? Colors.red.shade50  // Light red background for overdue
          : cardColors[index % cardColors.length],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(
          color: Colors.red.shade300,  // Red border for overdue
          width: 2,
        )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _showTaskUpdateDialog(
            context,
            currentStatus: status,
            currentProgress: progress,
            index: index,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overdue badge (if overdue)
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "OVERDUE",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Task Subject and Edit Icon
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? Colors.red.shade900  // Darker text for overdue
                                    : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // const SizedBox(height: 2),
                            // // Task ID and Project in one line
                            // Row(
                            //   children: [
                            //     Text(
                            //       name,
                            //       style: TextStyle(
                            //         fontSize: 9,
                            //         color: isOverdue
                            //             ? Colors.red.shade700
                            //             : Colors.grey[600],
                            //         fontStyle: FontStyle.italic,
                            //       ),
                            //     ),
                            //     if (projectName.isNotEmpty &&
                            //         projectName != "No Project") ...[
                            //       Text(
                            //         " • ",
                            //         style: TextStyle(
                            //           fontSize: 9,
                            //           color: Colors.grey[600],
                            //         ),
                            //       ),
                            //       Flexible(
                            //         child: Text(
                            //           projectId.isNotEmpty
                            //               ? "$projectName ($projectId)"
                            //               : projectName,
                            //           style: TextStyle(
                            //             fontSize: 9,
                            //             color: Colors.grey[600],
                            //           ),
                            //           overflow: TextOverflow.ellipsis,
                            //         ),
                            //       ),
                            //     ],
                            //   ],
                            // ),
                            const SizedBox(height: 3),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // Task ID row
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isOverdue
                                        ? Colors.red.shade700
                                        : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Project row
                                if (projectName.isNotEmpty &&
                                    projectName != "No Project")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      projectId.isNotEmpty
                                          ? "$projectName ($projectId)"
                                          : projectName,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (provider.updatingIndex == index)
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 📄 Description Icon
                            if (hasDescription)
                              IconButton(
                                icon: const Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showFullDescriptionDialog(
                                  context,
                                  htmlDescription,
                                  provider.apiService!.baseUrl,
                                ),
                              ),

                            // 📎 Attachment Icon
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.attach_file,
                                    size: 16,
                                    color: task["has_attachment"] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _attachFile(name),
                                ),
                                if (task["has_attachment"] == true)
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Compact info grid using Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      // Parent Task
                      if (_hasValidValue(parentTask))
                        _compactInfo(
                          Icons.subdirectory_arrow_right,
                          parentTask.toString(),
                        ),

                      // Type
                      if (_hasValidValue(type))
                        _compactInfo(Icons.category_outlined, type.toString()),

                      // Task Weight
                      if (_hasValidNumeric(taskWeight))
                        _compactInfo(Icons.fitness_center, "W:$taskWeight"),

                      // Issue
                      if (_hasValidValue(issue))
                        _compactInfo(Icons.bug_report_outlined, issue.toString()),

                      // Expected Time
                      if (_hasValidNumeric(expectedTime))
                        _compactInfo(Icons.schedule, "${expectedTime}h"),

                      // Dates
                      if (showDates && (startDate != null || endDate != null)) ...[
                        if (startDate != null)
                          _compactInfo(Icons.calendar_today, _formatDate(startDate)),
                        if (endDate != null)
                          _compactInfo(Icons.event, _formatDate(endDate)),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Compact Progress Bar
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
                            value: progress / 100,
                            minHeight: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverdue
                                  ? Colors.red.shade700  // Red progress for overdue
                                  : _getProgressColor(progress),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${progress.round()}%",
                        style: TextStyle(
                          fontSize: 9,
                          color: isOverdue
                              ? Colors.red.shade700
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status and Priority chips
                  Row(
                    children: [
                      _compactChip(
                        label: status,
                        color: statusColor(status),
                      ),
                      const SizedBox(width: 5),
                      _compactChip(
                        label: priority,
                        color: priorityColor(priority),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Animated pulse indicator for overdue (top-right corner)
            if (isOverdue)
              Positioned(
                top: 8,
                right: 8,
                child: _buildPulsingIndicator(),
              ),
          ],
        ),
      ),
    );
  }

// Add this helper widget for the pulsing indicator
  Widget _buildPulsingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 4 * value,
                  spreadRadius: 2 * value,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // This creates the pulsing effect by restarting the animation
        // Note: This will pulse once. For continuous pulsing, wrap in StatefulWidget
      },
    );
  }
// Compact info widget with icon (HELPER METHOD)
  Widget _compactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[700],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
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
  // Format date helper
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  // Build list view
  Widget _buildListView(SalesOrderProvider provider) {
    final filteredTasks = _getFilteredTasks(provider);

    return SafeArea(
      bottom: true,
      child: filteredTasks.isEmpty
          ? const Center(
        child: Text(
          "No tasks found",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: filteredTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          final globalIndex = provider.taskList.indexOf(task);
          return _buildTaskCard(provider, task, globalIndex,
              showDates: true);
        },
      ),
    );
  }

  Widget _buildCalendarView(SalesOrderProvider provider) {
    final selectedTasks =
    _getTasksForDate(provider, _selectedDay);

    return Column(
      children: [

        // 🔘 Calendar Toggle Header
        InkWell(
          onTap: () {
            setState(() {
              _showCalendar = !_showCalendar;
            });
          },
          child: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                const Text(
                  "Calendar",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (selectedTasks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Text(
                      selectedTasks.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const Spacer(),

                Icon(
                  _showCalendar
                      ? Icons.expand_less
                      : Icons.expand_more,
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // 🔽 Collapsible Calendar
        AnimatedCrossFade(
          firstChild: Column(
            children: [

              // Calendar Widget
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek:
                StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue
                        .withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration:
                  const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration:
                  const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                eventLoader: (day) {
                  return _getTasksForDate(
                      provider, day);
                },
                onDaySelected:
                    (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),

              const SizedBox(height: 8),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      "Tasks on ${_formatDate(_selectedDay.toIso8601String())}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),

          secondChild:
          const SizedBox.shrink(),

          crossFadeState: _showCalendar
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,

          duration:
          const Duration(milliseconds: 250),
        ),

        // Task List Always Visible
        Expanded(
          child:
          _buildTasksForSelectedDate(provider),
        ),
      ],
    );
  }


  // Build tasks for selected date
  Widget _buildTasksForSelectedDate(SalesOrderProvider provider) {
    final tasks = _getTasksForDate(provider, _selectedDay);

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          "No tasks on this date",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final globalIndex = provider.taskList.indexOf(task);
        return _buildTaskCard(provider, task, globalIndex, showDates: true);
      },
    );
  }

  // Build gantt view
// Build gantt view
  Widget _buildGanttView(SalesOrderProvider provider) {
    final filteredTasks = _getFilteredTasks(provider)
        .where((task) =>
    task["exp_start_date"] != null || task["exp_end_date"] != null)
        .toList();

    if (filteredTasks.isEmpty) {
      return const Center(
        child: Text(
          "No tasks with dates found",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Find date range
    DateTime? minDate;
    DateTime? maxDate;

    for (var task in filteredTasks) {
      if (task["exp_start_date"] != null) {
        final start = DateTime.parse(task["exp_start_date"]);
        if (minDate == null || start.isBefore(minDate)) {
          minDate = start;
        }
      }
      if (task["exp_end_date"] != null) {
        final end = DateTime.parse(task["exp_end_date"]);
        if (maxDate == null || end.isAfter(maxDate)) {
          maxDate = end;
        }
      }
    }

    if (minDate == null || maxDate == null) {
      return const Center(
        child: Text(
          "No valid date range found",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final totalDays = maxDate.difference(minDate).inDays + 1;
    final today = DateTime.now();
    final ganttWidth = totalDays * 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed task labels column header
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  "Task",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Text(
                      "Timeline (scroll horizontally →)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline header with horizontal scroll
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed space for task labels
                    const SizedBox(width: 120),

                    // Scrollable timeline header
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: ganttWidth,
                          height: 40,
                          child: Row(
                            children: List.generate(
                              totalDays,
                                  (index) {
                                final date = minDate!.add(Duration(days: index));
                                final isToday = isSameDay(date, today);
                                return Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.grey[300]!),
                                      bottom: BorderSide(
                                        color: isToday ? Colors.blue : Colors.grey[300]!,
                                        width: isToday ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "${date.day}\n${_getMonthShort(date.month)}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isToday ? Colors.blue : Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Task rows with synchronized horizontal scroll
                ...filteredTasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final task = entry.value;
                  final globalIndex = provider.taskList.indexOf(task);

                  final subject = task["subject"] ?? "No Subject";
                  final status = task["status"] ?? "Unknown";
                  final progress = (task["progress"] ?? 0.0).toDouble();
                  final startDate = task["exp_start_date"] != null
                      ? DateTime.parse(task["exp_start_date"])
                      : null;
                  final endDate = task["exp_end_date"] != null
                      ? DateTime.parse(task["exp_end_date"])
                      : null;

                  // Calculate position and width
                  final start = startDate ?? endDate!;
                  final end = endDate ?? startDate!;
                  final startOffset = start.difference(minDate!).inDays;
                  final duration = end.difference(start).inDays + 1;

                  return Container(
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed task label
                        SizedBox(
                          width: 120,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  subject,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${progress.round()}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Scrollable gantt bar area
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: ganttWidth,
                              height: 70,
                              child: Stack(
                                children: [
                                  // Grid lines
                                  Row(
                                    children: List.generate(
                                      totalDays,
                                          (index) {
                                        final date = minDate!.add(Duration(days: index));
                                        final isToday = isSameDay(date, today);
                                        return Container(
                                          width: 40,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(color: Colors.grey[300]!),
                                              top: BorderSide(color: Colors.grey[200]!),
                                              bottom: BorderSide(color: Colors.grey[200]!),
                                            ),
                                            color: isToday
                                                ? Colors.blue.withOpacity(0.05)
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Task bar
                                  Positioned(
                                    left: startOffset * 40.0,
                                    top: 15,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showTaskUpdateDialog(
                                          context,
                                          currentStatus: status,
                                          currentProgress: progress,
                                          index: globalIndex,
                                        );
                                      },
                                      child: Container(
                                        width: duration * 40.0,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: statusColor(status).withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: statusColor(status),
                                            width: 2,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Progress overlay
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  width: (duration * 40.0) * (progress / 100),
                                                  height: 40,
                                                  color: statusColor(status),
                                                ),
                                              ),
                                            ),
                                            // Text
                                            Center(
                                              child: Text(
                                                "$duration day${duration > 1 ? 's' : ''}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // // Build filter chips
  // Widget _buildFilterChips(SalesOrderProvider provider) {
  //   final statuses = [
  //     "All",
  //     "Open",
  //     "Working",
  //     "Pending Review",
  //     "Overdue",
  //     "Template",
  //     "Completed",
  //     "Cancelled",
  //   ];
  //
  //   return Container(
  //     height: 50,
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: ListView.separated(
  //       scrollDirection: Axis.horizontal,
  //       padding: const EdgeInsets.symmetric(horizontal: 12),
  //       itemCount: statuses.length,
  //       separatorBuilder: (_, __) => const SizedBox(width: 8),
  //       itemBuilder: (context, index) {
  //         final status = statuses[index];
  //         final isSelected = _selectedFilter == status;
  //
  //         return FilterChip(
  //           label: Text(status),
  //           selected: isSelected,
  //           onSelected: (selected) {
  //             setState(() {
  //               _selectedFilter = status;
  //             });
  //           },
  //           selectedColor: statusColor(status).withOpacity(0.3),
  //           checkmarkColor: statusColor(status),
  //           backgroundColor: Colors.grey[200],
  //           labelStyle: TextStyle(
  //             color: isSelected ? statusColor(status) : Colors.black87,
  //             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedFilter != "All") count++;
    if (_selectedProjectId != null) count++;
    return count;
  }

  Widget _buildFilterBar(SalesOrderProvider provider) {
    final hasActiveFilters =
        _selectedFilter != "All" || _selectedProjectId != null;

    const statuses = [
      "All", "Open", "Working", "Pending Review",
      "Overdue", "Template", "Completed", "Cancelled",
    ];

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Toggle row
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    "Filters",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
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
                        _selectedFilter = "All";
                        _selectedProjectId = null;
                      }),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          "Clear",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  Icon(
                    _showFilters ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Expanded filters
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  // Status chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final status = statuses[index];
                        final isSelected = _selectedFilter == status;
                        return FilterChip(
                          label: Text(status, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = status),
                          selectedColor: statusColor(status).withOpacity(0.3),
                          checkmarkColor: statusColor(status),
                          backgroundColor: Colors.grey.shade200,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? statusColor(status) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Project dropdown inline
                  Row(
                    children: [
                      const Text(
                        "Project:",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedProjectId,
                          isDense: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          hint: const Text("All Projects", style: TextStyle(fontSize: 12)),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("All Projects"),
                            ),
                            ..._projects.map((p) => DropdownMenuItem(
                              value: p["value"],
                              child: Text(p["label"] ?? ""),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedProjectId = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const Divider(height: 1),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "My Tasks",
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View selector icon
            IconButton(
              icon: Icon(
                _currentView == TaskViewType.list
                    ? Icons.view_list
                    : _currentView == TaskViewType.calendar
                    ? Icons.calendar_month
                    : Icons.bar_chart,
                color: Colors.white,
              ),
              onPressed: () => _showViewSelectionSheet(context),
            ),
            // Refresh button
            Consumer<SalesOrderProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: provider.isLoadingTasks
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.refresh, color: Colors.white),
                  onPressed: provider.isLoadingTasks
                      ? null
                      : () => provider.fetchTaskList(),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTasks && provider.taskList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Filter Chips
              // _buildFilterChips(provider),
              _buildFilterBar(provider),


              // Task Count
              if (_currentView == TaskViewType.list)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        '${_getFilteredTasks(provider).length} task(s)',
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

              // View Content
              Expanded(
                child: _currentView == TaskViewType.list
                    ? _buildListView(provider)
                    : _currentView == TaskViewType.calendar
                    ? _buildCalendarView(provider)
                    : _buildGanttView(provider),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttachmentSheet extends StatefulWidget {
  final String taskName;
  final VoidCallback onUpload;
  final dynamic apiService; // your ApiService type
  final VoidCallback? onDeleted;
  const _AttachmentSheet({
    required this.taskName,
    required this.onUpload,
    this.onDeleted,
    required this.apiService,
  });

  @override
  State<_AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<_AttachmentSheet> {
  List<Map<String, dynamic>> _attachments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    final list =
    await widget.apiService.fetchTaskAttachments(taskName: widget.taskName);
    if (mounted) setState(() { _attachments = list; _loading = false; });
  }
  Future<void> _deleteAttachment(Map<String, dynamic> file) async {
    final fileName = file["name"] as String?; // this is the File docname e.g. "2bac4186ea"
    final displayName = file["file_name"] as String? ?? "this file";

    if (fileName == null) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete Attachment", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$displayName"?\nThis cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await widget.apiService.deleteTaskAttachment(fileName);

    Navigator.pop(context); // close loading

    if (success) {
      setState(() {
        _attachments.removeWhere((f) => f["name"] == fileName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attachment deleted"),
          backgroundColor: Colors.green,
        ),
      );
      // Notify parent to refresh task list (to update the green dot)
      widget.onDeleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete attachment"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  /// Returns true if file type is an image we can preview inline
  bool _isImage(String? fileType) {
    if (fileType == null) return false;
    return ['JPG', 'JPEG', 'PNG', 'GIF', 'WEBP', 'BMP']
        .contains(fileType.toUpperCase());
  }

  /// Returns true if it's a PDF
  bool _isPdf(String? fileType) =>
      fileType?.toUpperCase() == 'PDF';

  /// Download and open file
  Future<void> _downloadAndOpen(Map<String, dynamic> file) async {
    final fileUrl = file["file_url"] as String?;
    final fileName = file["file_name"] as String? ?? "download";
    if (fileUrl == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final bytes = await widget.apiService.downloadPrivateFile(fileUrl);
    Navigator.pop(context);

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download file")),
      );
      return;
    }

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final localPath = '${dir.path}/$fileName';
    await File(localPath).writeAsBytes(bytes);

    // Open with the OS default app
    await OpenFilex.open(localPath);
  }

  /// Build an inline image preview widget (loads bytes from ERPNext)
  Widget _buildImagePreview(Map<String, dynamic> file) {
    final fileUrl = file["file_url"] as String?;
    if (fileUrl == null) return const SizedBox();

    return FutureBuilder<Uint8List?>(
      future: widget.apiService.downloadPrivateFile(fileUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        }
        return Container(
          height: 60,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      },
    );
  }

  String _formatSize(dynamic sizeBytes) {
    if (sizeBytes == null) return "";
    final kb = (sizeBytes as num) / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    return "${(kb / 1024).toStringAsFixed(1)} MB";
  }

  IconData _fileIcon(String? fileType) {
    switch (fileType?.toUpperCase()) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'DOC': case 'DOCX': return Icons.description;
      case 'XLS': case 'XLSX': return Icons.table_chart;
      case 'ZIP': case 'RAR': return Icons.folder_zip;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Attachments — ${widget.taskName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Upload new file button
                  TextButton.icon(
                    onPressed: widget.onUpload,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text("Add", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _attachments.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      "No attachments yet",
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemCount: _attachments.length,
                itemBuilder: (_, i) {
                  final file = _attachments[i];
                  final fileType = file["file_type"] as String?;
                  final fileName =
                      file["file_name"] as String? ?? "Unknown";

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // Image preview (only for images)
                          if (_isImage(fileType)) ...[
                            _buildImagePreview(file),
                            const SizedBox(height: 8),
                          ],

                          Row(
                            children: [
                              Icon(
                                _isImage(fileType)
                                    ? Icons.image
                                    : _fileIcon(fileType),
                                size: 20,
                                color: _isImage(fileType)
                                    ? Colors.blue
                                    : _isPdf(fileType)
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${fileType ?? 'File'} • ${_formatSize(file["file_size"])}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ⬇️ Download button
                              IconButton(
                                icon: const Icon(Icons.download_outlined, size: 20),
                                color: Colors.blue[700],
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _downloadAndOpen(file),
                              ),

                              const SizedBox(width: 8),

                              // 🗑️ Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: Colors.red[400],
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteAttachment(file),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}