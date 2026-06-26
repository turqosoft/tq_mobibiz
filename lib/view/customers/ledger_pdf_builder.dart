import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// // For General Ledger
// String BuildLedgerHtml(
//     Map<String, dynamic> ledgerJson,
//     String fromDate,
//     String toDate,
//     {String? fallbackCustomerName}) {
//
//   final results = (ledgerJson["message"]?["data"] as List<dynamic>?) ?? [];
//
// // Remove completely empty rows only
//   final trimmedResults = results.where((row) {
//     final hasAmount = (row["debit"] ?? 0) != 0 ||
//         (row["credit"] ?? 0) != 0 ||
//         (row["balance"] ?? 0) != 0;
//     final hasAccount = row["account"] != null;
//     return hasAmount || hasAccount;
//   }).toList();
//   // List<dynamic> reportRows = [];
//   List<dynamic> reportRows = trimmedResults;
//
//   if (trimmedResults.length > 3) {
//     reportRows = trimmedResults.sublist(1, trimmedResults.length - 2);
//   }
//
//   final printedOn = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());
//
//   // Format incoming fromDate & toDate
//   String formatDate(String date) {
//     try {
//       final parsed = DateTime.parse(date);
//       return DateFormat("dd-MM-yyyy").format(parsed);
//     } catch (_) {
//       return date;
//     }
//   }
//
//   final formattedFrom = formatDate(fromDate);
//   final formattedTo = formatDate(toDate);
//
//   String customerName = fallbackCustomerName ?? "";
//
//   final rows = StringBuffer();
//
// // Use a Set to keep track of unique entries
//   final seen = <String>{};
//
//   // for (var entry in trimmedResults) {
//   // for (int i = 0; i < trimmedResults.length; i++) {
//   //   final entry = trimmedResults[i];
//   for (int i = 0; i < reportRows.length; i++) {
//     final entry = reportRows[i];
//
//     // Build a unique key for each row (based on account + debit + credit + balance)
//     // You can add more fields if needed to make uniqueness stricter
//     final uniqueKey = jsonEncode({
//       "account": entry["account"],
//       "debit": entry["debit"],
//       "credit": entry["credit"],
//       "balance": entry["balance"],
//     });
//
//     // Format date
//     final rawDate = entry["posting_date"] ?? "";
//     String formattedDate = rawDate;
//     if (rawDate is String && rawDate.isNotEmpty) {
//       try {
//         final parsedDate = DateTime.parse(rawDate);
//         formattedDate = DateFormat("dd-MM-yyyy").format(parsedDate);
//       } catch (_) {
//         formattedDate = rawDate;
//       }
//     }
//
// // Reference: voucher_type first, then voucher_no
//     final voucherType = entry["voucher_type"] ?? "";
//     final reference = entry["voucher_no"] ?? "";
//     final displayReference =
//     voucherType.isNotEmpty ? "$voucherType - $reference" : reference;
//
// // Remarks (to be shown under Reference)
//     final rawAccount = entry["account"]?.toString() ?? "";
//     final accountsToSkip = {"Debtors - CENT", "Receivable - Institutions - KSHPDC"};
//
//     String remarks = accountsToSkip.contains(rawAccount) ? "" : rawAccount;
//     remarks = remarks.replaceAll("'", "");
//
//     // final isTopRow = i == 0;
//     // final isLastTwoRows = i >= trimmedResults.length - 2;
//     // final isBoldReference = isTopRow || isLastTwoRows;
//     final accountName = entry["account"]?.toString().replaceAll("'", "") ?? "";
//
//     final isSummaryRow =
//         accountName == "Opening" ||
//             accountName == "Total" ||
//             accountName.startsWith("Closing");
//
//     final isBoldReference = isSummaryRow;
//
// // Combine Reference + Remarks
//     final combinedReference = remarks.isNotEmpty
//         ? '''
//       <div style="
//         font-weight: ${isBoldReference ? 'bold' : 'normal'};
//         color: ${isBoldReference ? '#000' : '#333'};
//       ">
//         $displayReference
//       </div>
//       <div style="
//         font-size: 11px;
//         font-weight: ${isBoldReference ? 'bold' : 'normal'};
//         color: ${isBoldReference ? '#000' : '#666'};
//         margin-top: 2px;
//       ">
//         $remarks
//       </div>
//     '''
//         : '''
//       <div style="
//         font-weight: ${isBoldReference ? 'bold' : 'normal'};
//         color: ${isBoldReference ? '#000' : '#333'};
//       ">
//         $displayReference
//       </div>
//     ''';
//
//
//     // Amounts
//     final debit = (entry["debit"] ?? 0).toDouble();
//     final credit = (entry["credit"] ?? 0).toDouble();
//     final balance = (entry["balance"] ?? 0).toDouble();
//
//     rows.writeln('''
// <tr>
//   <td>$formattedDate</td>
//   <td>$combinedReference</td>
//   <td class="amount">₹ ${debit.toStringAsFixed(2)}</td>
//   <td class="amount">₹ ${credit.toStringAsFixed(2)}</td>
//   <td class="amount">₹ ${balance.toStringAsFixed(2)}</td>
// </tr>
// ''');
//
//   }
//
//   return '''
// <!DOCTYPE html>
// <html lang="en">
// <head>
// <meta charset="utf-8">
// <title>General Ledger</title>
// <style>
//   body {
//     font-family: Arial, sans-serif;
//     font-size: 13px;
//     margin: 20px;
//     color: #333;
//   }
//   h2, h4, h5 {
//     text-align: center;
//     margin: 5px 0;
//   }
//   hr {
//     margin: 15px 0;
//   }
//   table {
//     width: 100%;
//     border-collapse: collapse;
//     margin-top: 10px;
//   }
//   thead {
//     background-color: #f2f2f2;
//   }
//   th, td {
//     border: 1px solid #ccc;
//     padding: 6px 8px;
//   }
//   th {
//     text-align: center;
//     font-weight: bold;
//   }
//   td.amount {
//     text-align: right;
//     font-family: "Courier New", monospace;
//   }
//   tr:nth-child(even) {
//     background-color: #fafafa;
//   }
//   tr:hover {
//     background-color: #f5f5f5;
//   }
//   .footer {
//     text-align: right;
//     margin-top: 10px;
//     font-size: 11px;
//     color: #666;
//   }
// </style>
// </head>
// <body>
// <div class="print-format-gutter">
//   <div class="print-format landscape">
//     <h2>Statement of Account</h2>
//     <h4>$customerName</h4>
//     <h5>Period: $formattedFrom to $formattedTo</h5>
//     <hr>
//     <table>
// <thead>
//   <tr>
//     <th style="width: 12%">Date</th>
//     <th style="width: 40%">Reference</th>
//     <th style="width: 16%">Debit</th>
//     <th style="width: 16%">Credit</th>
//     <th style="width: 16%">Balance</th>
//   </tr>
// </thead>
//
//       <tbody>
//         ${rows.toString()}
//       </tbody>
//     </table>
//     <p class="footer">Printed on $printedOn</p>
//   </div>
// </div>
// </body>
// </html>
// ''';
// }
String BuildLedgerHtml(
    Map<String, dynamic> ledgerJson,
    String fromDate,
    String toDate, {
      String? fallbackCustomerName,
    }) {
  final results =
      (ledgerJson["message"]?["data"] as List<dynamic>?) ?? [];

  String formatDate(String date) {
    try {
      return DateFormat(
        "dd-MM-yyyy",
      ).format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String formatAmount(dynamic value) {
    final amount = (value ?? 0).toDouble();

    if (amount == 0) return "";

    return "₹ ${amount.toStringAsFixed(4)}";
  }

  final formattedFrom = formatDate(fromDate);
  final formattedTo = formatDate(toDate);

  final printedOn =
  DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.now());

  String customerName = fallbackCustomerName ?? "";

  Map<String, dynamic>? openingRow;
  Map<String, dynamic>? totalRow;
  Map<String, dynamic>? closingRow;

  final transactionRows = <dynamic>[];

  for (final row in results) {
    final account =
    (row["account"] ?? "")
        .toString()
        .replaceAll("'", "")
        .trim();

    if (account == "Opening") {
      openingRow ??= row;
    } else if (account == "Total") {
      totalRow ??= row;
    } else if (account.startsWith("Closing")) {
      closingRow ??= row;
    } else if (row["voucher_no"] != null) {
      transactionRows.add(row);
    }
  }

  final rows = StringBuffer();

  // Opening Row
  if (openingRow != null) {
    rows.writeln('''
<tr>
  <td>$formattedFrom</td>
  <td><strong>Opening</strong></td>
  <td class="amount">${formatAmount(openingRow["debit"])}</td>
  <td class="amount">${formatAmount(openingRow["credit"])}</td>
  <td class="amount">${formatAmount(openingRow["balance"])}</td>
</tr>
''');
  }

  // Transaction Rows
  // for (final entry in transactionRows) {
  final Map<String, Map<String, dynamic>> groupedRows = {};

  for (final entry in transactionRows) {
    final key =
        '${entry["posting_date"]}_${entry["voucher_type"]}_${entry["voucher_no"]}';

    if (!groupedRows.containsKey(key)) {
      groupedRows[key] = {
        "posting_date": entry["posting_date"],
        "voucher_type": entry["voucher_type"],
        "voucher_no": entry["voucher_no"],
        "debit": 0.0,
        "credit": 0.0,
        "balance": entry["balance"],
      };
    }

    groupedRows[key]!["debit"] =
        (groupedRows[key]!["debit"] as double) +
            ((entry["debit"] ?? 0).toDouble());

    groupedRows[key]!["credit"] =
        (groupedRows[key]!["credit"] as double) +
            ((entry["credit"] ?? 0).toDouble());

    // Keep latest balance
    groupedRows[key]!["balance"] =
        (entry["balance"] ?? 0).toDouble();
  }
  for (final entry in groupedRows.values) {
    String postingDate = "";

    if (entry["posting_date"] != null) {
      try {
        postingDate = DateFormat(
          "dd-MM-yyyy",
        ).format(DateTime.parse(entry["posting_date"]));
      } catch (_) {}
    }

    final voucherType = entry["voucher_type"] ?? "";
    final voucherNo = entry["voucher_no"] ?? "";

    final voucherDetails =
    voucherType.isNotEmpty
        ? "$voucherType $voucherNo"
        : voucherNo;

    rows.writeln('''
<tr>
<td class="date-column">$postingDate</td>
<td class="voucher-column">$voucherDetails</td>
  <td class="amount">${formatAmount(entry["debit"])}</td>
  <td class="amount">${formatAmount(entry["credit"])}</td>
  <td class="amount">${formatAmount(entry["balance"])}</td>
</tr>
''');
  }

  // Total Row
  if (totalRow != null) {
    rows.writeln('''
<tr class="total-row">
  <td></td>
  <td><strong>Total</strong></td>
  <td class="amount"><strong>${formatAmount(totalRow["debit"])}</strong></td>
  <td class="amount"><strong>${formatAmount(totalRow["credit"])}</strong></td>
  <td class="amount"><strong>${formatAmount(totalRow["balance"])}</strong></td>
</tr>
''');
  }

  // Closing Row
  if (closingRow != null) {
    final closingBalance =
    (closingRow["balance"] ?? 0).toDouble();

    final balanceText =
        "₹ ${NumberFormat('#,##0.0000').format(closingBalance)}";

    rows.writeln('''
<tr class="closing-row">
  <td></td>
  <td><strong>Closing [Opening + Total]</strong></td>
  <td class="amount">
    ${formatAmount(closingRow["debit"])}
  </td>
  <td class="amount">
    ${formatAmount(closingRow["credit"])}
  </td>
  <td class="amount">
    <strong>$balanceText</strong>
  </td>
</tr>
''');
  }

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>General Ledger</title>

<style>

body {
  font-family: Arial, sans-serif;
  margin: 12px;
  font-size: 13px;
  color: #222;
}

h2 {
  text-align: center;
  margin-bottom: 4px;
}

h4 {
  text-align: center;
  margin: 4px 0;
}

h5 {
  text-align: center;
  margin: 4px 0 12px 0;
  font-weight: normal;
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead th {
  background: #efefef;
  color: #666;
  font-weight: normal;
  text-align: left;
  padding: 10px;
  border: 1px solid #d9d9d9;
}

tbody td {
  padding: 10px;
  border: 1px solid #eeeeee;
}
.voucher-column {
  word-wrap: break-word;
  overflow-wrap: break-word;
  white-space: normal;
}
.amount {
  text-align: right;
  white-space: nowrap;
}

.total-row td {
  font-weight: bold;
  background: #fafafa;
}

.closing-row td {
  font-weight: bold;
  border-top: 1px solid #ddd;
  padding-top: 12px;
}
.closing-row .amount {
  font-size: 18px;
}
.closing-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer {
  text-align: right;
  margin-top: 12px;
  font-size: 11px;
  color: #555;
}

</style>
</head>

<body>

<h2>Statement of Account</h2>

<h4>$customerName</h4>

<h5>
Period: $formattedFrom to $formattedTo
</h5>

<table>

<thead>
<tr>
<th style="width:12%">Date</th>
<th style="width:43%">Reference</th>
<th style="width:15%; text-align:right;">Debit</th>
<th style="width:15%; text-align:right;">Credit</th>
<th style="width:15%; text-align:right;">Balance</th>
</tr>
</thead>

<tbody>
${rows.toString()}
</tbody>

</table>

<div class="footer">
Printed on $printedOn
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
    String companyName,
    String fullName,
    String? letterhead,
    // String baseDomain,
    String baseHost,
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

  // if (letterhead != null && letterhead.isNotEmpty) {
  //   letterHeadHtml = letterhead.replaceAll(
  //     '/files/',
  //     'https://$baseDomain.frappe.cloud/files/',
  //   );
  // }
  if (letterhead != null && letterhead.isNotEmpty) {
    // ✅ Check if it's a raw image path (starts with /files/)
    if (letterhead.startsWith('/files/')) {
      // Build a full <img> tag from the image path
      letterHeadHtml = """
        <div style="text-align:center; margin-bottom: 10px;">
          <img src="$baseHost$letterhead" style="max-width:100%; height:auto;" />
        </div>
      """;
    } else {
      // It's HTML content — replace relative /files/ paths with absolute URLs
      letterHeadHtml = letterhead.replaceAll(
        '/files/',
        '$baseHost/files/',
      );
    }
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
    <td>
      ${row["voucher_type"] ?? ""}<br>
      ${row["voucher_no"] ?? ""}
    </td>
    <td>${formatDate(row["due_date"] ?? "")}</td>
    <td style="text-align:right">₹ ${formatAmount(row["outstanding"] ?? 0)}</td>
    <td style="text-align:right">${row["age"] ?? ""}</td>
  </tr>
  """;
  }


  // Add totals
  double totalOutstanding =
  rows.fold(0.0, (sum, r) => sum + (r["outstanding"] ?? 0));
  final String overdueDate = formatDate(postingDate);

  String reminderHtml = """
<div style="
  border: 1px solid #999;
  padding: 10px;
  margin: 12px 0;
  font-size: 11pt;
  background-color: #f9f9f9;
">
  Hello! This is a reminder that your account balance of
  <b>₹ ${formatAmount(totalOutstanding)}</b>
  was overdue as of
  <b>$overdueDate</b>.
  Please find the Receivable for your reference.
  If you have any queries regarding this account,
  please contact our office as soon as possible.
</div>
""";
  String footerHtml = """
<div style="
  margin-top: 40px;
  font-size: 11pt;
  text-align: left;
">
  Regards,<br>
  
  <div style="height: 10px;"></div>

  <b>$fullName</b><br>
  <b>$companyName</b><br><br>
</div>
""";


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
<b>Date:</b> ${formatDate(postingDate)}
</div>
$reminderHtml
<table>
<colgroup>
  <col style="width:12%">   <!-- Date -->
  <col style="width:38%">   <!-- Reference (WIDER) -->
  <col style="width:15%">   <!-- Due Date -->
  <col style="width:20%">   <!-- Outstanding -->
  <col style="width:8%">    <!-- Overdue by days (NARROWER) -->
</colgroup>
<thead>
<tr>
  <th>Date</th>
  <th>Reference</th>
  <th>Due Date</th>
  <th style="text-align:right">Outstanding</th>
  <th style="text-align:right">Overdue by days</th>
</tr>
</thead>



<tbody>
$tableRows

<tr>
  <td colspan="3" style="text-align:right"><b>Total</b></td>
  <td style="text-align:right"><b>₹ ${formatAmount(totalOutstanding)}</b></td>
  <td></td>
</tr>



</tbody>
</table>
$footerHtml

</body>
</html>
""";
}
