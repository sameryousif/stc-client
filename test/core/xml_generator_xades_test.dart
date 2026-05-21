import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/invoice/xml_generator.dart';

void main() {
  group('XAdES XML generation', () {
    test(
      'SignedProperties canonicalization input matches server extraction root',
      () {
        final qualifyingProperties = buildSignedProperties(
          signatureId: 'signature',
          signingTime: '2026-05-21T12:00:00Z',
          certDigestBase64: 'certDigest',
          issuerName: 'CN=STC Root CA,O=STC,C=SD',
          serialNumber: '123',
        );

        final xml = xmlForServerSignedPropertiesCanonicalization(
          qualifyingProperties,
        );

        expect(
          xml,
          startsWith(
            '<xades:SignedProperties Id="xadesSignedProperties" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">',
          ),
        );
        expect(xml, contains('Id="xadesSignedProperties"'));
        expect(
          xml,
          contains('xmlns:xades="http://uri.etsi.org/01903/v1.3.2#"'),
        );
        expect(xml, contains('xmlns:ds="http://www.w3.org/2000/09/xmldsig#"'));
        expect(
          xml,
          contains(
            '<ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>',
          ),
        );
        expect(xml, isNot(contains('xades:QualifyingProperties')));
      },
    );

    test(
      'SignedInfo canonicalization input includes server-added ds namespace',
      () {
        final signedInfo = buildSignedInfo(
          invoiceHashBase64: 'invoiceHash',
          signedPropertiesHashBase64: 'propsHash',
        );

        final xml = xmlForServerSignedInfoCanonicalization(signedInfo);

        expect(xml, startsWith('<ds:SignedInfo '));
        expect(xml, contains('xmlns:ds="http://www.w3.org/2000/09/xmldsig#"'));
        expect(
          xml,
          contains(
            'Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"',
          ),
        );
        expect(
          xml,
          contains(
            '<ds:Reference URI="#xadesSignedProperties" Type="http://uri.etsi.org/01903#SignedProperties">',
          ),
        );
        expect(
          xml,
          contains(
            '<ds:CanonicalizationMethod Algorithm="http://www.w3.org/2006/12/xml-c14n11#"/>',
          ),
        );
      },
    );
  });
}
