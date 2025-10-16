class AttendanceDetails {
  List<Data>? data;

  AttendanceDetails({this.data});

  AttendanceDetails.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add( Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? employeeName;
  String? status;
  String? attendanceDate;
  String? employee;

  Data({this.employeeName, this.status, this.attendanceDate, this.employee});

  Data.fromJson(Map<String, dynamic> json) {
    employeeName = json['employee_name'];
    status = json['status'];
    attendanceDate = json['attendance_date'];
    employee = json['employee'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['employee_name'] = employeeName;
    data['status'] = status;
    data['attendance_date'] = attendanceDate;
    data['employee'] = employee;
    return data;
  }
}