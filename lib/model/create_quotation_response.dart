class CreateQuotationResponse {
  Data? data;

  CreateQuotationResponse({this.data});

  CreateQuotationResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? name;
  String? title;
  String? status;

  Data({this.name, this.title, this.status});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    title = json['title'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['title'] = title;
    data['status'] = status;
    return data;
  }
}
