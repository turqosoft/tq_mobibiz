import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// For General Ledger
String BuildLedgerHtml(
    Map<String, dynamic> ledgerJson,
    String fromDate,
    String toDate,
    {String? fallbackCustomerName}) {

  // final results = (ledgerJson["message"]?["result"] as List<dynamic>?) ?? [];
  final results = (ledgerJson["message"]?["data"] as List<dynamic>?) ?? [];

// TRIM FIRST 2 ROWS AND LAST 3 ROWS
  List<dynamic> trimmedResults = [];
  if (results.length > 5) {
    trimmedResults = results.sublist(2, results.length - 3);
  } else {
    // If not enough rows, produce empty list
    trimmedResults = [];
  }
  final printedOn = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());

  // Format incoming fromDate & toDate
  String formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat("dd-MM-yyyy").format(parsed);
    } catch (_) {
      return date;
    }
  }

  final formattedFrom = formatDate(fromDate);
  final formattedTo = formatDate(toDate);

  // Party Name: from ledger JSON or fallback to customer list
  String customerName = fallbackCustomerName ?? "";
  for (var row in trimmedResults) {
    if (row["party"] != null && row["party"].toString().isNotEmpty) {
      customerName = row["party"];
      break;
    }
  }

  final rows = StringBuffer();

// Use a Set to keep track of unique entries
  final seen = <String>{};

  for (var entry in trimmedResults) {
    // Build a unique key for each row (based on account + debit + credit + balance)
    // You can add more fields if needed to make uniqueness stricter
    final uniqueKey = jsonEncode({
      "account": entry["account"],
      "debit": entry["debit"],
      "credit": entry["credit"],
      "balance": entry["balance"],
    });

    // Skip if this row was already seen
    // if (seen.contains(uniqueKey)) continue;
    // seen.add(uniqueKey);

    // Format date
    final rawDate = entry["posting_date"] ?? "";
    String formattedDate = rawDate;
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(rawDate);
        formattedDate = DateFormat("dd-MM-yyyy").format(parsedDate);
      } catch (_) {
        formattedDate = rawDate;
      }
    }

    // Reference: voucher_type first, then voucher_no
    final voucherType = entry["voucher_type"] ?? "";
    final reference = entry["voucher_no"] ?? "";
    final displayReference =
    voucherType.isNotEmpty ? "$voucherType - $reference" : reference;

    final rawAccount = entry["account"]?.toString() ?? "";
    final accountsToSkip = {"Debtors - CENT", "Receivable - Institutions - KSHPDC"};

    String remarks = accountsToSkip.contains(rawAccount) ? "" : rawAccount;
    remarks = remarks.replaceAll("'", "");

    // Amounts
    final debit = (entry["debit"] ?? 0).toDouble();
    final credit = (entry["credit"] ?? 0).toDouble();
    final balance = (entry["balance"] ?? 0).toDouble();

    rows.writeln('''
  <tr>
    <td>$formattedDate</td>
    <td>$displayReference</td>
    <td><b>$remarks</b></td>
    <td class="amount">₹ ${debit.toStringAsFixed(2)}</td>
    <td class="amount">₹ ${credit.toStringAsFixed(2)}</td>
    <td class="amount">₹ ${balance.toStringAsFixed(2)}</td>
  </tr>
  ''');
  }

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>General Ledger</title>
<style>
  body {
    font-family: Arial, sans-serif;
    font-size: 13px;
    margin: 20px;
    color: #333;
  }
  h2, h4, h5 {
    text-align: center;
    margin: 5px 0;
  }
  hr {
    margin: 15px 0;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
  }
  thead {
    background-color: #f2f2f2;
  }
  th, td {
    border: 1px solid #ccc;
    padding: 6px 8px;
  }
  th {
    text-align: center;
    font-weight: bold;
  }
  td.amount {
    text-align: right;
    font-family: "Courier New", monospace;
  }
  tr:nth-child(even) {
    background-color: #fafafa;
  }
  tr:hover {
    background-color: #f5f5f5;
  }
  .footer {
    text-align: right;
    margin-top: 10px;
    font-size: 11px;
    color: #666;
  }
</style>
</head>
<body>
<div class="print-format-gutter">
  <div class="print-format landscape">
    <h2>Statement of Account</h2>
    <h4>$customerName</h4>
    <h5>Period: $formattedFrom to $formattedTo</h5>
    <hr>
    <table>
      <thead>
        <tr>
          <th style="width: 12%">Date</th>
          <th style="width: 15%">Reference</th>
          <th style="width: 25%">Remarks</th>
          <th style="width: 15%">Debit</th>
          <th style="width: 15%">Credit</th>
          <th style="width: 18%">Balance</th>
        </tr>
      </thead>
      <tbody>
        ${rows.toString()}
      </tbody>
    </table>
    <p class="footer">Printed on $printedOn</p>
  </div>
</div>
</body>
</html>
''';
}

// For Accounts Receivable
String buildAccountsReceivableHtml(
    Map<String, dynamic> report,
    String customerName,
    String postingDate,
    String rangeLabel, // <-- NEW (example: "0–30, 31–60, 61-Above")

    String? letterhead,
    String baseDomain,
    ) {
  final _inrFormatter = NumberFormat('#,##,##0.##', 'en_IN');

  String formatAmount(dynamic value) {
    final number = (value ?? 0).toDouble();
    return _inrFormatter.format(number);
  }
  final rows = report["data"] as List<dynamic>;
  if (rows.isEmpty) {
    return """
  <html>
  <body>
    <h2 style="text-align:center;">Accounts Receivable</h2>
    <p style="text-align:center;">No data available for the selected criteria.</p>
  </body>
  </html>
  """;
  }
  String letterHeadHtml = "";

  if (letterhead != null && letterhead.isNotEmpty) {
    letterHeadHtml = letterhead.replaceAll(
      '/files/',
      'https://$baseDomain.turqosoft.cloud/files/',
    );
  }


  String tableRows = "";
  final columns = report["columns"] as List<dynamic>;

  final rangeColumns = columns.where((c) =>
      c["fieldname"].toString().startsWith("range")
  ).toList();
  String rangeHeaders = "";
  for (var col in rangeColumns) {
    rangeHeaders += "<th>${col["label"]}</th>";
  }
  String rangeCells(Map<String, dynamic> row) {
    return rangeColumns
        .map((c) => "<td style='text-align:right'>₹ ${row[c["fieldname"]] ?? 0}</td>")
        .join();
  }
  String rangeTotals = "";
  for (var col in rangeColumns) {
    final total = rows.fold<double>(
      0,
          (s, r) => s + (r[col["fieldname"]] ?? 0),
    );
    rangeTotals += "<td style='text-align:right'>₹ ${formatAmount(total)}</td>";
  }

  String formatDate(String dateStr) {
    if (dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr); // parses yyyy-mm-dd
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (e) {
      return dateStr; // fallback if parsing fails
    }
  }

  for (var row in rows) {
    tableRows += """
      <tr>
        <td>${formatDate(row["posting_date"] ?? "")}</td>
        <td style="text-align:right">${row["age"] ?? ""}</td>
        <td>${row["voucher_type"] ?? ""}<br>${row["voucher_no"] ?? ""}</td>
        <td>${row["remarks"] ?? ""}</td>
        <td style="text-align:right">₹ ${row["invoiced"] ?? 0}</td>
        <td style="text-align:right">₹ ${row["paid"] ?? 0}</td>
        <td style="text-align:right">₹ ${row["credit_note"] ?? 0}</td>
        <td style="text-align:right">₹ ${row["outstanding"] ?? 0}</td>
${rangeCells(row)}
      </tr>
    """;
  }

  // Add totals
  double totalInv = rows.fold(0.0, (sum, r) => sum + (r["invoiced"] ?? 0));
  double totalPaid = rows.fold(0.0, (sum, r) => sum + (r["paid"] ?? 0));
  double totalCN = rows.fold(0.0, (sum, r) => sum + (r["credit_note"] ?? 0));
  double totalOut = rows.fold(0.0, (sum, r) => sum + (r["outstanding"] ?? 0));

  return """
<!DOCTYPE html>
<html>
<head>
 <meta charset="UTF-8">
 <title>Accounts Receivable</title>
 <style>
 table {
   width: 100%;
   border-collapse: collapse;
   font-size: 10pt;
 }
 th, td {
   border: 1px solid #999;
   padding: 5px;
 }
 th { background-color: #eee; }
 </style>
</head>
<body>
${letterHeadHtml.isNotEmpty ? """
<div class="letter-head-container">
  ${letterHeadHtml.replaceAll('width: 1200.0px;', 'width:100%;')
      .replaceAll('width="1200.0"', 'width="100%"')}
</div>
""" : ""}

<h2 style="text-align:center;">Accounts Receivable</h2>
<div style="text-align:center; font-size:12px; margin-bottom:10px;">
  <b>Customer:</b> $customerName<br>
<b>Due Date Until:</b> ${formatDate(postingDate)}
<b>Aging Range:</b> $rangeLabel
</div>

<table>
<thead>
<tr>
<th>Date</th>
<th>Age</th>
<th>Reference</th>
<th>Remarks</th>
<th>Invoiced</th>
<th>Paid</th>
<th>Credit Note</th>
<th>Outstanding</th>
$rangeHeaders

</tr>
</thead>

<tbody>
$tableRows

<tr>
  <td></td>
  <td></td>
  <td></td>
  <td style="text-align:right"><b>Total</b></td>
<td style="text-align:right">₹ ${formatAmount(totalInv)}</td>
<td style="text-align:right">₹ ${formatAmount(totalPaid)}</td>
<td style="text-align:right">₹ ${formatAmount(totalCN)}</td>
<td style="text-align:right">₹ ${formatAmount(totalOut)}</td>

$rangeTotals



</tr>

</tbody>
</table>

</body>
</html>
""";
}
