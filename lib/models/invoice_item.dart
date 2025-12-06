import 'package:flutter/material.dart';

class InvoiceItem {
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController taxRateController;

  InvoiceItem({
    String name = "Sample Item",
    String description = "Description here",
    double quantity = 1,
    double unitPrice = 0,
    double taxRate = 0,
  }) : name = TextEditingController(text: name),
       description = TextEditingController(text: description),
       quantityController = TextEditingController(text: quantity.toString()),
       unitPriceController = TextEditingController(text: unitPrice.toString()),
       taxRateController = TextEditingController(text: taxRate.toString());

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double get taxRate => double.tryParse(taxRateController.text) ?? 0;
  double get total => quantity * unitPrice;
}
