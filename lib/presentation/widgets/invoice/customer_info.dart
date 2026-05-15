import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

class CustomerSection extends StatelessWidget {
  final InvoiceFormController c;
  const CustomerSection({super.key, required this.c});

  String? _validateVat(String v) {
    if (v.trim().isEmpty) return "TIN is required";
    if (v.trim().length < 5) return "TIN seems too short";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cust = c.customer;

    return Column(
      children: [
        const SectionTitle("Customer Information"),
        const SizedBox(height: 10),
        CustomField(
          value: cust.name,
          label: "Customer Name",
          onChanged: (v) => cust.name = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.tin,
          label: "Customer TIN",
          onChanged: (v) => cust.tin = v,
          validator: _validateVat,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.street,
          label: "Customer street",
          onChanged: (v) => cust.street = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.address,
          label: "Customer Address",
          onChanged: (v) => cust.address = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.city,
          label: "Customer City",
          onChanged: (v) => cust.city = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.country,
          label: "Customer Country",
          onChanged: (v) => cust.country = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.phone,
          label: "Customer Phone",
          onChanged: (v) => cust.phone = v,
        ),
        const SizedBox(height: 10),
        CustomField(
          value: cust.email,
          label: "Customer Email",
          onChanged: (v) => cust.email = v,
        ),
      ],
    );
  }
}
