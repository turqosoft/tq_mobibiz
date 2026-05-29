import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/view/PickItems/qr_scanner_page.dart';

import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';

class PickScannerPage extends StatefulWidget {
  final String pickName;

  const PickScannerPage ({
    Key? key,
    required this.pickName,
  }) : super(key: key);

  @override
  State<PickScannerPage > createState() => _PickScannerPageState();
}

class _PickScannerPageState extends State<PickScannerPage > {
  final TextEditingController _warehouseController =
  TextEditingController();
  final Map<int, bool> _itemStatus = {};
  /// Serial number controllers per item (index-based)
  final Map<int, List<TextEditingController>> _serialControllers = {};
  final FocusNode _warehouseFocus = FocusNode();
  bool _warehouseInitialized = false;
  final Map<int, List<String>> _availableSerials = {};
  final TextEditingController _boxController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  /// itemIndex -> { boxName -> qty }
  final Map<int, Map<String, int>> _boxAllocations = {};
  final FocusNode _boxFocus = FocusNode();
  final FocusNode _itemCodeFocus = FocusNode();
  /// Stores all successfully scanned barcodes
  final Set<String> _scannedBarcodes = {};
  final Map<int, TextEditingController> _pickedQtyControllers = {};
  final Map<int, FocusNode> _pickedQtyFocusNodes = {};
  final Map<int, bool> _expandedBoxSection = {};
  Map<int, double> _originalPickedQty = {};
  Map<int, Map<String, int>> _originalBoxAllocations = {};
  bool _hasUnsavedChanges = true;
  @override
  void initState() {
    super.initState();

    // ✅ Reset the flag and clear the controller for fresh start
    _warehouseInitialized = false;
    _warehouseController.clear();

    _warehouseFocus.addListener(() {
      if (!_warehouseFocus.hasFocus) {
        context.read<SalesOrderProvider>().clearWarehouseResultss();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SalesOrderProvider>();
      await provider.fetchPickDetail(widget.pickName);

      if (!mounted) return;

      final pickDetail = provider.pickDetail;
      if (pickDetail != null) {
        _initializeSerialControllers(pickDetail); // ✅ IMPORTANT
      }
    });

  }
  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
  @override
  void dispose() {
    _warehouseController.dispose();
    _warehouseFocus.dispose(); // ✅ Don't forget to dispose this too
    _boxController.dispose();
    _itemCodeController.dispose();
    _boxFocus.dispose();
    _itemCodeFocus.dispose();
    super.dispose();
    for (final controllers in _serialControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }

    super.dispose();
  }
  Map<String, dynamic>? _parseGS1Barcode(String barcode) {
    try {
      if (!barcode.startsWith("02")) return null;

      /// 14-digit GTIN
      final String gtin14 = barcode.substring(2, 16);

      /// Convert to original barcode (remove leading zero if exists)
      String originalBarcode = gtin14;
      if (gtin14.startsWith("0")) {
        originalBarcode = gtin14.substring(1);
      }

      /// AI 37 → quantity
      if (!barcode.substring(16).startsWith("37")) return null;

      final String qtyStr = barcode.substring(18);
      final int quantity = int.tryParse(qtyStr) ?? 1;

      return {
        "barcode": originalBarcode,  // ✅ 13-digit
        "quantity": quantity,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _validateAndPickItem(String scannedBarcode) async {
    final provider = context.read<SalesOrderProvider>();
    final pickDetail = provider.pickDetail;

    if (pickDetail == null) return;

    final items = pickDetail["items"] as List<dynamic>? ?? [];
    final currentBox = _boxController.text.trim();

    /// 🔹 Parse GS1
    final parsed = _parseGS1Barcode(scannedBarcode);

    String actualBarcode = scannedBarcode;
    int scanQty = 1;

    if (parsed != null) {
      actualBarcode = parsed["barcode"];   // ✅ now 13-digit
      scanQty = parsed["quantity"];
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemCode = item["item_code"];

      final barcodes =
      await provider.apiService!.fetchItemBarcodes(itemCode);

      if (barcodes.contains(actualBarcode)) {

        final double qty =
            double.tryParse(item["qty"]?.toString() ?? "0") ?? 0;

        final double pickedQty =
            double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

        if (pickedQty + scanQty > qty) {
          _showSnack(
              "Scan exceeds allowed quantity. Max allowed: ${qty - pickedQty}");
          return;
        }

        setState(() {
          /// Increase picked_qty by scanned quantity
          item["picked_qty"] = pickedQty + scanQty;

          /// Register raw barcode (not GTIN)
          _scannedBarcodes.add(scannedBarcode);

          /// Update box allocation
          if (currentBox.isNotEmpty) {
            _boxAllocations.putIfAbsent(i, () => {});
            _boxAllocations[i]!.update(
              currentBox,
                  (existing) => existing + scanQty,
              ifAbsent: () => scanQty,
            );
          }
          _hasUnsavedChanges = true; // ← add this

        });

        _itemCodeController.clear();
        _itemCodeFocus.requestFocus();
        return;
      }
    }

    _showSnack("Scanned barcode does not belong to this Pick.");
  }
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Map<String, int> _parseBoxAllocation(String? tqPlBox) {
    final Map<String, int> result = {};

    if (tqPlBox == null || tqPlBox.trim().isEmpty) {
      return result;
    }

    /// Supports multiple values separated by newline or comma
    final parts = tqPlBox.split(RegExp(r'[\n,]'));

    for (final part in parts) {
      final segments = part.split(":");

      if (segments.length < 2) continue;

      /// Box name may contain ":" so join all except last
      final boxName = segments.sublist(0, segments.length - 1).join(":");
      final qty = int.tryParse(segments.last) ?? 0;

      if (boxName.isNotEmpty && qty > 0) {
        result[boxName] = qty;
      }
    }

    return result;
  }
  Future<bool> _showValidationSummaryDialog(
      List<PickValidationSummary> summary,
      ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Pick Details"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: summary.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {

                final item = summary[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    Text("Actual Qty: ${item.actualQty}"),
                    Text("Picked Qty: ${item.pickedQty}"),

                    const SizedBox(height: 6),

                    const Text(
                      "Boxes:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    if (item.boxes.isEmpty)
                      const Text("Unassigned")
                    else
                      ...item.boxes.entries.map((e) => Text(
                        "${e.key} : ${e.value}",
                      )),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    ) ??
        false;
  }


  Future<void> _onSavePressed() async {
    final provider = context.read<SalesOrderProvider>();

    final warehouse = _warehouseController.text.trim();
    if (warehouse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Warehouse is required")),
      );
      return;
    }

    final data = provider.pickDetail;
    if (data == null) return;
    final Map<int, int> statuses = {};

    _itemStatus.forEach((index, value) {
      statuses[index] = value ? 1 : 0;
    });

    final items = data["items"] as List<dynamic>? ?? [];

    /// 🔴 VALIDATION: serial count == qty ONLY when has_serial_no == 1
    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final bool hasSerial =
      (item["has_serial_no"] == 1 || item["has_serial_no"] == true);

      if (!hasSerial) continue; // ✅ skip non-serial items

      final int qty = item["qty"] ?? 0;
      final controllers = _serialControllers[i] ?? [];

      final int serialCount = controllers
          .where((c) => c.text.trim().isNotEmpty)
          .length;

      /// 🔴 RELAXED VALIDATION
      /// Allow partial serial entry (Draft Pick)
      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        final bool hasSerial =
        (item["has_serial_no"] == 1 || item["has_serial_no"] == true);

        if (!hasSerial) continue; // ✅ skip non-serial items

        final int qty = item["qty"] ?? 0;
        final controllers = _serialControllers[i] ?? [];

        final int serialCount = controllers
            .where((c) => c.text.trim().isNotEmpty)
            .length;

        // ❌ Block only if user enters MORE serials than qty
        if (serialCount > qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${item["item_name"]}: Qty is $qty but $serialCount serial(s) entered",
              ),
            ),
          );
          return;
        }
      }

    }
    /// 🔴 VALIDATION: Serial must exist in fetched list
    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final bool hasSerial =
      (item["has_serial_no"] == 1 || item["has_serial_no"] == true);

      if (!hasSerial) continue;

      final enteredSerials = _serialControllers[i]
          ?.map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList() ??
          [];

      final availableSerials = _availableSerials[i] ?? [];

      for (final serial in enteredSerials) {
        if (!availableSerials.contains(serial)) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Invalid Serial Number"),
              content: Text(
                'Serial "$serial" is not available for item ${item["item_name"]}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );

          return; // ❌ BLOCK SAVE
        }
      }
    }

    /// 🔴 VALIDATION: same serial number used multiple times (GLOBAL)
    final Map<String, List<String>> serialUsage = {};
// serial -> list of item names

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final bool hasSerial =
      (item["has_serial_no"] == 1 || item["has_serial_no"] == true);

      if (!hasSerial) continue;

      final itemName = item["item_name"] ?? item["item"];

      final controllers = _serialControllers[i] ?? [];

      for (final controller in controllers) {
        final serial = controller.text.trim();
        if (serial.isEmpty) continue;

        serialUsage.putIfAbsent(serial, () => []);
        serialUsage[serial]!.add(itemName);
      }
    }

    /// 🔴 Find duplicates
    final duplicates = serialUsage.entries
        .where((e) => e.value.length > 1)
        .toList();

    if (duplicates.isNotEmpty) {
      final message = duplicates
      // .map((e) => 'Serial "${e.key}" used in: ${e.value.join(", ")}')
          .map((e) => 'Serial "${e.key}" used multiple times')
          .join('\n');

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Duplicate Serial Numbers"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      return; // ❌ BLOCK SAVE
    }

    /// 🔹 Build validation summary
    final List<PickValidationSummary> summary = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final double currentPicked =
          double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

      final double originalPicked = _originalPickedQty[i] ?? 0;

      final currentBoxes = _boxAllocations[i] ?? {};
      final originalBoxes = _originalBoxAllocations[i] ?? {};

      final pickedChanged = currentPicked != originalPicked;

      final boxChanged =
          currentBoxes.toString() != originalBoxes.toString();

      if (!pickedChanged && !boxChanged) {
        continue; // skip unchanged items
      }

      summary.add(
        PickValidationSummary(
          itemName: item["item_name"] ?? item["item"],
          actualQty: item["qty"] ?? 0,
          pickedQty: currentPicked.toInt(),
          boxes: currentBoxes,
        ),
      );

    }

    /// 🔹 Collect serials for update
    final Map<int, List<String>> serials = {};

    _serialControllers.forEach((itemIndex, controllers) {
      final values = controllers
          .map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      if (values.isNotEmpty) {
        serials[itemIndex] = values;
      }
    });
    final confirmed = await _showValidationSummaryDialog(summary);

    if (!confirmed) return; // ❌ user cancelled

    final success = await provider.updatePick(
      pickName: widget.pickName,
      warehouse: warehouse,
      serials: serials,
      statuses: statuses,
      boxAllocations: _boxAllocations, // ✅ PASS THIS
    );


    if (!mounted) return;

    if (success) {
      setState(() => _hasUnsavedChanges = false); // ← mark clean after save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pick updated successfully")),
      );

      await provider.fetchPickDetail(widget.pickName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update Pick")),
      );
    }
  }

  void _initializeSerialControllers(Map<String, dynamic> pickDetail) {
    final items = pickDetail["items"] as List<dynamic>? ?? [];

    _itemStatus.clear();
    _serialControllers.clear();
    _boxAllocations.clear();   // ✅ important

    for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
      final item = items[itemIndex];

      _itemStatus[itemIndex] =
      (item["status"] == 1 || item["status"] == true);

      /// 🔹 PARSE tq_pl_box
      final tqPlBox = item["tq_pl_box"];

      if (tqPlBox != null && tqPlBox.toString().trim().isNotEmpty) {
        final parsed = _parseBoxAllocation(tqPlBox.toString());

        if (parsed.isNotEmpty) {
          _boxAllocations[itemIndex] = parsed;
        }
      }
      /// Save original picked_qty
      final pickedQty =
          double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

      _originalPickedQty[itemIndex] = pickedQty;

      /// Save original box allocations
      if (_boxAllocations[itemIndex] != null) {
        _originalBoxAllocations[itemIndex] =
        Map<String, int>.from(_boxAllocations[itemIndex]!);
      } else {
        _originalBoxAllocations[itemIndex] = {};
      }
      final bool hasSerial =
      (item["has_serial_no"] == 1 || item["has_serial_no"] == true);

      if (!hasSerial) continue;

      final rawSerial = item["serial_no"];

      if (rawSerial == null || rawSerial.toString().trim().isEmpty) {
        _serialControllers[itemIndex] = [TextEditingController()];
        continue;
      }

      final List<String> serials = rawSerial
          .toString()
          .split(RegExp(r'[\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _serialControllers[itemIndex] =
          serials.map((s) => TextEditingController(text: s)).toList();
    }

    setState(() {});
  }

  void _manuallyUpdatePickedQty(
      int index,
      String value, {
        bool fromTyping = false,
      }) {
    final provider = context.read<SalesOrderProvider>();
    final pickDetail = provider.pickDetail;
    if (pickDetail == null) return;

    final items = pickDetail["items"] as List<dynamic>? ?? [];
    final item = items[index];

    final double qty =
        double.tryParse(item["qty"]?.toString() ?? "0") ?? 0;

    double enteredQty = double.tryParse(value) ?? 0;

    if (enteredQty < 0) {
      enteredQty = 0;
    }

    if (enteredQty > qty) {
      if (!fromTyping) {
        _showSnack("Picked quantity cannot exceed $qty");
      }
      enteredQty = qty;
    }

    setState(() {
      item["picked_qty"] = enteredQty;

      /// ✅ If picked_qty becomes 0 → remove all box allocations
      if (enteredQty == 0) {
        _boxAllocations.remove(index);
      }
    });

    /// Only overwrite text if correction happened
    final correctedText = enteredQty.toStringAsFixed(0);
    if (_pickedQtyControllers[index]!.text != correctedText) {
      _pickedQtyControllers[index]!.text = correctedText;
    }
  }
  void _removeFromBox(int index, String boxName, int qtyToRemove) {
    final provider = context.read<SalesOrderProvider>();
    final pickDetail = provider.pickDetail;
    if (pickDetail == null) return;

    final items = pickDetail["items"] as List<dynamic>? ?? [];
    final item = items[index];

    setState(() {
      final boxMap = _boxAllocations[index];
      if (boxMap == null) return;

      final current = boxMap[boxName] ?? 0;
      final newQty = current - qtyToRemove;

      if (newQty <= 0) {
        boxMap.remove(boxName);
      } else {
        boxMap[boxName] = newQty;
      }

      if (boxMap.isEmpty) {
        _boxAllocations.remove(index);
      }

      final double pickedQty =
          double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

      final updatedPicked = pickedQty - qtyToRemove;

      item["picked_qty"] = updatedPicked < 0 ? 0 : updatedPicked;

      _pickedQtyControllers[index]!.text =
          item["picked_qty"].toStringAsFixed(0);
    });
  }

  void _removeFromUnassigned(int index, int qtyToRemove) {
    final provider = context.read<SalesOrderProvider>();
    final pickDetail = provider.pickDetail;
    if (pickDetail == null) return;

    final items = pickDetail["items"] as List<dynamic>? ?? [];
    final item = items[index];

    setState(() {
      final double pickedQty =
          double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

      final updatedPicked = pickedQty - qtyToRemove;

      item["picked_qty"] = updatedPicked < 0 ? 0 : updatedPicked;

      _pickedQtyControllers[index]!.text =
          item["picked_qty"].toStringAsFixed(0);
    });
  }
  void _addSerialField(int itemIndex, int qty, dynamic item) {
    final controllers = _serialControllers[itemIndex] ?? [];

    if (controllers.length >= qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only $qty serial number(s) allowed for this item"),
        ),
      );
      return;
    }

    setState(() {
      _serialControllers.putIfAbsent(itemIndex, () => []);
      _serialControllers[itemIndex]!.add(TextEditingController());
    });

    _validateSerialCompletion(itemIndex, item);
  }
  // void _validateSerialCompletion(int index, dynamic item) {
  //   final qty = (item["qty"] ?? 0).toInt();
  //   final controllers = _serialControllers[index];
  //
  //   if (controllers == null) return;
  //
  //   // Count only non-empty serial fields
  //   final filledCount = controllers
  //       .where((c) => c.text.trim().isNotEmpty)
  //       .length;
  //
  //   setState(() {
  //     _itemStatus[index] = (filledCount == qty && qty > 0);
  //   });
  // }
  void _validateSerialCompletion(int index, dynamic item) {
    final qty = (item["qty"] ?? 0).toInt();
    final controllers = _serialControllers[index];

    if (controllers == null) return;

    /// Count filled serial numbers
    final filledCount =
        controllers.where((c) => c.text.trim().isNotEmpty).length;

    setState(() {
      /// Update picked_qty based on serial count
      item["picked_qty"] = filledCount;

      /// Update picked qty text field
      _pickedQtyControllers[index]?.text = filledCount.toString();

      /// Mark item complete if serials match qty
      _itemStatus[index] = (filledCount == qty && qty > 0);
    });
  }

  Future<void> _showSerialNumberDialog({
    required int itemIndex,
    required int serialIndex,
    required dynamic item,
    required String itemCode,
    required String itemName,
    required String warehouse,
  }) async {
    final provider = context.read<SalesOrderProvider>();

    /// 🔹 Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading serial numbers...'),
              ],
            ),
          ),
        ),
      ),
    );

    /// Resolve item identifier
    final String resolvedItem =
    itemCode.trim().isNotEmpty ? itemCode : itemName.trim();

    if (resolvedItem.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid item. Cannot fetch serial numbers')),
        );
      }
      return;
    }

    /// 🔹 Fetch serial numbers
    final serialNumbers = await provider.fetchSerialNumbers(
      itemCode: resolvedItem,
      warehouse: warehouse,
    );

    _availableSerials[itemIndex] = serialNumbers;

    /// Close loading dialog
    if (mounted) Navigator.pop(context);

    if (serialNumbers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No serial numbers available for this item')),
        );
      }
      return;
    }

    /// 🔹 Show selection dialog
    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _SerialNumberSelectionDialog(
        serialNumbers: serialNumbers,
        itemCode: itemCode,
      ),
    );

    if (selected == null || selected.isEmpty) return;

    final controller = _serialControllers[itemIndex]![serialIndex];

    /// 🔴 Prevent duplicate serials
    final isDuplicate = _serialControllers[itemIndex]!
        .any((c) => c.text.trim() == selected);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Serial $selected already entered")),
      );
      return;
    }

    /// ✅ Set serial
    controller.text = selected;

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: selected.length,
    );

    /// 🔹 IMPORTANT: Update picked_qty
    _validateSerialCompletion(itemIndex, item);
  }
  void _removeSerialField(int itemIndex, int serialIndex, dynamic item) {
    setState(() {
      final controllers = _serialControllers[itemIndex];
      if (controllers == null) return;

      if (controllers.length > 1) {
        controllers[serialIndex].dispose();
        controllers.removeAt(serialIndex);
      }
    });

    _validateSerialCompletion(itemIndex, item);
  }

  Widget _buildSerialField(int itemIndex, int serialIndex, dynamic item) {
    final controller = _serialControllers[itemIndex]![serialIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        onTap: () {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
        onChanged: (_) {
          _validateSerialCompletion(itemIndex, item);
        },

        onFieldSubmitted: (value) {
          final serial = value.trim();
          if (serial.isEmpty) return;

          final availableSerials = _availableSerials[itemIndex] ?? [];

          /// 🔴 Ensure serial list was fetched
          if (availableSerials.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
                content: const Text(
                  "Please fetch serial numbers first",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
            controller.clear();
            return;
          }

          /// 🔴 Validate serial belongs to fetched list
          if (!availableSerials.contains(serial)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 8),
                behavior: SnackBarBehavior.floating,
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "$serial is not available for this item",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            controller.clear();
            return;
          }

          /// 🔴 Duplicate inside same item
          final isDuplicate = _serialControllers[itemIndex]!
              .where((c) => c != controller)
              .any((c) => c.text.trim() == serial);

          if (isDuplicate) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  "Serial $serial already entered",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
            controller.clear();
            return;
          }

          /// ✅ Accept
          controller.text = serial;
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: serial.length,
          );

          _validateSerialCompletion(itemIndex, item);
        },

        decoration: InputDecoration(
          hintText: "Serial ${serialIndex + 1}",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ✅ NEW: SELECT FROM LIST ICON
              IconButton(
                icon: const Icon(Icons.list_alt, size: 18, color: Colors.blue),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: 'Select from list',
                onPressed: () {
                  final warehouse = _warehouseController.text.trim();
                  if (warehouse.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a warehouse first')),
                    );
                    return;
                  }

                  _showSerialNumberDialog(
                    itemIndex: itemIndex,
                    serialIndex: serialIndex,
                    item: item,
                    itemCode: item["item_code"] ?? "",
                    itemName: item["item_name"] ?? item["item"] ?? "",
                    warehouse: warehouse,
                  );

                },
              ),

              /// QR SCAN
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: 'Scan QR',
                onPressed: () async {
                  final scannedValue = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QrScannerPage(),
                    ),
                  );

                  if (!mounted) return;

                  if (scannedValue != null && scannedValue.isNotEmpty) {
                    final provider = context.read<SalesOrderProvider>();
                    final serial = scannedValue.trim();

                    if (!provider.isSerialValid(serial)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 8),
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "$serial - invalid serial no",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )

                      );
                      controller.clear();
                      return;
                    }


                    // ❌ Duplicate serial in same item
                    final isDuplicate = _serialControllers[itemIndex]!
                        .any((c) => c.text.trim() == serial);

                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Serial $serial already entered"),
                        ),
                      );
                      controller.clear();
                      return;
                    }

                    // ✅ Accept serial
                    controller.text = serial;
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: serial.length,
                    );
                    _validateSerialCompletion(itemIndex, item);

                  }

                },
              ),

              /// REMOVE SERIAL
              if (_serialControllers[itemIndex]!.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: 'Remove',
                  onPressed: () => _removeSerialField(itemIndex, serialIndex, item),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _onSubmitPressed() async {
    final provider = context.read<SalesOrderProvider>();

    /// 🔹 Confirm before submitting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submit Pick"),
        content: const Text(
          "Submitting will finalize this pick and cannot be undone. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.submitPick(pickName: widget.pickName);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pick submitted successfully")),
      );
      Navigator.pop(context); // ✅ Go back after submit
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit Pick")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.read<SalesOrderProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CommonAppBar(
        title: "Pick Items",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () => Navigator.pop(context),
        actions: (provider.isSavingPick || provider.isSubmittingPick)
            ? const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: Colors.white),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 💾 SAVE
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: "Save",
              onPressed: _onSavePressed,
            ),
            /// ✅ SUBMIT
            // IconButton(
            //   icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            //   tooltip: "Submit",
            //   onPressed: _onSubmitPressed,
            // ),
          ],
        ),
      ),
      // appBar: CommonAppBar(
      //   title: "Pick Items",
      //   automaticallyImplyLeading: true,
      //   backgroundColor: AppColors.primaryColor,
      //   onBackTap: () => Navigator.pop(context),
      //   actions: (provider.isSavingPick || provider.isSubmittingPick)
      //       ? const Padding(
      //     padding: EdgeInsets.all(12),
      //     child: CircularProgressIndicator(color: Colors.white),
      //   )
      //       : _hasUnsavedChanges
      //
      //   /// 💾 SAVE BUTTON — shown when there are unsaved changes
      //       ? IconButton(
      //     icon: const Icon(Icons.save, color: Colors.white),
      //     tooltip: "Save",
      //     onPressed: _onSavePressed,
      //   )
      //
      //   /// ✅ SUBMIT BUTTON — shown only after saving
      //       : IconButton(
      //     icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      //     tooltip: "Submit Pick",
      //     onPressed: _onSubmitPressed,
      //   ),
      // ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingPickDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = provider.pickDetail;
          if (data == null) {
            return const Center(child: Text("Failed to load Pick details"));
          }

          final items = data["items"] as List<dynamic>? ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("No Pick Items found"));
          }

          final currentPickName = data["name"];
          final salesInvoice = data["sales_invoice"];
          final deliveryNote = data["delivery_note"];
          final customer = data["customer"];

          if (!_warehouseInitialized && currentPickName == widget.pickName) {
            final warehouse = data["warehouse"] ?? "";
            if (_warehouseController.text != warehouse) {
              _warehouseController.text = warehouse;
            }
            _warehouseInitialized = true;
          }

          return SafeArea(
            child: Column(
              children: [

                /// ─── FIXED TOP SECTION ───────────────────────────────────

                /// 🔹 PICK NAME HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.blue[100]!, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text("Pick: ",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                          Expanded(
                            child: Text(
                              currentPickName ?? widget.pickName,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (deliveryNote != null && deliveryNote.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 18, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                "Delivery Note: ",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  deliveryNote,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[900],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (salesInvoice != null && salesInvoice.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long, size: 18, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text("Invoice: ",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                              Expanded(
                                child: Text(
                                  salesInvoice,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green[900]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (customer != null && customer.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 18, color: Colors.deepPurple[700]),
                              const SizedBox(width: 8),
                              Text("Customer: ",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                              Expanded(
                                child: Text(
                                  customer,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepPurple[900]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                /// 🔹 COMPACT: WAREHOUSE + CONTAINER + SCAN ITEM
                Material(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// ROW 1: Warehouse + Container side by side
                        Row(
                          children: [

                            /// WAREHOUSE
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.warehouse, size: 14, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text("Warehouse",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _warehouseController,
                                    focusNode: _warehouseFocus,
                                    onChanged: (value) {
                                      final provider = context.read<SalesOrderProvider>();
                                      if (value.trim().isEmpty) {
                                        provider.clearWarehouseResultss();
                                      } else {
                                        provider.searchWarehouses(value.trim());
                                      }
                                    },
                                    onTap: () {
                                      _markDirty();
                                      _warehouseController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _warehouseController.text.length,
                                      );
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Search warehouse",
                                      isDense: true,
                                      filled: true,
                                      fillColor: Color(0xFFF3F4F6),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  Consumer<SalesOrderProvider>(
                                    builder: (context, provider, _) {
                                      if (!_warehouseFocus.hasFocus || provider.warehouseResultss.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        constraints: const BoxConstraints(maxHeight: 180),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: ListView.builder(
                                          itemCount: provider.warehouseResultss.length,
                                          itemBuilder: (context, index) {
                                            final warehouse = provider.warehouseResultss[index];
                                            return ListTile(
                                              dense: true,
                                              title: Text(warehouse, style: const TextStyle(fontSize: 13)),
                                              onTap: () {
                                                _warehouseController.text = warehouse;
                                                context.read<SalesOrderProvider>().clearWarehouseResultss();
                                                _warehouseFocus.unfocus();
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            /// CONTAINER
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text("Container",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _boxController,
                                    focusNode: _boxFocus,
                                    textInputAction: TextInputAction.next,
                                    onTap: () {
                                      _markDirty();
                                      _boxController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _boxController.text.length,
                                      );
                                    },
                                    onFieldSubmitted: (_) => _itemCodeFocus.requestFocus(),
                                    decoration: InputDecoration(
                                      hintText: "Scan container",
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF3F4F6),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () async {
                                          final scannedValue = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(builder: (_) => const QrScannerPage()),
                                          );
                                          if (!mounted) return;
                                          if (scannedValue != null && scannedValue.isNotEmpty) {
                                            _boxController.text = scannedValue.trim();
                                            _itemCodeFocus.requestFocus();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// ROW 2: SCAN ITEM (full width)
                        Row(
                          children: const [
                            Icon(Icons.qr_code, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text("Scan Item",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _itemCodeController,
                          focusNode: _itemCodeFocus,
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            _itemCodeController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _itemCodeController.text.length,
                            );
                          },
                          onFieldSubmitted: (value) {
                            if (value.trim().isNotEmpty) _validateAndPickItem(value.trim());
                          },
                          decoration: InputDecoration(
                            hintText: "Scan or enter item barcode",
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  tooltip: "Validate",
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    final value = _itemCodeController.text.trim();
                                    if (value.isNotEmpty) _validateAndPickItem(value);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () async {
                                    final scannedValue = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(builder: (_) => const QrScannerPage()),
                                    );
                                    if (!mounted) return;
                                    if (scannedValue != null && scannedValue.isNotEmpty) {
                                      _itemCodeController.text = scannedValue.trim();
                                      _validateAndPickItem(scannedValue.trim());
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// ─── SCROLLABLE ITEMS LIST ────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final bool hasSerial =
                      (item["has_serial_no"] == 1 || item["has_serial_no"] == true);
                      final double qty =
                          double.tryParse(item["qty"]?.toString() ?? "0") ?? 0;
                      _pickedQtyFocusNodes.putIfAbsent(index, () => FocusNode());
                      final double pickedQty =
                          double.tryParse(item["picked_qty"]?.toString() ?? "0") ?? 0;

                      _pickedQtyControllers.putIfAbsent(
                        index,
                            () => TextEditingController(text: pickedQty.toStringAsFixed(0)),
                      );

                      final allocations = _boxAllocations[index];
                      int totalBoxQty = 0;
                      if (allocations != null) {
                        totalBoxQty = allocations.values.fold(0, (sum, v) => sum + v);
                      }

                      final int unassignedQty = pickedQty.toInt() - totalBoxQty;
                      final controller = _pickedQtyControllers[index]!;
                      final focusNode = _pickedQtyFocusNodes[index]!;

                      if (!focusNode.hasFocus &&
                          controller.text != pickedQty.toStringAsFixed(0)) {
                        controller.text = pickedQty.toStringAsFixed(0);
                      }

                      if (hasSerial) {
                        _serialControllers.putIfAbsent(index, () => [TextEditingController()]);
                      } else {
                        _serialControllers.remove(index);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// ITEM HEADER
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["item_name"] ?? "-",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FE),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      "Qty ${item["qty"] ?? 0}",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 55,
                                    height: 32,
                                    child: TextFormField(
                                      controller: _pickedQtyControllers[index],
                                      focusNode: _pickedQtyFocusNodes[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onTap: () {
                                        final controller = _pickedQtyControllers[index]!;
                                        controller.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: controller.text.length,
                                        );
                                      },
                                      onChanged: (value) {
                                        _manuallyUpdatePickedQty(index, value, fromTyping: true);
                                      },
                                      onEditingComplete: () {
                                        _markDirty();
                                        _manuallyUpdatePickedQty(index, _pickedQtyControllers[index]!.text);
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              /// SERIAL SECTION (COMPACT)
                              if (hasSerial)
                                Container(
                                  padding: const EdgeInsets
                                      .fromLTRB(8, 6, 8, 6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFF9FAFB),
                                    borderRadius: BorderRadius
                                        .circular(8),
                                    border: Border.all(
                                        color: Colors.black12),
                                  ),
                                  child: Column(
                                    children: [
// In your items ListView.builder, update this line:
                                      for (int i = 0; i <
                                          _serialControllers[index]!
                                              .length; i++)
                                        _buildSerialField(
                                            index, i, item),
                                      // ✅ Add 'item' parameter

                                      Align(
                                        alignment: Alignment
                                            .centerRight,
                                        child: TextButton.icon(
                                          style: TextButton
                                              .styleFrom(
                                            visualDensity: VisualDensity
                                                .compact,
                                            padding: EdgeInsets
                                                .zero,
                                          ),
                                          // onPressed: () => _addSerialField(index, item["qty"] ?? 0),
                                          onPressed: () =>
                                              _addSerialField(
                                                  index,
                                                  item["qty"] ??
                                                      0, item),

                                          icon: const Icon(
                                              Icons.add,
                                              size: 18),
                                          label: const Text(
                                            "Add",
                                            style: TextStyle(
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              /// BOX BREAKDOWN
                              if ((allocations != null &&
                                  allocations.entries.any((e) => e.key.trim().isNotEmpty)) ||
                                  unassignedQty > 0) ...[
                                const Divider(height: 12),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _expandedBoxSection[index] =
                                      !(_expandedBoxSection[index] ?? false);
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Package Information",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey)),
                                      Icon(
                                        (_expandedBoxSection[index] ?? false)
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_expandedBoxSection[index] ?? false) ...[
                                  const SizedBox(height: 6),
                                  if (allocations != null)
                                    ...allocations.entries
                                        .where((e) => e.key.trim().isNotEmpty)
                                        .map((entry) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text("Box: ${entry.key}",
                                                  style: const TextStyle(
                                                      fontSize: 12, fontWeight: FontWeight.w500)),
                                            ),
                                            Text("Qty: ${entry.value}",
                                                style: const TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _removeFromBox(index, entry.key, entry.value),
                                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  if (unassignedQty > 0)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Expanded(
                                            child: Text("Unassigned",
                                                style: TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w500)),
                                          ),
                                          Text("Qty: $unassignedQty",
                                              style: const TextStyle(
                                                  fontSize: 12, fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _removeFromUnassigned(index, unassignedQty),
                                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

// class PickValidationSummary {
//   final String itemName;
//   final int qty;
//   final List<String> serials;
//
//   PickValidationSummary({
//     required this.itemName,
//     required this.qty,
//     required this.serials,
//   });
// }
class PickValidationSummary {
  final String itemName;
  final int actualQty;
  final int pickedQty;
  final Map<String, int> boxes;

  PickValidationSummary({
    required this.itemName,
    required this.actualQty,
    required this.pickedQty,
    required this.boxes,
  });
}
class _SerialNumberSelectionDialog extends StatefulWidget {
  final List<String> serialNumbers;
  final String itemCode;

  const _SerialNumberSelectionDialog({
    required this.serialNumbers,
    required this.itemCode,
  });

  @override
  State<_SerialNumberSelectionDialog> createState() =>
      _SerialNumberSelectionDialogState();
}

class _SerialNumberSelectionDialogState
    extends State<_SerialNumberSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSerials = [];

  @override
  void initState() {
    super.initState();
    _filteredSerials = widget.serialNumbers;
  }

  void _filterSerials(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSerials = widget.serialNumbers;
      } else {
        _filteredSerials = widget.serialNumbers
            .where((serial) =>
            serial.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Serial Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Item Code
            Text(
              widget.itemCode,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filterSerials,
              decoration: InputDecoration(
                hintText: 'Search serial number...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredSerials.length} serial(s) available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 8),

            // Serial List
            Expanded(
              child: _filteredSerials.isEmpty
                  ? Center(
                child: Text(
                  'No serial numbers found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredSerials.length,
                itemBuilder: (context, index) {
                  final serial = _filteredSerials[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        serial,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, serial),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}