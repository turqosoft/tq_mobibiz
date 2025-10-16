class PosInvoice {
  final int docstatus;
  final String customer;
  final String company;
  final String currency;
  final String sellingPriceList;
  final List<Payment> payments;
  final List<Items> items;
  double? additionalDiscountPercentage; // ✅ new field

  PosInvoice({
    required this.docstatus,
    required this.customer,
    required this.company,
    required this.currency,
    required this.sellingPriceList,
    required this.payments,
    required this.items,
    this.additionalDiscountPercentage,

  });
  Map<String, dynamic> toJson() {
    return {
        "docstatus": docstatus,
        "customer": customer,
      "company": company,
      "currency": currency,
      "selling_price_list": sellingPriceList,
      "payments": payments.map((p) => p.toJson()).toList(),
      "items": items.map((i) => i.toJson()).toList(),
      if (additionalDiscountPercentage != null)
        "additional_discount_percentage": additionalDiscountPercentage,
    };
  }
}

class Payment {
  final String modeOfPayment;
  final double amount;

  Payment({
    required this.modeOfPayment,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      "mode_of_payment": modeOfPayment,
      "amount": amount,
    };
  }
}

class Items {
  final String itemCode;
  final String itemName;

  final double qty;
  final String uom;
  final double rate;
  final double priceListRate;
  final String warehouse;

  Items({
    required this.itemCode,
    required this.itemName,

    required this.qty,
    required this.uom,
    required this.rate,
    required this.priceListRate,
    required this.warehouse,
  });

  Map<String, dynamic> toJson() {
    return {
      "item_code": itemCode,
      "item_name": itemName,
      "qty": qty,
      "uom": uom,
      "rate": rate,
      "price_list_rate": priceListRate,
      "warehouse": warehouse,
    };
  }
}
