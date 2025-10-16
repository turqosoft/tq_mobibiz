// class HomeTileResponse {
//   List<Message>? message;

//   HomeTileResponse({this.message});

//   HomeTileResponse.fromJson(Map<String, dynamic> json) {
//     if (json['message'] != null) {
//       message = <Message>[];
//       json['message'].forEach((v) {
//         message!.add(new Message.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.message != null) {
//       data['message'] = this.message!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Message {
//   String? parent;
//   String? tqMenuItem;
//   String? tqMenuGroup;

//   Message({this.parent, this.tqMenuItem, this.tqMenuGroup});

//   Message.fromJson(Map<String, dynamic> json) {
//     parent = json['parent'];
//     tqMenuItem = json['tq_menu_item'];
//     tqMenuGroup = json['tq_menu_group'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['parent'] = this.parent;
//     data['tq_menu_item'] = this.tqMenuItem;
//     data['tq_menu_group'] = this.tqMenuGroup;
//     return data;
//   }
// }
class HomeTileResponse {
  List<Message>? message;

  HomeTileResponse({this.message});

  HomeTileResponse.fromJson(Map<String, dynamic> json) {
    if (json['message'] != null) {
      message = <Message>[];
      json['message'].forEach((v) {
        message!.add(Message.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (message != null) {
      data['message'] = message!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Message {
  String? tqMenuItem;  // Maps to "menu_id"
  String? tqMenuGroup; // Maps to "parent_group"

  Message({this.tqMenuItem, this.tqMenuGroup});

  Message.fromJson(Map<String, dynamic> json) {
    tqMenuItem = json['menu_id'];       // Correct mapping
    tqMenuGroup = json['parent_group']; // Correct mapping
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': tqMenuItem,
      'parent_group': tqMenuGroup,
    };
  }
}
