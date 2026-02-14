import 'dart:io';
import 'package:stc_client/core/certificate/cert_info.dart';
import 'package:stc_client/utils/paths/app_paths.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';
import 'package:xml/xml.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
// Core functions for generating UBL invoices, constructing the necessary XML structures for the invoice, the XAdES signature, and the UBLExtensions, as well as injecting the signature into the invoice and adding a QR code reference to the invoice

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
            'http://www.w3.org/2006/12/xml-c14n11#',
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
            'ds:Transform',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/TR/1999/REC-xpath-19991116',
              );
              builder.element(
                'ds:XPath',
                nest: 'not(//ancestor-or-self::ext:UBLExtensions)',
              );
            },
          );

          builder.element(
            'ds:Transform',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/TR/1999/REC-xpath-19991116',
              );
              builder.element(
                'ds:XPath',
                nest: 'not(//ancestor-or-self::cac:Signature)',
              );
            },
          );

          builder.element(
            'ds:Transform',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/TR/1999/REC-xpath-19991116',
              );
              builder.element(
                'ds:XPath',
                nest:
                    'not(//ancestor-or-self::cac:AdditionalDocumentReference[cbc:ID="QR"])',
              );
            },
          );

          builder.element(
            'ds:Transform',
            nest: () {
              builder.attribute(
                'Algorithm',
                'http://www.w3.org/2006/12/xml-c14n11#',
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

/// Build the XAdES SignedProperties block
XmlElement buildSignedProperties({
  required String signatureId,
  required String signingTime,
  required String certDigestBase64,
  required String issuerName,
  required String serialNumber,
}) {
  final builder = XmlBuilder();

  builder.element(
    'xades:QualifyingProperties',
    nest: () {
      builder.attribute('Target', '#$signatureId');

      builder.element(
        'xades:SignedProperties',
        nest: () {
          builder.attribute('Id', 'xadesSignedProperties');

          builder.element(
            'xades:SignedSignatureProperties',
            nest: () {
              builder.element('xades:SigningTime', nest: signingTime);

              builder.element(
                'xades:SigningCertificate',
                nest: () {
                  builder.element(
                    'xades:Cert',
                    nest: () {
                      builder.element(
                        'xades:CertDigest',
                        nest: () {
                          builder.element(
                            'ds:DigestMethod',
                            nest: () {
                              builder.attribute(
                                'Algorithm',
                                'http://www.w3.org/2001/04/xmlenc#sha256',
                              );
                            },
                          );
                          builder.element(
                            'ds:DigestValue',
                            nest: certDigestBase64,
                          );
                        },
                      );

                      builder.element(
                        'xades:IssuerSerial',
                        nest: () {
                          builder.element(
                            'ds:X509IssuerName',
                            nest: issuerName,
                          );
                          builder.element(
                            'ds:X509SerialNumber',
                            nest: serialNumber,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    },
  );

  // return the first element of the fragment
  return builder.buildFragment().children.whereType<XmlElement>().first;
}

///////////////construct XAdES Signature
/// Build the full XAdES Signature block
XmlDocument buildXadesSignature({
  required XmlDocument signedInfo,
  required String signatureValueBase64,
  required String certificateBase64,
  required XmlElement signedProperties,
}) {
  final builder = XmlBuilder();

  builder.element(
    'ds:Signature',
    nest: () {
      //  builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
      builder.attribute('Id', 'signature');

      // Insert SignedInfo
      builder.xml(signedInfo.rootElement.toXmlString(pretty: false));

      // SignatureValue
      builder.element('ds:SignatureValue', nest: signatureValueBase64);

      // KeyInfo with certificate
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

      // XAdES SignedProperties inside ds:Object
      builder.element(
        'ds:Object',
        nest: () {
          builder.xml(signedProperties.toXmlString(pretty: false));
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
            'ext:ExtensionURI',
            nest: 'urn:oasis:names:specification:ubl:dsig:enveloped:xades',
          );

          builder.element(
            'ext:ExtensionContent',
            nest: () {
              builder.element(
                'sig:UBLDocumentSignatures',
                nest: () {
                  builder.element(
                    'sac:SignatureInformation',
                    nest: () {
                      builder.xml(
                        signatureDoc.rootElement.toXmlString(pretty: true),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    },
  );

  return builder.buildDocument().rootElement;
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

Future<String> generateUBLInvoice({
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
}) async {
  final builder = XmlBuilder();

  double subtotal = 0;
  double vatTotal = 0;

  for (final item in items) {
    subtotal += item.quantity * item.unitPrice;
    vatTotal += (item.quantity * item.unitPrice) * 0.15;
  }

  final total = subtotal + vatTotal;
  final subjectSerial = await extractSerial(
    opensslPath: await ToolPaths.opensslPath,
    certPath: await AppPaths.certPath(),
  );
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');

  builder.element(
    'Invoice',
    nest: () {
      //////////////namespaces
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
      /* builder.attribute(
        'xmlns:sac',
        'urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2',
      );
 builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
      builder.attribute(
        'xmlns:sig',
        'urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2',
      );
      builder.attribute('xmlns:xades', 'http://uri.etsi.org/01903/v1.3.2#');
*/
      //////////////////////////////////

      /////////  UBL EXTENSIONS
      ///////////////////////

      /////basic invoice info

      builder.element(
        'cbc:ProfileID',
        nest: () => builder.text('reporting:1.0'),
      );

      builder.element('cbc:ID', nest: () => builder.text("S003"));
      builder.element('cbc:UUID', nest: () => builder.text(invoiceNumber));
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
        nest: () => builder.text('SDG'),
      );
      builder.element('cbc:TaxCurrencyCode', nest: () => builder.text('SDG'));

      ///////////////////
      //  additional document references
      //////////////////////////
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

      ////supplier info
      //////////////////////////////
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

      ////customer info
      /////////////////////
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
                    nest: () => builder.text(subjectSerial!),
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

      /////invoice items
      //////////////////////////////////
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
                builder.attribute('currencyID', 'SDG');
                builder.text(lineTotal.toStringAsFixed(2));
              },
            );

            builder.element(
              'cac:TaxTotal',
              nest: () {
                builder.element(
                  'cbc:TaxAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SDG');
                    builder.text(tax.toStringAsFixed(2));
                  },
                );
              },
            );

            builder.element(
              'cac:Item',
              nest:
                  () => builder.element(
                    'cbc:Name',
                    nest: item.nameController.text,
                  ),
            );

            builder.element(
              'cac:Price',
              nest: () {
                builder.element(
                  'cbc:PriceAmount',
                  nest: () {
                    builder.attribute('currencyID', 'SDG');
                    builder.text(item.unitPrice.toStringAsFixed(2));
                  },
                );
              },
            );
          },
        );
      }

      ////////////totals
      /////////////////////
      builder.element(
        'cac:TaxTotal',
        nest:
            () => builder.element(
              'cbc:TaxAmount',
              nest: () {
                builder.attribute('currencyID', 'SDG');
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
              builder.attribute('currencyID', 'SDG');
              builder.text(subtotal.toStringAsFixed(2));
            },
          );
          builder.element(
            'cbc:TaxInclusiveAmount',
            nest: () {
              builder.attribute('currencyID', 'SDG');
              builder.text(total.toStringAsFixed(2));
            },
          );
          builder.element(
            'cbc:PayableAmount',
            nest: () {
              builder.attribute('currencyID', 'SDG');
              builder.text(total.toStringAsFixed(2));
            },
          );
        },
      );
    },
  );
  final invoiceDoc = builder.buildDocument();

  return invoiceDoc.toXmlString(pretty: true);
}

Future<void> addQrToInvoice({
  required String signedInvoicePath,
  required String qrBase64,
}) async {
  final xmlString = await File(signedInvoicePath).readAsString();
  final document = XmlDocument.parse(xmlString);

  final invoice = document.rootElement;

  // Build QR element using XmlBuilder
  final builder = XmlBuilder();
  builder.element(
    'cac:AdditionalDocumentReference',
    nest: () {
      builder.element('cbc:ID', nest: 'QR');
      builder.element(
        'cac:Attachment',
        nest: () {
          builder.element(
            'cbc:EmbeddedDocumentBinaryObject',
            nest: () {
              builder.attribute('mimeCode', 'text/plain');
              builder.text(qrBase64);
            },
          );
        },
      );
    },
  );

  // Convert builder to XmlDocument and extract the element
  final qrDocument = XmlDocument.parse(
    builder.buildDocument().toXmlString(pretty: true),
  );
  final qrElement =
      qrDocument.rootElement.copy(); // make a copy to avoid parent issues

  // Find all existing AdditionalDocumentReference nodes
  final adrNodes =
      invoice.findElements('cac:AdditionalDocumentReference').toList();

  if (adrNodes.isNotEmpty) {
    // Insert QR after the last existing AdditionalDocumentReference
    final lastAdr = adrNodes.last;
    final index = invoice.children.indexOf(lastAdr);
    invoice.children.insert(index + 1, qrElement);
  } else {
    // fallback: insert before the first AccountingSupplierParty
    final supplierIndex = invoice.children.indexWhere(
      (node) =>
          node is XmlElement && node.name.local == 'AccountingSupplierParty',
    );
    if (supplierIndex != -1) {
      invoice.children.insert(supplierIndex, qrElement);
    } else {
      invoice.children.add(qrElement);
    }
  }

  final finalXml = document.toXmlString(pretty: false);

  await File(signedInvoicePath).writeAsString(finalXml);
}
