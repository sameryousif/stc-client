import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';
import 'package:stc_client/models/invoice_item.dart';

/// ===============================
/// MAIN INVOICE GENERATOR
/// ===============================

////////canonicalize XML
String canonicalizeXml(String xmlString) {
  final document = XmlDocument.parse(xmlString);

  String normalizeNode(XmlNode node) {
    // Skip UBLExtensions and Signature
    if (node is XmlElement &&
        (node.name.local == 'UBLExtensions' ||
            node.name.local == 'Signature')) {
      return '';
    }

    // Preserve X509Certificate and SignatureValue exactly
    if (node is XmlElement &&
        (node.name.local == 'X509Certificate' ||
            node.name.local == 'SignatureValue')) {
      return node.toXmlString();
    }

    if (node is XmlElement) {
      final sortedAttributes =
          node.attributes.toList()
            ..sort((a, b) => a.name.local.compareTo(b.name.local));

      final buffer = StringBuffer();
      buffer.write('<${node.name.local}');
      for (var attr in sortedAttributes) {
        buffer.write(' ${attr.name.local}="${attr.value}"');
      }
      buffer.write('>');

      for (var child in node.children) {
        buffer.write(normalizeNode(child));
      }

      buffer.write('</${node.name.local}>');
      return buffer.toString();
    } else if (node is XmlText) {
      return node.value; // Do NOT trim text inside the certificate
    } else {
      return '';
    }
  }

  final normalizedXml = normalizeNode(document.rootElement);
  return normalizedXml;
}

////////calculate hash
String generateInvoiceHash(String normalizedXml) {
  final bytes = utf8.encode(normalizedXml);
  final hash = sha256.convert(bytes);
  return base64.encode(hash.bytes);
}

//////////////////////construct SignedInfo
XmlDocument buildSignedInfo({
  required String invoiceHashBase64,
  required String signedPropertiesHashBase64,
}) {
  final builder = XmlBuilder();

  builder.element(
    'ds:SignedInfo',
    nest: () {
      // Canonicalization method
      builder.element(
        'ds:CanonicalizationMethod',
        nest: () {
          builder.attribute(
            'Algorithm',
            'http://www.w3.org/2001/10/xml-exc-c14n#',
          );
        },
      );

      // Signature method
      builder.element(
        'ds:SignatureMethod',
        nest: () {
          builder.attribute(
            'Algorithm',
            'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
          );
        },
      );

      // Reference to INVOICE
      builder.element(
        'ds:Reference',
        nest: () {
          builder.attribute('URI', '');

          builder.element(
            'ds:Transforms',
            nest: () {
              builder.element(
                'ds:Transform',
                nest: () {
                  builder.attribute(
                    'Algorithm',
                    'http://www.w3.org/2001/10/xml-exc-c14n#',
                  );
                },
              );
            },
          );

          builder.element(
            'ds:DigestMethod',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/2001/04/xmlenc#sha256',
              );
            },
          );

          builder.element('ds:DigestValue', nest: invoiceHashBase64);
        },
      );

      // Reference to XAdES SignedProperties
      builder.element(
        'ds:Reference',
        nest: () {
          builder.attribute('URI', '#xadesSignedProperties');
          builder.attribute(
            'Type',
            'http://uri.etsi.org/01903#SignedProperties',
          );

          builder.element(
            'ds:DigestMethod',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/2001/04/xmlenc#sha256',
              );
            },
          );

          builder.element('ds:DigestValue', nest: signedPropertiesHashBase64);
        },
      );
    },
  );

  return builder.buildDocument();
}

///////////////construct XAdES Signature
XmlDocument buildXadesSignature({
  required XmlDocument signedInfo,
  required String signatureValueBase64,
  required String certificateBase64,
  required XmlDocument signedProperties,
}) {
  final builder = XmlBuilder();

  builder.element(
    'ds:Signature',
    attributes: {
      'xmlns:ds': 'http://www.w3.org/2000/09/xmldsig#',
      'Id': 'signature',
    },
    nest: () {
      // Insert SignedInfo
      builder.xml(signedInfo.rootElement.toXmlString());

      // SignatureValue (result of signing SignedInfo)
      builder.element('ds:SignatureValue', nest: signatureValueBase64);

      // Certificate
      builder.element(
        'ds:KeyInfo',
        nest: () {
          builder.element(
            'ds:X509Data',
            nest: () {
              builder.element('ds:X509Certificate', nest: certificateBase64);
            },
          );
        },
      );

      // XAdES block
      builder.element(
        'ds:Object',
        nest: () {
          builder.xml(signedProperties.rootElement.toXmlString());
        },
      );
    },
  );

  return builder.buildDocument();
}

//////////////////construct UBLExtensions
XmlElement buildUBLExtensions(XmlDocument signatureDoc) {
  final builder = XmlBuilder();

  builder.element(
    'ext:UBLExtensions',
    nest: () {
      builder.element(
        'ext:UBLExtension',
        nest: () {
          builder.element(
            'ext:ExtensionContent',
            nest: () {
              builder.xml(signatureDoc.rootElement.toXmlString());
            },
          );
        },
      );
    },
  );

  final doc = builder.buildDocument();
  return doc.rootElement;
}

////////inject signature into invoice
XmlDocument injectSignature({
  required XmlDocument invoice,
  required XmlDocument signature,
}) {
  final root = invoice.rootElement;

  // Remove existing UBLExtensions if any
  final existingExtensions =
      root.findElements('ext:UBLExtensions', namespace: '*').toList();
  for (var ext in existingExtensions) {
    ext.remove();
  }

  // Build new UBLExtensions block containing the signature
  final ublExtensions = buildUBLExtensions(signature);

  // Insert as the first child of the root element
  root.children.insert(0, ublExtensions.copy());

  return invoice;
}

String generateUBLInvoice({
  required String invoiceNumber,
  required String uuid,
  required String issueDate,
  required String issueTime,
  required int icv,
  required String previousInvoiceHash,
  required String supplierName,
  required String supplierVAT,
  required String customerName,
  required String customerVAT,
  required List<InvoiceItem> items,
  XmlDocument? signedProperties,
  String signatureValueBase64 = '',
  String certificateBase64 = '',
}) {
  final builder = XmlBuilder();

  double subtotal = 0;
  double vatTotal = 0;

  for (final item in items) {
    subtotal += item.quantity * item.unitPrice;
    vatTotal += (item.quantity * item.unitPrice) * 0.15;
  }

  final total = subtotal + vatTotal;

  builder.processing('xml', 'version="1.0" encoding="UTF-8"');

  builder.element(
    'Invoice',
    nest: () {
      // ================= NAMESPACES =================
      builder.attribute(
        'xmlns',
        'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
      );
      builder.attribute(
        'xmlns:cac',
        'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
      );
      builder.attribute(
        'xmlns:cbc',
        'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
      );
      builder.attribute(
        'xmlns:ext',
        'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
      );
      builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
      builder.attribute('xmlns:xades', 'http://uri.etsi.org/01903/v1.3.2#');

      // ===================================================

      //  UBL EXTENSIONS (SIGNATURE GOES HERE)
      // ===================================================

      // ===================================================
      //  BASIC HEADER
      // ===================================================
      builder.element(
        'cbc:ProfileID',
        nest: () => builder.text('reporting:1.0'),
      );
      builder.element('cbc:ID', nest: () => builder.text(invoiceNumber));
      builder.element('cbc:UUID', nest: () => builder.text(uuid));
      builder.element('cbc:IssueDate', nest: () => builder.text(issueDate));
      builder.element('cbc:IssueTime', nest: () => builder.text(issueTime));

      builder.element(
        'cbc:InvoiceTypeCode',
        nest: () {
          builder.attribute('name', '0100000');
          builder.text('388');
        },
      );

      builder.element(
        'cbc:DocumentCurrencyCode',
        nest: () => builder.text('SAR'),
      );
      builder.element('cbc:TaxCurrencyCode', nest: () => builder.text('SAR'));

      // ===================================================
      //  ADDITIONAL DOCUMENT REFERENCES
      // ===================================================
      builder.element(
        'cac:AdditionalDocumentReference',
        nest: () {
          builder.element('cbc:ID', nest: () => builder.text('ICV'));
          builder.element('cbc:UUID', nest: () => builder.text(icv.toString()));
        },
      );

      builder.element(
        'cac:AdditionalDocumentReference',
        nest: () {
          builder.element('cbc:ID', nest: () => builder.text('PIH'));
          builder.element(
            'cac:Attachment',
            nest: () {
              builder.element(
                'cbc:EmbeddedDocumentBinaryObject',
                nest: () {
                  builder.attribute('mimeCode', 'text/plain');
                  builder.text(previousInvoiceHash);
                },
              );
            },
          );
        },
      );

      // ===================================================
      //  SUPPLIER
      // ===================================================
      builder.element(
        'cac:AccountingSupplierParty',
        nest: () {
          builder.element(
            'cac:Party',
            nest: () {
              builder.element(
                'cac:PartyTaxScheme',
                nest: () {
                  builder.element(
                    'cbc:CompanyID',
                    nest: () => builder.text(supplierVAT),
                  );
                  builder.element(
                    'cac:TaxScheme',
                    nest: () => builder.element('cbc:ID', nest: 'VAT'),
                  );
                },
              );
              builder.element(
                'cac:PartyLegalEntity',
                nest:
                    () => builder.element(
                      'cbc:RegistrationName',
                      nest: () => builder.text(supplierName),
                    ),
              );
            },
          );
        },
      );

      // ===================================================
      //  CUSTOMER
      // ===================================================
      builder.element(
        'cac:AccountingCustomerParty',
        nest: () {
          builder.element(
            'cac:Party',
            nest: () {
              builder.element(
                'cac:PartyTaxScheme',
                nest: () {
                  builder.element(
                    'cbc:CompanyID',
                    nest: () => builder.text(customerVAT),
                  );
                  builder.element(
                    'cac:TaxScheme',
                    nest: () => builder.element('cbc:ID', nest: 'VAT'),
                  );
                },
              );
              builder.element(
                'cac:PartyLegalEntity',
                nest:
                    () => builder.element(
                      'cbc:RegistrationName',
                      nest: () => builder.text(customerName),
                    ),
              );
            },
          );
        },
      );

      // ===================================================
      //  INVOICE LINES
      // ===================================================
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final lineTotal = item.quantity * item.unitPrice;
        final tax = lineTotal * 0.15;

        builder.element(
          'cac:InvoiceLine',
          nest: () {
            builder.element('cbc:ID', nest: () => builder.text('${i + 1}'));

            builder.element(
              'cbc:InvoicedQuantity',
              nest: () {
                builder.attribute('unitCode', 'PCE');
                builder.text(item.quantity.toStringAsFixed(6));
              },
            );

            builder.element(
              'cbc:LineExtensionAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(lineTotal.toStringAsFixed(2));
              },
            );

            builder.element(
              'cac:TaxTotal',
              nest: () {
                builder.element(
                  'cbc:TaxAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SAR');
                    builder.text(tax.toStringAsFixed(2));
                  },
                );
              },
            );

            builder.element(
              'cac:Item',
              nest: () => builder.element('cbc:Name', nest: item.name),
            );

            builder.element(
              'cac:Price',
              nest: () {
                builder.element(
                  'cbc:PriceAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SAR');
                    builder.text(item.unitPrice.toStringAsFixed(2));
                  },
                );
              },
            );
          },
        );
      }

      // ===================================================
      //  TOTALS
      // ===================================================
      builder.element(
        'cac:TaxTotal',
        nest:
            () => builder.element(
              'cbc:TaxAmount',
              nest: () {
                builder.attribute('currencyID', 'SAR');
                builder.text(vatTotal.toStringAsFixed(2));
              },
            ),
      );

      builder.element(
        'cac:LegalMonetaryTotal',
        nest: () {
          builder.element(
            'cbc:LineExtensionAmount',
            nest: () {
              builder.attribute('currencyID', 'SAR');
              builder.text(subtotal.toStringAsFixed(2));
            },
          );
          builder.element(
            'cbc:TaxInclusiveAmount',
            nest: () {
              builder.attribute('currencyID', 'SAR');
              builder.text(total.toStringAsFixed(2));
            },
          );
          builder.element(
            'cbc:PayableAmount',
            nest: () {
              builder.attribute('currencyID', 'SAR');
              builder.text(total.toStringAsFixed(2));
            },
          );
        },
      );
    },
  );
  final invoiceDoc = builder.buildDocument();

  // ================= CANONICALIZE & HASH =================

  // Ensure signedProperties is available (use an empty SignedProperties fallback if null)

  // Build SignedInfo

  // Build XAdES Signature

  // Inject signature (UBLExtensions) into invoice

  // Return final XML string
  return invoiceDoc.toXmlString(pretty: true);
}

String pemToBase64(String pem) {
  return pem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll('\n', '')
      .trim();
}

Uint8List pemToDerBytes(String pem) {
  final base64Str = pemToBase64(pem);
  return base64.decode(base64Str);
}
