class StockReconciliation {
  int docstatus;
  String purpose;
  List<StockItem> items;

  StockReconciliation({
    this.docstatus = 0,
    this.purpose = "Stock Reconciliation",
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'docstatus': docstatus,
      'purpose': purpose,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class StockItem {
  String itemCode;
  String itemName;
  String warehouse;
  double qty;
  double valuationRate;

  StockItem({
    required this.itemCode,
    required this.itemName,
    required this.warehouse,
    required this.qty,
    required this.valuationRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'warehouse': warehouse,
      'qty': qty,
      'valuation_rate': valuationRate,
    };
  }
}
