import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

class InvoiceInfoSection extends StatelessWidget {
  final InvoiceFormController c;
  const InvoiceInfoSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Invoice Information"),
        CustomField(
          controller: c.invoiceNumber,
          label: "Invoice Number",
          readOnly: true,
        ),
        CustomField(controller: c.invoiceDate, label: "Invoice Date"),
        CustomField(controller: c.invoiceType, label: "Invoice Type"),
        CustomField(controller: c.currencyCode, label: "Currency Code"),
      ],
    );
  }
}
