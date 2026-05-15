import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';

void main() {
  group('InvoiceItem', () {
    test('total calculates correctly for positive values', () {
      final item = InvoiceItem(
        name: 'Test Item',
        description: 'A test item',
        quantity: 5,
        unitPrice: 100.0,
        taxRate: 15.0,
      );

      expect(item.total, equals(500.0));
    });

    test('total is zero when quantity is zero', () {
      final item = InvoiceItem(
        name: 'Free Item',
        description: '',
        quantity: 0,
        unitPrice: 100.0,
        taxRate: 15.0,
      );

      expect(item.total, equals(0.0));
    });

    test('total handles fractional quantities and prices', () {
      final item = InvoiceItem(
        name: 'Fractional',
        description: '',
        quantity: 3,
        unitPrice: 10.50,
        taxRate: 15.0,
      );

      expect(item.total, equals(31.5));
    });

    test('fields are mutable', () {
      final item = InvoiceItem(
        name: 'Original',
        description: 'Original desc',
        quantity: 1,
        unitPrice: 10.0,
        taxRate: 15.0,
      );

      item.name = 'Updated';
      item.quantity = 10;
      item.unitPrice = 25.0;

      expect(item.name, equals('Updated'));
      expect(item.total, equals(250.0));
    });
  });
}
