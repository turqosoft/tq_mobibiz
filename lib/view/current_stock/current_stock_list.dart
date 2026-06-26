
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class CurrentStockList extends StatefulWidget {
  const CurrentStockList({super.key});

  @override
  State<CurrentStockList> createState() => _CurrentStockListState();
}
class _CurrentStockListState extends State<CurrentStockList> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedItemCode;
  String? _selectedWarehouse;
  bool _showSuggestions = false;
  bool _showItemSuggestions = false;
  bool _showWarehouseSuggestions = false;
  final GlobalKey _itemKey = GlobalKey();
  final GlobalKey _warehouseKey = GlobalKey();

  OverlayEntry? _itemOverlayEntry;
  OverlayEntry? _warehouseOverlayEntry;


  Future<void> _fetchCurrentStockList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    await provider.currentStockList(context);
  }

  Future<void> _fetchStock() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    if (_selectedItemCode != null && _selectedWarehouse != null) {
      // Both filters applied
      await provider.currentStockFilter(_selectedItemCode!, _selectedWarehouse!, context);
    } else if (_selectedItemCode != null) {
      // Only item filter
      await provider.currentStockListByItem(context, _selectedItemCode!);
    } else if (_selectedWarehouse != null) {
      // Only warehouse filter
      await provider.currentStockListByWarehouse(context, _selectedWarehouse!);
    } else {
      // No filter, fetch all
      await provider.currentStockList(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentStockList();
    });
  }
  String formatDescription(String raw) {
    // remove HTML tags like <div>, <p>, </div>
    final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '');

    // split by comma
    final parts = cleaned.split(',');

    if (parts.length == 1) {
      return cleaned.trim();
    } else {
      // Example: "Tomato, Tomato, VEGETABLE"
      final mainName = parts[0].trim();
      final group = parts.last.trim();
      return "$mainName (${group})";
    }
  }
  void _showItemOverlay(List<Map<String, dynamic>> suggestions) {
    _itemOverlayEntry?.remove(); // remove previous overlay if any
    _itemOverlayEntry = null;
    final renderBox = _itemKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _itemOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final formatted = formatDescription(suggestion['description'] ?? "");
                return ListTile(
                  title: Text(formatted),
                  onTap: () {
                    _itemController.text = formatted;
                    _selectedItemCode = suggestion['value'];
                    _itemOverlayEntry?.remove();
                    _itemOverlayEntry = null;
                    FocusScope.of(context).unfocus();
                    // provider.clearSearchResults();
                    _fetchStock();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_itemOverlayEntry!);
  }
  void _showWarehouseOverlay(List<Map<String, dynamic>> suggestions) {
    _warehouseOverlayEntry?.remove();
    _warehouseOverlayEntry = null;
    final renderBox = _warehouseKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _warehouseOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final displayText = suggestion['description']?.isNotEmpty == true
                    ? suggestion['description']
                    : suggestion['value'];
                return ListTile(
                  title: Text(displayText ?? ""),
                  onTap: () {
                    _warehouseController.text = displayText ?? "";
                    _selectedWarehouse = suggestion['value'];
                    _warehouseOverlayEntry?.remove();
                    _warehouseOverlayEntry = null;
                    FocusScope.of(context).unfocus();
                    // provider.clearWarehouseResults();
                    _fetchStock();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_warehouseOverlayEntry!);
  }
  @override
  void dispose() {
    // Remove overlays
    _itemOverlayEntry?.remove();
    _itemOverlayEntry = null;

    _warehouseOverlayEntry?.remove();
    _warehouseOverlayEntry = null;

    // Dispose controllers
    _itemController.dispose();
    _warehouseController.dispose();
    _searchController.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _itemOverlayEntry?.remove();
            _itemOverlayEntry = null;

            _warehouseOverlayEntry?.remove();
            _warehouseOverlayEntry = null;
          }
        },
        child: Scaffold(
    // return Scaffold(
      appBar: CommonAppBar(
        title: 'Current Stocks',
        // onBackTap: () => Navigator.pop(context),
        onBackTap: () {
          _itemOverlayEntry?.remove();
          _itemOverlayEntry = null;

          _warehouseOverlayEntry?.remove();
          _warehouseOverlayEntry = null;

          Navigator.pop(context);
        },
        actions: IconButton(
          onPressed: () {
            // Remove item overlay
            _itemOverlayEntry?.remove();
            _itemOverlayEntry = null;

            // Remove warehouse overlay
            _warehouseOverlayEntry?.remove();
            _warehouseOverlayEntry = null;
            _itemController.clear();
            _warehouseController.clear();
            _selectedItemCode = null;
            _selectedWarehouse = null;
            _fetchCurrentStockList();
          },
          icon: Icon(Icons.refresh,color: Colors.white,),
        ),
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [

                Stack(
                  children: [
                    Row(
                      children: [
                        // Item filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Item", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Container(
                                key: _itemKey,
                                child: TextField(
                                  controller: _itemController,
                                  decoration: InputDecoration(
                                    hintText: "Search Item...",
                                    prefixIcon: _itemController.text.isEmpty
                                        ? Icon(Icons.search) // show search only when empty
                                        : null,
                                    suffixIcon: _itemController.text.isNotEmpty
                                        ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _itemController.clear();
                                        provider.clearSearchResults();
                                        _itemOverlayEntry?.remove();
                                        _itemOverlayEntry = null;
                                        setState(() {}); // refresh UI
                                      },
                                    )
                                        : null,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // refresh icon visibility
                                    if (value.isNotEmpty) {
                                      provider.searchItem(value, context).then((_) {
                                        if (provider.searchResults.isNotEmpty) {
                                          _showItemOverlay(provider.searchResults);
                                        }
                                      });
                                    } else {
                                      _itemOverlayEntry?.remove();
                                      _itemOverlayEntry = null;
                                      provider.clearSearchResults();
                                    }
                                  },
                                ),
                              ),


                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Warehouse filter
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Warehouse", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),

                              Container(
                                key: _warehouseKey,
                                child: TextField(
                                  controller: _warehouseController,
                                  decoration: InputDecoration(
                                    hintText: "Search Warehouse...",
                                    prefixIcon: _warehouseController.text.isEmpty
                                        ? Icon(Icons.home_work) // show warehouse icon only when empty
                                        : null,
                                    suffixIcon: _warehouseController.text.isNotEmpty
                                        ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _warehouseController.clear();
                                        provider.clearWarehouseResults();
                                        _warehouseOverlayEntry?.remove();
                                        _warehouseOverlayEntry = null;
                                        setState(() {}); // refresh UI
                                      },
                                    )
                                        : null,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // refresh icon visibility
                                    if (value.isNotEmpty) {
                                      provider.searchWarehouse(value, context).then((_) {
                                        if (provider.warehouseResults.isNotEmpty) {
                                          _showWarehouseOverlay(provider.warehouseResults);
                                        }
                                      });
                                    } else {
                                      _warehouseOverlayEntry?.remove();
                                      _warehouseOverlayEntry = null;
                                      provider.clearWarehouseResults();
                                    }
                                  },
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),

                    // 🔹 Item suggestions overlay
                    if (_showItemSuggestions && provider.searchResults.isNotEmpty)
                      Positioned(
                        top: 50, // adjust to match TextField height + padding
                        left: 0,
                        right: MediaQuery.of(context).size.width / 2 + 6, // half width minus spacing
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: provider.searchResults.length,
                              itemBuilder: (context, index) {
                                final suggestion = provider.searchResults[index];
                                final formatted = formatDescription(suggestion['description'] ?? "");
                                return ListTile(
                                  title: Text(formatted),
                                  onTap: () {
                                    setState(() {
                                      _itemController.text = formatted;
                                      _selectedItemCode = suggestion['value'];
                                      _showItemSuggestions = false;
                                    });
                                    FocusScope.of(context).unfocus();
                                    provider.clearSearchResults();
                                    _fetchStock(); // Combined fetch
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // 🔹 Warehouse suggestions overlay
                    if (_showWarehouseSuggestions && provider.warehouseResults.isNotEmpty)
                      Positioned(
                        top: 50, // match TextField height
                        left: MediaQuery.of(context).size.width / 2 + 6,
                        right: 0,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: provider.warehouseResults.length,
                              itemBuilder: (context, index) {
                                final suggestion = provider.warehouseResults[index];
                                final displayText = suggestion['description']?.isNotEmpty == true
                                    ? suggestion['description']
                                    : suggestion['value'];
                                return ListTile(
                                  title: Text(displayText ?? ""),
                                  onTap: () {
                                    setState(() {
                                      _warehouseController.text = displayText ?? "";
                                      _selectedWarehouse = suggestion['value'];
                                      _showWarehouseSuggestions = false;
                                    });
                                    FocusScope.of(context).unfocus();
                                    provider.clearWarehouseResults();
                                    _fetchStock(); // Combined fetch
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),


                SizedBox(height: 20),

                // 🔹 Stock list
                Expanded(
                  child: provider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : (provider.currentStockListModel == null ||
                      provider.currentStockListModel!.message == null ||
                      provider.currentStockListModel!.message!.isEmpty)
                      ? Center(child: Text("No stock data available"))
                      : ListView.separated(
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemCount: provider.currentStockListModel!.message!.length,
                    itemBuilder: (context, index) {
                      final stock = provider.currentStockListModel!.message![index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      stock.itemCode ?? "",
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.inventory, color: AppColors.primaryColor),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Item Name: ${stock.itemName}",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Warehouse: ${stock.warehouse}",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              _buildStockInfoRow("Actual Qty", stock.actualQty),
                              SizedBox(height: 4),
                              _buildStockInfoRow(
                                "Available Qty",
                                ((stock.actualQty ?? 0) - (stock.reservedQty ?? 0)),
                                valueColor: ((stock.actualQty ?? 0) - (stock.reservedQty ?? 0)) <= 0
                                    ? Colors.red
                                    : Colors.green,
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
          );
        },
      ),
    ),
    );
  }


  //
  // Widget _buildStockInfoRow(String label, dynamic value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Flexible(
  //           child: Text(
  //             "$label:",
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         Flexible(
  //           child: Text(
  //             "$value",
  //             style: TextStyle(fontSize: 16),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildStockInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: Text(
              "$value",
              style: TextStyle(fontSize: 16, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
