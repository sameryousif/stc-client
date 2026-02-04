import 'package:flutter/material.dart';
import 'package:stc_client/models/invoice_item.dart';
import 'package:uuid/uuid.dart';

class InvoiceFormController {
  // Invoice info
  final invoiceNumber = TextEditingController();
  final invoiceDate = TextEditingController();
  final invoiceType = TextEditingController();
  final currencyCode = TextEditingController();

  // Supplier info
  final supplierName = TextEditingController();
  final supplierTIN = TextEditingController();
  final supplierAddress = TextEditingController();
  final supplierCity = TextEditingController();
  final supplierCountry = TextEditingController();
  final supplierPhone = TextEditingController();
  final supplierEmail = TextEditingController();

  // Customer info
  final customerName = TextEditingController();
  final customerTIN = TextEditingController();
  final customerAddress = TextEditingController();
  final customerCity = TextEditingController();
  final customerCountry = TextEditingController();
  final customerPhone = TextEditingController();
  final customerEmail = TextEditingController();

  //////
  final xmlController = TextEditingController();
  // Items list
  final List<InvoiceItem> items = [];

  void initDefaults(VoidCallback recalculate) {
    invoiceNumber.text = const Uuid().v4();
    invoiceDate.text = DateTime.now().toString().split(' ').first;
    invoiceType.text = "380";
    currencyCode.text = "SDG";

    supplierName.text = "My Supplier";
    supplierTIN.text = "123456789";
    supplierAddress.text = "Khartoum Bahri";
    supplierCity.text = "Khartoum";
    supplierCountry.text = "SD";
    supplierPhone.text = "+249912345678";
    supplierEmail.text = "supplier@example.com";

    customerName.text = "Default Customer";
    customerTIN.text = "5566778899";
    customerAddress.text = "Omdurman";
    customerCity.text = "Omdurman";
    customerCountry.text = "SD";
    customerPhone.text = "+249911111111";
    customerEmail.text = "customer@example.com";

    final firstItem = InvoiceItem(
      name: "Laptop",
      description: "Dell",
      quantity: 2,
      unitPrice: 1500,
      taxRate: 15,
    );

    _addItemListeners(firstItem, recalculate);
    items.add(firstItem);
  }

  void addItem(InvoiceItem item, VoidCallback recalculate) {
    _addItemListeners(item, recalculate);
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void _addItemListeners(InvoiceItem item, VoidCallback recalculate) {
    item.quantityController.addListener(recalculate);
    item.unitPriceController.addListener(recalculate);
    item.taxRateController.addListener(recalculate);
  }

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.quantity * item.unitPrice);

  double get taxTotal =>
      items.fold(0, (sum, item) => sum + item.total * (item.taxRate / 100));

  double get grandTotal => subtotal + taxTotal;

  Map<String, String> get supplierInfo => {
    "name": supplierName.text,
    "vat": supplierTIN.text,
  };

  Map<String, String> get customerInfo => {
    "name": customerName.text,
    "vat": customerTIN.text,
  };

  void dispose() {
    invoiceNumber.dispose();
    invoiceDate.dispose();
    invoiceType.dispose();
    currencyCode.dispose();

    supplierName.dispose();
    supplierTIN.dispose();
    supplierAddress.dispose();
    supplierCity.dispose();
    supplierCountry.dispose();
    supplierPhone.dispose();
    supplierEmail.dispose();

    customerName.dispose();
    customerTIN.dispose();
    customerAddress.dispose();
    customerCity.dispose();
    customerCountry.dispose();
    customerPhone.dispose();
    customerEmail.dispose();
  }

  //////////////////
  /// Clear all fields
  void clearAll() {
    invoiceNumber.clear();
    invoiceDate.clear();
    invoiceType.clear();
    currencyCode.clear();

    supplierName.clear();
    supplierTIN.clear();
    supplierAddress.clear();
    supplierCity.clear();
    supplierCountry.clear();
    supplierPhone.clear();
    supplierEmail.clear();

    customerName.clear();
    customerTIN.clear();
    customerAddress.clear();
    customerCity.clear();
    customerCountry.clear();
    customerPhone.clear();
    customerEmail.clear();

    items.clear();
    xmlController.clear();
  }
}
