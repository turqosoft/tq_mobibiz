import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import '../../model/get_quotation_response.dart';
import '../new_Transcation/get_sales_order.dart';
import 'SalesQuotation.dart';

class QuotationListTab extends StatefulWidget {
  const QuotationListTab({super.key});

  @override
  State<QuotationListTab> createState() => QuotationListTabState();
}

class QuotationListTabState extends State<QuotationListTab>
    with AutomaticKeepAliveClientMixin{
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();
  final TextEditingController _quotationNameController = TextEditingController();
  final TextEditingController _partyNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedQuotationStatus;
  final _searchItemController = TextEditingController();
  String _fromDate = '';
  String _toDate = '';
  int limitStart = 0;
  final int pageLength = 15;
  bool isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setTodayQuotationFilter();
    });
  }
  // 🆕 Method to refresh list while preserving state
  Future<void> refreshQuotationList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    // Save current scroll position
    final currentScrollPosition = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    // Refresh based on current filter state
    // Since you only have date filter, use that
    if (_fromDate.isNotEmpty && _toDate.isNotEmpty) {
      await provider.getQuotationDateFilter(context, _fromDate, _toDate);
    } else {
      // Default to today's filter if no filter is active
      await _setTodayQuotationFilter();
    }

    // Restore scroll position after rebuild
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(
            currentScrollPosition.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
          );
        }
      });
    }
  }
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return dateStr; // fallback if parsing fails
    }
  }
  dynamic getPreferredValue(Map<String, dynamic> data, String primary, String fallback) {
    final primaryValue = data[primary];
    if (primaryValue != null) {
      final num? parsed = primaryValue is num ? primaryValue : num.tryParse(primaryValue.toString());
      if (parsed != null && parsed != 0) return primaryValue;
    }
    return data[fallback];
  }
  Future<void> _getQuotationDateFilterList(String startDate, String endDate) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getQuotationDateFilter(context, startDate, endDate);
    } catch (e) {
      debugPrint('Error fetching filtered quotations: $e');
    }
  }
  Future<void> _setTodayQuotationFilter() async {
    final today = DateTime.now();

    // API format
    final apiDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // UI format
    final uiDate =
        "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

    setState(() {
      _fromDate = apiDate;
      _toDate = apiDate;

      _fromDateController.text = uiDate;
      _toDateController.text = uiDate;
    });

    await context
        .read<SalesOrderProvider>()
        .getQuotationDateFilter(context, _fromDate, _toDate);
  }
  DateTime? _parseApiDate(String date) {
    if (date.isEmpty) return null;
    try {
      final parts = date.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate(
      BuildContext context,
      TextEditingController controller,
      bool isFromDate,
      ) async {
    final fromDateTime = _parseApiDate(_fromDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? DateTime.now()
          : (fromDateTime ?? DateTime.now()),
      firstDate: isFromDate
          ? DateTime(2020)
          : (fromDateTime ?? DateTime(2020)), // 🔒 Restrict To Date
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    final apiDate =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

    final uiDate =
        "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";

    setState(() {
      controller.text = uiDate;

      if (isFromDate) {
        _fromDate = apiDate;

        // ✅ Auto-adjust To Date if it becomes invalid
        if (_toDate.isEmpty || _parseApiDate(_toDate)!.isBefore(pickedDate)) {
          _toDate = apiDate;
          _toDateController.text = uiDate;
        }
      } else {
        _toDate = apiDate;
      }
    });

    // ✅ APPLY FILTER IMMEDIATELY
    await _getQuotationDateFilterList(_fromDate, _toDate);
  }


  Future<void> _loadMoreItems({bool next = true}) async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
      if (next) {
        limitStart += pageLength;
      } else {
        if (limitStart > 0) {
          limitStart -= pageLength;
        }
      }
    });

    await context
        .read<SalesOrderProvider>()
        .getQuotationListFromERP(context, limitStart, pageLength);

    setState(() {
      isLoadingMore = false;
    });
  }

  // void _showSearchPopup(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Search Quotation'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: _quotationNameController,
  //               decoration: const InputDecoration(
  //                 labelText: 'Quotation Name',
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             TextField(
  //               controller: _partyNameController,
  //               decoration: const InputDecoration(
  //                 labelText: 'Party Name',
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               _getSearchQuotationList(
  //                 _quotationNameController.text,
  //                 _partyNameController.text,
  //               );
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Search'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // Future<void> _getSearchQuotationList(String? quotationName, String? partyName) async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   try {
  //     await provider.getSearchQuotation(
  //       context,
  //       quotationName ?? '',
  //       partyName ?? '',
  //     );
  //   } catch (e) {
  //     debugPrint('Error fetching quotation list: $e');
  //   }
  // }
  void _showSearchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Search Quotation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _quotationNameController,
                    decoration: const InputDecoration(labelText: 'Quotation Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _partyNameController,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchItemController,
                    decoration: const InputDecoration(labelText: 'Item Code or Item Name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedQuotationStatus,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'Open', child: Text('Open')),
                      DropdownMenuItem(value: 'Replied', child: Text('Replied')),
                      DropdownMenuItem(value: 'Partially Ordered', child: Text('Partially Ordered')),
                      DropdownMenuItem(value: 'Ordered', child: Text('Ordered')),
                      DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _selectedQuotationStatus = value);
                      setState(() => _selectedQuotationStatus = value);
                    },
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _quotationNameController.clear();
                          _partyNameController.clear();
                          _searchItemController.clear();
                          _selectedQuotationStatus = null;
                        });
                        Navigator.of(context).pop();
                        _getSearchQuotationList();
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _getSearchQuotationList();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _getSearchQuotationList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getSearchQuotation(
        context,
        quotationName: _quotationNameController.text.isNotEmpty ? _quotationNameController.text : null,
        partyName: _partyNameController.text.isNotEmpty ? _partyNameController.text : null,
        itemSearch: _searchItemController.text.isNotEmpty ? _searchItemController.text : null,
        status: _selectedQuotationStatus,
      );
    } catch (e) {
      debugPrint('Error fetching quotation list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }

        final quotations = provider.quotationList?.data ?? [];

        return Stack(
            children: [
        Column(
        children: [
        // 🗓 Date Filters Row
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
        children: [
        Expanded(
        child: TextField(
        controller: _fromDateController,
        readOnly: true,
        decoration: InputDecoration(
        labelText: 'From Date',
        suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () => _selectDate(context, _fromDateController, true),
        ),
        ),
        ),
        ),
        const SizedBox(width: 10),
        Expanded(
        child: TextField(
        controller: _toDateController,
        readOnly: true,
        decoration: InputDecoration(
        labelText: 'To Date',
        suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () => _selectDate(context, _toDateController, false),
        ),
        ),
        ),
        ),
        ],
        ),
        ),

              // 🔍 Search and 🔄 Refresh buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _showSearchPopup(context);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: "Reset to Today",
                        onPressed: () async {
                          _quotationNameController.clear();
                          _partyNameController.clear();
                          _searchItemController.clear();
                          setState(() => _selectedQuotationStatus = null);  // ✅

                          limitStart = 0; // reset pagination if used

                          await _setTodayQuotationFilter();
                        },
                      ),

                    ],
                  ),
                ),
              ),
        Expanded(
            child: quotations.isEmpty
                ? const Center(
              child: Text(
                'No quotations are available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : ListView.builder(
              key: const PageStorageKey<String>('quotationListScroll'),
              controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: quotations.length,
          itemBuilder: (context, index) {
            final QuotationData qtn = quotations[index];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              child: ListTile(
                  onLongPress: () async {
                    final rootContext = Navigator.of(context, rootNavigator: true).context;

                    if (qtn.status != "Open") {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text("Only Open quotations can create Sales Order")),
                      );
                      return;
                    }

                    final provider = context.read<SalesOrderProvider>();

                    final mappedData =
                    await provider.mapQuotationToSalesOrder(qtn.name ?? "");

                    if (mappedData == null) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text("Failed to create Sales Order")),
                      );
                      return;
                    }

                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => SalesOrderPage(
                          mappedQuotation: mappedData,
                        ),
                      ),
                    );
                  },
                  leading: const Icon(Icons.description_outlined, color: AppColors.primaryColor),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qtn.name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        qtn.title ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ✅ Status row below title
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            qtn.status ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: qtn.status == 'Draft'
                                  ? Colors.orange
                                  : qtn.status == 'Open'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${_formatDate(qtn.transactionDate)}\n'
                            'Valid Till: ${_formatDate(qtn.validTill)}',
                        style: const TextStyle(height: 1.4),
                      ),
                      if (qtn.status == 'Open') ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.touch_app, size: 13, color: Colors.blue.shade600),
                            const SizedBox(width: 3),
                            Text(
                              "Hold to create Sales Order",
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                // 🟢 Show PDF icon for all quotations (including Draft)
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    tooltip: 'Download PDF',
                    onPressed: () async {
                      final provider = context.read<SalesOrderProvider>();

                      // 🟢 Step 1: Fetch available print formats
                      final formats = await provider.getQuotationPrintFormats(context);

                      if (formats.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No print formats available')),
                        );
                        return;
                      }

                      // 🟢 Step 2: Show dialog to select format
                      final selectedFormat = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String? chosenFormat;
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Text('Select Print Format'),
                            content: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: formats.first,
                              items: formats
                                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (value) => chosenFormat = value,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, chosenFormat ?? formats.first),
                                child: const Text('Download'),
                              ),
                            ],
                          );
                        },
                      );

                      // 🟢 Step 3: If user selected a format, download PDF
                      if (selectedFormat != null) {
                        await provider.downloadQuotationPdf(
                          qtn.name ?? '',
                          context,
                          formatName: selectedFormat,
                        );
                      }
                    },
                  ),

                  onTap: () async {
                    final provider = context.read<SalesOrderProvider>();
                    final safeContext = Navigator.of(context).context;

                    if (qtn.status == 'Draft') {
                      final parentState = context.findAncestorStateOfType<SalesQuotationPageState>();
                      await provider.fetchQuotationDetails(qtn.name ?? '', context);

                      if (!mounted) return;

                      final quotationData = provider.quotationDetails;
                      if (quotationData != null && parentState != null) {
                        parentState.createQuotationTabKey.currentState?.prefillQuotationForm(quotationData);
                        Future.microtask(() {
                          parentState.tabController.animateTo(0);
                        });
                      }
                    } else {
                      // Show a local loading indicator — no provider state change, no list rebuild
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      final quotationData = await provider.fetchQuotationDetailsSilent(qtn.name ?? '', context);

                      // Dismiss loader
                      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
                      if (!mounted || quotationData == null) return;

                      showDialog(
                        context: safeContext,
                        builder: (_) {
                          final items = (quotationData['items'] ?? []) as List<dynamic>;

                          // Helper functions
                          String _formatDate(String? date) {
                            if (date == null) return '-';
                            try {
                              final parsed = DateTime.parse(date);
                              return DateFormat('dd/MM/yyyy').format(parsed);
                            } catch (_) {
                              return date;
                            }
                          }

                          double _toDouble(dynamic value) {
                            if (value == null) return 0.0;
                            if (value is num) return value.toDouble();
                            return double.tryParse(value.toString()) ?? 0.0;
                          }

                          String _formatFieldValue(dynamic value, {bool isCurrency = false}) {
                            if (value == null) return '-';
                            final num? parsed = value is num ? value : num.tryParse(value.toString());
                            if (parsed == null || parsed == 0) return '-';
                            if (isCurrency) return parsed.toStringAsFixed(2);
                            if (parsed == parsed.toInt()) return parsed.toInt().toString();
                            return parsed.toStringAsFixed(2);
                          }

                          return AlertDialog(
                            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                            elevation: 6,

                            // ---------- HEADER ----------
                            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            title: Row(
                              children: [
                                const Icon(Icons.description, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    quotationData['name'] ?? 'Quotation',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(quotationData['transaction_date']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // ---------- CONTENT ----------
                            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            content: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(safeContext).size.height * 0.75,
                                maxWidth: MediaQuery.of(safeContext).size.width * 0.90,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _dialogRow("Customer", quotationData['party_name']),
                                    _dialogRow("Status", quotationData['status']),
                                    _dialogRow("Valid Till", _formatDate(quotationData['valid_till'])),

                                    const Divider(height: 16),

                                    _sectionHeader("Financials"),
                                    _financialGrid(quotationData),

                                    const Divider(height: 16),

                                    _sectionHeader("Items (${items.length})"),
                                    const SizedBox(height: 4),

                                    if (items.isEmpty)
                                      const Text("No items available."),

                                    ...items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final itm = entry.value as Map<String, dynamic>;

                                      final qty = _toDouble(itm['qty']);
                                      final rate = _toDouble(itm['rate']);
                                      final amount = _toDouble(itm['amount']);
                                      final igstAmount = _toDouble(itm['igst_amount']);
                                      final cgstAmount = _toDouble(itm['cgst_amount']);
                                      final sgstAmount = _toDouble(itm['sgst_amount']);
                                      final cessAmount = _toDouble(itm['cess_amount']);

                                      final gstAmount =
                                          igstAmount + cgstAmount + sgstAmount + cessAmount;
                                      return ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: const EdgeInsets.symmetric(vertical: 6),

                                        title: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              child: Text(
                                                "${index + 1}.",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                itm['item_name'] ?? itm['item_code'] ?? 'Unnamed Item',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ---------- SUBTITLE ----------
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(left: 24),
                                          child: Text(
                                            "Qty ${qty.toStringAsFixed(2)} • Rate ₹${rate.toStringAsFixed(2)} • Total ₹${amount.toStringAsFixed(2)}",
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),

                                        // ---------- DETAILS ----------
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _itemRow("Code", itm['item_code']),
                                                _itemRow("Qty", qty.toStringAsFixed(2)),
                                                _itemRow("Unit", itm['uom']),
                                                _itemRow("MRP", _formatFieldValue(itm['mrp'], isCurrency: true)),
                                                _itemRow("Item Tax Template",(itm['item_tax_template'])),
                                                _itemRow(
                                                  "GST Amount",
                                                  "₹ ${gstAmount.toStringAsFixed(2)}",
                                                ),
                                                _itemRow("Price List Rate", _formatFieldValue(itm['price_list_rate'], isCurrency: true)),

                                                if (_toDouble(itm['discount_percentage']) > 0)
                                                  _itemRow(
                                                    "Discount %",
                                                    "${_formatFieldValue(itm['discount_percentage'])} %",
                                                  ),

                                                if (_toDouble(itm['discount_amount']) > 0)
                                                  _itemRow(
                                                    "Discount Amt",
                                                    "₹ ${_formatFieldValue(itm['discount_amount'], isCurrency: true)}",
                                                  ),

                                                _itemRow("Rate", "₹ ${rate.toStringAsFixed(2)}"),
                                                _itemRow("Total", "₹ ${amount.toStringAsFixed(2)}"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),

                            // ---------- ACTIONS ----------
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              TextButton.icon(
                                onPressed: () => Navigator.pop(safeContext),
                                icon: const Icon(Icons.close),
                                label: const Text("Close"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }

            ),
            );

          },
        ))]),
              // ✅ Floating pagination buttons
              if (!provider.isLoading)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: limitStart > 0
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () => _loadMoreItems(next: false),
                    child: const Text('Previous'),
                  )
                      : const SizedBox.shrink(),
                ),

              Positioned(
                bottom: 16,
                right: 16,
                child: quotations.length >= pageLength
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => _loadMoreItems(next: true),
                  child: const Text('Next'),
                )
                    : const SizedBox.shrink(),
              ),
            ]

        );
      },
    );

  }

}

Widget _dialogRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value ?? "-",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _itemRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? "-",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );
}

Widget _financialGrid(Map<String, dynamic> quotationData) {
  const TextStyle labelStyle = TextStyle(fontSize: 12, color: Colors.grey);
  const TextStyle valueStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 13);

  Widget cell(String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  dynamic getPreferredValue(Map<String, dynamic> data, String primary, String fallback) {
    final primaryValue = data[primary];
    if (primaryValue != null) {
      final num? parsed = primaryValue is num ? primaryValue : num.tryParse(primaryValue.toString());
      if (parsed != null && parsed != 0) return primaryValue;
    }
    return data[fallback];
  }
  List<Widget> cells = [
    cell(
      "Net Total",
      _toDouble(getPreferredValue(quotationData, 'net_total', 'total')).toStringAsFixed(2),
    ),
    cell(
      "Taxes",
      _toDouble(quotationData['total_taxes_and_charges']).toStringAsFixed(2),
    ),
    cell(
      "Grand Total",
      _toDouble(getPreferredValue(quotationData, 'rounded_total', 'grand_total')).toStringAsFixed(2),
    ),
  ];

  // Add discount amount if available
  if (_toDouble(quotationData['discount_amount']) > 0) {
    cells.add(
      cell(
        "Discount Amount",
        _toDouble(quotationData['discount_amount']).toStringAsFixed(2),
      ),
    );
  }

  // Add additional discount percentage if available
  if (_toDouble(quotationData['additional_discount_percentage']) > 0) {
    cells.add(
      cell(
        "Additional Discount %",
        "${_toDouble(quotationData['additional_discount_percentage']).toStringAsFixed(2)} %",
      ),
    );
  }

  return Wrap(
    spacing: 16,
    runSpacing: 12,
    children: cells,
  );
}
