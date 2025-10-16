class EmployeeDetails {
  List<Data>? data;

  EmployeeDetails({this.data});

  EmployeeDetails.fromJson(Map<String, dynamic> json) {
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
  String? employeeName;
  String? leaveApprover;
  String? expenseApprover;
  String? userId;

  Data(
      {this.name,
      this.employeeName,
      this.leaveApprover,
      this.expenseApprover,
      this.userId});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    employeeName = json['employee_name'];
    leaveApprover = json['leave_approver'];
    expenseApprover = json['expense_approver'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['employee_name'] = this.employeeName;
    data['leave_approver'] = this.leaveApprover;
    data['expense_approver'] = this.expenseApprover;
    data['user_id'] = this.userId;
    return data;
  }
}