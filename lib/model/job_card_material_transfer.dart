class MaterialTransfer {
  final String stockEntryType;
  final String workOrder;
  final String bomNo;
  final String jobCard;
  final List<MaterialTransferItem> items;

  MaterialTransfer({
    required this.stockEntryType,
    required this.workOrder,
    required this.bomNo,
    required this.jobCard,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'stock_entry_type': stockEntryType,
        'work_order': workOrder,
        'bom_no': bomNo,
        'job_card': jobCard,
        'items': items.map((item) => item.toJson()).toList(),
      },
    };
  }
}

class MaterialTransferItem {
  final String sWarehouse;
  final String tWarehouse;
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final String jobCardItem;

  MaterialTransferItem({
    required this.sWarehouse,
    required this.tWarehouse,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.jobCardItem,
  });

  Map<String, dynamic> toJson() {
    return {
      's_warehouse': sWarehouse,
      't_warehouse': tWarehouse,
      'item_code': itemCode,
      'item_name': itemName,
      'qty': qty,
      'uom': uom,
      'job_card_item': jobCardItem,
    };
  }
}
