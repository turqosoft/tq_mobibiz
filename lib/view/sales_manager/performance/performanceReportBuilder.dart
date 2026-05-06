import 'package:intl/intl.dart';

class PerformanceReportHtmlBuilder {
  final String? salesperson;
  final String fromDate;
  final String toDate;
  final List<Map<String, dynamic>> salesOrders;
  final List<Map<String, dynamic>> estimates;
  final List<Map<String, dynamic>> quotations;
  final List<Map<String, dynamic>> paymentCollections;
  final List<Map<String, dynamic>> visits;

  PerformanceReportHtmlBuilder({
    required this.salesperson,
    required this.fromDate,
    required this.toDate,
    required this.salesOrders,
    required this.estimates,
    required this.quotations,
    required this.paymentCollections,
    required this.visits,
  });

  final _fmt = DateFormat('dd MMM yyyy');
  final _amountFmt = NumberFormat('#,##0.00', 'en_IN');

  int _rowIndex = 1;

  String build() {
    _rowIndex = 1; // reset counter each build

    // ── Build all sections ──────────────────────────────────────────────────
    final quotationSection   = _sectionRows('QUOTATION',           quotations);
    final salesOrderSection  = _sectionRows('SALES ORDER',         salesOrders);
    final paymentSection     = _sectionRows('PAYMENT COLLECTION',  paymentCollections);
    final estimateSection    = _sectionRows('ESTIMATE',            estimates);
    final visitSection       = _sectionRows('SITE VISIT',         visits, isVisit: true);

    // ── Grand total row ─────────────────────────────────────────────────────
    final grandTotalCount = [salesOrders, estimates, quotations, paymentCollections]
        .fold(0, (sum, list) => sum + list.fold(0, (s, e) => s + (e['total_count'] as int? ?? 0)));

    final grandTotalAmount = [salesOrders, estimates, quotations, paymentCollections]
        .fold(0.0, (sum, list) => sum + list.fold(0.0, (s, e) => s + (e['total_amount'] as num? ?? 0).toDouble()));

    final grandTotalRow = '''
      <tr style="height:30px">
        <td><span>${_rowIndex++}</span></td>
        <td><span>Total</span></td>
        <td></td>
        <td><span><b>$grandTotalCount</b></span></td>
        <td><span><b>${_amountFmt.format(grandTotalAmount)}</b></span></td>
        <td></td>
        <td></td>
      </tr>''';

    final rows = [
      quotationSection,
      salesOrderSection,
      paymentSection,
      estimateSection,
      visitSection,
      grandTotalRow,
    ].join('');

    return '''
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
  <meta charset="utf-8">
  <title>Sales Man Summary</title>
  <style>
    @media print {
      .print-format p { margin-left: 1px; margin-right: 1px; }
    }
    body {
      font-size: 9pt;
      font-family: Inter, "Helvetica Neue", Helvetica, Arial, "Open Sans", sans-serif;
      -webkit-print-color-adjust: exact;
    }
    .print-format-gutter {
      background-color: #d1d8dd;
      padding: 30px 0px;
    }
    .print-format {
      background-color: white;
      max-width: 11.69in;
      padding: 0.2in;
      margin: auto;
    }
    .print-heading {
      text-align: right;
      text-transform: uppercase;
      color: #666;
      padding-bottom: 20px;
      margin-bottom: 20px;
      border-bottom: 1px solid #d1d8dd;
    }
    .print-heading h2 { font-size: 24px; margin: 0; }
    h2.text-center { text-align: center; }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: inherit;
      margin: 20px 0px;
    }
    th {
      background-color: #eee !important;
      border-bottom: 0px !important;
      vertical-align: top !important;
      padding: 6px !important;
      text-align: left;
      border: 1px solid #dee2e6;
    }
    td {
      vertical-align: top !important;
      padding: 6px !important;
      border: 1px solid #dee2e6;
    }
    .ql-editor { padding: 0; }
    .ql-editor p { margin: 3px 0; }
    b { font-weight: bold; }
  </style>
</head>
<body>
  <div class="print-format-gutter">
    <div class="print-format landscape">
      <h2 class="text-center">Sales Man Summary</h2>
      <hr>
      <table class="table table-bordered">
        <thead>
          <tr>
            <th>#</th>
            <th>Section</th>
            <th>Customer</th>
            <th>Count</th>
            <th>Amount</th>
            <th>Site</th>
            <th>Remarks</th>
          </tr>
        </thead>
        <tbody>
          $rows
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>''';
  }

  // ── Section builder ─────────────────────────────────────────────────────────

  String _sectionRows(
      String sectionTitle,
      List<Map<String, dynamic>> items, {
        bool isVisit = false,
      }) {
    if (items.isEmpty) return '';

    // Section header row
    final headerRow = '''
      <tr style="height:30px">
        <td><span>${_rowIndex++}</span></td>
        <td><span style="padding-left:0em"><b>$sectionTitle</b></span></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
      </tr>''';

    // Data rows
    final dataRows = items.map((item) {
      final customer = item['customer'] ?? '';
      final count    = isVisit ? '' : '${item['total_count'] ?? ''}';
      final amount   = isVisit ? '' : _formatAmount(item['total_amount']);
      final site     = isVisit ? (item['site'] ?? '') : '';

      // remarks — strip ql-editor wrapper if present, keep inner html
      final rawRemarks = item['remarks'] ?? '';
      final remarks = rawRemarks.toString().trim().isNotEmpty
          ? '<div class="ql-editor read-mode"><p>$rawRemarks</p></div>'
          : '<div class="ql-editor read-mode"><p></p></div>';

      return '''
        <tr style="height:30px">
          <td><span>${_rowIndex++}</span></td>
          <td><span style="padding-left:0em"></span></td>
          <td><span>$customer</span></td>
          <td><span>$count</span></td>
          <td><span>$amount</span></td>
          <td><span>$site</span></td>
          <td>${isVisit ? remarks : ''}</td>
        </tr>''';
    }).join('');

    // Section total row
    final totalCount = isVisit
        ? items.length
        : items.fold(0, (s, e) => s + (e['total_count'] as int? ?? 0));
    final totalAmount = isVisit
        ? 0.0
        : items.fold(0.0, (s, e) => s + (e['total_amount'] as num? ?? 0).toDouble());

    final totalRow = '''
      <tr style="height:30px">
        <td><span>${_rowIndex++}</span></td>
        <td><span style="padding-left:0em"><b>Total</b></span></td>
        <td></td>
        <td><span><b>$totalCount</b></span></td>
        <td><span>${isVisit ? '' : '<b>${_formatAmount(totalAmount)}</b>'}</span></td>
        <td></td>
        <td></td>
      </tr>
      <tr style="height:30px">
        <td><span>${_rowIndex++}</span></td>
        <td></td><td></td><td></td><td></td><td></td><td></td>
      </tr>''';

    return '$headerRow$dataRows$totalRow';
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '';
    final num amount = value is num ? value : num.tryParse('$value') ?? 0;
    return _amountFmt.format(amount);
  }
}