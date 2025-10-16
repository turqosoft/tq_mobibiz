import 'dart:convert';

import 'package:intl/intl.dart';

String buildLedgerHtml(
    Map<String, dynamic> ledgerJson,
    String fromDate,
    String toDate,
    {String? fallbackCustomerName}) {

  // final results = (ledgerJson["message"]?["result"] as List<dynamic>?) ?? [];
  final results = (ledgerJson["message"]?["data"] as List<dynamic>?) ?? [];

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
  for (var row in results) {
    if (row["party"] != null && row["party"].toString().isNotEmpty) {
      customerName = row["party"];
      break;
    }
  }

  final rows = StringBuffer();

// Use a Set to keep track of unique entries
  final seen = <String>{};

  for (var entry in results) {
    // Build a unique key for each row (based on account + debit + credit + balance)
    // You can add more fields if needed to make uniqueness stricter
    final uniqueKey = jsonEncode({
      "account": entry["account"],
      "debit": entry["debit"],
      "credit": entry["credit"],
      "balance": entry["balance"],
    });

    // Skip if this row was already seen
    if (seen.contains(uniqueKey)) continue;
    seen.add(uniqueKey);

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
