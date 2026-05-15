import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/qr/qr_generator.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/services/invoice_processing_service.dart';
import 'package:stc_client/core/invoice/xml_generator.dart';
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

    test('produces valid base64 output', () {
      final signature = Uint8List.fromList([1, 2, 3, 4]);
      final certificate = Uint8List.fromList([5, 6, 7, 8]);

      final result = generateQr(
        sellerName: 'Test',
        vatNumber: '12345',
        issueDate: DateTime(2024, 1, 1),
        total: 50.0,
        vatTotal: 7.5,
        xmlHash: 'hash',
        signature: signature,
        certificate: certificate,
      );

      expect(() => base64.decode(result), returnsNormally);
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

  group('removeSections', () {
    XmlDocument _makeDoc(String extraContent) {
      return XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>INV001</cbc:ID>
  $extraContent
</Invoice>''');
    }

    test('removes UBLExtensions element', () {
      final doc = _makeDoc('''
  <ext:UBLExtensions>
    <ext:UBLExtension>
      <ext:ExtensionURI>test</ext:ExtensionURI>
    </ext:UBLExtension>
  </ext:UBLExtensions>''');

      InvoiceProcessingService.removeSections(doc);

      expect(
        doc.findAllElements('UBLExtensions', namespace: '*').length,
        equals(0),
      );
    });

    test('removes QR AdditionalDocumentReference but keeps ICV', () {
      final doc = _makeDoc('''
  <cac:AdditionalDocumentReference>
    <cbc:ID>ICV</cbc:ID>
    <cbc:UUID>1</cbc:UUID>
  </cac:AdditionalDocumentReference>
  <cac:AdditionalDocumentReference>
    <cbc:ID>QR</cbc:ID>
    <cac:Attachment>
      <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">qrdata</cbc:EmbeddedDocumentBinaryObject>
    </cac:Attachment>
  </cac:AdditionalDocumentReference>''');

      InvoiceProcessingService.removeSections(doc);

      final adrs = doc.findAllElements('AdditionalDocumentReference', namespace: '*');
      expect(adrs.length, equals(1));
      expect(
        adrs.first.findElements('ID', namespace: '*').first.text.trim(),
        equals('ICV'),
      );
    });

    test('removes Signature element', () {
      final doc = _makeDoc('''
  <cac:Signature>
    <cbc:ID>sig1</cbc:ID>
  </cac:Signature>''');

      InvoiceProcessingService.removeSections(doc);

      expect(
        doc.findAllElements('Signature', namespace: '*').length,
        equals(0),
      );
    });

    test('handles document with no sections to remove', () {
      final doc = _makeDoc('<cbc:Note>Test note</cbc:Note>');

      expect(() => InvoiceProcessingService.removeSections(doc), returnsNormally);
    });
  });

  group('generateUBLInvoice XML structure', () {
    test('output contains correct invoice number in cbc:ID', () async {
      final items = [
        InvoiceItem(
          name: 'Test Item',
          description: '',
          quantity: 2,
          unitPrice: 100.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: 'INV-2024-001',
        uuid: 'test-uuid',
        issueDate: '2024-01-15',
        issueTime: '10:30:00',
        icv: 5,
        previousInvoiceHash: 'prevHash',
        supplierName: 'Supplier Co',
        supplierStreet: 'Main St',
        supplierCity: 'Riyadh',
        supplierVAT: '399999999900003',
        supplierPhone: '+966500000000',
        supplierEmail: 'supplier@test.com',
        supplierCountry: 'SA',
        customerName: 'Customer Co',
        customerVAT: '399999999800003',
        customerStreet: 'Other St',
        customerCity: 'Jeddah',
        customerPhone: '+966500000001',
        customerEmail: 'customer@test.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'CLEARED',
      );

      final doc = XmlDocument.parse(xmlString);

      final idElements = doc.findAllElements('ID', namespace: '*');
      expect(idElements.isNotEmpty, isTrue);
      expect(idElements.first.text.trim(), equals('INV-2024-001'));
    });

    test('output contains correct ProfileID', () async {
      final items = [
        InvoiceItem(
          name: 'Item',
          description: '',
          quantity: 1,
          unitPrice: 50.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: '1',
        uuid: 'u',
        issueDate: '2024-01-01',
        issueTime: '00:00:00',
        icv: 1,
        previousInvoiceHash: 'hash',
        supplierName: 'S',
        supplierStreet: 'S',
        supplierCity: 'S',
        supplierVAT: '123',
        supplierPhone: '1',
        supplierEmail: 's@s.com',
        supplierCountry: 'SA',
        customerName: 'C',
        customerVAT: '456',
        customerStreet: 'C',
        customerCity: 'C',
        customerPhone: '2',
        customerEmail: 'c@c.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'REPORTED',
      );

      final doc = XmlDocument.parse(xmlString);
      final profileId = doc.findAllElements('ProfileID', namespace: '*').first.text.trim();
      expect(profileId, equals('REPORTED'));
    });

    test('output contains required namespace declarations', () async {
      final items = [
        InvoiceItem(
          name: 'Item',
          description: '',
          quantity: 1,
          unitPrice: 10.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: '1',
        uuid: 'u',
        issueDate: '2024-01-01',
        issueTime: '00:00:00',
        icv: 1,
        previousInvoiceHash: 'h',
        supplierName: 'S',
        supplierStreet: 'S',
        supplierCity: 'S',
        supplierVAT: '1',
        supplierPhone: '1',
        supplierEmail: 's@s.com',
        supplierCountry: 'SA',
        customerName: 'C',
        customerVAT: '2',
        customerStreet: 'C',
        customerCity: 'C',
        customerPhone: '1',
        customerEmail: 'c@c.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'CLEARED',
      );

      expect(xmlString.contains('xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"'), isTrue);
      expect(xmlString.contains('xmlns:cac='), isTrue);
      expect(xmlString.contains('xmlns:cbc='), isTrue);
      expect(xmlString.contains('xmlns:ext='), isTrue);
    });

    test('output contains ICV reference', () async {
      final items = [
        InvoiceItem(
          name: 'Item',
          description: '',
          quantity: 1,
          unitPrice: 10.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: '1',
        uuid: 'u',
        issueDate: '2024-01-01',
        issueTime: '00:00:00',
        icv: 42,
        previousInvoiceHash: 'h',
        supplierName: 'S',
        supplierStreet: 'S',
        supplierCity: 'S',
        supplierVAT: '1',
        supplierPhone: '1',
        supplierEmail: 's@s.com',
        supplierCountry: 'SA',
        customerName: 'C',
        customerVAT: '2',
        customerStreet: 'C',
        customerCity: 'C',
        customerPhone: '1',
        customerEmail: 'c@c.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'CLEARED',
      );

      final doc = XmlDocument.parse(xmlString);
      final icvRefs = doc.findAllElements('ID', namespace: '*')
          .where((e) => e.text.trim() == 'ICV')
          .toList();
      expect(icvRefs.isNotEmpty, isTrue);

      final uuidElements = doc.findAllElements('UUID', namespace: '*');
      expect(uuidElements.length, greaterThanOrEqualTo(1));
      expect(uuidElements[1].text.trim(), equals('42'));
    });

    test('output contains supplier and customer registration names', () async {
      final items = [
        InvoiceItem(
          name: 'Item',
          description: '',
          quantity: 1,
          unitPrice: 10.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: '1',
        uuid: 'u',
        issueDate: '2024-01-01',
        issueTime: '00:00:00',
        icv: 1,
        previousInvoiceHash: 'h',
        supplierName: 'Acme Corp',
        supplierStreet: 'S',
        supplierCity: 'S',
        supplierVAT: '1',
        supplierPhone: '1',
        supplierEmail: 's@s.com',
        supplierCountry: 'SA',
        customerName: 'Beta Ltd',
        customerVAT: '2',
        customerStreet: 'C',
        customerCity: 'C',
        customerPhone: '1',
        customerEmail: 'c@c.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'CLEARED',
      );

      expect(xmlString.contains('Acme Corp'), isTrue);
      expect(xmlString.contains('Beta Ltd'), isTrue);
    });

    test('output contains invoice line items with correct totals', () async {
      final items = [
        InvoiceItem(
          name: 'Widget',
          description: '',
          quantity: 3,
          unitPrice: 200.0,
          taxRate: 15.0,
        ),
      ];

      final xmlString = await generateUBLInvoice(
        invoiceNumber: '1',
        uuid: 'u',
        issueDate: '2024-01-01',
        issueTime: '00:00:00',
        icv: 1,
        previousInvoiceHash: 'h',
        supplierName: 'S',
        supplierStreet: 'S',
        supplierCity: 'S',
        supplierVAT: '1',
        supplierPhone: '1',
        supplierEmail: 's@s.com',
        supplierCountry: 'SA',
        customerName: 'C',
        customerVAT: '2',
        customerStreet: 'C',
        customerCity: 'C',
        customerPhone: '1',
        customerEmail: 'c@c.com',
        customerCountry: 'SA',
        items: items,
        profileId: 'CLEARED',
      );

      final doc = XmlDocument.parse(xmlString);
      final lines = doc.findAllElements('InvoiceLine', namespace: '*');
      expect(lines.length, equals(1));

      final lineTotal = doc.findAllElements('LineExtensionAmount', namespace: '*')
          .where((e) => e.parent?.name.local == 'InvoiceLine')
          .first;
      expect(lineTotal.text.trim(), equals('600.00'));
    });
  });
}
