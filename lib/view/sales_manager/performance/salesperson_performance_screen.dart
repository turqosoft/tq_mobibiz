import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

class SalesPersonPerformanceScreen extends StatefulWidget {
  const SalesPersonPerformanceScreen({super.key}); // ← no salesperson param

  @override
  State<SalesPersonPerformanceScreen> createState() =>
      _SalesPersonPerformanceScreenState();
}

class _SalesPersonPerformanceScreenState
    extends State<SalesPersonPerformanceScreen> {
  final _displayFmt = DateFormat('dd MMM yyyy');
  final _currencyFmt = NumberFormat('#,##0.00', 'en_IN');
  final _scrollController = ScrollController();

  // One key per section in the same order as the grid
  final _sectionKeys = List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SalesOrderProvider>().fetchPerformanceReport(); // ← no salesperson
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Future<DateTime?> _pickDate(DateTime initial) {
  //   return showDatePicker(
  //     context: context,
  //     initialDate: initial,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2030),
  //   );
  // }
  Future<DateTime?> _pickDate(DateTime initial) {
    final twoMonthsAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month - 2,
      DateTime.now().day,
    );

    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: twoMonthsAgo, // ← can't go further back than 2 months
      lastDate: DateTime.now(), // ← can't select future dates
    );
  }
  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0, // snap to top of section
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SalesOrderProvider>();

    return Scaffold(
      appBar: CommonAppBar(
        title: "Performance Report",
        subtitle: p.resolvedSalesPerson,
        actions: p.performanceReportState == PerformanceReportState.success
            ? p.isPdfDownloading
            ? const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        )
            : IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined,
              color: Colors.white),
          tooltip: 'Download PDF',
          onPressed: () => p.downloadPerformanceReportPdf(),
        )
            : null,
      ),
      body: Column(
        children: [
          _buildFilterCard(p),
          Expanded(child: _buildBody(p)),
        ],
      ),
    );
  }
  Widget _buildBody(SalesOrderProvider p) {
    switch (p.performanceReportState) {
      case PerformanceReportState.loading:
        return const Center(child: CircularProgressIndicator());
      case PerformanceReportState.error:
        return _buildError(p);
      case PerformanceReportState.success:
        return _buildReport(p);
      case PerformanceReportState.idle:
      default:
        return const SizedBox();
    }
  }

  Widget _buildFilterCard(SalesOrderProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _DateField(
              label: 'From',
              date: p.perfFromDate,
              displayFmt: _displayFmt,
              onTap: () async {
                final picked = await _pickDate(p.perfFromDate);
                if (picked != null) p.setPerfFromDate(picked);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          Expanded(
            child: _DateField(
              label: 'To',
              date: p.perfToDate,
              displayFmt: _displayFmt,
              onTap: () async {
                final picked = await _pickDate(p.perfToDate);
                if (picked != null) p.setPerfToDate(picked);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => p.fetchPerformanceReport(
                salesperson: p.resolvedSalesPerson,
              ),
              child: const Icon(Icons.search, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(SalesOrderProvider p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(p.performanceReportError ?? 'Something went wrong'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => p.fetchPerformanceReport(
                salesperson: p.resolvedSalesPerson,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(SalesOrderProvider p) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        12, 12, 12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryGrid(p),
          const SizedBox(height: 16),
          _buildSection(key: _sectionKeys[0], title: 'Sales Orders',  data: p.perfSalesOrders,        color: Colors.blue),
          _buildSection(key: _sectionKeys[1], title: 'Estimates',     data: p.perfEstimates,           color: Colors.orange),
          _buildSection(key: _sectionKeys[2], title: 'Quotations',    data: p.perfQuotations,          color: Colors.purple),
          _buildSection(key: _sectionKeys[3], title: 'Payments',      data: p.perfPaymentCollections,  color: Colors.green),
          _buildSection(key: _sectionKeys[4], title: 'Visits', data: p.perfVisits, color: Colors.teal, countLabel: 'visits'),        ],
      ),
    );
  }

  Widget _buildSummaryGrid(SalesOrderProvider p) {
    final items = [
      (
      'Sales Orders',
      p.perfTotalCount(p.perfSalesOrders),
      p.perfTotalAmount(p.perfSalesOrders),
      Colors.blue,
      0, // section index
      ),
      (
      'Estimates',
      p.perfTotalCount(p.perfEstimates),
      p.perfTotalAmount(p.perfEstimates),
      Colors.orange,
      1,
      ),
      (
      'Quotations',
      p.perfTotalCount(p.perfQuotations),
      p.perfTotalAmount(p.perfQuotations),
      Colors.purple,
      2,
      ),
      (
      'Payments',
      p.perfTotalCount(p.perfPaymentCollections),
      p.perfTotalAmount(p.perfPaymentCollections),
      Colors.green,
      3,
      ),
      (
      'Visits',
      p.perfVisitCount,
      p.perfTotalAmount(p.perfVisits),
      Colors.teal,
      4,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: items.map((item) {
        final (label, count, amount, color, sectionIndex) = item;
        return GestureDetector(
          onTap: () => _scrollToSection(sectionIndex),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('$count',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                if (amount > 0)
                  Text('₹${_currencyFmt.format(amount)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildSection({
    required GlobalKey key,
    required String title,
    required List<Map<String, dynamic>> data,
    required Color color,
    String countLabel = 'records',

  }) {
    return Padding(
      key: key, // ← attach here
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data.length} $countLabel',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            if (data.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('No records', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              ...data.map((item) => ListTile(
                title: Text(item['customer'] ?? '', style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  item['site'] != null && item['site'].toString().isNotEmpty
                      ? item['site'].toString()
                      : '${item['total_count']} order(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: Text(
                  '₹${_currencyFmt.format(item['total_amount'] ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )),
          ],
        ),
      ),
    );
  }
  }
// ─── _DateField ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat displayFmt;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.displayFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                  Text(displayFmt.format(date),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}