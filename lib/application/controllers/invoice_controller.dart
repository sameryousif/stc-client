import 'package:flutter/foundation.dart';
import 'package:stc_client/core/certificate/cert_info.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/models/data_model.dart';
import 'package:uuid/uuid.dart';

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

  InvoiceFormController._({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceType,
    required this.currencyCode,
    required this.supplier,
    required this.customer,
  });

  static Future<InvoiceFormController> create({
    Supplier? supplier,
    Customer? customer,
  }) async {
    final String serial = await extractSerial() ?? 'UNKNOWN_TIN';

    final controller = InvoiceFormController._(
      invoiceNumber: const Uuid().v4(),
      invoiceDate: DateTime.now(),
      invoiceType: '380',
      currencyCode: 'SDG',
      supplier:
          supplier ??
          Supplier(
            name: 'My Supplier',
            tin: '123456789',
            street: 'Baladyia st',
            address: 'Khartoum Bahri',
            city: 'Khartoum',
            country: 'SD',
            phone: '+249912345678',
            email: 'supplier@example.com',
          ),
      customer:
          customer ??
          Customer(
            name: 'Default Customer',
            tin: serial,
            street: 'Baladyia st',
            address: 'Omdurman',
            city: 'Omdurman',
            country: 'SD',
            phone: '+249911111111',
            email: 'customer@example.com',
          ),
    );

    controller.addItem(
      InvoiceItem(
        name: "Laptop",
        description: "Dell",
        quantity: 2,
        unitPrice: 1500,
        taxRate: 15,
      ),
    );

    return controller;
  }

  // Supplier and Customer info getters
  Map<String, String> get supplierInfo => {
    "name": supplier.name,
    "vat": supplier.tin,
    "street": supplier.street,
    "address": supplier.address,
    "city": supplier.city,
    "country": supplier.country,
    "phone": supplier.phone,
    "email": supplier.email,
  };

  Map<String, String> get customerInfo => {
    "name": customer.name,
    "vat": customer.tin,
    "street": customer.street,
    "address": customer.address,
    "city": customer.city,
    "country": customer.country,
    "phone": customer.phone,
    "email": customer.email,
  };

  void addItem(InvoiceItem item) {
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
    recalculateTotals();
    invoiceNumber = const Uuid().v4();
    invoiceDate = DateTime.now();
  }
}
