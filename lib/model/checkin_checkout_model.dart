// class CheckInCheckOut {
//   Data? data;

//   CheckInCheckOut({this.data});

//   CheckInCheckOut.fromJson(Map<String, dynamic> json) {
//     data = json['data'] != null ? new Data.fromJson(json['data']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.toJson();
//     }
//     return data;
//   }
// }

// class Data {
//   String? name;
//   String? owner;
//   String? creation;
//   String? modified;
//   String? modifiedBy;
//   int? docstatus;
//   int? idx;
//   String? employee;
//   String? employeeName;
//   String? logType;
//   String? time;
//   int? skipAutoAttendance;
//   String? longitude;
//   String? latitude;
//   String? doctype;

//   Data(
//       {this.name,
//       this.owner,
//       this.creation,
//       this.modified,
//       this.modifiedBy,
//       this.docstatus,
//       this.idx,
//       this.employee,
//       this.employeeName,
//       this.logType,
//       this.time,
//       this.skipAutoAttendance,
//       this.longitude,
//       this.latitude,
//       this.doctype});

//   Data.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     owner = json['owner'];
//     creation = json['creation'];
//     modified = json['modified'];
//     modifiedBy = json['modified_by'];
//     docstatus = json['docstatus'];
//     idx = json['idx'];
//     employee = json['employee'];
//     employeeName = json['employee_name'];
//     logType = json['log_type'];
//     time = json['time'];
//     skipAutoAttendance = json['skip_auto_attendance'];
//     longitude = json['longitude'];
//     latitude = json['latitude'];
//     doctype = json['doctype'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['owner'] = this.owner;
//     data['creation'] = this.creation;
//     data['modified'] = this.modified;
//     data['modified_by'] = this.modifiedBy;
//     data['docstatus'] = this.docstatus;
//     data['idx'] = this.idx;
//     data['employee'] = this.employee;
//     data['employee_name'] = this.employeeName;
//     data['log_type'] = this.logType;
//     data['time'] = this.time;
//     data['skip_auto_attendance'] = this.skipAutoAttendance;
//     data['longitude'] = this.longitude;
//     data['latitude'] = this.latitude;
//     data['doctype'] = this.doctype;
//     return data;
//   }
// }

class CheckInCheckOut {
  Data? data;

  CheckInCheckOut({this.data});

  CheckInCheckOut.fromJson(Map<String, dynamic> json) {
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
  String? owner;
  String? creation;
  String? modified;
  String? modifiedBy;
  int? docstatus;
  int? idx;
  String? employee;
  String? employeeName;
  String? logType;
  String? time;
  int? skipAutoAttendance;
  double? latitude;
  double? longitude;
  String? geolocation;
  String? doctype;
  String? customer;

  Data(
      {this.name,
      this.owner,
      this.creation,
      this.modified,
      this.modifiedBy,
      this.docstatus,
      this.idx,
      this.employee,
      this.employeeName,
      this.logType,
      this.time,
      this.skipAutoAttendance,
      this.latitude,
      this.longitude,
      this.geolocation,
        this.customer,
        this.doctype});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    owner = json['owner'];
    creation = json['creation'];
    modified = json['modified'];
    modifiedBy = json['modified_by'];
    docstatus = json['docstatus'];
    idx = json['idx'];
    employee = json['employee'];
    employeeName = json['employee_name'];
    logType = json['log_type'];
    time = json['time'];
    skipAutoAttendance = json['skip_auto_attendance'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    geolocation = json['geolocation'];
    doctype = json['doctype'];
    customer = json['customer'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['owner'] = this.owner;
    data['creation'] = this.creation;
    data['modified'] = this.modified;
    data['modified_by'] = this.modifiedBy;
    data['docstatus'] = this.docstatus;
    data['idx'] = this.idx;
    data['employee'] = this.employee;
    data['employee_name'] = this.employeeName;
    data['log_type'] = this.logType;
    data['time'] = this.time;
    data['skip_auto_attendance'] = this.skipAutoAttendance;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['geolocation'] = this.geolocation;
    data['doctype'] = this.doctype;
    data['customer'] = customer;
    return data;
  }
}