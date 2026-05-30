import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import '../custom_field.dart';
import '../section_title.dart';

class SupplierSection extends StatelessWidget {
  final InvoiceFormController c;
  const SupplierSection({super.key, required this.c});

  String? _validateVat(String v) {
    if (v.trim().isEmpty) return "TIN is required";
    if (v.trim().length < 5) return "TIN seems too short";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = c.supplier;

    return Column(
      children: [
        const SectionTitle("Supplier Information"),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: s.name, label: "Supplier Name",
                onChanged: (v) => s.name = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: s.tin, label: "Supplier TIN",
                onChanged: (v) => s.tin = v, compact: true,
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
                value: s.street, label: "Street Name",
                onChanged: (v) => s.street = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: s.address, label: "Address",
                onChanged: (v) => s.address = v, compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: s.city, label: "City",
                onChanged: (v) => s.city = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: s.country, label: "Country",
                onChanged: (v) => s.country = v, compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CustomField(
                value: s.phone, label: "Phone",
                onChanged: (v) => s.phone = v, compact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomField(
                value: s.email, label: "Email",
                onChanged: (v) => s.email = v, compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
