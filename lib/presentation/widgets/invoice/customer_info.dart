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
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: cust.name, label: "Customer Name",
                onChanged: (v) => cust.name = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: cust.tin, label: "Customer TIN",
                onChanged: (v) => cust.tin = v, compact: true,
                validator: _validateVat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: cust.street, label: "Street Name",
                onChanged: (v) => cust.street = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: cust.address, label: "Address",
                onChanged: (v) => cust.address = v, compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: cust.city, label: "City",
                onChanged: (v) => cust.city = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: cust.country, label: "Country",
                onChanged: (v) => cust.country = v, compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: cust.phone, label: "Phone",
                onChanged: (v) => cust.phone = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: cust.email, label: "Email",
                onChanged: (v) => cust.email = v, compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
