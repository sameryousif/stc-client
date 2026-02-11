import 'package:flutter/material.dart';

class InvoiceItem {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController taxRateController;

  InvoiceItem({
    String name = "Sample Item",
    String description = "Description here",
    double quantity = 1,
    double unitPrice = 0,
    double taxRate = 0,
  }) : nameController = TextEditingController(text: name),
       descriptionController = TextEditingController(text: description),
       quantityController = TextEditingController(text: quantity.toString()),
       unitPriceController = TextEditingController(text: unitPrice.toString()),
       taxRateController = TextEditingController(text: taxRate.toString());

  // Numeric getters
  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double get taxRate => double.tryParse(taxRateController.text) ?? 0;
  double get total => quantity * unitPrice;

  // Text getters (THIS FIXES YOUR XML)
  String get name => nameController.text;
  String get description => descriptionController.text;
}
