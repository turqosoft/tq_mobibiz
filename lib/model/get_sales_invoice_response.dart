class GetSalesInvoiceResponse {
  List<SalesInvoice>? data;

  GetSalesInvoiceResponse({this.data});

  factory GetSalesInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return GetSalesInvoiceResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => SalesInvoice.fromJson(item))
          .toList(),
    );
  }
}

class SalesInvoice {
  String? name;
  String? customer;
  String? postingDate;
  String? dueDate;
  String? status;
  double? grandTotal;

  SalesInvoice({
    this.name,
    this.customer,
    this.postingDate,
    this.dueDate,
    this.status,
    this.grandTotal,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      name: json['name'],
      customer: json['customer'],
      postingDate: json['posting_date'],
      dueDate: json['due_date'],
      status: json['status'],
      grandTotal: (json['grand_total'] is int)
          ? (json['grand_total'] as int).toDouble()
          : json['grand_total'],
    );
  }
}
