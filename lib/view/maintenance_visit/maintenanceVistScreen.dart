import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import '../../model/maintenance_visit_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';

class MaintenanceVisitScreen extends StatefulWidget {

  final String? salesOrderName;
  final String? maintenanceVisitName;
  const MaintenanceVisitScreen({
    super.key,
    this.salesOrderName,
    this.maintenanceVisitName,

  });

  @override
  State<MaintenanceVisitScreen> createState() =>
      _MaintenanceVisitScreenState();
}
class _MaintenanceVisitScreenState extends State<MaintenanceVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Header fields
  final _customerCtrl = TextEditingController();
  DateTime? _mntcDate;
  TimeOfDay? _mntcTime;
  String _completionStatus = 'Fully Completed';
  String _maintenanceType = 'Scheduled';
  String? _resolvedSalesPerson;
  bool _isResolvingSalesPerson = false;
  // Purpose items
  final List<PurposeItem> _purposeItems = [];
  String _selectedItemNameTemp = "";
  // Dropdown options
  final List<String> _statusOptions = ['Fully Completed', 'Partially Completed'];
  final List<String> _typeOptions = ['Breakdown', 'Unscheduled', 'Scheduled'];
  final _customerFeedbackCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _mntcDate = DateTime.now();
    _mntcTime = TimeOfDay.now();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSalesPerson();

      if (widget.maintenanceVisitName != null) {
        await _loadMaintenanceVisitData(widget.maintenanceVisitName!);
      } else if (widget.salesOrderName != null) {
        await _loadSalesOrderData(widget.salesOrderName!);
      } else {

      }
    });
  }

  Future<void> _loadMaintenanceVisitData(String name) async {
    final provider = context.read<SalesOrderProvider>();

    final visit =
    await provider.fetchMaintenanceVisitByName(name);

    if (visit == null) return;

    final items =
        visit["purposes"] ?? visit["maintenance_visit_purpose"];

    setState(() {
      _customerCtrl.text = visit["customer"] ?? "";

      _completionStatus =
          visit["completion_status"] ?? "Fully Completed";

      _maintenanceType =
          visit["maintenance_type"] ?? "Scheduled";
      _customerFeedbackCtrl.text = visit["customer_feedback"] ?? "";
      if (visit["mntc_date"] != null) {
        _mntcDate = DateTime.parse(visit["mntc_date"]);
      }

      if (visit["mntc_time"] != null) {
        final timeParts =
        visit["mntc_time"].toString().split(":");
        _mntcTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      _purposeItems.clear();

      if (items != null && items is List) {
        for (final row in items) {
          _purposeItems.add(
            PurposeItem(
              itemCode: row["item_code"] ?? "",
              itemName: row["item_name"] ?? "",
              servicePerson: row["service_person"] ?? "",
              serialNo: row["serial_no"] ?? "",
              workDone: row["work_done"] ?? "",
            ),
          );
        }
      }
    });
  }
  Future<void> _loadSalesOrderData(String salesOrderName) async {
    final provider = context.read<SalesOrderProvider>();

    final salesOrder =
    await provider.fetchSalesOrderByName(salesOrderName);

    if (salesOrder == null) return;

    final customer = salesOrder["customer"];
    final items = salesOrder["items"] as List<dynamic>?;

    setState(() {
      // ✅ Prefill customer
      _customerCtrl.text = customer ?? "";

      // ✅ Clear existing purpose items
      _purposeItems.clear();

      // ✅ Prefill items from Sales Order
      if (items != null && items.isNotEmpty) {
        for (final soItem in items) {
          _purposeItems.add(
            PurposeItem(
              itemCode: soItem["item_code"] ?? "",
              itemName: soItem["item_name"] ?? "",
              servicePerson: _resolvedSalesPerson ?? "",
              serialNo: "", // user will select later
              workDone: "",
            ),
          );
        }
      }
    });
  }
  Future<void> _loadSalesPerson() async {
    setState(() {
      _isResolvingSalesPerson = true;
    });

    final provider = context.read<SalesOrderProvider>();
    final salesPerson =
    await provider.apiService!.resolveLoggedInSalesPerson();

    setState(() {
      _resolvedSalesPerson = salesPerson;
      _isResolvingSalesPerson = false;
    });
  }
  // ── helpers ──────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mntcDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _mntcDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _mntcTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _mntcTime = picked);
  }

  void _removePurposeItem(int index) {
    setState(() => _purposeItems.removeAt(index));
  }

  void _openItemSearchSheet(TextEditingController controller) {
    final provider = context.read<SalesOrderProvider>();
    final searchCtrl = TextEditingController();
    final searchFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {

        // 🔥 Auto focus after sheet builds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });

        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Select Item",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  focusNode: searchFocusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search item...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    provider.searchItemm(value);
                  },
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Consumer<SalesOrderProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearchingItem) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.itemSearchResults.isEmpty) {
                      return const Center(
                        child: Text("No items found"),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.itemSearchResults.length,
                      itemBuilder: (context, index) {
                        final item =
                        provider.itemSearchResults[index];

                        return ListTile(
                          title: Text(
                            item["item_name"] ?? "",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            item["item_code"] ?? "",
                            style: const TextStyle(fontSize: 8),
                          ),
                          onTap: () {
                            setState(() {
                              controller.text =
                                  item["item_code"] ?? "";
                              _selectedItemNameTemp =
                                  item["item_name"] ?? "";
                            });

                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildItemSearchField(TextEditingController controller) {
    return GestureDetector(
      onTap: () => _openItemSearchSheet(controller),
      child: AbsorbPointer(
        child: _dialogField(
          controller: controller,
          label: 'Item Code',
          icon: Icons.qr_code,
          required: true,
        ),
      ),
    );
  }
  void _openSerialSearchSheet({
    required TextEditingController controller,
    required String itemCode,
  }) {
    if (itemCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Item first"),
        ),
      );
      return;
    }

    final provider = context.read<SalesOrderProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {

        // 🔥 Fetch serials immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.fetchSerialNumber(itemCode);
        });

        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Select Serial Number",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Consumer<SalesOrderProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoadingSerials) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.serialSearchResults.isEmpty) {
                      return const Center(
                        child: Text("No serial numbers available"),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.serialSearchResults.length,
                      itemBuilder: (context, index) {
                        final serial =
                        provider.serialSearchResults[index];

                        return ListTile(
                          title: Text(serial),
                          onTap: () {
                            controller.text = serial;
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showAddEditItemDialog({int? editIndex}) {
    final item = editIndex != null ? _purposeItems[editIndex] : PurposeItem();
    final codeCtrl = TextEditingController(text: item.itemCode);
    final personCtrl = TextEditingController(
      text: editIndex != null
          ? item.servicePerson
          : (_resolvedSalesPerson ?? ""),
    );
    final serialCtrl = TextEditingController(text: item.serialNo);
    final workCtrl = TextEditingController(text: item.workDone);
    final dialogFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (_) {
          final mediaQuery = MediaQuery.of(context);

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: mediaQuery.viewInsets.bottom +
                    mediaQuery.viewPadding.bottom, // ✅ keyboard + system nav
              ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build_outlined,
                          color: AppColors.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      editIndex != null ? 'Edit Item' : 'Add Item',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Form
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildItemSearchField(codeCtrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogField(
                                  controller: personCtrl,
                                  label: 'Service Person',
                                  required: true,
                                  readOnly: true,
                                  icon: Icons.person_outline),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _openSerialSearchSheet(
                                  controller: serialCtrl,
                                  itemCode: codeCtrl.text,
                                ),
                                child: AbsorbPointer(
                                  child: _dialogField(
                                    controller: serialCtrl,
                                    label: 'Serial No',
                                    icon: Icons.tag,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _dialogField(
                          controller: workCtrl,
                          label: 'Work Done',
                          icon: Icons.checklist_outlined,
                          maxLines: 3,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (dialogFormKey.currentState!.validate()) {
                                setState(() {
                                  final newItem = PurposeItem(
                                    itemCode: codeCtrl.text,
                                    itemName: _selectedItemNameTemp,
                                    servicePerson: personCtrl.text,
                                    serialNo: serialCtrl.text,
                                    workDone: workCtrl.text,
                                  );
                                  if (editIndex != null) {
                                    _purposeItems[editIndex] = newItem;
                                  } else {
                                    _purposeItems.add(newItem);
                                  }
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              editIndex != null ? 'Update Item' : 'Add Item',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
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
      ));},
    );
  }
  // Widget _dialogField({
  //   required TextEditingController controller,
  //   required String label,
  //   required IconData icon,
  //   int maxLines = 1,
  //   bool required = false,
  //   bool readOnly = false,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     maxLines: maxLines,
  //     readOnly: readOnly,
  //     validator: required
  //         ? (v) => (v == null || v.isEmpty) ? 'Required' : null
  //         : null,
  //     style: const TextStyle(fontSize: 14, color: AppColors.textColor),
  //     decoration: InputDecoration(
  //       labelText: label,
  //       labelStyle: const TextStyle(fontSize: 13, color: AppColors.labelColor),
  //       prefixIcon: Icon(icon, size: 18, color: AppColors.labelColor),
  //       filled: true,
  //       fillColor: AppColors.surfaceColor,
  //       contentPadding:
  //       const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide: const BorderSide(color: AppColors.borderColor),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide: const BorderSide(color: AppColors.borderColor),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(10),
  //         borderSide:
  //         const BorderSide(color: AppColors.primaryColor, width: 1.5),
  //       ),
  //     ),
  //   );
  // }
  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
      style: const TextStyle(fontSize: 13, color: AppColors.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(fontSize: 12, color: AppColors.labelColor),
        prefixIcon: Icon(icon, size: 16, color: AppColors.labelColor),
        filled: true,
        fillColor: AppColors.surfaceColor,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide:
          const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
      ),
    );
  }
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mntcDate == null || _mntcTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select maintenance date & time")),
      );
      return;
    }

    if (_purposeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one purpose item")),
      );
      return;
    }
// 🔴 Validate work_done for every purpose item
    final hasEmptyWorkDone = _purposeItems.any(
          (item) => item.workDone.trim().isEmpty,
    );

    if (hasEmptyWorkDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Work Done for all purpose items"),
        ),
      );
      return;
    }
    final provider = context.read<SalesOrderProvider>();

    // 🔹 Format Date
    final formattedDate =
        "${_mntcDate!.year.toString().padLeft(4, '0')}-"
        "${_mntcDate!.month.toString().padLeft(2, '0')}-"
        "${_mntcDate!.day.toString().padLeft(2, '0')}";

    // 🔹 Format Time
    final formattedTime =
        "${_mntcTime!.hour.toString().padLeft(2, '0')}:"
        "${_mntcTime!.minute.toString().padLeft(2, '0')}:00";

    // 🔹 Convert Purpose Items to API Format
    final purposes = _purposeItems.map((item) {
      return {
        "item_code": item.itemCode,
        // "item_name": item.itemName,
        "service_person": item.servicePerson,
        "serial_no": item.serialNo,
        "work_done": item.workDone,
      };
    }).toList();

    try {
      if (widget.maintenanceVisitName != null) {
        // 🔥 EDIT MODE → PUT
        await provider.updateMaintenanceVisit(
          name: widget.maintenanceVisitName!,
          customer: _customerCtrl.text.trim(),
          customerName: _customerCtrl.text.trim(),
          mntcDate: formattedDate,
          mntcTime: formattedTime,
          completionStatus: _completionStatus,
          maintenanceType: _maintenanceType,
          customerFeedback: _customerFeedbackCtrl.text.trim(),

          purposes: purposes,
        );
      } else {
        // 🔥 CREATE MODE → POST
        await provider.createMaintenanceVisit(
          customer: _customerCtrl.text.trim(),
          customerName: _customerCtrl.text.trim(),
          mntcDate: formattedDate,
          mntcTime: formattedTime,
          completionStatus: _completionStatus,
          maintenanceType: _maintenanceType,
          customerFeedback: _customerFeedbackCtrl.text.trim(),

          purposes: purposes,
          // ✅ Pass reference only if coming from Sales Order
          prevDocName: widget.salesOrderName,
          prevDocType:
          widget.salesOrderName != null ? "Sales Order" : null,
        );
      }

      if (provider.maintenanceVisitCreated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                // Text('Maintenance Visit Created Successfully'),
                Text(
                    widget.maintenanceVisitName != null
                        ? 'Maintenance Visit Updated Successfully'
                        : 'Maintenance Visit Created Successfully'
                )
              ],
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );

        Navigator.pop(context); // Go back after success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create Maintenance Visit")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _openCustomerSearchSheet() {
    final provider = context.read<SalesOrderProvider>();
    final searchCtrl = TextEditingController();
    final searchFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {

        // 🔥 Request focus after frame builds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });

        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Select Customer",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  focusNode: searchFocusNode,
                  autofocus: true, // extra safety
                  decoration: const InputDecoration(
                    hintText: "Search customer...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    provider.searchCustomers(value);
                  },
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Consumer<SalesOrderProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearchingCustomer) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.customerSearchResults.isEmpty) {
                      return const Center(
                        child: Text("No customers found"),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.customerSearchResults.length,
                      itemBuilder: (context, index) {
                        final customer =
                        provider.customerSearchResults[index];

                        return ListTile(
                          title: Text(customer),
                          onTap: () {
                            setState(() {
                              _customerCtrl.text = customer;
                            });

                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  //search customer
  Widget _buildCustomerField() {
    return GestureDetector(
      onTap: _openCustomerSearchSheet,
      child: AbsorbPointer(
        child: _buildTextField(
          controller: _customerCtrl,
          label: 'Customer',
          icon: Icons.business_outlined,
          required: true,
        ),
      ),
    );
  }
  // ── build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: CommonAppBar(
        title: 'Maintenance Visit',
        actions: Consumer<SalesOrderProvider>(
          builder: (context, provider, _) {
            return TextButton(
              onPressed: provider.isCreatingMaintenanceVisit ? null : _saveForm,
              child: provider.isCreatingMaintenanceVisit
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Row(
                children: const [
                  Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Static: Visit Details ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _sectionCard(
                title: 'Visit Details',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primaryColor,
                children: [
                  _buildCustomerField(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTapField(
                          label: 'Maintenance Date',
                          icon: Icons.calendar_today_outlined,
                          value: _mntcDate != null
                              ? '${_mntcDate!.day.toString().padLeft(2, '0')}/'
                              '${_mntcDate!.month.toString().padLeft(2, '0')}/'
                              '${_mntcDate!.year}'
                              : null,
                          hint: 'Select date',
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTapField(
                          label: 'Maintenance Time',
                          icon: Icons.access_time_outlined,
                          value: _mntcTime != null
                              ? _mntcTime!.format(context)
                              : null,
                          hint: 'Select time',
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Completion Status',
                          icon: Icons.flag_outlined,
                          value: _completionStatus,
                          items: _statusOptions,
                          onChanged: (v) =>
                              setState(() => _completionStatus = v!),
                          badgeColor: _statusBadgeColor(_completionStatus),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Maintenance Type',
                          icon: Icons.settings_outlined,
                          value: _maintenanceType,
                          items: _typeOptions,
                          onChanged: (v) =>
                              setState(() => _maintenanceType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _dialogField(
                    controller: _customerFeedbackCtrl,
                    label: 'Customer Feedback',
                    icon: Icons.feedback_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // ── Scrollable: Purpose Items ──────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _purposeSectionCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── Sub-widgets ───────────────────────────────
  Widget _purposeSectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — fixed, never scrolls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.list_alt_outlined,
                      color: AppColors.accentOrange, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Purpose Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const Spacer(),
                _buildAddButton(),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderColor),

          // Body — scrollable list fills remaining space
          Expanded(
            child: _purposeItems.isEmpty
                ? _emptyState()
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _purposeItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) =>
                  _purposeItemCard(_purposeItems[index], index),
            ),
          ),
        ],
      ),
    );
  }
  // Widget _sectionCard({
  //   required String title,
  //   required IconData icon,
  //   required Color iconColor,
  //   required List<Widget> children,
  //   Widget? trailing,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: AppColors.cardColor,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 10,
  //             offset: const Offset(0, 2)),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Section header
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
  //           child: Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(6),
  //                 decoration: BoxDecoration(
  //                   color: iconColor.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Icon(icon, color: iconColor, size: 16),
  //               ),
  //               const SizedBox(width: 10),
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.textColor,
  //                 ),
  //               ),
  //               const Spacer(),
  //               if (trailing != null) trailing,
  //             ],
  //           ),
  //         ),
  //         const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
  //         Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: children,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: iconColor, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
          : null,
      style: const TextStyle(fontSize: 14, color: AppColors.textColor),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  // Widget _buildTapField({
  //   required String label,
  //   required IconData icon,
  //   required String? value,
  //   required String hint,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  //       decoration: BoxDecoration(
  //         color: AppColors.surfaceColor,
  //         borderRadius: BorderRadius.circular(10),
  //         border: Border.all(color: AppColors.borderColor),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, size: 16, color: AppColors.labelColor),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(label,
  //                     style: const TextStyle(
  //                         fontSize: 11, color: AppColors.labelColor)),
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   value ?? hint,
  //                   style: TextStyle(
  //                     fontSize: 13,
  //                     color: value != null
  //                         ? AppColors.textColor
  //                         : Colors.grey[400],
  //                     fontWeight: value != null
  //                         ? FontWeight.w500
  //                         : FontWeight.normal,
  //                   ),
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Icon(Icons.chevron_right,
  //               size: 16, color: Colors.grey[400]),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildTapField({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.labelColor),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 12,
                  color: value != null ? AppColors.textColor : Colors.grey[400],
                  fontWeight:
                  value != null ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Color? badgeColor,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down,
          size: 18, color: AppColors.labelColor),
      style: const TextStyle(fontSize: 13, color: AppColors.textColor),
      decoration: _inputDecoration(label: label, icon: icon),
      items: items
          .map((s) => DropdownMenuItem(
        value: s,
        child: Text(s,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis),
      ))
          .toList(),
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.labelColor),
      prefixIcon: Icon(icon, size: 17, color: AppColors.labelColor),
      filled: true,
      fillColor: AppColors.surfaceColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.deleteRed, width: 1.5),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddEditItemDialog(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Add',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 72),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined,
                size: 28, color: Colors.grey[400]),
          ),
          const SizedBox(height: 10),
          Text('No items added yet',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Tap "Add" to include purpose items',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }
  // Add this to your state - track which cards are expanded
  final Set<int> _expandedItems = {};

  Widget _purposeItemCard(PurposeItem item, int index) {
    final isExpanded = _expandedItems.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Row (always visible) ──────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Index badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),

                // Item code + name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.itemName.isNotEmpty ? item.itemName : 'Unnamed Item',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        item.itemCode.isNotEmpty ? item.itemCode : '—',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() {
                    isExpanded
                        ? _expandedItems.remove(index)
                        : _expandedItems.add(index);
                  }),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? 'Less' : 'More',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Edit
                GestureDetector(
                  onTap: () => _showAddEditItemDialog(editIndex: index),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 13, color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 6),

                // Delete
                GestureDetector(
                  onTap: () => _confirmDelete(index),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.deleteRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 13, color: AppColors.deleteRed),
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded Details (hidden by default) ──
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoChip(
                            Icons.tag,
                            'Serial No',
                            item.serialNo.isNotEmpty ? item.serialNo : '—'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _infoChip(
                            Icons.person_outline,
                            'Service Person',
                            item.servicePerson.isNotEmpty
                                ? item.servicePerson
                                : '—'),
                      ),
                    ],
                  ),
                  if (item.workDone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Work Done',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.labelColor,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(item.workDone,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textColor)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.labelColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.labelColor)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to remove this item?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.labelColor)),
          ),
          ElevatedButton(
            onPressed: () {
              _removePurposeItem(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _statusBadgeColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.accentGreen;
      case 'In Progress':
        return AppColors.primaryColor;
      case 'Cancelled':
        return AppColors.deleteRed;
      default:
        return AppColors.accentOrange;
    }
  }
}