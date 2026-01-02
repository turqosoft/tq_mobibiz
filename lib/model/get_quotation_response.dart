class GetQuotationResponse {
  List<QuotationData>? data;

  GetQuotationResponse({this.data});

  GetQuotationResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <QuotationData>[];
      json['data'].forEach((v) {
        data!.add(QuotationData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class QuotationData {
  String? name;
  String? title;
  String? transactionDate;
  String? validTill;
  String? status;

  QuotationData({
    this.name,
    this.title,
    this.transactionDate,
    this.validTill,
    this.status,
  });

  QuotationData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    title = json['title'];
    transactionDate = json['transaction_date'];
    validTill = json['valid_till'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['title'] = title;
    data['transaction_date'] = transactionDate;
    data['valid_till'] = validTill;
    data['status'] = status;
    return data;
  }
}
