import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:stc_client/services/invoice_processing_service.dart';

void main() {
  group('removeSections', () {
    XmlDocument _makeDoc(String extraContent) {
      return XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
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

    test('removes QR AdditionalDocumentReference', () {
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

      expect(
        doc.findAllElements('Note', namespace: '*').length,
        equals(1),
      );
    });
  });
}
