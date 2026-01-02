import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import '../../model/get_quotation_response.dart';
import 'SalesQuotation.dart';

class QuotationListTab extends StatefulWidget {
  const QuotationListTab({super.key});

  @override
  State<QuotationListTab> createState() => _QuotationListTabState();
}

class _QuotationListTabState extends State<QuotationListTab> {
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();
  final TextEditingController _quotationNameController = TextEditingController();
  final TextEditingController _partyNameController = TextEditingController();

  String _fromDate = '';
  String _toDate = '';
  int limitStart = 0;
  final int pageLength = 15;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context
          .read<SalesOrderProvider>()
          .getQuotationListFromERP(context, 0, 15);
    });
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );

    if (picked != null) {
      setState(() {
        // Display date in dd-MM-yyyy format
        String displayDate = DateFormat('dd-MM-yyyy').format(picked);
        controller.text = displayDate;

        // API date format
        String apiDate = DateFormat('yyyy-MM-dd').format(picked);

        if (isFromDate) {
          _fromDate = apiDate;
        } else {
          _toDate = apiDate;
          if (_fromDate.isNotEmpty) {
            _getQuotationDateFilterList(_fromDate, _toDate);
          }
        }
      });
    }
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

  void _showSearchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Quotation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _quotationNameController,
                decoration: const InputDecoration(
                  labelText: 'Quotation Name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _partyNameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _getSearchQuotationList(
                  _quotationNameController.text,
                  _partyNameController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _getSearchQuotationList(String? quotationName, String? partyName) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.getSearchQuotation(
        context,
        quotationName ?? '',
        partyName ?? '',
      );
    } catch (e) {
      debugPrint('Error fetching quotation list: $e');
    }
  }

  void _resetFilters() {
    _quotationNameController.clear();
    _partyNameController.clear();
    _fromDateController.clear();
    _toDateController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }

        final quotations = provider.quotationList?.data ?? [];

        if (quotations.isEmpty) {
          return const Center(child: Text('No quotations found.'));
        }

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
                        onPressed: () {
                          _resetFilters();
                          provider.getQuotationListFromERP(context, 0, 20); // Reload default quotation list
                        },
                      ),
                    ],
                  ),
                ),
              ),
        Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: quotations.length,
          itemBuilder: (context, index) {
            final QuotationData qtn = quotations[index];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              child: ListTile(
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

                  subtitle: Text(
                    'Date: ${_formatDate(qtn.transactionDate)}\n'
                        'Valid Till: ${_formatDate(qtn.validTill)}',
                    style: const TextStyle(height: 1.4),
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

                      // :null,

                  onTap: () async {
                    final provider = context.read<SalesOrderProvider>();
                    final safeContext = Navigator
                        .of(context)
                        .context; // <-- ✅ Use parent context

                    if (qtn.status == 'Draft') {
                      final parentState = context.findAncestorStateOfType<
                          SalesQuotationPageState>();
                      await provider.fetchQuotationDetails(
                          qtn.name ?? '', context);

                      if (!mounted) return;

                      final quotationData = provider.quotationDetails;
                      if (quotationData != null && parentState != null) {
                        parentState.createQuotationTabKey.currentState
                            ?.prefillQuotationForm(quotationData);
                        Future.microtask(() {
                          parentState.tabController.animateTo(0);
                        });
                      }
                    } else {
                      // Fetch details first
                      await provider.fetchQuotationDetails(
                          qtn.name ?? '', context);
                      if (!mounted) return;

                      final quotationData = provider.quotationDetails;
                      if (quotationData == null) return;

                      showDialog(
                        context: safeContext,
                        builder: (_) {
                          final items = (quotationData['items'] ?? []) as List<dynamic>;

                          String formatCurrency(dynamic value) {
                            if (value == null) return '0.00';
                            final num? parsed = value is num ? value : num.tryParse(value.toString());
                            return parsed?.toStringAsFixed(2) ?? '0.00';
                          }

                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            scrollable: true,
                            contentPadding: const EdgeInsets.all(20),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🧾 Header (Quotation ID and Customer)
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        quotationData['name'] ?? 'Quotation',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        quotationData['party_name'] ?? 'Unknown Customer',
                                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Divider(thickness: 1, color: Colors.grey.shade300),

                                // 📋 Status + Date Info Card
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildInfoRow("Status", quotationData['status'] ?? 'N/A'),
                                      _buildInfoRow("Date", _formatDate(quotationData['transaction_date'])),
                                      _buildInfoRow("Valid Till", _formatDate(quotationData['valid_till'])),
                                      const SizedBox(height: 6),
                                      _buildInfoRow("Total (₹)", formatCurrency(getPreferredValue(quotationData, 'net_total', 'total'))),
                                      _buildInfoRow("Grand Total (₹)", formatCurrency(getPreferredValue(quotationData, 'rounded_total', 'grand_total'))),

                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // 📦 Items Header
                                const Text(
                                  "Items",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (items.isEmpty)
                                  const Text("No items available", style: TextStyle(color: Colors.black54))
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) => Divider(height: 12, color: Colors.grey.shade300),
                                    itemBuilder: (_, index) {
                                      final itm = items[index] as Map<String, dynamic>;
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 🔹 Index Number
                                          Container(
                                            width: 26,
                                            height: 26,
                                            margin: const EdgeInsets.only(right: 10, top: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "${index + 1}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),

                                          // 🧾 Item details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  itm['item_name'] ?? itm['item_code'] ?? 'Unnamed Item',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 16,
                                                  runSpacing: 4,
                                                  children: [
                                                    Text("Qty: ${itm['qty'] ?? 0}",
                                                        style: TextStyle(color: Colors.grey.shade800)),
                                                    Text("Rate: ₹${formatCurrency(itm['rate'])}",
                                                        style: TextStyle(color: Colors.grey.shade800)),
                                                    Text("Amt: ₹${formatCurrency(itm['amount'])}",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87,
                                                        )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(safeContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.close, color: Colors.white),
                                label: const Text(
                                  "Close",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
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
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
