class InvoiceItem {
  String name;
  String description;
  int quantity;
  double unitPrice;
  double taxRate;

  InvoiceItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
  });

  double get total => quantity * unitPrice;
}
