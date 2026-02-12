import 'package:flutter/material.dart';

// Model class representing an invoice item, containing TextEditingControllers for the item's name, description, quantity, unit price, and tax rate, as well as getter methods to retrieve the current values of these fields and calculate the total price for the item based on the quantity and unit price
class InvoiceItem {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController taxRateController;

  InvoiceItem({
    required String name,
    required String description,
    required int quantity,
    required double unitPrice,
    required double taxRate,
  }) : nameController = TextEditingController(text: name),
       descriptionController = TextEditingController(text: description),
       quantityController = TextEditingController(text: quantity.toString()),
       unitPriceController = TextEditingController(text: unitPrice.toString()),
       taxRateController = TextEditingController(text: taxRate.toString());

  int get quantity => int.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double get taxRate => double.tryParse(taxRateController.text) ?? 0;
  double get total => quantity * unitPrice;
}
