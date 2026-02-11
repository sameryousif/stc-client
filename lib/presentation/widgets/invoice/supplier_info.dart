import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

class SupplierSection extends StatelessWidget {
  final InvoiceFormController c;
  const SupplierSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Supplier Information"),
        CustomField(controller: c.supplierName, label: "Supplier Name"),
        CustomField(controller: c.supplierTIN, label: "Supplier TIN"),
        CustomField(controller: c.supplierAddress, label: "Supplier Address"),
        CustomField(controller: c.supplierCity, label: "Supplier City"),
        CustomField(controller: c.supplierCountry, label: "Supplier Country"),
        CustomField(controller: c.supplierPhone, label: "Supplier Phone"),
        CustomField(controller: c.supplierEmail, label: "Supplier Email"),
      ],
    );
  }
}
