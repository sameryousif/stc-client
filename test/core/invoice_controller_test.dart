import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/models/data_model.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';

void main() {
  group('InvoiceFormController calculations', () {
    InvoiceFormController _createTestController() {
      return InvoiceFormController.createForTest(
        supplier: Supplier(
          name: 'Test Supplier',
          tin: '123456',
          street: 'Main St',
          address: 'City',
          city: 'Riyadh',
          country: 'SA',
          phone: '+966500000000',
          email: 's@test.com',
        ),
        customer: Customer(
          name: 'Test Customer',
          tin: '789012',
          street: 'Other St',
          address: 'City',
          city: 'Jeddah',
          country: 'SA',
          phone: '+966500000001',
          email: 'c@test.com',
        ),
      );
    }

    test('recalculateTotals computes correct subtotal for single item', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Widget',
        description: '',
        quantity: 5,
        unitPrice: 100.0,
        taxRate: 15.0,
      ));

      expect(controller.subtotal.value, equals(500.0));
    });

    test('recalculateTotals computes correct tax total', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Widget',
        description: '',
        quantity: 5,
        unitPrice: 100.0,
        taxRate: 15.0,
      ));

      expect(controller.taxTotal.value, equals(75.0));
    });

    test('recalculateTotals computes correct grand total', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Widget',
        description: '',
        quantity: 5,
        unitPrice: 100.0,
        taxRate: 15.0,
      ));

      expect(controller.grandTotal.value, equals(575.0));
    });

    test('recalculateTotals handles multiple items', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Widget A',
        description: '',
        quantity: 2,
        unitPrice: 50.0,
        taxRate: 15.0,
      ));
      controller.addItem(InvoiceItem(
        name: 'Widget B',
        description: '',
        quantity: 3,
        unitPrice: 200.0,
        taxRate: 10.0,
      ));

      expect(controller.subtotal.value, equals(700.0));
      expect(controller.taxTotal.value, closeTo(75.0, 0.01));
      expect(controller.grandTotal.value, closeTo(775.0, 0.01));
    });

    test('recalculateTotals updates when item is removed', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Widget',
        description: '',
        quantity: 10,
        unitPrice: 50.0,
        taxRate: 15.0,
      ));
      controller.addItem(InvoiceItem(
        name: 'Gadget',
        description: '',
        quantity: 5,
        unitPrice: 20.0,
        taxRate: 15.0,
      ));

      expect(controller.subtotal.value, equals(600.0));

      controller.removeItem(0);

      expect(controller.subtotal.value, equals(100.0));
      expect(controller.items.length, equals(1));
    });

    test('recalculateTotals handles zero quantity items', () {
      final controller = _createTestController();
      controller.addItem(InvoiceItem(
        name: 'Free Item',
        description: '',
        quantity: 0,
        unitPrice: 100.0,
        taxRate: 15.0,
      ));

      expect(controller.subtotal.value, equals(0.0));
      expect(controller.taxTotal.value, equals(0.0));
    });

    test('supplierInfo returns correct map', () {
      final controller = _createTestController();

      expect(controller.supplierInfo['name'], equals('Test Supplier'));
      expect(controller.supplierInfo['vat'], equals('123456'));
      expect(controller.supplierInfo['city'], equals('Riyadh'));
    });

    test('customerInfo returns correct map', () {
      final controller = _createTestController();

      expect(controller.customerInfo['name'], equals('Test Customer'));
      expect(controller.customerInfo['vat'], equals('789012'));
      expect(controller.customerInfo['city'], equals('Jeddah'));
    });

    test('clearAll resets invoice number and date', () {
      final controller = _createTestController();
      final originalNumber = controller.invoiceNumber;
      controller.clearAll();

      expect(controller.invoiceNumber, isNot(equals(originalNumber)));
      expect(controller.invoiceDate.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    });
  });
}
