import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/common/common_widgets.dart';
import '../../../utils/sharedpreference.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);


  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  String? _savedPrinter;
  bool _autoSubmitPickList = false;
  String? _defaultWarehouse; // ✅ Add this
  final TextEditingController _warehouseController = TextEditingController();
  bool _filterBySalesPerson = true;
  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _loadSubmitToggle();
    _loadDefaultWarehouse();
    _loadCustomerFilterToggle();// ✅ Add this
  }

  @override
  void dispose() {
    _warehouseController.dispose();
    super.dispose();
  }
  Future<void> _loadCustomerFilterToggle() async {
    final value = await _sharedPrefService.getCustomerFilterBySalesPerson();
    setState(() {
      _filterBySalesPerson = value;
    });
  }
  Future<void> _loadDefaultWarehouse() async {
    final warehouse = await _sharedPrefService.getDefaultWarehouse();
    setState(() {
      _defaultWarehouse = warehouse;
      if (warehouse != null) {
        _warehouseController.text = warehouse;
      }
    });
  }
  Future<void> _updateCustomerFilterToggle(bool value) async {
    await _sharedPrefService.saveCustomerFilterBySalesPerson(value);
    setState(() {
      _filterBySalesPerson = value;
    });
  }
  Future<void> _loadSubmitToggle() async {
    final value = await _sharedPrefService.getAutoSubmitPickList();
    setState(() {
      _autoSubmitPickList = value;
    });
  }

  Future<void> _updateSubmitToggle(bool value) async {
    await _sharedPrefService.saveAutoSubmitPickList(value);
    setState(() {
      _autoSubmitPickList = value;
    });
  }

  Future<void> _loadSavedPrinter() async {
    final name = await _sharedPrefService.getPrinterName();
    final address = await _sharedPrefService.getPrinterAddress();
    setState(() {
      _savedPrinter = name?.isNotEmpty == true ? name : address;
    });
  }

  Future<void> _pickPrinter() async {
    final device = await FlutterBluetoothPrinter.selectDevice(context);
    if (device != null) {
      await _sharedPrefService.savePrinter(device.name ?? "", device.address);

      setState(() {
        _savedPrinter = device.name ?? device.address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Printer set to ${device.name ?? device.address}")),
      );
    }
  }

  Future<void> _clearPrinter() async {
    await _sharedPrefService.clearPrinter();

    setState(() {
      _savedPrinter = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🖨️ Printer cleared")),
    );
  }

  // ✅ Add this method
  Future<void> _clearDefaultWarehouse() async {
    await _sharedPrefService.clearDefaultWarehouse();

    // Also clear in provider
    if (mounted) {
      context.read<SalesOrderProvider>().setDefaultWarehouse(null);
    }

    setState(() {
      _defaultWarehouse = null;
      _warehouseController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🏢 Default warehouse cleared")),
    );
  }

  // ✅ Add this method
  void _showWarehouseDialog() {
    showDialog(
      context: context,
      builder: (context) => _WarehouseSelectionDialog(
        currentWarehouse: _defaultWarehouse,
        onWarehouseSelected: (warehouse) async {
          await _sharedPrefService.saveDefaultWarehouse(warehouse);

          // Update provider
          if (mounted) {
            context.read<SalesOrderProvider>().setDefaultWarehouse(warehouse);
          }

          setState(() {
            _defaultWarehouse = warehouse;
            _warehouseController.text = warehouse;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Default warehouse set to $warehouse")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Settings',
        onBackTap: () {
          Navigator.pop(context);
        },
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text("Printer"),
            subtitle: Text(_savedPrinter ?? "No printer selected"),
            onTap: _pickPrinter,
            trailing: _savedPrinter != null
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _clearPrinter,
            )
                : null,
          ),

          // ✅ Add Default Warehouse Setting
          ListTile(
            leading: const Icon(Icons.warehouse),
            title: const Text("Default Warehouse"),
            subtitle: Text(_defaultWarehouse ?? "No default warehouse set"),
            onTap: _showWarehouseDialog,
            trailing: _defaultWarehouse != null
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _clearDefaultWarehouse,
            )
                : null,
          ),

          SwitchListTile(
            title: const Text("Auto Submit Pick List"),
            subtitle: const Text("If ON: Pick List will be submitted automatically"),
            value: _autoSubmitPickList,
            onChanged: (value) async {
              await _updateSubmitToggle(value);
            },
          ),
          SwitchListTile(
            title: const Text("Filter Customers by Sales Person"),
            subtitle: const Text(
                "If ON: Only customers assigned to your Sales Person will be shown"),
            value: _filterBySalesPerson,
            onChanged: (value) async {
              await _updateCustomerFilterToggle(value);
            },
          ),
        ],
      ),
    );
  }
}

// ✅ Add Warehouse Selection Dialog
class _WarehouseSelectionDialog extends StatefulWidget {
  final String? currentWarehouse;
  final Function(String) onWarehouseSelected;

  const _WarehouseSelectionDialog({
    this.currentWarehouse,
    required this.onWarehouseSelected,
  });

  @override
  State<_WarehouseSelectionDialog> createState() => _WarehouseSelectionDialogState();
}

class _WarehouseSelectionDialogState extends State<_WarehouseSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warehouse_rounded,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Warehouse",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Search and choose your default warehouse",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              /// SEARCH + AUTOCOMPLETE
              Consumer<SalesOrderProvider>(
                builder: (context, provider, _) {
                  return Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.searchWarehouses(value.text);
                      });

                      return provider.warehouseResultss;
                    },
                    onSelected: (String selection) {
                      widget.onWarehouseSelected(selection);
                      Navigator.pop(context);
                    },
                    fieldViewBuilder: (
                        context,
                        textController,
                        focusNode,
                        onFieldSubmitted,
                        ) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        focusNode.requestFocus();
                      });

                      return Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        child: TextFormField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Type warehouse name…",
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: provider.isSearchingWarehouse
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (
                        context,
                        onSelected,
                        options,
                        ) {
                      if (options.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                final isSelected =
                                    option == widget.currentWarehouse;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warehouse_outlined,
                                          size: 20,
                                          color: isSelected
                                              ? AppColors.primaryColor
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            size: 20,
                                            color: AppColors.primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              /// FOOTER HINT
              const Text(
                "Tip: Start typing to quickly find your warehouse",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
