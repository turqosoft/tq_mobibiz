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
  String? setWarehouse;
  String? applyDiscountOn;
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
    this.setWarehouse,
    this.additionalDiscountPercentage,
    this.applyDiscountOn,
    this.items,
  });

  factory SalesOrderDetails.fromJson(Map<String, dynamic> json) {
    double? _parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return SalesOrderDetails(
      name: json['name'],
      customer: json['customer'],
      setWarehouse: json['set_warehouse'],
      customerName: json['customer_name'],
      deliveryDate: json['delivery_date'],
      transactionDate: json['transaction_date'],
      applyDiscountOn: json['apply_discount_on'],
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


class SalesOrderItem {
  String? rowName;
  String? itemCode;
  String? itemName;
  String? uom;
  String? itemTaxDetails;
  double? qty;
  double? deliveredQty;
  double? pickedQty;
  double? priceListRate;
  double? discountPercentage;
  double? rate;
  double? discountAmount;
  double? distributedDiscountAmount;
  double? netRate;
  double? amount;
  double? netAmount;
  double? igstAmount;
  double? cgstAmount;
  double? sgstAmount;
  double? cessAmount;

  // ✅ Computed GST total
  double get gstAmount =>
      (igstAmount ?? 0) + (cgstAmount ?? 0) + (sgstAmount ?? 0) + (cessAmount ?? 0);
  final String? quotationItem;
  final String? prevdocDocname;


  SalesOrderItem({
    this.rowName,
    this.itemCode,
    this.itemName,
    this.uom,
    this.qty,
    this.deliveredQty,
    this.pickedQty,
    this.itemTaxDetails,
    this.priceListRate,
    this.discountAmount,
    this.discountPercentage,
    this.rate,
    this.distributedDiscountAmount,
    this.netRate,
    this.amount,
    this.netAmount,
    this.quotationItem,
    this.prevdocDocname,
    this.igstAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.cessAmount,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    double? _parse(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    return SalesOrderItem(
      rowName: json['name'],
      itemCode: json['item_code'],
      itemName: json['item_name'],
      uom: json['uom'],
      qty: _parse(json['qty']),
      deliveredQty: _parse(json['delivered_qty']),
      pickedQty: _parse(json['picked_qty']),
      itemTaxDetails: json["item_tax_template"],
      priceListRate: _parse(json['price_list_rate']),
      discountAmount: _parse(json['discount_amount']),
      discountPercentage: _parse(json['discount_percentage']),
      rate: _parse(json['rate']),
      distributedDiscountAmount:
      _parse(json['distributed_discount_amount']),
      netRate: _parse(json['net_rate']),
      amount: _parse(json['amount']),
      netAmount: _parse(json['net_amount']),
      quotationItem: json['quotation_item'],
      prevdocDocname: json['prevdoc_docname'],
      igstAmount: _parse(json['igst_amount']),
      cgstAmount: _parse(json['cgst_amount']),
      sgstAmount: _parse(json['sgst_amount']),
      cessAmount: _parse(json['cess_amount']),

    );
  }
}
