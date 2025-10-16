class LoginNewModel {
  Message? message;
  String? homePage;
  String? fullName;

  LoginNewModel({this.message, this.homePage, this.fullName});

  LoginNewModel.fromJson(Map<String, dynamic> json) {
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
    homePage = json['home_page'];
    fullName = json['full_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    data['home_page'] = this.homePage;
    data['full_name'] = this.fullName;
    return data;
  }
}

class Message {
  int? statusCode;
  String? text;
  String? user;
  String? token;

  Message({this.statusCode, this.text, this.user, this.token});

  Message.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    text = json['text'];
    user = json['user'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status_code'] = this.statusCode;
    data['text'] = this.text;
    data['user'] = this.user;
    data['token'] = this.token;
    return data;
  }
}
