class PaymentEntry {
  String modeOfPayment;
  double amount;

  PaymentEntry({
    required this.modeOfPayment,
    required this.amount,
  });

  @override
  String toString() {
    return "{modeOfPayment: $modeOfPayment, amount: $amount}";
  }
}
