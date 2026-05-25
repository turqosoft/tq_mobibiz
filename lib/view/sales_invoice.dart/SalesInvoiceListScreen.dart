import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';

import '../../service/apiservices.dart';

// class SalesInvoiceScreen extends StatefulWidget {
class SalesInvoiceScreen extends StatefulWidget {
  final String? highlightInvoice; // 👈 invoice to highlight

  const SalesInvoiceScreen({
    super.key,
    this.highlightInvoice,
  });
  @override
  _SalesInvoiceScreenState createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // 👈 add this



  int limitStart = 0;
final int pageLength = 10; // or any number you want per page

  DateTime? _fromDate;
  DateTime? _toDate;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _scrollController.dispose(); // 👈 dispose it
    super.dispose();
  }

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
  bool isFromDate,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    // Display in dd-MM-yyyy format
    final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    controller.text = formatted;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });

    // Trigger filter only if both dates are selected
    if (_fromDate != null && _toDate != null) {
      _getFilteredInvoices();
    }
  }
}


// Future<void> _getFilteredInvoices() async {
//   final startDate = "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
//   final endDate = "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";
//
//   await Provider.of<SalesOrderProvider>(context, listen: false)
//       .getSalesInvoiceDateFilter(context, startDate, endDate);
// }
  Future<void> _getFilteredInvoices({String? searchInvoice}) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    if (searchInvoice != null) {
      // 👇 Fetch by specific invoice name — bypass date filter
      await provider.getSalesInvoiceByName(context, searchInvoice);
    } else {
      // 👇 Your existing date filter logic — unchanged
      final startDate =
          "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
      final endDate =
          "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";

      await provider.getSalesInvoiceDateFilter(context, startDate, endDate);
    }
  }


void _showSearchPopup(BuildContext context) {
  final _invoiceController = TextEditingController();
  final _customerController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Search Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _invoiceController,
              decoration: InputDecoration(
                hintText: 'Enter Invoice Name',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _customerController,
              decoration: InputDecoration(
                hintText: 'Enter Customer',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _getSearchInvoiceList(
                _invoiceController.text,
                _customerController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      );
    },
  );
}

//   Future<void> _getSalesInvoiceList() async {
//   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
//   await provider.getSalesInvoice(context, limitStart, pageLength);
// }

  Future<void> _getSearchInvoiceList(
      String? invoiceId,
      String? customerId,
      ) async {
    final provider =
    Provider.of<SalesOrderProvider>(context, listen: false);

    String? startDate;
    String? endDate;

    if (_fromDate != null && _toDate != null) {
      startDate =
      "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
      endDate =
      "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";
    }

    await provider.getSearchSalesInvoice(
      context,
      invoiceId,
      customerId,
      startDate,
      endDate,
    );
  }



  Future<void> _loadMoreInvoices({required bool next}) async {
  setState(() {
    if (next) {
      limitStart += pageLength;
    } else {
      limitStart = (limitStart - pageLength).clamp(0, limitStart);
    }
  });

  final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  await provider.getSalesInvoice(context, limitStart, pageLength);
}

  // @override
  // void initState() {
  //   super.initState();
  //
  //   final today = DateTime.now();
  //
  //   _fromDate = today;
  //   _toDate = today;
  //
  //   // Set dd-MM-yyyy format for textfields
  //   _fromDateController.text =
  //   "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  //   _toDateController.text =
  //   "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  //
  //   // Fetch invoice list based on default date range (today to today)
  //   _getFilteredInvoices();
  // }
  @override
  void initState() {
    super.initState();

    // 👇 If a specific invoice is highlighted, clear date filters
    // so the invoice is not hidden by the default "today" range
    if (widget.highlightInvoice != null) {
      _fromDate = null;
      _toDate = null;
      _fromDateController.text = '';
      _toDateController.text = '';
      // Fetch without date filter so the invoice is guaranteed to appear
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getFilteredInvoices(searchInvoice: widget.highlightInvoice);
      });

    } else {
      final today = DateTime.now();
      _fromDate = today;
      _toDate = today;
      _fromDateController.text =
      "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
      _toDateController.text =
      "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getFilteredInvoices();
      });
    }
  }
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _showInvoiceDetailsDialog(BuildContext context, String invoiceName) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);

    final details =
    await provider.fetchSalesInvoiceDetails(context, invoiceName);

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch invoice details')),
      );
      return;
    }

    final List items = details['items'] ?? [];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 6,

          // ---------- HEADER ----------
          titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),

              /// Invoice name (left)
              Expanded(
                child: Text(
                  invoiceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              /// Posting date (right)
              Text(
                _formatDate(details["posting_date"]),
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
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: MediaQuery.of(context).size.width * 0.90,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogRow("Customer", details["customer"]),
                  const Divider(height: 16),

                  _sectionHeader("Financials"),
                  _financialGrid(details),

                  const Divider(height: 16),

                  _sectionHeader("Items (${items.length})"),

                  const SizedBox(height: 4),
                  ...items.asMap().entries.map<Widget>((entry) {
                    final int index = entry.key;
                    final item = entry.value;

                    final netAmount =
                        item["net_amount"] ?? item["amount"] ?? 0.0;
                    final netRate =
                        item["net_rate"] ?? item["rate"] ?? 0.0;
                    final amount = item["amount"] ?? item["net_amount"] ?? 0.0;

                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.symmetric(vertical: 6),

                      /// TITLE ROW WITH SL NO.
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// SL NO
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

                          /// ITEM NAME
                          Expanded(
                            child: Text(
                              item["item_name"] ?? "-",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          "Qty ${item["qty"]} • Net Rt ₹${netRate.toStringAsFixed(2)} • Total ₹${amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                      children: [
                        /// 🔷 LEFT DETAILS BOX
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
                              _itemRow("Code", item["item_code"]),

                              _itemRow(
                                "Qty",
                                _toDouble(item["qty"]).toStringAsFixed(2),
                              ),

                              _itemRow("Unit", item["uom"]),
                              _itemRow("Item Tax Template",(item['item_tax_template'])),

                              _itemRow(
                                "Price List Rate",
                                item["price_list_rate"]?.toString(),
                              ),

                              /// ✅ Discount %
                              if (_toDouble(item["discount_percentage"]) > 0)
                                _itemRow(
                                  "Discount %",
                                  "${_toDouble(item["discount_percentage"]).toStringAsFixed(2)} %",
                                ),

                              /// ✅ Discount Amount
                              if (_toDouble(item["discount_amount"]) > 0)
                                _itemRow(
                                  "Discount Amt",
                                  "₹ ${_toDouble(item["discount_amount"]).toStringAsFixed(2)}",
                                ),

                              _itemRow(
                                "Rate",
                                item["rate"]?.toString(),
                              ),

                              _itemRow(
                                "Total",
                                "₹ ${amount.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                        ),

                        /// 🔽 RIGHT-BOTTOM SUMMARY (already boxed)
                        _rightBottomSummary(
                          addlDiscount: _toDouble(item["distributed_discount_amount"]),
                          netRate: netRate,
                          netAmount: _toDouble(item["net_amount"]),
                        ),
                      ],


                    );
                  }).toList(),

                ],
              ),
            ),
          ),

          // ---------- ACTIONS ----------
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
  Widget _rightBottomSummary({
    double? addlDiscount,
    double? netRate,
    double? netAmount,
  }) {
    final hasAnyValue =
        (addlDiscount ?? 0) > 0 ||
            (netRate ?? 0) > 0 ||
            (netAmount ?? 0) > 0;

    if (!hasAnyValue) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        // margin: const EdgeInsets.only(top: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if ((addlDiscount ?? 0) > 0)
              _summaryRow("Addl. Disc. Amt", addlDiscount!),

            if ((netRate ?? 0) > 0)
              _summaryRow("Net Rate", netRate!),

            if ((netAmount ?? 0) > 0)
              _summaryRow("Net Amount", netAmount!, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label : ₹ ${value.toStringAsFixed(2)}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  void _showPrintFormatDialog(
      BuildContext context,
      String invoiceName,
      ) async {
    final provider = context.read<SalesOrderProvider>();

    final formats = await provider.fetchInvoicePrintFormats();
    String selectedFormat = formats.first;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // prevents accidental close
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Print Format"),
              content: SizedBox(
                width: double.maxFinite,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedFormat,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: formats.map(
                        (f) => DropdownMenuItem<String>(
                      value: f,
                      child: Text(
                        f,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ).toList(),
                  onChanged: isDownloading
                      ? null
                      : (val) {
                    setState(() {
                      selectedFormat = val!;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDownloading
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                    setState(() => isDownloading = true);

                    try {
                      await provider.downloadInvoicePdf(
                        invoiceName: invoiceName,
                        printFormat: selectedFormat,
                      );
                    } finally {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: isDownloading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Download"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _resetToTodayAndFetch() async {
    final today = DateTime.now();

    final formattedApiDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    setState(() {
      _fromDate = today;
      _toDate = today;

      _fromDateController.text =
      "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
      _toDateController.text =
      "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";
    });

    await Provider.of<SalesOrderProvider>(context, listen: false)
        .getSalesInvoiceDateFilter(
      context,
      formattedApiDate,
      formattedApiDate,
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Date Filters Row
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
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, _fromDateController, true),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _toDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, _toDateController, false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search and Refresh Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _showSearchPopup(context),
                  ),
// IconButton(
//   icon: Icon(Icons.refresh),
//   onPressed: () {
//     final provider =
//     Provider.of<SalesOrderProvider>(context, listen: false);
//
//     setState(() {
//       _fromDateController.clear();
//       _toDateController.clear();
//       _fromDate = null;
//       _toDate = null;
//     });
//
//     provider.clearSearchState();
//     provider.getSalesInvoice(context, 0, pageLength);
//   },
//
// ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: "Reset to Today",
                    onPressed: () async {
                      final provider =
                      Provider.of<SalesOrderProvider>(context, listen: false);

                      provider.clearSearchState();

                      await _resetToTodayAndFetch();
                    },
                  ),


                ],
              ),
            ),
          ),
          
          // Invoice List (watch provider)
Expanded(
  child: Consumer<SalesOrderProvider>(
    builder: (context, provider, _) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (provider.errorMessage != null) {
        return Center(child: Text(provider.errorMessage!));
      }

      final invoices = provider.salesInvoiceList?.data ?? [];

      if (invoices.isEmpty) {
        return const Center(child: Text('No Sales Invoices found.'));
      }

      // return ListView.builder(
      //   key: const PageStorageKey<String>('invoiceListScroll'),
      //   itemCount: invoices.length,
      //   itemBuilder: (context, index) {
      //     final invoice = invoices[index];
      //     return InkWell(
      //         onTap: () {
      //       _showInvoiceDetailsDialog(context, invoice.name!);
      //     },
      //       child: Card(
      //         elevation: 4,
      //         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(15.0),
      //         ),
      //         child: Container(
      //           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      //           constraints: const BoxConstraints(minHeight: 100),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               _buildRow(
      //                 'Invoice Number',
      //                 invoice.name,
      //                 Icons.receipt_long,
      //                 trailing: IconButton(
      //                   icon: const Icon(Icons.print, size: 20),
      //                   onPressed: () {
      //                     _showPrintFormatDialog(
      //                       context,
      //                       invoice.name!,
      //                     );
      //                   },
      //                 ),
      //               ),
      //               _buildRow('Customer', invoice.customer, Icons.person),
      //               _buildRow(
      //                 'Posting Date',
      //                 _formatDate(invoice.postingDate),
      //                 Icons.date_range,
      //               ),
      //               _buildRow(
      //                 'Due Date',
      //                 _formatDate(invoice.dueDate),
      //                 Icons.event,
      //               ),
      //               _buildRow('Status', invoice.status, Icons.info_outline),
      //               _buildRow(
      //                 'Total',
      //                 '₹ ${invoice.displayTotal.toStringAsFixed(2)}',
      //                 Icons.attach_money,
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //
      //     );
      //   },
      // );
      return ListView.builder(
        key: const PageStorageKey<String>('invoiceListScroll'),
        controller: _scrollController, // 👈 add this for auto-scroll
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          final isHighlighted = invoice.name == widget.highlightInvoice; // 👈

          return InkWell(
            onTap: () {
              _showInvoiceDetailsDialog(context, invoice.name!);
            },
            child: Stack(
              children: [
                Card(
                  elevation: isHighlighted ? 6 : 4, // 👈 subtle elevation boost
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: isHighlighted
                        ? const BorderSide(color: Colors.red, width: 1.5) // 👈 red border
                        : BorderSide.none,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: isHighlighted
                          ? Colors.red.withOpacity(0.04) // 👈 subtle red tint
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👇 Banner shown only on highlighted invoice
                        if (isHighlighted)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward,
                                    color: Colors.red, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'Navigated from customer unpaid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildRow(
                          'Invoice Number',
                          invoice.name,
                          Icons.receipt_long,
                          trailing: IconButton(
                            icon: const Icon(Icons.print, size: 20),
                            onPressed: () {
                              _showPrintFormatDialog(context, invoice.name!);
                            },
                          ),
                        ),
                        _buildRow('Customer', invoice.customer, Icons.person),
                        _buildRow(
                          'Posting Date',
                          _formatDate(invoice.postingDate),
                          Icons.date_range,
                        ),
                        _buildRow(
                          'Due Date',
                          _formatDate(invoice.dueDate),
                          Icons.event,
                        ),
                        _buildRow('Status', invoice.status, Icons.info_outline),
                        _buildRow(
                          'Total',
                          '₹ ${invoice.displayTotal.toStringAsFixed(2)}',
                          Icons.attach_money,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
  child: Consumer<SalesOrderProvider>(
    builder: (context, provider, _) {
      final invoices = provider.salesInvoiceList?.data ?? [];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: limitStart > 0
                ? () => _loadMoreInvoices(next: false)
                : null, // disables button when on first page
            child: Text('Previous'),
          ),
          ElevatedButton(
            onPressed: invoices.length < pageLength
                ? null // disables "Next" button if no more data
                : () => _loadMoreInvoices(next: true),
            child: Text('Next'),
          ),
        ],
      );
    },
  ),
),


],),);
    
  }

  Widget _buildRow(
      String label,
      String? value,
      IconData icon, {
        Widget? trailing, // ✅ NEW
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),

          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),

          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // ✅ Optional trailing widget (e.g. print icon)
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _financialGrid(Map<String, dynamic> details) {
    const TextStyle labelStyle =
    TextStyle(fontSize: 12, color: Colors.grey);
    const TextStyle valueStyle =
    TextStyle(fontWeight: FontWeight.w600, fontSize: 13);

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
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value.toString()) ?? 0.0;
    }
    final rounded = _toDouble(details["rounded_total"]);
    final grand = _toDouble(details["grand_total"]);

    final total = rounded > 0 ? rounded : grand;

    final discountAmount = _toDouble(details["discount_amount"]);
    final additionalDiscount =
    _toDouble(details["additional_discount_percentage"]);

    List<Widget> cells = [
      cell(
        "Net Total",
        _toDouble(details["net_total"] ?? details["total"])
            .toStringAsFixed(2),
      ),
      cell(
        "Taxes",
        _toDouble(details["total_taxes_and_charges"])
            .toStringAsFixed(2),
      ),
      // cell(
      //   "Total",
      //   _toDouble(details["rounded_total"] ?? details["grand_total"])
      //       .toStringAsFixed(2),
      // ),
      cell(
        "Total",
        total.toStringAsFixed(2),
      ),
    ];

    /// ✅ Additional Discount % LAST (RIGHT)
    if (additionalDiscount > 0) {
      cells.add(
        cell(
          "Additional Discount %",
          "${additionalDiscount.toStringAsFixed(2)} %",
        ),
      );
    }


    /// ✅ Outstanding FIRST (LEFT)
    cells.add(
      cell(
        "Outstanding",
        _toDouble(details["outstanding_amount"]).toStringAsFixed(2),
      ),
    );


    /// ✅ Discount Amount
    if (discountAmount > 0) {
      cells.add(
        cell(
          "Discount Amount",
          discountAmount.toStringAsFixed(2),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: cells,
    );
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
              softWrap: true,
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


  String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}'; // Format: DD/MM/YYYY
  } catch (e) {
    return dateStr; // If parsing fails, return as-is
  }
}

}
