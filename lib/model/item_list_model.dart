class ItemListResponse {
  List<ItemData>? data;

  ItemListResponse({this.data});

  ItemListResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <ItemData>[];
      json['data'].forEach((v) {
        data!.add(ItemData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((v) => v.toJson()).toList(),
    };
  }
}

// class ItemData {
//   String? itemCode;
//   String? itemName;
//   double? valuationRate;
//   String? image;
//   String? brand;
//   String? itemGroup;
//
//   ItemData({
//     this.itemCode,
//     this.itemName,
//     this.valuationRate,
//     this.image,
//     this.brand,
//     this.itemGroup,
//   });
//
//   ItemData.fromJson(Map<String, dynamic> json) {
//     itemCode = json['item_code'];
//     itemName = json['item_name'];
//     valuationRate = json['valuation_rate'];
//     image = json['image'];
//     brand = json['brand'];
//     itemGroup = json['item_group'];
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'item_code': itemCode,
//       'item_name': itemName,
//       'valuation_rate': valuationRate,
//       'image': image,
//       'brand': brand,
//       'item_group': itemGroup,
//     };
//   }
// }
class ItemData {
  String? itemCode;
  String? itemName;
  String? normalizedItemCode; // ✅ new field
  double? valuationRate;
  String? image;
  String? brand;
  String? itemGroup;

  ItemData({
    this.itemCode,
    this.itemName,
    this.normalizedItemCode, // ✅
    this.valuationRate,
    this.image,
    this.brand,
    this.itemGroup,
  });

  ItemData.fromJson(Map<String, dynamic> json) {
    itemCode = json['item_code'];
    itemName = json['item_name'];
    normalizedItemCode = json['normalized_item_code']; // ✅
    valuationRate = json['valuation_rate'];
    image = json['image'];
    brand = json['brand'];
    itemGroup = json['item_group'];
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'normalized_item_code': normalizedItemCode, // ✅
      'valuation_rate': valuationRate,
      'image': image,
      'brand': brand,
      'item_group': itemGroup,
    };
  }
}

