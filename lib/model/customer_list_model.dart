// class CustomerList {
//   List<Data>? data;

//   CustomerList({this.data});

//   CustomerList.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Data {
//   String? name;
//   String? customerName;
//   Null taxId;
//   String? gstin;
//   String? territory;
//   String? customerPrimaryContact;
//   Null customerPrimaryAddress;
//   Null primaryAddress;
//   String? mobileNo;
//   Null emailId;
//   String? taxCategory;
//   String? customerGroup;

//   Data(
//       {this.name,
//       this.customerName,
//       this.taxId,
//       this.gstin,
//       this.territory,
//       this.customerPrimaryContact,
//       this.customerPrimaryAddress,
//       this.primaryAddress,
//       this.mobileNo,
//       this.emailId,
//       this.taxCategory,
//       this.customerGroup});

//   Data.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     customerName = json['customer_name'];
//     taxId = json['tax_id'];
//     gstin = json['gstin'];
//     territory = json['territory'];
//     customerPrimaryContact = json['customer_primary_contact'];
//     customerPrimaryAddress = json['customer_primary_address'];
//     primaryAddress = json['primary_address'];
//     mobileNo = json['mobile_no'];
//     emailId = json['email_id'];
//     taxCategory = json['tax_category'];
//     customerGroup = json['customer_group'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['customer_name'] = this.customerName;
//     data['tax_id'] = this.taxId;
//     data['gstin'] = this.gstin;
//     data['territory'] = this.territory;
//     data['customer_primary_contact'] = this.customerPrimaryContact;
//     data['customer_primary_address'] = this.customerPrimaryAddress;
//     data['primary_address'] = this.primaryAddress;
//     data['mobile_no'] = this.mobileNo;
//     data['email_id'] = this.emailId;
//     data['tax_category'] = this.taxCategory;
//     data['customer_group']= this.customerGroup;
//     return data;
//   }
// }
class CustomerList {
  List<Data>? data;

  CustomerList({this.data});

  CustomerList.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? name;
  String? customerName;
  String? taxId;
  String? gstin;
  String? territory;
  String? customerPrimaryContact;
  String? customerPrimaryAddress;
  String? primaryAddress;
  String? mobileNo;
  String? emailId;
  String? taxCategory;
  String? customerGroup;
  double? billingThisYear;
  double? totalUnpaid;
  String? latitude;
  String? longitude;
  Data({
    this.name,
    this.customerName,
    this.taxId,
    this.gstin,
    this.territory,
    this.customerPrimaryContact,
    this.customerPrimaryAddress,
    this.primaryAddress,
    this.mobileNo,
    this.emailId,
    this.taxCategory,
    this.customerGroup,
    this.billingThisYear,
    this.totalUnpaid,
    this.latitude,
    this.longitude,
  });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    customerName = json['customer_name'] as String?;
    taxId = json['tax_id'] as String?;
    gstin = json['gstin'] as String?;
    territory = json['territory'] as String?;
    customerPrimaryContact = json['customer_primary_contact'] as String?;
    customerPrimaryAddress = json['customer_primary_address'] as String?;
    primaryAddress = json['primary_address'] as String?;
    mobileNo = json['mobile_no'] as String?;
    emailId = json['email_id'] as String?;
    taxCategory = json['tax_category'] as String?;
    customerGroup = json['customer_group'] as String?;
    billingThisYear = (json['billing_this_year'] ?? 0).toDouble();
    totalUnpaid = (json['total_unpaid'] ?? 0).toDouble();
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['customer_name'] = customerName;
    data['tax_id'] = taxId;
    data['gstin'] = gstin;
    data['territory'] = territory;
    data['customer_primary_contact'] = customerPrimaryContact;
    data['customer_primary_address'] = customerPrimaryAddress;
    data['primary_address'] = primaryAddress;
    data['mobile_no'] = mobileNo;
    data['email_id'] = emailId;
    data['tax_category'] = taxCategory;
    data['customer_group'] = customerGroup;
    data['billing_this_year'] = billingThisYear;
    data['total_unpaid'] = totalUnpaid;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}
