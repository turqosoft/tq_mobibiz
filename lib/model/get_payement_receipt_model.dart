class GetPaymentEntryResponse {
  List<Data>? data;

  GetPaymentEntryResponse({this.data});

  GetPaymentEntryResponse.fromJson(Map<String, dynamic> json) {
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
  String? paymentType;
  String? postingDate;
  String? modeOfPayment;
  String? partyType;
  String? party;
  String? partyName;
  double? partyBalance;
  String? paidFrom;
  double? paidFromAccountBalance;
  String? paidTo;
  String? paidToAccountType;
  double? paidAmount;
  double? receivedAmount;
  String? referenceNo;
  String? referenceDate;
  String? remarks;

  Data(
      {this.name,
      this.paymentType,
      this.postingDate,
      this.modeOfPayment,
      this.partyType,
      this.party,
      this.partyName,
      this.partyBalance,
      this.paidFrom,
      this.paidFromAccountBalance,
      this.paidTo,
      this.paidToAccountType,
      this.paidAmount,
      this.receivedAmount,
      this.referenceNo,
      this.referenceDate,
      this.remarks});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    paymentType = json['payment_type'];
    postingDate = json['posting_date'];
    modeOfPayment = json['mode_of_payment'];
    partyType = json['party_type'];
    party = json['party'];
    partyName = json['party_name'];
    partyBalance = json['party_balance'];
    paidFrom = json['paid_from'];
    paidFromAccountBalance = json['paid_from_account_balance'];
    paidTo = json['paid_to'];
    paidToAccountType = json['paid_to_account_type'];
    paidAmount = json['paid_amount'];
    receivedAmount = json['received_amount'];
    referenceNo = json['reference_no'];
    referenceDate = json['reference_date'];
    remarks = json['remarks'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['payment_type'] = this.paymentType;
    data['posting_date'] = this.postingDate;
    data['mode_of_payment'] = this.modeOfPayment;
    data['party_type'] = this.partyType;
    data['party'] = this.party;
    data['party_name'] = this.partyName;
    data['party_balance'] = this.partyBalance;
    data['paid_from'] = this.paidFrom;
    data['paid_from_account_balance'] = this.paidFromAccountBalance;
    data['paid_to'] = this.paidTo;
    data['paid_to_account_type'] = this.paidToAccountType;
    data['paid_amount'] = this.paidAmount;
    data['received_amount'] = this.receivedAmount;
    data['reference_no'] = this.referenceNo;
    data['reference_date'] = this.referenceDate;
    data['remarks'] = this.remarks;
    return data;
  }
}