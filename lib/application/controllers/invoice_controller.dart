import 'package:flutter/foundation.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/models/data_model.dart';
import 'package:uuid/uuid.dart';

// Controller responsible for managing the state of the invoice form, including the invoice information, supplier and customer details, invoice items, and reactive totals, while providing methods to add/remove items and recalculate totals whenever item details change, as well as a method to clear all data and reset the form
class InvoiceFormController {
  String invoiceNumber;
  DateTime invoiceDate;
  String invoiceType;
  String currencyCode;

  Supplier supplier;
  Customer customer;

  final List<InvoiceItem> items = [];

  final ValueNotifier<double> subtotal = ValueNotifier(0);
  final ValueNotifier<double> taxTotal = ValueNotifier(0);
  final ValueNotifier<double> grandTotal = ValueNotifier(0);

  InvoiceFormController({Supplier? supplier, Customer? customer})
    : invoiceNumber = const Uuid().v4(),
      invoiceDate = DateTime.now(),
      invoiceType = '380',
      currencyCode = 'SDG',
      supplier =
          supplier ??
          Supplier(
            name: 'My Supplier',
            tin: '123456789',
            address: 'Khartoum Bahri',
            city: 'Khartoum',
            country: 'SD',
            phone: '+249912345678',
            email: 'supplier@example.com',
          ),
      customer =
          customer ??
          Customer(
            name: 'Default Customer',
            tin: '5566778899',
            address: 'Omdurman',
            city: 'Omdurman',
            country: 'SD',
            phone: '+249911111111',
            email: 'customer@example.com',
          ) {
    addItem(
      InvoiceItem(
        name: "Laptop",
        description: "Dell",
        quantity: 2,
        unitPrice: 1500,
        taxRate: 15,
      ),
    );
  }

  // Supplier and Customer info getters for UI/backend
  Map<String, String> get supplierInfo => {
    "name": supplier.name,
    "vat": supplier.tin,
    "address": supplier.address,
    "city": supplier.city,
    "country": supplier.country,
    "phone": supplier.phone,
    "email": supplier.email,
  };

  Map<String, String> get customerInfo => {
    "name": customer.name,
    "vat": customer.tin,
    "address": customer.address,
    "city": customer.city,
    "country": customer.country,
    "phone": customer.phone,
    "email": customer.email,
  };

  void addItem(InvoiceItem item) {
    // Listen to item changes
    item.quantityController.addListener(recalculateTotals);
    item.unitPriceController.addListener(recalculateTotals);
    item.taxRateController.addListener(recalculateTotals);

    items.add(item);
    recalculateTotals();
  }

  void addItemListeners(InvoiceItem item) {
    item.quantityController.addListener(recalculateTotals);
    item.unitPriceController.addListener(recalculateTotals);
    item.taxRateController.addListener(recalculateTotals);
  }

  void removeItem(int index) {
    final item = items.removeAt(index);
    item.quantityController.removeListener(recalculateTotals);
    item.unitPriceController.removeListener(recalculateTotals);
    item.taxRateController.removeListener(recalculateTotals);
    recalculateTotals();
  }

  void recalculateTotals() {
    double sub = 0;
    double tax = 0;
    for (var item in items) {
      sub += item.total;
      tax += item.total * (item.taxRate / 100);
    }
    subtotal.value = sub;
    taxTotal.value = tax;
    grandTotal.value = sub + tax;
  }

  void clearAll() {
    items.clear();
    recalculateTotals();
    invoiceNumber = const Uuid().v4();
    invoiceDate = DateTime.now();
  }
}
