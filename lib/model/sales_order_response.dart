// class SalesOrderResponse {
//   SalesOrderResponse({
//     required this.data,
//     required this.exc,
//   });
//   late final Data data;
//   late final String exc;
  
//   SalesOrderResponse.fromJson(Map<String, dynamic> json){
//     data = Data.fromJson(json['data']);
//     exc = json['exc'];
//   }

//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     _data['data'] = data.toJson();
//     _data['exc'] = exc;
//     return _data;
//   }
// }

// class Data {
//   Data({
//     required this.name,
//     // required this.owner,
//     // required this.creation,
//     // required this.modified,
//     // required this.modifiedBy,
//     // required this.docstatus,
//     // required this.idx,
//     // required this.title,
//     // required this.namingSeries,
//     // required this.customer,
//     // required this.customerName,
//     // required this.orderType,
//     // required this.transactionDate,
//     // required this.deliveryDate,
//     // required this.company,
//     // required this.skipDeliveryNote,
//     // required this.isReverseCharge,
//     // required this.isExportWithGst,
//     // required this.currency,
//     // required this.conversionRate,
//     // required this.sellingPriceList,
//     // required this.priceListCurrency,
//     // required this.plcConversionRate,
//     // required this.ignorePricingRule,
//     // required this.reserveStock,
//     // required this.totalQty,
//     // required this.totalNetWeight,
//     // required this.baseTotal,
//     // required this.baseNetTotal,
//     // required this.total,
//     // required this.netTotal,
//     // required this.taxCategory,
//     // required this.taxesAndCharges,
//     // required this.baseTotalTaxesAndCharges,
//     // required this.totalTaxesAndCharges,
//     // required this.baseGrandTotal,
//     // required this.baseRoundingAdjustment,
//     // required this.baseRoundedTotal,
//     // required this.baseInWords,
//     // required this.grandTotal,
//     // required this.roundingAdjustment,
//     // required this.roundedTotal,
//     // required this.inWords,
//     // required this.advancePaid,
//     // required this.disableRoundedTotal,
//     // required this.applyDiscountOn,
//     // required this.baseDiscountAmount,
//     // required this.additionalDiscountPercentage,
//     // required this.discountAmount,
//     // required this.customerAddress,
//     // required this.addressDisplay,
//     // required this.billingAddressGstin,
//     // required this.gstCategory,
//     // required this.placeOfSupply,
//     // required this.customerGroup,
//     // required this.territory,
//     // required this.contactPerson,
//     // required this.contactDisplay,
//     // required this.contactPhone,
//     // required this.contactMobile,
//     // required this.contactEmail,
//     // required this.companyAddress,
//     // required this.companyGstin,
//     // required this.companyAddressDisplay,
//     // required this.status,
//     // required this.deliveryStatus,
//     // required this.perDelivered,
//     // required this.perPrimaryPacked,
//     // required this.perSecondaryPacked,
//     // required this.primaryPackingStatus,
//     // required this.secondaryPackingStatus,
//     // required this.perBilled,
//     // required this.perPicked,
//     // required this.billingStatus,
//     // required this.amountEligibleForCommission,
//     // required this.commissionRate,
//     // required this.totalCommission,
//     // required this.loyaltyPoints,
//     // required this.loyaltyAmount,
//     // required this.groupSameItems,
//     // required this.language,
//     // required this.isInternalCustomer,
//     // required this.doctype,
//     // required this.paymentSchedule,
//     // required this.taxes,
//     // required this.packedItems,
//     // required this.pricingRules,
//     // required this.salesTeam,
//     // required this.items,
//   });
//   late final String name;
//   // late final String owner;
//   // late final String creation;
//   // late final String modified;
//   // late final String modifiedBy;
//   // late final int docstatus;
//   // late final int idx;
//   // late final String title;
//   // late final String namingSeries;
//   // late final String customer;
//   // late final String customerName;
//   // late final String orderType;
//   // late final String transactionDate;
//   // late final String deliveryDate;
//   // late final String company;
//   // late final int skipDeliveryNote;
//   // late final int isReverseCharge;
//   // late final int isExportWithGst;
//   // late final String currency;
//   // late final int conversionRate;
//   // late final String sellingPriceList;
//   // late final String priceListCurrency;
//   // late final int plcConversionRate;
//   // late final int ignorePricingRule;
//   // late final int reserveStock;
//   // late final int totalQty;
//   // late final int totalNetWeight;
//   // late final int baseTotal;
//   // late final int baseNetTotal;
//   // late final int total;
//   // late final int netTotal;
//   // late final String taxCategory;
//   // late final String taxesAndCharges;
//   // late final int baseTotalTaxesAndCharges;
//   // late final int totalTaxesAndCharges;
//   // late final int baseGrandTotal;
//   // late final int baseRoundingAdjustment;
//   // late final int baseRoundedTotal;
//   // late final String baseInWords;
//   // late final int grandTotal;
//   // late final int roundingAdjustment;
//   // late final int roundedTotal;
//   // late final String inWords;
//   // late final int advancePaid;
//   // late final int disableRoundedTotal;
//   // late final String applyDiscountOn;
//   // late final int baseDiscountAmount;
//   // late final int additionalDiscountPercentage;
//   // late final int discountAmount;
//   // late final String customerAddress;
//   // late final String addressDisplay;
//   // late final String billingAddressGstin;
//   // late final String gstCategory;
//   // late final String placeOfSupply;
//   // late final String customerGroup;
//   // late final String territory;
//   // late final String contactPerson;
//   // late final String contactDisplay;
//   // late final String contactPhone;
//   // late final String contactMobile;
//   // late final String contactEmail;
//   // late final String companyAddress;
//   // late final String companyGstin;
//   // late final String companyAddressDisplay;
//   // late final String status;
//   // late final String deliveryStatus;
//   // late final int perDelivered;
//   // late final int perPrimaryPacked;
//   // late final int perSecondaryPacked;
//   // late final String primaryPackingStatus;
//   // late final String secondaryPackingStatus;
//   // late final int perBilled;
//   // late final int perPicked;
//   // late final String billingStatus;
//   // late final int amountEligibleForCommission;
//   // late final int commissionRate;
//   // late final int totalCommission;
//   // late final int loyaltyPoints;
//   // late final int loyaltyAmount;
//   // late final int groupSameItems;
//   // late final String language;
//   // late final int isInternalCustomer;
//   // late final String doctype;
//   // late final List<PaymentSchedule> paymentSchedule;
//   // late final List<dynamic> taxes;
//   // late final List<dynamic> packedItems;
//   // late final List<dynamic> pricingRules;
//   // late final List<dynamic> salesTeam;
//   // late final List<Items> items;
  
//   Data.fromJson(Map<String, dynamic> json){
//     name = json['name'];
//     // owner = json['owner'];
//     // creation = json['creation'];
//     // modified = json['modified'];
//     // modifiedBy = json['modified_by'];
//     // docstatus = json['docstatus'];
//     // idx = json['idx'];
//     // title = json['title'];
//     // namingSeries = json['naming_series'];
//     // customer = json['customer'];
//     // customerName = json['customer_name'];
//     // orderType = json['order_type'];
//     // transactionDate = json['transaction_date'];
//     // deliveryDate = json['delivery_date'];
//     // company = json['company'];
//     // skipDeliveryNote = json['skip_delivery_note'];
//     // isReverseCharge = json['is_reverse_charge'];
//     // isExportWithGst = json['is_export_with_gst'];
//     // currency = json['currency'];
//     // conversionRate = json['conversion_rate'];
//     // sellingPriceList = json['selling_price_list'];
//     // priceListCurrency = json['price_list_currency'];
//     // plcConversionRate = json['plc_conversion_rate'];
//     // ignorePricingRule = json['ignore_pricing_rule'];
//     // reserveStock = json['reserve_stock'];
//     // totalQty = json['total_qty'];
//     // totalNetWeight = json['total_net_weight'];
//     // baseTotal = json['base_total'];
//     // baseNetTotal = json['base_net_total'];
//     // total = json['total'];
//     // netTotal = json['net_total'];
//     // taxCategory = json['tax_category'];
//     // taxesAndCharges = json['taxes_and_charges'];
//     // baseTotalTaxesAndCharges = json['base_total_taxes_and_charges'];
//     // totalTaxesAndCharges = json['total_taxes_and_charges'];
//     // baseGrandTotal = json['base_grand_total'];
//     // baseRoundingAdjustment = json['base_rounding_adjustment'];
//     // baseRoundedTotal = json['base_rounded_total'];
//     // baseInWords = json['base_in_words'];
//     // grandTotal = json['grand_total'];
//     // roundingAdjustment = json['rounding_adjustment'];
//     // roundedTotal = json['rounded_total'];
//     // inWords = json['in_words'];
//     // advancePaid = json['advance_paid'];
//     // disableRoundedTotal = json['disable_rounded_total'];
//     // applyDiscountOn = json['apply_discount_on'];
//     // baseDiscountAmount = json['base_discount_amount'];
//     // additionalDiscountPercentage = json['additional_discount_percentage'];
//     // discountAmount = json['discount_amount'];
//     // customerAddress = json['customer_address'];
//     // addressDisplay = json['address_display'];
//     // billingAddressGstin = json['billing_address_gstin'];
//     // gstCategory = json['gst_category'];
//     // placeOfSupply = json['place_of_supply'];
//     // customerGroup = json['customer_group'];
//     // territory = json['territory'];
//     // contactPerson = json['contact_person'];
//     // contactDisplay = json['contact_display'];
//     // contactPhone = json['contact_phone'];
//     // contactMobile = json['contact_mobile'];
//     // contactEmail = json['contact_email'];
//     // companyAddress = json['company_address'];
//     // companyGstin = json['company_gstin'];
//     // companyAddressDisplay = json['company_address_display'];
//     // status = json['status'];
//     // deliveryStatus = json['delivery_status'];
//     // perDelivered = json['per_delivered'];
//     // perPrimaryPacked = json['per_primary_packed'];
//     // perSecondaryPacked = json['per_secondary_packed'];
//     // primaryPackingStatus = json['primary_packing_status'];
//     // secondaryPackingStatus = json['secondary_packing_status'];
//     // perBilled = json['per_billed'];
//     // perPicked = json['per_picked'];
//     // billingStatus = json['billing_status'];
//     // amountEligibleForCommission = json['amount_eligible_for_commission'];
//     // commissionRate = json['commission_rate'];
//     // totalCommission = json['total_commission'];
//     // loyaltyPoints = json['loyalty_points'];
//     // loyaltyAmount = json['loyalty_amount'];
//     // groupSameItems = json['group_same_items'];
//     // language = json['language'];
//     // isInternalCustomer = json['is_internal_customer'];
//     // doctype = json['doctype'];
//     // paymentSchedule = List.from(json['payment_schedule']).map((e)=>PaymentSchedule.fromJson(e)).toList();
//     // taxes = List.castFrom<dynamic, dynamic>(json['taxes']);
//     // packedItems = List.castFrom<dynamic, dynamic>(json['packed_items']);
//     // pricingRules = List.castFrom<dynamic, dynamic>(json['pricing_rules']);
//     // salesTeam = List.castFrom<dynamic, dynamic>(json['sales_team']);
//     // items = List.from(json['items']).map((e)=>Items.fromJson(e)).toList();
//   }

//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     _data['name'] = name;
//     // _data['owner'] = owner;
//     // _data['creation'] = creation;
//     // _data['modified'] = modified;
//     // _data['modified_by'] = modifiedBy;
//     // _data['docstatus'] = docstatus;
//     // _data['idx'] = idx;
//     // _data['title'] = title;
//     // _data['naming_series'] = namingSeries;
//     // _data['customer'] = customer;
//     // _data['customer_name'] = customerName;
//     // _data['order_type'] = orderType;
//     // _data['transaction_date'] = transactionDate;
//     // _data['delivery_date'] = deliveryDate;
//     // _data['company'] = company;
//     // _data['skip_delivery_note'] = skipDeliveryNote;
//     // _data['is_reverse_charge'] = isReverseCharge;
//     // _data['is_export_with_gst'] = isExportWithGst;
//     // _data['currency'] = currency;
//     // _data['conversion_rate'] = conversionRate;
//     // _data['selling_price_list'] = sellingPriceList;
//     // _data['price_list_currency'] = priceListCurrency;
//     // _data['plc_conversion_rate'] = plcConversionRate;
//     // _data['ignore_pricing_rule'] = ignorePricingRule;
//     // _data['reserve_stock'] = reserveStock;
//     // _data['total_qty'] = totalQty;
//     // _data['total_net_weight'] = totalNetWeight;
//     // _data['base_total'] = baseTotal;
//     // _data['base_net_total'] = baseNetTotal;
//     // _data['total'] = total;
//     // _data['net_total'] = netTotal;
//     // _data['tax_category'] = taxCategory;
//     // _data['taxes_and_charges'] = taxesAndCharges;
//     // _data['base_total_taxes_and_charges'] = baseTotalTaxesAndCharges;
//     // _data['total_taxes_and_charges'] = totalTaxesAndCharges;
//     // _data['base_grand_total'] = baseGrandTotal;
//     // _data['base_rounding_adjustment'] = baseRoundingAdjustment;
//     // _data['base_rounded_total'] = baseRoundedTotal;
//     // _data['base_in_words'] = baseInWords;
//     // _data['grand_total'] = grandTotal;
//     // _data['rounding_adjustment'] = roundingAdjustment;
//     // _data['rounded_total'] = roundedTotal;
//     // _data['in_words'] = inWords;
//     // _data['advance_paid'] = advancePaid;
//     // _data['disable_rounded_total'] = disableRoundedTotal;
//     // _data['apply_discount_on'] = applyDiscountOn;
//     // _data['base_discount_amount'] = baseDiscountAmount;
//     // _data['additional_discount_percentage'] = additionalDiscountPercentage;
//     // _data['discount_amount'] = discountAmount;
//     // _data['customer_address'] = customerAddress;
//     // _data['address_display'] = addressDisplay;
//     // _data['billing_address_gstin'] = billingAddressGstin;
//     // _data['gst_category'] = gstCategory;
//     // _data['place_of_supply'] = placeOfSupply;
//     // _data['customer_group'] = customerGroup;
//     // _data['territory'] = territory;
//     // _data['contact_person'] = contactPerson;
//     // _data['contact_display'] = contactDisplay;
//     // _data['contact_phone'] = contactPhone;
//     // _data['contact_mobile'] = contactMobile;
//     // _data['contact_email'] = contactEmail;
//     // _data['company_address'] = companyAddress;
//     // _data['company_gstin'] = companyGstin;
//     // _data['company_address_display'] = companyAddressDisplay;
//     // _data['status'] = status;
//     // _data['delivery_status'] = deliveryStatus;
//     // _data['per_delivered'] = perDelivered;
//     // _data['per_primary_packed'] = perPrimaryPacked;
//     // _data['per_secondary_packed'] = perSecondaryPacked;
//     // _data['primary_packing_status'] = primaryPackingStatus;
//     // _data['secondary_packing_status'] = secondaryPackingStatus;
//     // _data['per_billed'] = perBilled;
//     // _data['per_picked'] = perPicked;
//     // _data['billing_status'] = billingStatus;
//     // _data['amount_eligible_for_commission'] = amountEligibleForCommission;
//     // _data['commission_rate'] = commissionRate;
//     // _data['total_commission'] = totalCommission;
//     // _data['loyalty_points'] = loyaltyPoints;
//     // _data['loyalty_amount'] = loyaltyAmount;
//     // _data['group_same_items'] = groupSameItems;
//     // _data['language'] = language;
//     // _data['is_internal_customer'] = isInternalCustomer;
//     // _data['doctype'] = doctype;
//     // _data['payment_schedule'] = paymentSchedule.map((e)=>e.toJson()).toList();
//     // _data['taxes'] = taxes;
//     // _data['packed_items'] = packedItems;
//     // _data['pricing_rules'] = pricingRules;
//     // _data['sales_team'] = salesTeam;
//     // _data['items'] = items.map((e)=>e.toJson()).toList();
//     return _data;
//   }
// }

// class PaymentSchedule {
//   PaymentSchedule({
//     required this.name,
//     // required this.creation,
//     // required this.modified,
//     // required this.modifiedBy,
//     // required this.docstatus,
//     // required this.idx,
//     // required this.dueDate,
//     // required this.invoicePortion,
//     // required this.discount,
//     // required this.paymentAmount,
//     // required this.outstanding,
//     // required this.paidAmount,
//     // required this.discountedAmount,
//     // required this.basePaymentAmount,
//     // required this.parent,
//     // required this.parentfield,
//     // required this.parenttype,
//     // required this.doctype,
//   });
//   late final String name;
//   // late final String creation;
//   // late final String modified;
//   // late final String modifiedBy;
//   // late final int docstatus;
//   // late final int idx;
//   // late final String dueDate;
//   // late final int invoicePortion;
//   // late final int discount;
//   // late final int paymentAmount;
//   // late final int outstanding;
//   // late final int paidAmount;
//   // late final int discountedAmount;
//   // late final int basePaymentAmount;
//   // late final String parent;
//   // late final String parentfield;
//   // late final String parenttype;
//   // late final String doctype;
  
//   PaymentSchedule.fromJson(Map<String, dynamic> json){
//     name = json['name'];
//     // creation = json['creation'];
//     // modified = json['modified'];
//     // modifiedBy = json['modified_by'];
//     // docstatus = json['docstatus'];
//     // idx = json['idx'];
//     // dueDate = json['due_date'];
//     // invoicePortion = json['invoice_portion'];
//     // discount = json['discount'];
//     // paymentAmount = json['payment_amount'];
//     // outstanding = json['outstanding'];
//     // paidAmount = json['paid_amount'];
//     // discountedAmount = json['discounted_amount'];
//     // basePaymentAmount = json['base_payment_amount'];
//     // parent = json['parent'];
//     // parentfield = json['parentfield'];
//     // parenttype = json['parenttype'];
//     // doctype = json['doctype'];
//   }

//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     // _data['name'] = name;
//     // _data['creation'] = creation;
//     // _data['modified'] = modified;
//     // _data['modified_by'] = modifiedBy;
//     // _data['docstatus'] = docstatus;
//     // _data['idx'] = idx;
//     // _data['due_date'] = dueDate;
//     // _data['invoice_portion'] = invoicePortion;
//     // _data['discount'] = discount;
//     // _data['payment_amount'] = paymentAmount;
//     // _data['outstanding'] = outstanding;
//     // _data['paid_amount'] = paidAmount;
//     // _data['discounted_amount'] = discountedAmount;
//     // _data['base_payment_amount'] = basePaymentAmount;
//     // _data['parent'] = parent;
//     // _data['parentfield'] = parentfield;
//     // _data['parenttype'] = parenttype;
//     // _data['doctype'] = doctype;
//     return _data;
//   }
// }

// class Items {
//   Items({
//     required this.name,
//     // required this.owner,
//     // required this.creation,
//     // required this.modified,
//     // required this.modifiedBy,
//     // required this.docstatus,
//     // required this.idx,
//     // required this.itemCode,
//     // required this.ensureDeliveryBasedOnProducedSerialNo,
//     // required this.reserveStock,
//     // required this.deliveryDate,
//     // required this.itemName,
//     // required this.siNo,
//     // required this.package,
//     // required this.description,
//     // required this.gstHsnCode,
//     // required this.itemGroup,
//     // required this.image,
//     // required this.qty,
//     // required this.cancelledQuantity,
//     // required this.cancellationReason,
//     // required this.stockUom,
//     // required this.uom,
//     // required this.conversionFactor,
//     // required this.stockQty,
//     // required this.actualOrderedQuanity,
//     // required this.stockReservedQty,
//     // required this.priceListRate,
//     // required this.basePriceListRate,
//     // required this.marginType,
//     // required this.marginRateOrAmount,
//     // required this.rateWithMargin,
//     // required this.discountPercentage,
//     // required this.discountAmount,
//     // required this.baseRateWithMargin,
//     // required this.rate,
//     // required this.amount,
//     // required this.gstTreatment,
//     // required this.baseRate,
//     // required this.baseAmount,
//     // required this.stockUomRate,
//     // required this.isFreeItem,
//     // required this.grantCommission,
//     // required this.netRate,
//     // required this.netAmount,
//     // required this.baseNetRate,
//     // required this.baseNetAmount,
//     // required this.taxableValue,
//     // required this.igstRate,
//     // required this.cgstRate,
//     // required this.sgstRate,
//     // required this.cessRate,
//     // required this.cessNonAdvolRate,
//     // required this.igstAmount,
//     // required this.cgstAmount,
//     // required this.sgstAmount,
//     // required this.cessAmount,
//     // required this.cessNonAdvolAmount,
//     // required this.billedAmt,
//     // required this.valuationRate,
//     // required this.grossProfit,
//     // required this.deliveredBySupplier,
//     // required this.weightPerUnit,
//     // required this.totalWeight,
//     // required this.customItemSize,
//     // required this.customLenthOfItem,
//     // required this.customWidthOfItem,
//     // required this.warehouse,
//     // required this.againstBlanketOrder,
//     // required this.blanketOrderRate,
//     // required this.projectedQty,
//     // required this.actualQty,
//     // required this.orderedQty,
//     // required this.plannedQty,
//     // required this.productionPlanQty,
//     // required this.workOrderQty,
//     // required this.deliveredQty,
//     // required this.producedQty,
//     // required this.returnedQty,
//     // required this.pickedQty,
//     // required this.pageBreak,
//     // required this.itemTaxRate,
//     // required this.transactionDate,
//     // required this.parent,
//     // required this.parentfield,
//     // required this.parenttype,
//     // required this.doctype,
//     //required this._Unsaved,
//   });
//   late final String name;
//   // late final String owner;
//   // late final String creation;
//   // late final String modified;
//   // late final String modifiedBy;
//   // late final int docstatus;
//   // late final int idx;
//   // late final String itemCode;
//   // late final int ensureDeliveryBasedOnProducedSerialNo;
//   // late final int reserveStock;
//   // late final String deliveryDate;
//   // late final String itemName;
//   // late final int siNo;
//   // late final int package;
//   // late final String description;
//   // late final String gstHsnCode;
//   // late final String itemGroup;
//   // late final String image;
//   // late final int qty;
//   // late final int cancelledQuantity;
//   // late final String cancellationReason;
//   // late final String stockUom;
//   // late final String uom;
//   // late final int conversionFactor;
//   // late final int stockQty;
//   // late final int actualOrderedQuanity;
//   // late final int stockReservedQty;
//   // late final int priceListRate;
//   // late final int basePriceListRate;
//   // late final String marginType;
//   // late final int marginRateOrAmount;
//   // late final int rateWithMargin;
//   // late final int discountPercentage;
//   // late final int discountAmount;
//   // late final int baseRateWithMargin;
//   // late final int rate;
//   // late final int amount;
//   // late final String gstTreatment;
//   // late final int baseRate;
//   // late final int baseAmount;
//   // late final int stockUomRate;
//   // late final int isFreeItem;
//   // late final int grantCommission;
//   // late final int netRate;
//   // late final int netAmount;
//   // late final int baseNetRate;
//   // late final int baseNetAmount;
//   // late final int taxableValue;
//   // late final int igstRate;
//   // late final int cgstRate;
//   // late final int sgstRate;
//   // late final int cessRate;
//   // late final int cessNonAdvolRate;
//   // late final int igstAmount;
//   // late final int cgstAmount;
//   // late final int sgstAmount;
//   // late final int cessAmount;
//   // late final int cessNonAdvolAmount;
//   // late final int billedAmt;
//   // late final int valuationRate;
//   // late final int grossProfit;
//   // late final int deliveredBySupplier;
//   // late final int weightPerUnit;
//   // late final int totalWeight;
//   // late final String customItemSize;
//   // late final int customLenthOfItem;
//   // late final int customWidthOfItem;
//   // late final String warehouse;
//   // late final int againstBlanketOrder;
//   // late final int blanketOrderRate;
//   // late final int projectedQty;
//   // late final int actualQty;
//   // late final int orderedQty;
//   // late final int plannedQty;
//   // late final int productionPlanQty;
//   // late final int workOrderQty;
//   // late final int deliveredQty;
//   // late final int producedQty;
//   // late final int returnedQty;
//   // late final int pickedQty;
//   // late final int pageBreak;
//   // late final String itemTaxRate;
//   // late final String transactionDate;
//   // late final String parent;
//   // late final String parentfield;
//   // late final String parenttype;
//   // late final String doctype;
//   // late final int _Unsaved;
  
//   Items.fromJson(Map<String, dynamic> json){
//     name = json['name'];
//     // owner = json['owner'];
//     // creation = json['creation'];
//     // modified = json['modified'];
//     // modifiedBy = json['modified_by'];
//     // docstatus = json['docstatus'];
//     // idx = json['idx'];
//     // itemCode = json['item_code'];
//     // ensureDeliveryBasedOnProducedSerialNo = json['ensure_delivery_based_on_produced_serial_no'];
//     // reserveStock = json['reserve_stock'];
//     // deliveryDate = json['delivery_date'];
//     // itemName = json['item_name'];
//     // siNo = json['si_no'];
//     // package = json['package'];
//     // description = json['description'];
//     // gstHsnCode = json['gst_hsn_code'];
//     // itemGroup = json['item_group'];
//     // image = json['image'];
//     // qty = json['qty'];
//     // cancelledQuantity = json['cancelled_quantity'];
//     // cancellationReason = json['cancellation_reason'];
//     // stockUom = json['stock_uom'];
//     // uom = json['uom'];
//     // conversionFactor = json['conversion_factor'];
//     // stockQty = json['stock_qty'];
//     // actualOrderedQuanity = json['actual_ordered_quanity'];
//     // stockReservedQty = json['stock_reserved_qty'];
//     // priceListRate = json['price_list_rate'];
//     // basePriceListRate = json['base_price_list_rate'];
//     // marginType = json['margin_type'];
//     // marginRateOrAmount = json['margin_rate_or_amount'];
//     // rateWithMargin = json['rate_with_margin'];
//     // discountPercentage = json['discount_percentage'];
//     // discountAmount = json['discount_amount'];
//     // baseRateWithMargin = json['base_rate_with_margin'];
//     // rate = json['rate'];
//     // amount = json['amount'];
//     // gstTreatment = json['gst_treatment'];
//     // baseRate = json['base_rate'];
//     // baseAmount = json['base_amount'];
//     // stockUomRate = json['stock_uom_rate'];
//     // isFreeItem = json['is_free_item'];
//     // grantCommission = json['grant_commission'];
//     // netRate = json['net_rate'];
//     // netAmount = json['net_amount'];
//     // baseNetRate = json['base_net_rate'];
//     // baseNetAmount = json['base_net_amount'];
//     // taxableValue = json['taxable_value'];
//     // igstRate = json['igst_rate'];
//     // cgstRate = json['cgst_rate'];
//     // sgstRate = json['sgst_rate'];
//     // cessRate = json['cess_rate'];
//     // cessNonAdvolRate = json['cess_non_advol_rate'];
//     // igstAmount = json['igst_amount'];
//     // cgstAmount = json['cgst_amount'];
//     // sgstAmount = json['sgst_amount'];
//     // cessAmount = json['cess_amount'];
//     // cessNonAdvolAmount = json['cess_non_advol_amount'];
//     // billedAmt = json['billed_amt'];
//     // valuationRate = json['valuation_rate'];
//     // grossProfit = json['gross_profit'];
//     // deliveredBySupplier = json['delivered_by_supplier'];
//     // weightPerUnit = json['weight_per_unit'];
//     // totalWeight = json['total_weight'];
//     // customItemSize = json['custom_item_size'];
//     // customLenthOfItem = json['custom_lenth_of_item'];
//     // customWidthOfItem = json['custom_width_of_item'];
//     // warehouse = json['warehouse'];
//     // againstBlanketOrder = json['against_blanket_order'];
//     // blanketOrderRate = json['blanket_order_rate'];
//     // projectedQty = json['projected_qty'];
//     // actualQty = json['actual_qty'];
//     // orderedQty = json['ordered_qty'];
//     // plannedQty = json['planned_qty'];
//     // productionPlanQty = json['production_plan_qty'];
//     // workOrderQty = json['work_order_qty'];
//     // deliveredQty = json['delivered_qty'];
//     // producedQty = json['produced_qty'];
//     // returnedQty = json['returned_qty'];
//     // pickedQty = json['picked_qty'];
//     // pageBreak = json['page_break'];
//     // itemTaxRate = json['item_tax_rate'];
//     // transactionDate = json['transaction_date'];
//     // parent = json['parent'];
//     // parentfield = json['parentfield'];
//     // parenttype = json['parenttype'];
//     // doctype = json['doctype'];
//     // _Unsaved = json['__unsaved'];
//   }

//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     _data['name'] = name;
//     // _data['owner'] = owner;
//     // _data['creation'] = creation;
//     // _data['modified'] = modified;
//     // _data['modified_by'] = modifiedBy;
//     // _data['docstatus'] = docstatus;
//     // _data['idx'] = idx;
//     // _data['item_code'] = itemCode;
//     // _data['ensure_delivery_based_on_produced_serial_no'] = ensureDeliveryBasedOnProducedSerialNo;
//     // _data['reserve_stock'] = reserveStock;
//     // _data['delivery_date'] = deliveryDate;
//     // _data['item_name'] = itemName;
//     // _data['si_no'] = siNo;
//     // _data['package'] = package;
//     // _data['description'] = description;
//     // _data['gst_hsn_code'] = gstHsnCode;
//     // _data['item_group'] = itemGroup;
//     // _data['image'] = image;
//     // _data['qty'] = qty;
//     // _data['cancelled_quantity'] = cancelledQuantity;
//     // _data['cancellation_reason'] = cancellationReason;
//     // _data['stock_uom'] = stockUom;
//     // _data['uom'] = uom;
//     // _data['conversion_factor'] = conversionFactor;
//     // _data['stock_qty'] = stockQty;
//     // _data['actual_ordered_quanity'] = actualOrderedQuanity;
//     // _data['stock_reserved_qty'] = stockReservedQty;
//     // _data['price_list_rate'] = priceListRate;
//     // _data['base_price_list_rate'] = basePriceListRate;
//     // _data['margin_type'] = marginType;
//     // _data['margin_rate_or_amount'] = marginRateOrAmount;
//     // _data['rate_with_margin'] = rateWithMargin;
//     // _data['discount_percentage'] = discountPercentage;
//     // _data['discount_amount'] = discountAmount;
//     // _data['base_rate_with_margin'] = baseRateWithMargin;
//     // _data['rate'] = rate;
//     // _data['amount'] = amount;
//     // _data['gst_treatment'] = gstTreatment;
//     // _data['base_rate'] = baseRate;
//     // _data['base_amount'] = baseAmount;
//     // _data['stock_uom_rate'] = stockUomRate;
//     // _data['is_free_item'] = isFreeItem;
//     // _data['grant_commission'] = grantCommission;
//     // _data['net_rate'] = netRate;
//     // _data['net_amount'] = netAmount;
//     // _data['base_net_rate'] = baseNetRate;
//     // _data['base_net_amount'] = baseNetAmount;
//     // _data['taxable_value'] = taxableValue;
//     // _data['igst_rate'] = igstRate;
//     // _data['cgst_rate'] = cgstRate;
//     // _data['sgst_rate'] = sgstRate;
//     // _data['cess_rate'] = cessRate;
//     // _data['cess_non_advol_rate'] = cessNonAdvolRate;
//     // _data['igst_amount'] = igstAmount;
//     // _data['cgst_amount'] = cgstAmount;
//     // _data['sgst_amount'] = sgstAmount;
//     // _data['cess_amount'] = cessAmount;
//     // _data['cess_non_advol_amount'] = cessNonAdvolAmount;
//     // _data['billed_amt'] = billedAmt;
//     // _data['valuation_rate'] = valuationRate;
//     // _data['gross_profit'] = grossProfit;
//     // _data['delivered_by_supplier'] = deliveredBySupplier;
//     // _data['weight_per_unit'] = weightPerUnit;
//     // _data['total_weight'] = totalWeight;
//     // _data['custom_item_size'] = customItemSize;
//     // _data['custom_lenth_of_item'] = customLenthOfItem;
//     // _data['custom_width_of_item'] = customWidthOfItem;
//     // _data['warehouse'] = warehouse;
//     // _data['against_blanket_order'] = againstBlanketOrder;
//     // _data['blanket_order_rate'] = blanketOrderRate;
//     // _data['projected_qty'] = projectedQty;
//     // _data['actual_qty'] = actualQty;
//     // _data['ordered_qty'] = orderedQty;
//     // _data['planned_qty'] = plannedQty;
//     // _data['production_plan_qty'] = productionPlanQty;
//     // _data['work_order_qty'] = workOrderQty;
//     // _data['delivered_qty'] = deliveredQty;
//     // _data['produced_qty'] = producedQty;
//     // _data['returned_qty'] = returnedQty;
//     // _data['picked_qty'] = pickedQty;
//     // _data['page_break'] = pageBreak;
//     // _data['item_tax_rate'] = itemTaxRate;
//     // _data['transaction_date'] = transactionDate;
//     // _data['parent'] = parent;
//     // _data['parentfield'] = parentfield;
//     // _data['parenttype'] = parenttype;
//     // _data['doctype'] = doctype;
//     // _data['__unsaved'] = _Unsaved;
//     return _data;
//   }
// }

class SalesOrderResponse {
  Data? data;

  SalesOrderResponse({this.data});

  SalesOrderResponse.fromJson(Map<String, dynamic> json) {
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
  // String? owner;
  // String? creation;
  // String? modified;
  // String? modifiedBy;
  // int? docstatus;
  // int? idx;
  // String? title;
  // String? namingSeries;
  // String? customer;
  // String? customerName;
  // String? orderType;
  // String? transactionDate;
  // String? deliveryDate;
  // String? company;
  // int? skipDeliveryNote;
  // int? isReverseCharge;
  // int? isExportWithGst;
  // String? currency;
  // int? conversionRate;
  // String? sellingPriceList;
  // String? priceListCurrency;
  // int? plcConversionRate;
  // int? ignorePricingRule;
  // int? reserveStock;
  // int? totalQty;
  // int? totalNetWeight;
  // int? baseTotal;
  // int? baseNetTotal;
  // int? total;
  // int? netTotal;
  // String? taxCategory;
  // String? taxesAndCharges;
  // int? baseTotalTaxesAndCharges;
  // int? totalTaxesAndCharges;
  // int? baseGrandTotal;
  // int? baseRoundingAdjustment;
  // int? baseRoundedTotal;
  // String? baseInWords;
  // int? grandTotal;
  // int? roundingAdjustment;
  // int? roundedTotal;
  // String? inWords;
  // int? advancePaid;
  // int? disableRoundedTotal;
  // String? applyDiscountOn;
  // int? baseDiscountAmount;
  // int? additionalDiscountPercentage;
  // int? discountAmount;
  // String? customerAddress;
  // String? addressDisplay;
  // String? billingAddressGstin;
  // String? gstCategory;
  // String? placeOfSupply;
  // String? customerGroup;
  // String? territory;
  // String? contactPerson;
  // String? contactDisplay;
  // String? contactPhone;
  // String? contactMobile;
  // String? contactEmail;
  // String? companyAddress;
  // String? companyGstin;
  // String? companyAddressDisplay;
  // String? status;
  // String? deliveryStatus;
  // int? perDelivered;
  // int? perPrimaryPacked;
  // int? perSecondaryPacked;
  // String? primaryPackingStatus;
  // String? secondaryPackingStatus;
  // int? perBilled;
  // int? perPicked;
  // String? billingStatus;
  // int? amountEligibleForCommission;
  // int? commissionRate;
  // int? totalCommission;
  // int? loyaltyPoints;
  // int? loyaltyAmount;
  // int? groupSameItems;
  // String? language;
  // int? isInternalCustomer;
  // String? doctype;
  // List<Items>? items;
  // List<Null>? pricingRules;
  // List<Null>? salesTeam;
  // List<Null>? taxes;
  // List<Null>? packedItems;
  // List<PaymentSchedule>? paymentSchedule;

  Data(
      {this.name,
      // this.owner,
      // this.creation,
      // this.modified,
      // this.modifiedBy,
      // this.docstatus,
      // this.idx,
      // this.title,
      // this.namingSeries,
      // this.customer,
      // this.customerName,
      // this.orderType,
      // this.transactionDate,
      // this.deliveryDate,
      // this.company,
      // this.skipDeliveryNote,
      // this.isReverseCharge,
      // this.isExportWithGst,
      // this.currency,
      // this.conversionRate,
      // this.sellingPriceList,
      // this.priceListCurrency,
      // this.plcConversionRate,
      // this.ignorePricingRule,
      // this.reserveStock,
      // this.totalQty,
      // this.totalNetWeight,
      // this.baseTotal,
      // this.baseNetTotal,
      // this.total,
      // this.netTotal,
      // this.taxCategory,
      // this.taxesAndCharges,
      // this.baseTotalTaxesAndCharges,
      // this.totalTaxesAndCharges,
      // this.baseGrandTotal,
      // this.baseRoundingAdjustment,
      // this.baseRoundedTotal,
      // this.baseInWords,
      // this.grandTotal,
      // this.roundingAdjustment,
      // this.roundedTotal,
      // this.inWords,
      // this.advancePaid,
      // this.disableRoundedTotal,
      // this.applyDiscountOn,
      // this.baseDiscountAmount,
      // this.additionalDiscountPercentage,
      // this.discountAmount,
      // this.customerAddress,
      // this.addressDisplay,
      // this.billingAddressGstin,
      // this.gstCategory,
      // this.placeOfSupply,
      // this.customerGroup,
      // this.territory,
      // this.contactPerson,
      // this.contactDisplay,
      // this.contactPhone,
      // this.contactMobile,
      // this.contactEmail,
      // this.companyAddress,
      // this.companyGstin,
      // this.companyAddressDisplay,
      // this.status,
      // this.deliveryStatus,
      // this.perDelivered,
      // this.perPrimaryPacked,
      // this.perSecondaryPacked,
      // this.primaryPackingStatus,
      // this.secondaryPackingStatus,
      // this.perBilled,
      // this.perPicked,
      // this.billingStatus,
      // this.amountEligibleForCommission,
      // this.commissionRate,
      // this.totalCommission,
      // this.loyaltyPoints,
      // this.loyaltyAmount,
      // this.groupSameItems,
      // this.language,
      // this.isInternalCustomer,
      // this.doctype,
      // this.items,
      // this.pricingRules,
      // this.salesTeam,
      // this.taxes,
      // this.packedItems,
      // this.paymentSchedule
      });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    // owner = json['owner'];
    // creation = json['creation'];
    // modified = json['modified'];
    // modifiedBy = json['modified_by'];
    // docstatus = json['docstatus'];
    // idx = json['idx'];
    // title = json['title'];
    // namingSeries = json['naming_series'];
    // customer = json['customer'];
    // customerName = json['customer_name'];
    // orderType = json['order_type'];
    // transactionDate = json['transaction_date'];
    // deliveryDate = json['delivery_date'];
    // company = json['company'];
    // skipDeliveryNote = json['skip_delivery_note'];
    // isReverseCharge = json['is_reverse_charge'];
    // isExportWithGst = json['is_export_with_gst'];
    // currency = json['currency'];
    // conversionRate = json['conversion_rate'];
    // sellingPriceList = json['selling_price_list'];
    // priceListCurrency = json['price_list_currency'];
    // plcConversionRate = json['plc_conversion_rate'];
    // ignorePricingRule = json['ignore_pricing_rule'];
    // reserveStock = json['reserve_stock'];
    // totalQty = json['total_qty'];
    // totalNetWeight = json['total_net_weight'];
    // baseTotal = json['base_total'];
    // baseNetTotal = json['base_net_total'];
    // total = json['total'];
    // netTotal = json['net_total'];
    // taxCategory = json['tax_category'];
    // taxesAndCharges = json['taxes_and_charges'];
    // baseTotalTaxesAndCharges = json['base_total_taxes_and_charges'];
    // totalTaxesAndCharges = json['total_taxes_and_charges'];
    // baseGrandTotal = json['base_grand_total'];
    // baseRoundingAdjustment = json['base_rounding_adjustment'];
    // baseRoundedTotal = json['base_rounded_total'];
    // baseInWords = json['base_in_words'];
    // grandTotal = json['grand_total'];
    // roundingAdjustment = json['rounding_adjustment'];
    // roundedTotal = json['rounded_total'];
    // inWords = json['in_words'];
    // advancePaid = json['advance_paid'];
    // disableRoundedTotal = json['disable_rounded_total'];
    // applyDiscountOn = json['apply_discount_on'];
    // baseDiscountAmount = json['base_discount_amount'];
    // additionalDiscountPercentage = json['additional_discount_percentage'];
    // discountAmount = json['discount_amount'];
    // customerAddress = json['customer_address'];
    // addressDisplay = json['address_display'];
    // billingAddressGstin = json['billing_address_gstin'];
    // gstCategory = json['gst_category'];
    // placeOfSupply = json['place_of_supply'];
    // customerGroup = json['customer_group'];
    // territory = json['territory'];
    // contactPerson = json['contact_person'];
    // contactDisplay = json['contact_display'];
    // contactPhone = json['contact_phone'];
    // contactMobile = json['contact_mobile'];
    // contactEmail = json['contact_email'];
    // companyAddress = json['company_address'];
    // companyGstin = json['company_gstin'];
    // companyAddressDisplay = json['company_address_display'];
    // status = json['status'];
    // deliveryStatus = json['delivery_status'];
    // perDelivered = json['per_delivered'];
    // perPrimaryPacked = json['per_primary_packed'];
    // perSecondaryPacked = json['per_secondary_packed'];
    // primaryPackingStatus = json['primary_packing_status'];
    // secondaryPackingStatus = json['secondary_packing_status'];
    // perBilled = json['per_billed'];
    // perPicked = json['per_picked'];
    // billingStatus = json['billing_status'];
    // amountEligibleForCommission = json['amount_eligible_for_commission'];
    // commissionRate = json['commission_rate'];
    // totalCommission = json['total_commission'];
    // loyaltyPoints = json['loyalty_points'];
    // loyaltyAmount = json['loyalty_amount'];
    // groupSameItems = json['group_same_items'];
    // language = json['language'];
    // isInternalCustomer = json['is_internal_customer'];
    // doctype = json['doctype'];
    // if (json['items'] != null) {
    //   items = <Items>[];
    //   json['items'].forEach((v) {
    //     items!.add(new Items.fromJson(v));
    //   });
    // }
    // if (json['pricing_rules'] != null) {
    //   pricingRules = <Null>[];
    //   json['pricing_rules'].forEach((v) {
    //     pricingRules!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['sales_team'] != null) {
    //   salesTeam = <Null>[];
    //   json['sales_team'].forEach((v) {
    //     salesTeam!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['taxes'] != null) {
    //   taxes = <Null>[];
    //   json['taxes'].forEach((v) {
    //     taxes!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['packed_items'] != null) {
    //   packedItems = <Null>[];
    //   json['packed_items'].forEach((v) {
    //     packedItems!.add(new Null.fromJson(v));
    //   });
    // }
    // if (json['payment_schedule'] != null) {
    //   paymentSchedule = <PaymentSchedule>[];
    //   json['payment_schedule'].forEach((v) {
    //     paymentSchedule!.add(new PaymentSchedule.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    // data['owner'] = this.owner;
    // data['creation'] = this.creation;
    // data['modified'] = this.modified;
    // data['modified_by'] = this.modifiedBy;
    // data['docstatus'] = this.docstatus;
    // data['idx'] = this.idx;
    // data['title'] = this.title;
    // data['naming_series'] = this.namingSeries;
    // data['customer'] = this.customer;
    // data['customer_name'] = this.customerName;
    // data['order_type'] = this.orderType;
    // data['transaction_date'] = this.transactionDate;
    // data['delivery_date'] = this.deliveryDate;
    // data['company'] = this.company;
    // data['skip_delivery_note'] = this.skipDeliveryNote;
    // data['is_reverse_charge'] = this.isReverseCharge;
    // data['is_export_with_gst'] = this.isExportWithGst;
    // data['currency'] = this.currency;
    // data['conversion_rate'] = this.conversionRate;
    // data['selling_price_list'] = this.sellingPriceList;
    // data['price_list_currency'] = this.priceListCurrency;
    // data['plc_conversion_rate'] = this.plcConversionRate;
    // data['ignore_pricing_rule'] = this.ignorePricingRule;
    // data['reserve_stock'] = this.reserveStock;
    // data['total_qty'] = this.totalQty;
    // data['total_net_weight'] = this.totalNetWeight;
    // data['base_total'] = this.baseTotal;
    // data['base_net_total'] = this.baseNetTotal;
    // data['total'] = this.total;
    // data['net_total'] = this.netTotal;
    // data['tax_category'] = this.taxCategory;
    // data['taxes_and_charges'] = this.taxesAndCharges;
    // data['base_total_taxes_and_charges'] = this.baseTotalTaxesAndCharges;
    // data['total_taxes_and_charges'] = this.totalTaxesAndCharges;
    // data['base_grand_total'] = this.baseGrandTotal;
    // data['base_rounding_adjustment'] = this.baseRoundingAdjustment;
    // data['base_rounded_total'] = this.baseRoundedTotal;
    // data['base_in_words'] = this.baseInWords;
    // data['grand_total'] = this.grandTotal;
    // data['rounding_adjustment'] = this.roundingAdjustment;
    // data['rounded_total'] = this.roundedTotal;
    // data['in_words'] = this.inWords;
    // data['advance_paid'] = this.advancePaid;
    // data['disable_rounded_total'] = this.disableRoundedTotal;
    // data['apply_discount_on'] = this.applyDiscountOn;
    // data['base_discount_amount'] = this.baseDiscountAmount;
    // data['additional_discount_percentage'] = this.additionalDiscountPercentage;
    // data['discount_amount'] = this.discountAmount;
    // data['customer_address'] = this.customerAddress;
    // data['address_display'] = this.addressDisplay;
    // data['billing_address_gstin'] = this.billingAddressGstin;
    // data['gst_category'] = this.gstCategory;
    // data['place_of_supply'] = this.placeOfSupply;
    // data['customer_group'] = this.customerGroup;
    // data['territory'] = this.territory;
    // data['contact_person'] = this.contactPerson;
    // data['contact_display'] = this.contactDisplay;
    // data['contact_phone'] = this.contactPhone;
    // data['contact_mobile'] = this.contactMobile;
    // data['contact_email'] = this.contactEmail;
    // data['company_address'] = this.companyAddress;
    // data['company_gstin'] = this.companyGstin;
    // data['company_address_display'] = this.companyAddressDisplay;
    // data['status'] = this.status;
    // data['delivery_status'] = this.deliveryStatus;
    // data['per_delivered'] = this.perDelivered;
    // data['per_primary_packed'] = this.perPrimaryPacked;
    // data['per_secondary_packed'] = this.perSecondaryPacked;
    // data['primary_packing_status'] = this.primaryPackingStatus;
    // data['secondary_packing_status'] = this.secondaryPackingStatus;
    // data['per_billed'] = this.perBilled;
    // data['per_picked'] = this.perPicked;
    // data['billing_status'] = this.billingStatus;
    // data['amount_eligible_for_commission'] = this.amountEligibleForCommission;
    // data['commission_rate'] = this.commissionRate;
    // data['total_commission'] = this.totalCommission;
    // data['loyalty_points'] = this.loyaltyPoints;
    // data['loyalty_amount'] = this.loyaltyAmount;
    // data['group_same_items'] = this.groupSameItems;
    // data['language'] = this.language;
    // data['is_internal_customer'] = this.isInternalCustomer;
    // data['doctype'] = this.doctype;
    // if (this.items != null) {
    //   data['items'] = this.items!.map((v) => v.toJson()).toList();
    // }
    // if (this.pricingRules != null) {
    //   data['pricing_rules'] =
    //       this.pricingRules!.map((v) => v.toJson()).toList();
    // }
    // if (this.salesTeam != null) {
    //   data['sales_team'] = this.salesTeam!.map((v) => v.toJson()).toList();
    // }
    // if (this.taxes != null) {
    //   data['taxes'] = this.taxes!.map((v) => v.toJson()).toList();
    // }
    // if (this.packedItems != null) {
    //   data['packed_items'] = this.packedItems!.map((v) => v.toJson()).toList();
    // }
    // if (this.paymentSchedule != null) {
    //   data['payment_schedule'] =
    //       this.paymentSchedule!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Items {
  String? name;
  // String? owner;
  // String? creation;
  // String? modified;
  // String? modifiedBy;
  // int? docstatus;
  // int? idx;
  // String? itemCode;
  // int? ensureDeliveryBasedOnProducedSerialNo;
  // int? reserveStock;
  // String? deliveryDate;
  // String? itemName;
  // int? siNo;
  // int? package;
  // String? description;
  // String? gstHsnCode;
  // String? itemGroup;
  // String? image;
  // int? qty;
  // int? cancelledQuantity;
  // String? cancellationReason;
  // String? stockUom;
  // String? uom;
  // int? conversionFactor;
  // int? stockQty;
  // int? actualOrderedQuanity;
  // int? stockReservedQty;
  // int? priceListRate;
  // int? basePriceListRate;
  // String? marginType;
  // int? marginRateOrAmount;
  // int? rateWithMargin;
  // int? discountPercentage;
  // int? discountAmount;
  // int? baseRateWithMargin;
  // int? rate;
  // int? amount;
  // String? gstTreatment;
  // int? baseRate;
  // int? baseAmount;
  // int? stockUomRate;
  // int? isFreeItem;
  // int? grantCommission;
  // int? netRate;
  // int? netAmount;
  // int? baseNetRate;
  // int? baseNetAmount;
  // int? taxableValue;
  // int? igstRate;
  // int? cgstRate;
  // int? sgstRate;
  // int? cessRate;
  // int? cessNonAdvolRate;
  // int? igstAmount;
  // int? cgstAmount;
  // int? sgstAmount;
  // int? cessAmount;
  // int? cessNonAdvolAmount;
  // int? billedAmt;
  // int? valuationRate;
  // int? grossProfit;
  // int? deliveredBySupplier;
  // int? weightPerUnit;
  // int? totalWeight;
  // String? customItemSize;
  // int? customLenthOfItem;
  // int? customWidthOfItem;
  // String? warehouse;
  // int? againstBlanketOrder;
  // int? blanketOrderRate;
  // int? projectedQty;
  // int? actualQty;
  // int? orderedQty;
  // int? plannedQty;
  // int? productionPlanQty;
  // int? workOrderQty;
  // int? deliveredQty;
  // int? producedQty;
  // int? returnedQty;
  // int? pickedQty;
  // int? pageBreak;
  // String? itemTaxRate;
  // String? transactionDate;
  // String? parent;
  // String? parentfield;
  // String? parenttype;
  // String? doctype;
  // int? iUnsaved;

  Items(
      {this.name,
      // this.owner,
      // this.creation,
      // this.modified,
      // this.modifiedBy,
      // this.docstatus,
      // this.idx,
      // this.itemCode,
      // this.ensureDeliveryBasedOnProducedSerialNo,
      // this.reserveStock,
      // this.deliveryDate,
      // this.itemName,
      // this.siNo,
      // this.package,
      // this.description,
      // this.gstHsnCode,
      // this.itemGroup,
      // this.image,
      // this.qty,
      // this.cancelledQuantity,
      // this.cancellationReason,
      // this.stockUom,
      // this.uom,
      // this.conversionFactor,
      // this.stockQty,
      // this.actualOrderedQuanity,
      // this.stockReservedQty,
      // this.priceListRate,
      // this.basePriceListRate,
      // this.marginType,
      // this.marginRateOrAmount,
      // this.rateWithMargin,
      // this.discountPercentage,
      // this.discountAmount,
      // this.baseRateWithMargin,
      // this.rate,
      // this.amount,
      // this.gstTreatment,
      // this.baseRate,
      // this.baseAmount,
      // this.stockUomRate,
      // this.isFreeItem,
      // this.grantCommission,
      // this.netRate,
      // this.netAmount,
      // this.baseNetRate,
      // this.baseNetAmount,
      // this.taxableValue,
      // this.igstRate,
      // this.cgstRate,
      // this.sgstRate,
      // this.cessRate,
      // this.cessNonAdvolRate,
      // this.igstAmount,
      // this.cgstAmount,
      // this.sgstAmount,
      // this.cessAmount,
      // this.cessNonAdvolAmount,
      // this.billedAmt,
      // this.valuationRate,
      // this.grossProfit,
      // this.deliveredBySupplier,
      // this.weightPerUnit,
      // this.totalWeight,
      // this.customItemSize,
      // this.customLenthOfItem,
      // this.customWidthOfItem,
      // this.warehouse,
      // this.againstBlanketOrder,
      // this.blanketOrderRate,
      // this.projectedQty,
      // this.actualQty,
      // this.orderedQty,
      // this.plannedQty,
      // this.productionPlanQty,
      // this.workOrderQty,
      // this.deliveredQty,
      // this.producedQty,
      // this.returnedQty,
      // this.pickedQty,
      // this.pageBreak,
      // this.itemTaxRate,
      // this.transactionDate,
      // this.parent,
      // this.parentfield,
      // this.parenttype,
      // this.doctype,
      // this.iUnsaved
      });

  Items.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    // owner = json['owner'];
    // creation = json['creation'];
    // modified = json['modified'];
    // modifiedBy = json['modified_by'];
    // docstatus = json['docstatus'];
    // idx = json['idx'];
    // itemCode = json['item_code'];
    // ensureDeliveryBasedOnProducedSerialNo =
    //     json['ensure_delivery_based_on_produced_serial_no'];
    // reserveStock = json['reserve_stock'];
    // deliveryDate = json['delivery_date'];
    // itemName = json['item_name'];
    // siNo = json['si_no'];
    // package = json['package'];
    // description = json['description'];
    // gstHsnCode = json['gst_hsn_code'];
    // itemGroup = json['item_group'];
    // image = json['image'];
    // qty = json['qty'];
    // cancelledQuantity = json['cancelled_quantity'];
    // cancellationReason = json['cancellation_reason'];
    // stockUom = json['stock_uom'];
    // uom = json['uom'];
    // conversionFactor = json['conversion_factor'];
    // stockQty = json['stock_qty'];
    // actualOrderedQuanity = json['actual_ordered_quanity'];
    // stockReservedQty = json['stock_reserved_qty'];
    // priceListRate = json['price_list_rate'];
    // basePriceListRate = json['base_price_list_rate'];
    // marginType = json['margin_type'];
    // marginRateOrAmount = json['margin_rate_or_amount'];
    // rateWithMargin = json['rate_with_margin'];
    // discountPercentage = json['discount_percentage'];
    // discountAmount = json['discount_amount'];
    // baseRateWithMargin = json['base_rate_with_margin'];
    // rate = json['rate'];
    // amount = json['amount'];
    // gstTreatment = json['gst_treatment'];
    // baseRate = json['base_rate'];
    // baseAmount = json['base_amount'];
    // stockUomRate = json['stock_uom_rate'];
    // isFreeItem = json['is_free_item'];
    // grantCommission = json['grant_commission'];
    // netRate = json['net_rate'];
    // netAmount = json['net_amount'];
    // baseNetRate = json['base_net_rate'];
    // baseNetAmount = json['base_net_amount'];
    // taxableValue = json['taxable_value'];
    // igstRate = json['igst_rate'];
    // cgstRate = json['cgst_rate'];
    // sgstRate = json['sgst_rate'];
    // cessRate = json['cess_rate'];
    // cessNonAdvolRate = json['cess_non_advol_rate'];
    // igstAmount = json['igst_amount'];
    // cgstAmount = json['cgst_amount'];
    // sgstAmount = json['sgst_amount'];
    // cessAmount = json['cess_amount'];
    // cessNonAdvolAmount = json['cess_non_advol_amount'];
    // billedAmt = json['billed_amt'];
    // valuationRate = json['valuation_rate'];
    // grossProfit = json['gross_profit'];
    // deliveredBySupplier = json['delivered_by_supplier'];
    // weightPerUnit = json['weight_per_unit'];
    // totalWeight = json['total_weight'];
    // customItemSize = json['custom_item_size'];
    // customLenthOfItem = json['custom_lenth_of_item'];
    // customWidthOfItem = json['custom_width_of_item'];
    // warehouse = json['warehouse'];
    // againstBlanketOrder = json['against_blanket_order'];
    // blanketOrderRate = json['blanket_order_rate'];
    // projectedQty = json['projected_qty'];
    // actualQty = json['actual_qty'];
    // orderedQty = json['ordered_qty'];
    // plannedQty = json['planned_qty'];
    // productionPlanQty = json['production_plan_qty'];
    // workOrderQty = json['work_order_qty'];
    // deliveredQty = json['delivered_qty'];
    // producedQty = json['produced_qty'];
    // returnedQty = json['returned_qty'];
    // pickedQty = json['picked_qty'];
    // pageBreak = json['page_break'];
    // itemTaxRate = json['item_tax_rate'];
    // transactionDate = json['transaction_date'];
    // parent = json['parent'];
    // parentfield = json['parentfield'];
    // parenttype = json['parenttype'];
    // doctype = json['doctype'];
    // iUnsaved = json['__unsaved'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    // data['owner'] = this.owner;
    // data['creation'] = this.creation;
    // data['modified'] = this.modified;
    // data['modified_by'] = this.modifiedBy;
    // data['docstatus'] = this.docstatus;
    // data['idx'] = this.idx;
    // data['item_code'] = this.itemCode;
    // data['ensure_delivery_based_on_produced_serial_no'] =
    //     this.ensureDeliveryBasedOnProducedSerialNo;
    // data['reserve_stock'] = this.reserveStock;
    // data['delivery_date'] = this.deliveryDate;
    // data['item_name'] = this.itemName;
    // data['si_no'] = this.siNo;
    // data['package'] = this.package;
    // data['description'] = this.description;
    // data['gst_hsn_code'] = this.gstHsnCode;
    // data['item_group'] = this.itemGroup;
    // data['image'] = this.image;
    // data['qty'] = this.qty;
    // data['cancelled_quantity'] = this.cancelledQuantity;
    // data['cancellation_reason'] = this.cancellationReason;
    // data['stock_uom'] = this.stockUom;
    // data['uom'] = this.uom;
    // data['conversion_factor'] = this.conversionFactor;
    // data['stock_qty'] = this.stockQty;
    // data['actual_ordered_quanity'] = this.actualOrderedQuanity;
    // data['stock_reserved_qty'] = this.stockReservedQty;
    // data['price_list_rate'] = this.priceListRate;
    // data['base_price_list_rate'] = this.basePriceListRate;
    // data['margin_type'] = this.marginType;
    // data['margin_rate_or_amount'] = this.marginRateOrAmount;
    // data['rate_with_margin'] = this.rateWithMargin;
    // data['discount_percentage'] = this.discountPercentage;
    // data['discount_amount'] = this.discountAmount;
    // data['base_rate_with_margin'] = this.baseRateWithMargin;
    // data['rate'] = this.rate;
    // data['amount'] = this.amount;
    // data['gst_treatment'] = this.gstTreatment;
    // data['base_rate'] = this.baseRate;
    // data['base_amount'] = this.baseAmount;
    // data['stock_uom_rate'] = this.stockUomRate;
    // data['is_free_item'] = this.isFreeItem;
    // data['grant_commission'] = this.grantCommission;
    // data['net_rate'] = this.netRate;
    // data['net_amount'] = this.netAmount;
    // data['base_net_rate'] = this.baseNetRate;
    // data['base_net_amount'] = this.baseNetAmount;
    // data['taxable_value'] = this.taxableValue;
    // data['igst_rate'] = this.igstRate;
    // data['cgst_rate'] = this.cgstRate;
    // data['sgst_rate'] = this.sgstRate;
    // data['cess_rate'] = this.cessRate;
    // data['cess_non_advol_rate'] = this.cessNonAdvolRate;
    // data['igst_amount'] = this.igstAmount;
    // data['cgst_amount'] = this.cgstAmount;
    // data['sgst_amount'] = this.sgstAmount;
    // data['cess_amount'] = this.cessAmount;
    // data['cess_non_advol_amount'] = this.cessNonAdvolAmount;
    // data['billed_amt'] = this.billedAmt;
    // data['valuation_rate'] = this.valuationRate;
    // data['gross_profit'] = this.grossProfit;
    // data['delivered_by_supplier'] = this.deliveredBySupplier;
    // data['weight_per_unit'] = this.weightPerUnit;
    // data['total_weight'] = this.totalWeight;
    // data['custom_item_size'] = this.customItemSize;
    // data['custom_lenth_of_item'] = this.customLenthOfItem;
    // data['custom_width_of_item'] = this.customWidthOfItem;
    // data['warehouse'] = this.warehouse;
    // data['against_blanket_order'] = this.againstBlanketOrder;
    // data['blanket_order_rate'] = this.blanketOrderRate;
    // data['projected_qty'] = this.projectedQty;
    // data['actual_qty'] = this.actualQty;
    // data['ordered_qty'] = this.orderedQty;
    // data['planned_qty'] = this.plannedQty;
    // data['production_plan_qty'] = this.productionPlanQty;
    // data['work_order_qty'] = this.workOrderQty;
    // data['delivered_qty'] = this.deliveredQty;
    // data['produced_qty'] = this.producedQty;
    // data['returned_qty'] = this.returnedQty;
    // data['picked_qty'] = this.pickedQty;
    // data['page_break'] = this.pageBreak;
    // data['item_tax_rate'] = this.itemTaxRate;
    // data['transaction_date'] = this.transactionDate;
    // data['parent'] = this.parent;
    // data['parentfield'] = this.parentfield;
    // data['parenttype'] = this.parenttype;
    // data['doctype'] = this.doctype;
    // data['__unsaved'] = this.iUnsaved;
    return data;
  }
}

// class PaymentSchedule {
//   String? name;
//   String? creation;
//   String? modified;
//   String? modifiedBy;
//   int? docstatus;
//   int? idx;
//   String? dueDate;
//   int? invoicePortion;
//   int? discount;
//   int? paymentAmount;
//   int? outstanding;
//   int? paidAmount;
//   int? discountedAmount;
//   int? basePaymentAmount;
//   String? parent;
//   String? parentfield;
//   String? parenttype;
//   String? doctype;

//   PaymentSchedule(
//       {this.name,
//       this.creation,
//       this.modified,
//       this.modifiedBy,
//       this.docstatus,
//       this.idx,
//       this.dueDate,
//       this.invoicePortion,
//       this.discount,
//       this.paymentAmount,
//       this.outstanding,
//       this.paidAmount,
//       this.discountedAmount,
//       this.basePaymentAmount,
//       this.parent,
//       this.parentfield,
//       this.parenttype,
//       this.doctype});

//   PaymentSchedule.fromJson(Map<String, dynamic> json) {
//     name = json['name'];
//     creation = json['creation'];
//     modified = json['modified'];
//     modifiedBy = json['modified_by'];
//     docstatus = json['docstatus'];
//     idx = json['idx'];
//     dueDate = json['due_date'];
//     invoicePortion = json['invoice_portion'];
//     discount = json['discount'];
//     paymentAmount = json['payment_amount'];
//     outstanding = json['outstanding'];
//     paidAmount = json['paid_amount'];
//     discountedAmount = json['discounted_amount'];
//     basePaymentAmount = json['base_payment_amount'];
//     parent = json['parent'];
//     parentfield = json['parentfield'];
//     parenttype = json['parenttype'];
//     doctype = json['doctype'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['name'] = this.name;
//     data['creation'] = this.creation;
//     data['modified'] = this.modified;
//     data['modified_by'] = this.modifiedBy;
//     data['docstatus'] = this.docstatus;
//     data['idx'] = this.idx;
//     data['due_date'] = this.dueDate;
//     data['invoice_portion'] = this.invoicePortion;
//     data['discount'] = this.discount;
//     data['payment_amount'] = this.paymentAmount;
//     data['outstanding'] = this.outstanding;
//     data['paid_amount'] = this.paidAmount;
//     data['discounted_amount'] = this.discountedAmount;
//     data['base_payment_amount'] = this.basePaymentAmount;
//     data['parent'] = this.parent;
//     data['parentfield'] = this.parentfield;
//     data['parenttype'] = this.parenttype;
//     data['doctype'] = this.doctype;
//     return data;
//   }
// }