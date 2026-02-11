import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

class CustomerSection extends StatelessWidget {
  final InvoiceFormController c;
  const CustomerSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Customer Information"),
        CustomField(controller: c.customerName, label: "Customer Name"),
        CustomField(controller: c.customerTIN, label: "Customer TIN"),
        CustomField(controller: c.customerAddress, label: "Customer Address"),
        CustomField(controller: c.customerCity, label: "Customer City"),
        CustomField(controller: c.customerCountry, label: "Customer Country"),
        CustomField(controller: c.customerPhone, label: "Customer Phone"),
        CustomField(controller: c.customerEmail, label: "Customer Email"),
      ],
    );
  }
}
