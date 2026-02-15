import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

// Widget that displays the supplier information section of the invoice form, allowing users to input the supplier's name, TIN, address, city, country, phone number, and email address, and using the SectionTitle widget to label the section
class SupplierSection extends StatelessWidget {
  final InvoiceFormController c;
  const SupplierSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final s = c.supplier;

    return Column(
      children: [
        const SectionTitle("Supplier Information"),
        const SizedBox(height: 10),
        CustomField(
          value: s.name,
          label: "Supplier Name",
          onChanged: (v) => s.name = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.tin,
          label: "Supplier TIN",
          onChanged: (v) => s.tin = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.street,
          label: "Street Name",
          onChanged: (v) => s.street = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.address,
          label: "Supplier Address",
          onChanged: (v) => s.address = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.city,
          label: "Supplier City",
          onChanged: (v) => s.city = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.country,
          label: "Supplier Country",
          onChanged: (v) => s.country = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.phone,
          label: "Supplier Phone",
          onChanged: (v) => s.phone = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: s.email,
          label: "Supplier Email",
          onChanged: (v) => s.email = v,
        ),
      ],
    );
  }
}
