import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/qr/qr_generator.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/services/invoice_processing_service.dart';
import 'package:xml/xml.dart';

void main() {
  group('generateQr', () {
    test('produces deterministic output for identical inputs', () {
      final signature = Uint8List.fromList([1, 2, 3, 4]);
      final certificate = Uint8List.fromList([5, 6, 7, 8]);
      final issueDate = DateTime(2024, 1, 15);

      final result1 = generateQr(
        sellerName: 'Test Seller',
        vatNumber: '399999999900003',
        issueDate: issueDate,
        total: 100.0,
        vatTotal: 15.0,
        xmlHash: 'abc123',
        signature: signature,
        certificate: certificate,
      );

      final result2 = generateQr(
        sellerName: 'Test Seller',
        vatNumber: '399999999900003',
        issueDate: issueDate,
        total: 100.0,
        vatTotal: 15.0,
        xmlHash: 'abc123',
        signature: signature,
        certificate: certificate,
      );

      expect(result1, equals(result2));
    });
  });

  group('InvoiceItem', () {
    test('total calculates correctly', () {
      final item = InvoiceItem(
        name: 'Test Item',
        description: 'A test item',
        quantity: 5,
        unitPrice: 100.0,
        taxRate: 15.0,
      );

      expect(item.total, equals(500.0));
    });
  });

  group('removeSections', () {
    test('removes UBLExtensions element', () {
      final doc = XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">
  <ext:UBLExtensions>
    <ext:UBLExtension>
      <ext:ExtensionURI>test</ext:ExtensionURI>
    </ext:UBLExtension>
  </ext:UBLExtensions>
</Invoice>''');

      expect(
        doc.findAllElements('UBLExtensions', namespace: '*').length,
        greaterThan(0),
      );

      InvoiceProcessingService.removeSections(doc);

      expect(
        doc.findAllElements('UBLExtensions', namespace: '*').length,
        equals(0),
      );
    });
  });
}
