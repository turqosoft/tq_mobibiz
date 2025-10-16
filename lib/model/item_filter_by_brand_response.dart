class ItemBrandResponse {
  List<Data>? data;

  ItemBrandResponse({this.data});

  ItemBrandResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? itemCode;
  String? itemName;
  double? valuationRate;
  String? image;
  String? brand;

  Data(
      {this.itemCode,
      this.itemName,
      this.valuationRate,
      this.image,
      this.brand});

  Data.fromJson(Map<String, dynamic> json) {
    itemCode = json['item_code'];
    itemName = json['item_name'];
    valuationRate = json['valuation_rate'];
    image = json['image'];
    brand = json['brand'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['item_code'] = this.itemCode;
    data['item_name'] = this.itemName;
    data['valuation_rate'] = this.valuationRate;
    data['image'] = this.image;
    data['brand'] = this.brand;
    return data;
  }
}