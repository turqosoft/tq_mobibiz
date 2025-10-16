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

  Data(
      {this.name,
      this.customer,
      this.deliveryDate,
      this.creation,
      this.status,
      this.transactionDate});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    customerName = json['customer_name'];
    customer = json['customer'];
    deliveryDate = json['delivery_date'];
    creation = json['creation'];
    status = json['status'];
    transactionDate = json['transaction_date'];
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
    this.items,
  });

  factory SalesOrderDetails.fromJson(Map<String, dynamic> json) {
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
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SalesOrderItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class SalesOrderItem {
  String? itemCode;
  String? itemName;
  double? qty;
  double? rate;
  double? amount;


  SalesOrderItem({this.itemCode, this.itemName, this.qty, this.rate, this.amount});

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      qty: (json['qty'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),

    );
  }
}
