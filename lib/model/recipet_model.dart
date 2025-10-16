class ReceiptResponse {
  ReceiptResponse({
    required this.data,
  });
  late final Data data;
  
  ReceiptResponse.fromJson(Map<String, dynamic> json){
    data = Data.fromJson(json['data']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['data'] = data.toJson();
    return _data;
  }
}

class Data {
  Data({
    required this.name,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
    required this.docstatus,
    required this.idx,
    required this.namingSeries,
    required this.paymentType,
    required this.paymentOrderStatus,
    required this.postingDate,
    required this.company,
    required this.modeOfPayment,
    required this.partyType,
    required this.party,
    required this.partyName,
    required this.bookAdvancePaymentsInSeparatePartyAccount,
    required this.partyBalance,
    required this.paidFrom,
    required this.paidFromAccountCurrency,
    required this.paidFromAccountBalance,
    required this.paidTo,
    required this.paidToAccountType,
    required this.paidToAccountCurrency,
    required this.paidToAccountBalance,
    required this.paidAmount,
    required this.paidAmountAfterTax,
    required this.sourceExchangeRate,
    required this.basePaidAmount,
    required this.basePaidAmountAfterTax,
    required this.receivedAmount,
    required this.receivedAmountAfterTax,
    required this.targetExchangeRate,
    required this.baseReceivedAmount,
    required this.baseReceivedAmountAfterTax,
    required this.totalAllocatedAmount,
    required this.baseTotalAllocatedAmount,
    required this.unallocatedAmount,
    required this.differenceAmount,
    required this.applyTaxWithholdingAmount,
    required this.baseTotalTaxesAndCharges,
    required this.totalTaxesAndCharges,
    required this.referenceNo,
    required this.referenceDate,
    required this.status,
    required this.customRemarks,
    required this.remarks,
    required this.title,
    required this.doctype,
    required this.deductions,
    required this.references,
    required this.taxes,
  });
  late final String name;
  late final String owner;
  late final String creation;
  late final String modified;
  late final String modifiedBy;
  late final int docstatus;
  late final int idx;
  late final String namingSeries;
  late final String paymentType;
  late final String paymentOrderStatus;
  late final String postingDate;
  late final String company;
  late final String modeOfPayment;
  late final String partyType;
  late final String party;
  late final String partyName;
  late final int bookAdvancePaymentsInSeparatePartyAccount;
  late final int partyBalance;
  late final String paidFrom;
  late final String paidFromAccountCurrency;
  late final int paidFromAccountBalance;
  late final String paidTo;
  late final String paidToAccountType;
  late final String paidToAccountCurrency;
  late final int paidToAccountBalance;
  late final int paidAmount;
  late final int paidAmountAfterTax;
  late final int sourceExchangeRate;
  late final int basePaidAmount;
  late final int basePaidAmountAfterTax;
  late final int receivedAmount;
  late final int receivedAmountAfterTax;
  late final int targetExchangeRate;
  late final int baseReceivedAmount;
  late final int baseReceivedAmountAfterTax;
  late final int totalAllocatedAmount;
  late final int baseTotalAllocatedAmount;
  late final int unallocatedAmount;
  late final int differenceAmount;
  late final int applyTaxWithholdingAmount;
  late final int baseTotalTaxesAndCharges;
  late final int totalTaxesAndCharges;
  late final String referenceNo;
  late final String referenceDate;
  late final String status;
  late final int customRemarks;
  late final String remarks;
  late final String title;
  late final String doctype;
  late final List<dynamic> deductions;
  late final List<dynamic> references;
  late final List<dynamic> taxes;
  
  Data.fromJson(Map<String, dynamic> json){
    name = json['name'];
    // owner = json['owner'];
    // creation = json['creation'];
    // modified = json['modified'];
    // modifiedBy = json['modified_by'];
    // docstatus = json['docstatus'];
    // idx = json['idx'];
    // namingSeries = json['naming_series'];
    // paymentType = json['payment_type'];
    // paymentOrderStatus = json['payment_order_status'];
    // postingDate = json['posting_date'];
    // company = json['company'];
    // modeOfPayment = json['mode_of_payment'];
    // partyType = json['party_type'];
    // party = json['party'];
    // partyName = json['party_name'];
    // bookAdvancePaymentsInSeparatePartyAccount = json['book_advance_payments_in_separate_party_account'];
    // partyBalance = json['party_balance'];
    // paidFrom = json['paid_from'];
    // paidFromAccountCurrency = json['paid_from_account_currency'];
    // paidFromAccountBalance = json['paid_from_account_balance'];
    // paidTo = json['paid_to'];
    // paidToAccountType = json['paid_to_account_type'];
    // paidToAccountCurrency = json['paid_to_account_currency'];
    // paidToAccountBalance = json['paid_to_account_balance'];
    // paidAmount = json['paid_amount'];
    // paidAmountAfterTax = json['paid_amount_after_tax'];
    // sourceExchangeRate = json['source_exchange_rate'];
    // basePaidAmount = json['base_paid_amount'];
    // basePaidAmountAfterTax = json['base_paid_amount_after_tax'];
    // receivedAmount = json['received_amount'];
    // receivedAmountAfterTax = json['received_amount_after_tax'];
    // targetExchangeRate = json['target_exchange_rate'];
    // baseReceivedAmount = json['base_received_amount'];
    // baseReceivedAmountAfterTax = json['base_received_amount_after_tax'];
    // totalAllocatedAmount = json['total_allocated_amount'];
    // baseTotalAllocatedAmount = json['base_total_allocated_amount'];
    // unallocatedAmount = json['unallocated_amount'];
    // differenceAmount = json['difference_amount'];
    // applyTaxWithholdingAmount = json['apply_tax_withholding_amount'];
    // baseTotalTaxesAndCharges = json['base_total_taxes_and_charges'];
    // totalTaxesAndCharges = json['total_taxes_and_charges'];
    // referenceNo = json['reference_no'];
    // referenceDate = json['reference_date'];
    // status = json['status'];
    // customRemarks = json['custom_remarks'];
    // remarks = json['remarks'];
    // title = json['title'];
    // doctype = json['doctype'];
    // deductions = List.castFrom<dynamic, dynamic>(json['deductions']);
    // references = List.castFrom<dynamic, dynamic>(json['references']);
    // taxes = List.castFrom<dynamic, dynamic>(json['taxes']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['name'] = name;
    // _data['owner'] = owner;
    // _data['creation'] = creation;
    // _data['modified'] = modified;
    // _data['modified_by'] = modifiedBy;
    // _data['docstatus'] = docstatus;
    // _data['idx'] = idx;
    // _data['naming_series'] = namingSeries;
    // _data['payment_type'] = paymentType;
    // _data['payment_order_status'] = paymentOrderStatus;
    // _data['posting_date'] = postingDate;
    // _data['company'] = company;
    // _data['mode_of_payment'] = modeOfPayment;
    // _data['party_type'] = partyType;
    // _data['party'] = party;
    // _data['party_name'] = partyName;
    // _data['book_advance_payments_in_separate_party_account'] = bookAdvancePaymentsInSeparatePartyAccount;
    // _data['party_balance'] = partyBalance;
    // _data['paid_from'] = paidFrom;
    // _data['paid_from_account_currency'] = paidFromAccountCurrency;
    // _data['paid_from_account_balance'] = paidFromAccountBalance;
    // _data['paid_to'] = paidTo;
    // _data['paid_to_account_type'] = paidToAccountType;
    // _data['paid_to_account_currency'] = paidToAccountCurrency;
    // _data['paid_to_account_balance'] = paidToAccountBalance;
    // _data['paid_amount'] = paidAmount;
    // _data['paid_amount_after_tax'] = paidAmountAfterTax;
    // _data['source_exchange_rate'] = sourceExchangeRate;
    // _data['base_paid_amount'] = basePaidAmount;
    // _data['base_paid_amount_after_tax'] = basePaidAmountAfterTax;
    // _data['received_amount'] = receivedAmount;
    // _data['received_amount_after_tax'] = receivedAmountAfterTax;
    // _data['target_exchange_rate'] = targetExchangeRate;
    // _data['base_received_amount'] = baseReceivedAmount;
    // _data['base_received_amount_after_tax'] = baseReceivedAmountAfterTax;
    // _data['total_allocated_amount'] = totalAllocatedAmount;
    // _data['base_total_allocated_amount'] = baseTotalAllocatedAmount;
    // _data['unallocated_amount'] = unallocatedAmount;
    // _data['difference_amount'] = differenceAmount;
    // _data['apply_tax_withholding_amount'] = applyTaxWithholdingAmount;
    // _data['base_total_taxes_and_charges'] = baseTotalTaxesAndCharges;
    // _data['total_taxes_and_charges'] = totalTaxesAndCharges;
    // _data['reference_no'] = referenceNo;
    // _data['reference_date'] = referenceDate;
    // _data['status'] = status;
    // _data['custom_remarks'] = customRemarks;
    // _data['remarks'] = remarks;
    // _data['title'] = title;
    // _data['doctype'] = doctype;
    // _data['deductions'] = deductions;
    // _data['references'] = references;
    // _data['taxes'] = taxes;
    return _data;
  }
}