import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

// Widget that displays the invoice information section of the invoice form, allowing users to input the invoice number, date, type, and currency code, and using the SectionTitle widget to label the section
class InvoiceInfoSection extends StatelessWidget {
  final InvoiceFormController c;
  const InvoiceInfoSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle("Invoice Information"),
        const SizedBox(height: 10),
        CustomField(
          value: c.invoiceNumber,
          label: "Invoice Number",
          onChanged: (String value) {
            c.invoiceNumber = value;
          },
        ),
        const SizedBox(height: 10),
        CustomField(
          value: c.invoiceDate.toString().split(' ').first,
          label: "Invoice Date",
          onChanged: (v) {
            // parse date if needed
            c.invoiceDate = DateTime.tryParse(v) ?? c.invoiceDate;
          },
        ),
        const SizedBox(height: 10),
        CustomField(
          value: c.invoiceType,
          label: "Invoice Type",
          onChanged: (v) => c.invoiceType = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: c.currencyCode,
          label: "Currency Code",
          onChanged: (v) => c.currencyCode = v,
        ),
      ],
    );
  }
}
