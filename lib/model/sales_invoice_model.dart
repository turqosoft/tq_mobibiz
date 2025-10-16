// class SalesInvoiceResponse {
//   final String? name;
//   final String? message;
//   final Map<String, dynamic>? data;

//   SalesInvoiceResponse({
//     this.name,
//     this.message,
//     this.data,
//   });

//   factory SalesInvoiceResponse.fromJson(Map<String, dynamic> json) {
//     return SalesInvoiceResponse(
//       name: json['name'],
//       message: json['message'],
//       data: json['data'],
//     );
//   }
// }

// class Customer {
//   final String name;
//   final String customerName;
//   final String? taxId;
//   final String? paymentTerms;

//   Customer({
//     required this.name,
//     required this.customerName,
//     this.taxId,
//     this.paymentTerms,
//   });

//   factory Customer.fromJson(Map<String, dynamic> json) {
//     return Customer(
//       name: json['name'],
//       customerName: json['customer_name'],
//       taxId: json['tax_id'],
//       paymentTerms: json['payment_terms'],
//     );
//   }
// }






class SalesInvoiceResponse {
  Data? data;

  SalesInvoiceResponse({this.data});

  SalesInvoiceResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? name;


  Data(
      {this.name,

      });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;

    return data;
  }
}

class Items {
  String? name;


  Items(
      {this.name,

      });

  Items.fromJson(Map<String, dynamic> json) {
    name = json['name'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;

    return data;
  }
}

