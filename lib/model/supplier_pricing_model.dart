

class ItemPrice {
  String itemCode; // Made mutable
  String itemName; // Made mutable
  String priceList; // Made mutable
  double priceListRate; // Made mutable
  String? description; // NEW: Optional field

  ItemPrice({
    required this.itemCode,
    required this.itemName,
    required this.priceList,
    required this.priceListRate,
    this.description, // NEW: Optional field
  });

  // Factory method to create an ItemPrice object from JSON
  factory ItemPrice.fromJson(Map<String, dynamic> json) {
    return ItemPrice(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      priceList: json['price_list'],
      priceListRate: json['price_list_rate'],
      description: json['item_name_local'], // NEW: Handle description
    );
  }

  // Convert the ItemPrice object to JSON
  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'price_list': priceList,
      'price_list_rate': priceListRate,
      'item_name_local': description, // NEW: Include description
    };
  }

  // CopyWith method for creating a new instance with modified fields
  ItemPrice copyWith({
    String? itemCode,
    String? itemName,
    String? priceList,
    double? priceListRate,
    String? description, // NEW: Allow updating description
  }) {
    return ItemPrice(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      priceList: priceList ?? this.priceList,
      priceListRate: priceListRate ?? this.priceListRate,
      description: description ?? this.description, // NEW: Update description if provided
    );
  }
}
