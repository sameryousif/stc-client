import 'package:stc_client/models/invoice_item.dart';

String generateUBLInvoice({
  required String invoiceNumber,
  required String uuid,
  required String issueDate, // YYYY-MM-DD
  required String issueTime, // HH:MM:SS
  required int icv, // Invoice Counter
  required String previousInvoiceHash, // PIH (Base64)
  // /*required*/ String qrBase64, // QR Base64
  required String supplierName,
  required String supplierVAT,
  required String customerName,
  required String customerVAT,
  required List<InvoiceItem> items,
}) {
  double subtotal = 0;
  double vatTotal = 0;

  for (var i in items) {
    subtotal += i.quantity * i.unitPrice;
    vatTotal += (i.quantity * i.unitPrice) * 0.15;
  }

  double total = subtotal + vatTotal;

  String invoiceLines = items
      .asMap()
      .entries
      .map((e) {
        final index = e.key + 1;
        final item = e.value;
        final lineTotal = item.quantity * item.unitPrice;
        final tax = lineTotal * 0.15;

        return '''
<cac:InvoiceLine>
 <cbc:ID>$index</cbc:ID>
 <cbc:InvoicedQuantity unitCode="PCE">${item.quantity.toStringAsFixed(6)}</cbc:InvoicedQuantity>
 <cbc:LineExtensionAmount currencyID="SAR">${lineTotal.toStringAsFixed(2)}</cbc:LineExtensionAmount>
 <cac:TaxTotal>
  <cbc:TaxAmount currencyID="SAR">${tax.toStringAsFixed(2)}</cbc:TaxAmount>
  <cbc:RoundingAmount currencyID="SAR">${(lineTotal + tax).toStringAsFixed(2)}</cbc:RoundingAmount>
 </cac:TaxTotal>
 <cac:Item>
  <cbc:Name>${item.name}</cbc:Name>
  <cac:ClassifiedTaxCategory>
   <cbc:ID>S</cbc:ID>
   <cbc:Percent>15.00</cbc:Percent>
   <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
  </cac:ClassifiedTaxCategory>
 </cac:Item>
 <cac:Price>
  <cbc:PriceAmount currencyID="SAR">${item.unitPrice.toStringAsFixed(2)}</cbc:PriceAmount>
 </cac:Price>
</cac:InvoiceLine>
''';
      })
      .join("\n");

  return '''<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
         xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">

  <ext:UBLExtensions>
    <ext:UBLExtension>
      <ext:ExtensionURI>urn:oasis:names:specification:ubl:dsig:enveloped:xades</ext:ExtensionURI>
      <ext:ExtensionContent>
        <sig:UBLDocumentSignatures xmlns:sig="urn:oasis:names:specification:ubl:schema:xsd:CommonSignatureComponents-2"
                                   xmlns:sac="urn:oasis:names:specification:ubl:schema:xsd:SignatureAggregateComponents-2"
                                   xmlns:sbc="urn:oasis:names:specification:ubl:schema:xsd:SignatureBasicComponents-2">
          <sac:SignatureInformation>
            <cbc:ID>urn:oasis:names:specification:ubl:signature:1</cbc:ID>
            <sbc:ReferencedSignatureID>urn:oasis:names:specification:ubl:signature:Invoice</sbc:ReferencedSignatureID>
            <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="signature">
              <ds:SignedInfo>
                <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2006/12/xml-c14n11"/>
                <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"/>
                <ds:Reference Id="invoiceSignedData" URI="">
                  <ds:Transforms>
                    <ds:Transform Algorithm="http://www.w3.org/TR/1999/REC-xpath-19991116">
                      <ds:XPath>not(//ancestor-or-self::ext:UBLExtensions)</ds:XPath>
                    </ds:Transform>
                    <ds:Transform Algorithm="http://www.w3.org/TR/1999/REC-xpath-19991116">
                      <ds:XPath>not(//ancestor-or-self::cac:Signature)</ds:XPath>
                    </ds:Transform>
                    <ds:Transform Algorithm="http://www.w3.org/TR/1999/REC-xpath-19991116">
                      <ds:XPath>not(//ancestor-or-self::cac:AdditionalDocumentReference[cbc:ID='QR'])</ds:XPath>
                    </ds:Transform>
                    <ds:Transform Algorithm="http://www.w3.org/2006/12/xml-c14n11"/>
                  </ds:Transforms>
                  <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                  <ds:DigestValue>PLACEHOLDER_DIGEST</ds:DigestValue>
                </ds:Reference>
                <ds:Reference Type="http://www.w3.org/2000/09/xmldsig#SignatureProperties" URI="#xadesSignedProperties">
                  <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                  <ds:DigestValue>PLACEHOLDER_PROPERTIES_DIGEST</ds:DigestValue>
                </ds:Reference>
              </ds:SignedInfo>
              <ds:SignatureValue>PLACEHOLDER_SIGNATURE</ds:SignatureValue>
              <ds:KeyInfo>
                <ds:X509Data>
                  <ds:X509Certificate>PLACEHOLDER_CERTIFICATE</ds:X509Certificate>
                </ds:X509Data>
              </ds:KeyInfo>
            </ds:Signature>
          </sac:SignatureInformation>
        </sig:UBLDocumentSignatures>
      </ext:ExtensionContent>
    </ext:UBLExtension>
  </ext:UBLExtensions>

  <cbc:ProfileID>reporting:1.0</cbc:ProfileID>
  <cbc:ID>$invoiceNumber</cbc:ID>
  <cbc:UUID>$uuid</cbc:UUID>
  <cbc:IssueDate>$issueDate</cbc:IssueDate>
  <cbc:IssueTime>$issueTime</cbc:IssueTime>
  <cbc:InvoiceTypeCode name="0100000">388</cbc:InvoiceTypeCode>
  <cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>
  <cbc:TaxCurrencyCode>SAR</cbc:TaxCurrencyCode>

  <!-- Additional Documents -->
  <cac:AdditionalDocumentReference>
    <cbc:ID>ICV</cbc:ID>
    <cbc:UUID>$icv</cbc:UUID>
  </cac:AdditionalDocumentReference>
  <cac:AdditionalDocumentReference>
    <cbc:ID>PIH</cbc:ID>
    <cac:Attachment>
      <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">$previousInvoiceHash</cbc:EmbeddedDocumentBinaryObject>
    </cac:Attachment>
  </cac:AdditionalDocumentReference>
  <cac:AdditionalDocumentReference>
    <cbc:ID>QR</cbc:ID>
    <cac:Attachment>
      <cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">test</cbc:EmbeddedDocumentBinaryObject>
    </cac:Attachment>
  </cac:AdditionalDocumentReference>

  <!-- Supplier -->
  <cac:AccountingSupplierParty>
    <cac:Party>
      <cac:PartyTaxScheme>
        <cbc:CompanyID>$supplierVAT</cbc:CompanyID>
        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
      </cac:PartyTaxScheme>
      <cac:PartyLegalEntity>
        <cbc:RegistrationName>$supplierName</cbc:RegistrationName>
      </cac:PartyLegalEntity>
    </cac:Party>
  </cac:AccountingSupplierParty>

  <!-- Customer -->
  <cac:AccountingCustomerParty>
    <cac:Party>
      <cac:PartyTaxScheme>
        <cbc:CompanyID>$customerVAT</cbc:CompanyID>
        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
      </cac:PartyTaxScheme>
      <cac:PartyLegalEntity>
        <cbc:RegistrationName>$customerName</cbc:RegistrationName>
      </cac:PartyLegalEntity>
    </cac:Party>
  </cac:AccountingCustomerParty>

  $invoiceLines

  <cac:TaxTotal>
    <cbc:TaxAmount currencyID="SAR">${vatTotal.toStringAsFixed(2)}</cbc:TaxAmount>
  </cac:TaxTotal>

  <cac:LegalMonetaryTotal>
    <cbc:LineExtensionAmount currencyID="SAR">${subtotal.toStringAsFixed(2)}</cbc:LineExtensionAmount>
    <cbc:TaxExclusiveAmount currencyID="SAR">${subtotal.toStringAsFixed(2)}</cbc:TaxExclusiveAmount>
    <cbc:TaxInclusiveAmount currencyID="SAR">${total.toStringAsFixed(2)}</cbc:TaxInclusiveAmount>
    <cbc:AllowanceTotalAmount currencyID="SAR">0.00</cbc:AllowanceTotalAmount>
    <cbc:PrepaidAmount currencyID="SAR">0.00</cbc:PrepaidAmount>
    <cbc:PayableAmount currencyID="SAR">${total.toStringAsFixed(2)}</cbc:PayableAmount>
  </cac:LegalMonetaryTotal>

  <cac:Signature>
    <cbc:ID>urn:oasis:names:specification:ubl:signature:Invoice</cbc:ID>
    <cbc:SignatureMethod>urn:oasis:names:specification:ubl:dsig:enveloped:xades</cbc:SignatureMethod>
  </cac:Signature>

</Invoice>
''';
}
