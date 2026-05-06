import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/view/PickItems/pick_detail_page.dart';
import 'package:sales_ordering_app/view/PickItems/pick_scanner_page.dart';

import '../../provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/common/common_widgets.dart';

class PickItemsPage extends StatefulWidget {

  const PickItemsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<PickItemsPage> createState() => _PickItemsPageState();
}

class _PickItemsPageState extends State<PickItemsPage> {
  bool isLoading = true;
  final TextEditingController _warehouseController = TextEditingController();
  bool _showWarehouseSearch = false;

  // @override
  // void initState() {
  //   super.initState();
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final provider = context.read<SalesOrderProvider>();
  //
  //     // ✅ Fetch picks with the currently selected warehouse (if any)
  //     provider.fetchPickLists(warehouse: provider.selectedWarehouse);
  //
  //     // ✅ Sync the text controller if a warehouse is already selected
  //     if (provider.selectedWarehouse != null) {
  //       _warehouseController.text = provider.selectedWarehouse!;
  //     }
  //   });
  // }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SalesOrderProvider>();

      // ✅ Load default warehouse first
      await provider.loadDefaultWarehouse();

      // ✅ Fetch picks with the selected warehouse (default or previously selected)
      await provider.fetchPickLists(warehouse: provider.selectedWarehouse);

      // ✅ Sync the text controller if a warehouse is selected
      if (provider.selectedWarehouse != null) {
        _warehouseController.text = provider.selectedWarehouse!;
      }
    });
  }
  @override
  void dispose() {
    _warehouseController.dispose();
    super.dispose();
  }

  final List<Color> _cardColors = [
    const Color.fromARGB(255, 205, 227, 225),
    const Color.fromARGB(255, 205, 213, 221),
  ];

  String _statusText(int docstatus) {
    switch (docstatus) {
      case 0:
        return "Draft";
      case 1:
        return "Submitted";
      case 2:
        return "Cancelled";
      default:
        return "Unknown";
    }
  }

  Color _statusColor(int docstatus) {
    switch (docstatus) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatDateDMY(String date) {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "Pick",
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primaryColor,
        onBackTap: () => Navigator.pop(context),
        isAction: false,
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Compact Warehouse Filter
              _buildCompactFilter(provider),

              // Pick List
              Expanded(
                child: _buildPickList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactFilter(SalesOrderProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter Button or Active Filter Display
          if (provider.selectedWarehouse == null && !_showWarehouseSearch)
            InkWell(
              onTap: () {
                setState(() {
                  _showWarehouseSearch = true;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      "Filter by Warehouse",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            )
          else if (provider.selectedWarehouse != null && !_showWarehouseSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warehouse,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.selectedWarehouse!,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      _warehouseController.clear();
                      provider.clearWarehouseResultss();
                      provider.clearWarehouseFilter();
                      setState(() {
                        _showWarehouseSearch = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showWarehouseSearch = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Expandable Search Field
          if (_showWarehouseSearch) ...[
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.searchWarehouses(textEditingValue.text);
                      });
                      return provider.warehouseResultss;
                    },
                    onSelected: (String selection) {
                      _warehouseController.text = selection;
                      provider.setSelectedWarehouse(selection);
                      setState(() {
                        _showWarehouseSearch = false;
                      });
                    },
                    fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                        ) {
                      if (_warehouseController.text.isNotEmpty &&
                          textEditingController.text.isEmpty) {
                        textEditingController.text = _warehouseController.text;
                      }

                      // Auto-focus when search opens
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        focusNode.requestFocus();
                      });

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Type to search warehouse...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: provider.isSearchingWarehouse
                              ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                              : (textEditingController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              textEditingController.clear();
                              _warehouseController.clear();
                              provider.clearWarehouseResultss();
                            },
                          )
                              : null),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          _warehouseController.text = value;
                        },
                      );
                    },
                    optionsViewBuilder: (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                        ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 200,
                              maxWidth: MediaQuery.of(context).size.width - 64,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warehouse_outlined,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: const TextStyle(fontSize: 14),
                                          ),
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _warehouseController.clear();
                    provider.clearWarehouseResultss();
                    setState(() {
                      _showWarehouseSearch = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: "Cancel",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickList(SalesOrderProvider provider) {
    if (provider.isLoadingPickList) {
      return const Center(child: CircularProgressIndicator());
    }

    final picks = provider.pickLists;

    if (picks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.selectedWarehouse != null
                  ? "No picks found for this warehouse"
                  : "No Pick List available",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            if (provider.selectedWarehouse != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.selectedWarehouse!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _warehouseController.clear();
                  provider.clearWarehouseResultss();
                  provider.clearWarehouseFilter();
                  setState(() {
                    _showWarehouseSearch = false;
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("Clear Filter"),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchPickLists(warehouse: provider.selectedWarehouse);
      },
      child: ListView.builder(
        itemCount: picks.length,
        itemBuilder: (context, index) {
          final pick = picks[index];
          final bgColor = _cardColors[index % _cardColors.length];
          final int docstatus = pick["docstatus"] ?? 0;
          final statusText = _statusText(docstatus);
          final statusColor = _statusColor(docstatus);

          return Card(
            color: bgColor,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ListTile(
                  title: Text(
                    pick["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((pick["customer"] ?? "").toString().isNotEmpty)
                        Text(
                          "Customer: ${pick["customer"]}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      // Text("Delivery Note: ${pick["delivery_note"] ?? "-"}"),
                      // Text("Sales Invoice: ${pick["sales_invoice"] ?? "-"}"),
                      if ((pick["delivery_note"] ?? "").toString().trim().isNotEmpty)
                        Text(
                          "Delivery Note: ${pick["delivery_note"]}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),

                      if ((pick["sales_invoice"] ?? "").toString().trim().isNotEmpty)
                        Text(
                          "Sales Invoice: ${pick["sales_invoice"]}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      Text("Date: ${formatDateDMY(pick["date"])}"),
                      if ((pick["warehouse"] ?? "").toString().isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.warehouse,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pick["warehouse"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // builder: (_) => PickDetailPage(
                      builder: (_) => PickScannerPage(

                      pickName: pick["name"],
                        ),
                      ),
                    );
                  },
                ),

                // STATUS BADGE
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
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