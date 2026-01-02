class GetSalesOrderResponse {
  List<Data>? data;

  GetSalesOrderResponse({this.data});

  GetSalesOrderResponse.fromJson(Map<String, dynamic> json) {
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
  String? name;
  String? customerName;
  String? customer;
  String? deliveryDate;
  String? creation;
  String? status;
  String? transactionDate;
  double? grandTotal;
  double? roundedTotal;

  Data(
      {this.name,
      this.customer,
      this.deliveryDate,
      this.creation,
      this.status,
      this.transactionDate,
      this.grandTotal,
      this.roundedTotal,
      });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    customerName = json['customer_name'];
    customer = json['customer'];
    deliveryDate = json['delivery_date'];
    creation = json['creation'];
    status = json['status'];
    transactionDate = json['transaction_date'];
    grandTotal = (json['grand_total'] != null)
        ? double.tryParse(json['grand_total'].toString())
        : null;
    roundedTotal = (json['rounded_total'] != null)
        ? double.tryParse(json['rounded_total'].toString())
        : null;
  }
  double get displayTotal {
    if (roundedTotal != null && roundedTotal! > 0) {
      return roundedTotal!;
    }
    return grandTotal ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['customer_name'] = this.customerName;
    data['customer'] = this.customer;
    data['delivery_date'] = this.deliveryDate;
    data['creation'] = this.creation;
    data['status'] = this.status;
    data['transaction_date'] = this.transactionDate;
    return data;
  }
}
class SalesOrderDetails {
  String? name;
  String? customer;
  String? customerName;
  String? deliveryDate;
  String? transactionDate;
  String? status;
  double? netTotal;
  double? roundedTotal;
  double? total;
  double? grandTotal;
  double? totalTaxesAndCharges;
  double? discountAmount;
  double? additionalDiscountPercentage;
  List<SalesOrderItem>? items;

  SalesOrderDetails({
    this.name,
    this.customer,
    this.customerName,
    this.deliveryDate,
    this.transactionDate,
    this.status,
    this.netTotal,
    this.grandTotal,
    this.roundedTotal,
    this.total,
    this.totalTaxesAndCharges,
    this.discountAmount,
    this.additionalDiscountPercentage,
    this.items,
  });

  factory SalesOrderDetails.fromJson(Map<String, dynamic> json) {
    double? _parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return SalesOrderDetails(
      name: json['name'],
      customer: json['customer'],
      customerName: json['customer_name'],
      deliveryDate: json['delivery_date'],
      transactionDate: json['transaction_date'],
      status: json['status'],
      netTotal: (json['net_total'] != null)
          ? double.tryParse(json['net_total'].toString())
          : null,
      total: (json['total'] != null)
          ? double.tryParse(json['total'].toString())
          : null,
      grandTotal: (json['grand_total'] != null)
          ? double.tryParse(json['grand_total'].toString())
          : null,
      roundedTotal: (json['rounded_total'] != null)
          ? double.tryParse(json['rounded_total'].toString())
          : null,
      totalTaxesAndCharges: _parse(json['total_taxes_and_charges']),
      discountAmount: _parse(json['discount_amount']),
      additionalDiscountPercentage:
      _parse(json['additional_discount_percentage']),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SalesOrderItem.fromJson(e))
          .toList() ??
          [],
    );
  }
  double get displayTotal {
    if (roundedTotal != null && roundedTotal! > 0) {
      return roundedTotal!;
    }
    return grandTotal ?? 0.0;
  }
}

// class SalesOrderItem {
//   String? itemCode;
//   String? itemName;
//   double? qty;
//   double? rate;
//   double? amount;
//
//
//   SalesOrderItem({this.itemCode, this.itemName, this.qty, this.rate, this.amount});
//
//   factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
//     return SalesOrderItem(
//       itemCode: json['item_code'],
//       itemName: json['item_name'],
//       qty: (json['qty'] ?? 0).toDouble(),
//       rate: (json['rate'] ?? 0).toDouble(),
//       amount: (json['amount'] as num?)?.toDouble(),
//
//     );
//   }
// }

class SalesOrderItem {
  String? itemCode;
  String? itemName;
  String? uom;

  double? qty;
  double? priceListRate;
  double? discountPercentage;
  double? rate;
  double? distributedDiscountAmount;
  double? netRate;
  double? amount;

  SalesOrderItem({
    this.itemCode,
    this.itemName,
    this.uom,
    this.qty,
    this.priceListRate,
    this.discountPercentage,
    this.rate,
    this.distributedDiscountAmount,
    this.netRate,
    this.amount,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    double? _parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    return SalesOrderItem(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      uom: json['uom'],
      qty: _parse(json['qty']),
      priceListRate: _parse(json['price_list_rate']),
      discountPercentage: _parse(json['discount_percentage']),
      rate: _parse(json['rate']),
      distributedDiscountAmount:
      _parse(json['distributed_discount_amount']),
      netRate: _parse(json['net_rate']),
      amount: _parse(json['amount']),
    );
  }
}
