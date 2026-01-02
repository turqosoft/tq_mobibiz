// material_request_model.dart
class MaterialRequest {
  final String materialRequestType;
  final String setWarehouse;
  final String scheduleDate;
  final List<MaterialRequestItem> items;

  MaterialRequest({
    required this.materialRequestType,
    required this.setWarehouse,
    required this.scheduleDate,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'material_request_type': materialRequestType,
      'set_warehouse': setWarehouse,
      'schedule_date': scheduleDate,
      'docstatus': 0,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class MaterialRequestItem {
  final String itemCode;
  final String itemName; // New field for item name
  final double qty;

  MaterialRequestItem({
    required this.itemCode,
    required this.itemName, // Update constructor
    required this.qty,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName, // Include in JSON serialization
      'qty': qty,
    };
  }
}
