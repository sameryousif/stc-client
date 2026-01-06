import '../models/invoice_item.dart';

String generateUBLInvoice({
  required String invoiceNumber,
  required String invoiceDate,
  required String invoiceType,
  required String currencyCode,
  required String supplierName,
  required String supplierTIN,
  required String supplierAddress,
  required String supplierCity,
  required String supplierCountry,
  required String supplierPhone,
  required String supplierEmail,
  required String customerName,
  required String customerTIN,
  required String customerAddress,
  required String customerCity,
  required String customerCountry,
  required String customerPhone,
  required String customerEmail,
  required List<InvoiceItem> items,
}) {
  // Helper to escape XML special characters
  String escapeXml(String? s) {
    if (s == null) return '';
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // Compute totals
  double subtotal = 0;
  double taxTotal = 0;
  for (var item in items) {
    final lineTotal = item.total; // quantity * unitPrice
    final taxAmount = lineTotal * (item.taxRate / 100);
    subtotal += lineTotal;
    taxTotal += taxAmount;
  }
  final grandTotal = subtotal + taxTotal;

  // Build invoice lines XML
  final invoiceLinesXml = items
      .asMap()
      .entries
      .map((entry) {
        final idx = entry.key + 1;
        final item = entry.value;
        final qty = item.quantity;
        final unitPrice = item.unitPrice;
        final lineTotal = item.total;
        final taxAmount = lineTotal * (item.taxRate / 100);
        return '''
    <cac:InvoiceLine>
      <cbc:ID>$idx</cbc:ID>
      <cbc:InvoicedQuantity unitCode="EA">${qty.toStringAsFixed(2)}</cbc:InvoicedQuantity>
      <cbc:LineExtensionAmount currencyID="${escapeXml(currencyCode)}">${lineTotal.toStringAsFixed(2)}</cbc:LineExtensionAmount>

      <cac:Item>
        <cbc:Name>${escapeXml(item.name.text)}</cbc:Name>
        <cbc:Description>${escapeXml(item.description.text)}</cbc:Description>
      </cac:Item>

      <cac:Price>
        <cbc:PriceAmount currencyID="${escapeXml(currencyCode)}">${unitPrice.toStringAsFixed(2)}</cbc:PriceAmount>
      </cac:Price>

      <cac:TaxTotal>
        <cbc:TaxAmount currencyID="${escapeXml(currencyCode)}">${taxAmount.toStringAsFixed(2)}</cbc:TaxAmount>
        <cac:TaxSubtotal>
          <cbc:TaxableAmount currencyID="${escapeXml(currencyCode)}">${lineTotal.toStringAsFixed(2)}</cbc:TaxableAmount>
          <cbc:TaxAmount currencyID="${escapeXml(currencyCode)}">${taxAmount.toStringAsFixed(2)}</cbc:TaxAmount>
          <cac:TaxCategory>
            <cbc:Percent>${item.taxRate.toStringAsFixed(2)}</cbc:Percent>
            <cac:TaxScheme>
              <cbc:ID>VAT</cbc:ID>
            </cac:TaxScheme>
          </cac:TaxCategory>
        </cac:TaxSubtotal>
      </cac:TaxTotal>
    </cac:InvoiceLine>
''';
      })
      .join('\n');

  // Final XML
  final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>${escapeXml(invoiceNumber)}</cbc:ID>
  <cbc:IssueDate>${escapeXml(invoiceDate)}</cbc:IssueDate>
  <cbc:InvoiceTypeCode>${escapeXml(invoiceType)}</cbc:InvoiceTypeCode>
  <cbc:DocumentCurrencyCode>${escapeXml(currencyCode)}</cbc:DocumentCurrencyCode>

  <cac:AccountingSupplierParty>
    <cac:Party>
      <cbc:Name>${escapeXml(supplierName)}</cbc:Name>
      <cac:PostalAddress>
        <cbc:StreetName>${escapeXml(supplierAddress)}</cbc:StreetName>
        <cbc:CityName>${escapeXml(supplierCity)}</cbc:CityName>
        <cbc:Country>
          <cbc:IdentificationCode>${escapeXml(supplierCountry)}</cbc:IdentificationCode>
        </cbc:Country>
      </cac:PostalAddress>
      <cac:PartyTaxScheme>
        <cbc:CompanyID>${escapeXml(supplierTIN)}</cbc:CompanyID>
        <cac:TaxScheme>
          <cbc:ID>VAT</cbc:ID>
        </cac:TaxScheme>
      </cac:PartyTaxScheme>
      <cac:Contact>
        <cbc:Telephone>${escapeXml(supplierPhone)}</cbc:Telephone>
        <cbc:ElectronicMail>${escapeXml(supplierEmail)}</cbc:ElectronicMail>
      </cac:Contact>
    </cac:Party>
  </cac:AccountingSupplierParty>

  <cac:AccountingCustomerParty>
    <cac:Party>
      <cbc:Name>${escapeXml(customerName)}</cbc:Name>
      <cac:PostalAddress>
        <cbc:StreetName>${escapeXml(customerAddress)}</cbc:StreetName>
        <cbc:CityName>${escapeXml(customerCity)}</cbc:CityName>
        <cbc:Country>
          <cbc:IdentificationCode>${escapeXml(customerCountry)}</cbc:IdentificationCode>
        </cbc:Country>
      </cac:PostalAddress>
      <cac:PartyTaxScheme>
        <cbc:CompanyID>${escapeXml(customerTIN)}</cbc:CompanyID>
        <cac:TaxScheme>
          <cbc:ID>VAT</cbc:ID>
        </cac:TaxScheme>
      </cac:PartyTaxScheme>
      <cac:Contact>
        <cbc:Telephone>${escapeXml(customerPhone)}</cbc:Telephone>
        <cbc:ElectronicMail>${escapeXml(customerEmail)}</cbc:ElectronicMail>
      </cac:Contact>
    </cac:Party>
  </cac:AccountingCustomerParty>

  $invoiceLinesXml

  <cac:TaxTotal>
    <cbc:TaxAmount currencyID="${escapeXml(currencyCode)}">${taxTotal.toStringAsFixed(2)}</cbc:TaxAmount>
  </cac:TaxTotal>

  <cac:LegalMonetaryTotal>
    <cbc:LineExtensionAmount currencyID="${escapeXml(currencyCode)}">${subtotal.toStringAsFixed(2)}</cbc:LineExtensionAmount>
    <cbc:TaxExclusiveAmount currencyID="${escapeXml(currencyCode)}">${subtotal.toStringAsFixed(2)}</cbc:TaxExclusiveAmount>
    <cbc:TaxInclusiveAmount currencyID="${escapeXml(currencyCode)}">${grandTotal.toStringAsFixed(2)}</cbc:TaxInclusiveAmount>
    <cbc:PayableAmount currencyID="${escapeXml(currencyCode)}">${grandTotal.toStringAsFixed(2)}</cbc:PayableAmount>
  </cac:LegalMonetaryTotal>
</Invoice>
''';

  return xml;
}
