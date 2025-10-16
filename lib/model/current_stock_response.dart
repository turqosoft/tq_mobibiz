class CurrentStockResponse {
  List<Message>? message;

  CurrentStockResponse({this.message});

  CurrentStockResponse.fromJson(Map<String, dynamic> json) {
    if (json['message'] != null) {
      message = <Message>[];
      json['message'].forEach((v) {
        message!.add(new Message.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Message {
  String? itemCode;
  String? warehouse;
  double? projectedQty;
  double? reservedQty;
  double? reservedQtyForProduction;
  double? reservedQtyForSubContract;
  double? actualQty;
  double? valuationRate;
  String? itemName;
  int? disableQuickEntry;
  double? reservedStock;

  Message(
      {this.itemCode,
      this.warehouse,
      this.projectedQty,
      this.reservedQty,
      this.reservedQtyForProduction,
      this.reservedQtyForSubContract,
      this.actualQty,
      this.valuationRate,
      this.itemName,
      this.disableQuickEntry,
      this.reservedStock});

  Message.fromJson(Map<String, dynamic> json) {
    itemCode = json['item_code'];
    warehouse = json['warehouse'];
    projectedQty = json['projected_qty'];
    reservedQty = json['reserved_qty'];
    reservedQtyForProduction = json['reserved_qty_for_production'];
    reservedQtyForSubContract = json['reserved_qty_for_sub_contract'];
    actualQty = json['actual_qty'];
    valuationRate = json['valuation_rate'];
    itemName = json['item_name'];
    disableQuickEntry = json['disable_quick_entry'];
    reservedStock = json['reserved_stock'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['item_code'] = this.itemCode;
    data['warehouse'] = this.warehouse;
    data['projected_qty'] = this.projectedQty;
    data['reserved_qty'] = this.reservedQty;
    data['reserved_qty_for_production'] = this.reservedQtyForProduction;
    data['reserved_qty_for_sub_contract'] = this.reservedQtyForSubContract;
    data['actual_qty'] = this.actualQty;
    data['valuation_rate'] = this.valuationRate;
    data['item_name'] = this.itemName;
    data['disable_quick_entry'] = this.disableQuickEntry;
    data['reserved_stock'] = this.reservedStock;
    return data;
  }
}
