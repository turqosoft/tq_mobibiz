import 'dart:core';
import 'dart:math';

class InvoiceFormatter {
  // ===== Layout tuning (change if needed) =====
  static const int paperWidth = 45; // typical 58mm: 32-42 chars, 80mm: ~48
  // static const int itemW = 24;      // "Item" column width
  // static const int qtyW  = 6;       // "Qty" column width
  // static const int amtW  = 12;      // "Amount" column width
  static const int itemW = 20;   // Item column width
  static const int rateW = 8;    // Rate column width
  static const int qtyW  = 6;    // Qty column width
  static const int amtW  = 11;   // Amount column width
  static String _line([String ch = '-']) =>
      List.filled(paperWidth, ch).join();

  static String _center(String text) {
    if (text.length >= paperWidth) return text.substring(0, paperWidth);
    final pad = ((paperWidth - text.length) / 2).floor();
    return '${' ' * pad}$text';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static String _fmtAmt(dynamic v) =>
      ' ${_toDouble(v).toStringAsFixed(2)}';



  static String _fmtQty(dynamic v) {
    final d = _toDouble(v);
    return (d == d.roundToDouble())
        ? d.toStringAsFixed(0)
        : d.toStringAsFixed(2);
  }

  // static List<String> _wrap(String text, int width) {
  //   if (text.isEmpty) return [''];
  //   final lines = <String>[];
  //   var remaining = text;
  //   while (remaining.length > width) {
  //     lines.add(remaining.substring(0, width));
  //     remaining = remaining.substring(width);
  //   }
  //   lines.add(remaining);
  //   return lines;
  // }
  /// ✅ Improved word-wrap (no chopping words in the middle)
  static List<String> _wrap(String text, int width) {
    if (text.isEmpty) return [''];
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var currentLine = StringBuffer();

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine.clear();
        currentLine.write(word);
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }
    return lines;
  }

  // static String _row(String c1, String c2, String c3) {
  //   final col1 = c1.padRight(itemW).substring(0, itemW);
  //   final col2 = c2.padLeft(qtyW).substring(0, qtyW);
  //   final col3 = c3.padLeft(amtW).substring(0, amtW);
  //   return '$col1$col2$col3';
  // }
  static String _rowWithRate(String c1, String c2, String c3, String c4) {
    final col1 = c1.padRight(itemW).substring(0, itemW);
    final col2 = c2.padLeft(rateW).substring(0, rateW);
    final col3 = c3.padLeft(qtyW).substring(0, qtyW);
    final col4 = c4.padLeft(amtW).substring(0, amtW);
    return '$col1$col2$col3$col4';
  }


  static String _leftRight(String left, String right) {
    // Single-line left/right with tight spacing
    final l = left.length > paperWidth ? left.substring(0, paperWidth) : left;
    final r = right.length > paperWidth ? right.substring(0, paperWidth) : right;
    final spaces = max(1, paperWidth - l.length - r.length);
    return '$l${' ' * spaces}$r';
  }
  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr); // expects yyyy-mm-dd
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}";
    } catch (_) {
      return dateStr; // fallback: print as is if parse fails
    }
  }
  static String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      // ERPNext usually gives "HH:MM:SS.ssssss"
      return timeStr.split('.').first;
    } catch (_) {
      return timeStr; // fallback
    }
  }


  // static String buildInvoiceText(Map<String, dynamic> invoice) {
  //   final buffer = StringBuffer();
  //
  //   // ===== HEADER =====
  //   buffer.writeln(_center("Kerala State Horticultural Products"));
  //   buffer.writeln(_center("Development Corporation"));
  //   buffer.writeln(_center("Invoice"));
  //   buffer.writeln('');
  static String buildInvoiceText(
      Map<String, dynamic> invoice, {
        required String companyName,
      }) {
    final buffer = StringBuffer();

    // ===== HEADER =====
    final wrappedCompany = _wrap(companyName, paperWidth);
    for (final line in wrappedCompany) {
      buffer.writeln(_center(line));
    }

    buffer.writeln(_center("Invoice"));
    buffer.writeln('');


    // ===== INVOICE INFO =====
    buffer.writeln(_leftRight("Receipt No :", "${invoice['name']}"));
    // buffer.writeln(_leftRight("Cashier    :", "${invoice['owner'] ?? ''}"));
    buffer.writeln(
        _leftRight("Cashier    :", "${invoice['owner_fullname'] ?? invoice['owner'] ?? ''}")
    );

    buffer.writeln(_leftRight("Customer   :", "${invoice['customer'] ?? ''}"));
    buffer.writeln(
        _leftRight("Date       :", _formatDate(invoice['posting_date']?.toString()))
    );
    buffer.writeln(
        _leftRight("Time       :", _formatTime(invoice['posting_time']?.toString()))
    );

    buffer.writeln(_line());

    // // ===== ITEMS TABLE (Item | Qty | Amount) =====
    // buffer.writeln(_row('Item', 'Qty', 'Amount'));
    // buffer.writeln(_line());
    //
    // final items = (invoice['items'] as List<dynamic>? ?? []);
    // for (final it in items) {
    //   final name = (it['item_name'] ?? '').toString();
    //   final qty  = _fmtQty(it['qty']);
    //   final amt  = _fmtAmt(it['amount']);
    //
    //   final wrapped = _wrap(name, itemW);
    //   // first line with qty & amount
    //   buffer.writeln(_row(wrapped.first, qty, amt));
    //   // continuation lines (name only)
    //   for (var i = 1; i < wrapped.length; i++) {
    //     buffer.writeln(_row(wrapped[i], '', ''));
    //   }
    // }
// ===== ITEMS TABLE (Item | Rate | Qty | Amount) =====
    buffer.writeln(_rowWithRate('Item', 'Rate', 'Qty', 'Amount'));
    buffer.writeln(_line());

    final items = (invoice['items'] as List<dynamic>? ?? []);
    for (final it in items) {
      final name = (it['item_name'] ?? '').toString();
      final rate = _fmtAmt(it['price_list_rate']); // ✅ New rate
      final qty  = _fmtQty(it['qty']);
      final amt  = _fmtAmt(it['amount']);

      final wrapped = _wrap(name, itemW);
      // first line with rate, qty & amount
      buffer.writeln(_rowWithRate(wrapped.first, rate, qty, amt));
      // continuation lines (name only)
      for (var i = 1; i < wrapped.length; i++) {
        buffer.writeln(_rowWithRate(wrapped[i], '', '', ''));
      }
    }

    buffer.writeln(_line());
// ===== TOTALS =====
    final addlDiscPct = _toDouble(invoice['additional_discount_percentage']);
    final discountAmt = _toDouble(invoice['discount_amount']);
    final total       = _toDouble(invoice['total']);
    final grandTotal  = _toDouble(invoice['grand_total']);
    final rounded     = invoice['rounded_total'] != null
        ? _toDouble(invoice['rounded_total'])
        : grandTotal;

    buffer.writeln(_leftRight('Total', _fmtAmt(total)));

// ✅ Print Discount % only if > 0
    if (addlDiscPct > 0) {
      buffer.writeln(_leftRight('Discount %', '${addlDiscPct.toStringAsFixed(2)}%'));
    }

// ✅ Print Discount Amount only if > 0
    if (discountAmt > 0) {
      buffer.writeln(_leftRight('Discount', _fmtAmt(discountAmt)));
    }

    buffer.writeln(_leftRight('Grand Total', _fmtAmt(grandTotal)));

// ✅ Print Rounded Total only if different from Grand Total
    if (rounded != grandTotal) {
      buffer.writeln(_leftRight('Rounded Total', _fmtAmt(rounded)));
    }

    buffer.writeln(_line());

    // ===== TAX TOTALS =====
    final item = (invoice['items'] as List<dynamic>? ?? []);
    double totalSGST = 0;
    double totalCGST = 0;

    for (final it in items) {
      totalSGST += _toDouble(it['sgst_amount']);
      totalCGST += _toDouble(it['cgst_amount']);
    }

    final totalTaxes = _toDouble(invoice['total_taxes_and_charges']);

    if (totalSGST > 0) {
      buffer.writeln(_leftRight("Total SGST", _fmtAmt(totalSGST)));
    }
    if (totalCGST > 0) {
      buffer.writeln(_leftRight("Total CGST", _fmtAmt(totalCGST)));
    }

    if (totalTaxes > 0) {
      buffer.writeln(_leftRight("Total Taxes", _fmtAmt(totalTaxes)));
    }

    buffer.writeln(_line());


// ===== PAYMENTS =====
    final payments = (invoice['payments'] as List<dynamic>? ?? []);
    for (final p in payments) {
      final amtVal = _toDouble(p['amount']);
      if (amtVal > 0) { // ✅ Print only if amount > 0
        final mode = (p['mode_of_payment'] ?? '').toString();
        final amt  = _fmtAmt(amtVal);
        buffer.writeln(_leftRight(mode, amt));
      }
    }

    final paid   = _toDouble(invoice['paid_amount'] ?? grandTotal);
    final change = _toDouble(invoice['change_amount'] ?? 0);

// ✅ Print Paid only if > 0
    if (paid > 0) {
      buffer.writeln(_leftRight('Paid Amount', _fmtAmt(paid)));
    }

// ✅ Print Change only if > 0
    if (change > 0) {
      buffer.writeln(_leftRight('Change Amount', _fmtAmt(change)));
    }

    buffer.writeln('');

    // ===== FOOTER =====
    buffer.writeln(_center("Thank you, please visit again."));
    // buffer.writeln('\n\n\n'); // feed for tear

    return buffer.toString();
  }
}

