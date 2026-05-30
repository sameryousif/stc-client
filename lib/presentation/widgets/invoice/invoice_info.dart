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
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: c.invoiceNumber,
                label: "Invoice Number",
                onChanged: (v) => c.invoiceNumber = v,
                compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: c.invoiceDate.toString().split(' ').first,
                label: "Invoice Date",
                onChanged: (v) =>
                    c.invoiceDate = DateTime.tryParse(v) ?? c.invoiceDate,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: c.invoiceType,
                label: "Invoice Type",
                onChanged: (v) => c.invoiceType = v,
                compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: c.currencyCode,
                label: "Currency Code",
                onChanged: (v) => c.currencyCode = v,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
