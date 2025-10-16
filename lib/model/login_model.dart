class LoginModel {
  String? message;
  String? homePage;
  String? fullName;


  LoginModel({this.message, this.homePage, this.fullName});

  LoginModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    homePage = json['home_page'];
    fullName = json['full_name'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['message'] = message;
    data['home_page'] = homePage;
    data['full_name'] = fullName;

    return data;
  }
}