class UserDetails {
  List<Data>? data;

  UserDetails({this.data});

  UserDetails.fromJson(Map<String, dynamic> json) {
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
  String? email;
  String? fullName;

  Data({this.name, this.email, this.fullName});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    fullName = json['full_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['full_name'] = this.fullName;
    return data;
  }
}