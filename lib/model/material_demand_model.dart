
// class MaterialDemand {
//   final String scheduleDate;
//   final List<MaterialDemandItem> items;
//   String? user; // New field
//   String? customerInfo; // New field
//   String? territory; // New field
//   String? userTypes; // New field
//
//   MaterialDemand({
//     required this.scheduleDate,
//     required this.items,
//     this.user, // Initialize the new field
//     this.customerInfo, // Initialize the new field
//     this.territory, // Initialize the new field
//     this.userTypes, // Initialize the new field
//   });
//
//   factory MaterialDemand.fromMap(Map<String, dynamic> map) {
//     return MaterialDemand(
//       scheduleDate: map['schedule_date'],
//       items: List<MaterialDemandItem>.from(
//         map['items']?.map((item) => MaterialDemandItem.fromMap(item)) ?? [],
//       ),
//       user: map['user'], // Map the new field
//       customerInfo: map['customer_info'], // Map the new field
//       territory: map['territory'], // Map the new field
//       userTypes: map['user_types'], // Map the new field
//     );
//   }
//
// Map<String, dynamic> toJson() {
//   final Map<String, dynamic> json = {
//     'schedule_date': scheduleDate, // Required field
//     'items': items.map((item) => item.toJson()).toList(), // Required field
//   };
//
//   // Add optional fields if they are not null
//   if (user != null) json['user'] = user;
//   if (customerInfo != null) json['customer_info'] = customerInfo;
//   if (territory != null) json['territory'] = territory;
//   if (userTypes != null) json['user_types'] = userTypes;
//
//   return json;
// }
// }
class MaterialDemand {
  final String scheduleDate;
  final List<MaterialDemandItem> items;
  String? user;
  String? customerInfo;
  String? territory;
  String? userTypes;
  String? purpose; // <-- Add this field

  MaterialDemand({
    required this.scheduleDate,
    required this.items,
    this.user,
    this.customerInfo,
    this.territory,
    this.userTypes,
    this.purpose, // <-- Initialize it
  });

  factory MaterialDemand.fromMap(Map<String, dynamic> map) {
    return MaterialDemand(
      scheduleDate: map['schedule_date'],
      items: List<MaterialDemandItem>.from(
        map['items']?.map((item) => MaterialDemandItem.fromMap(item)) ?? [],
      ),
      user: map['user'],
      customerInfo: map['customer_info'],
      territory: map['territory'],
      userTypes: map['user_types'],
      purpose: map['purpose'], // <-- Map it
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'schedule_date': scheduleDate,
      'items': items.map((item) => item.toJson()).toList(),
    };

    if (user != null) json['user'] = user;
    if (customerInfo != null) json['customer_info'] = customerInfo;
    if (territory != null) json['territory'] = territory;
    if (userTypes != null) json['user_types'] = userTypes;
    if (purpose != null) json['purpose'] = purpose; // <-- Include it

    return json;
  }
}

class MaterialDemandItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final String notes;
  final String uom; // Existing field

  MaterialDemandItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.notes,
    required this.uom, // Initialize the existing field
  });

  factory MaterialDemandItem.fromMap(Map<String, dynamic> map) {
    return MaterialDemandItem(
      itemCode: map['item_code'] ?? '',
      itemName: map['item_name'] ?? '',
      qty: map['qty'] ?? 0.0,
      notes: map['notes'] ?? '',
      uom: map['uom'] ?? '', // Map the existing field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'qty': qty,
      'notes': notes,
      'uom': uom, // Include the existing field in JSON
    };
  }
}

