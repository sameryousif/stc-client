import 'package:flutter/material.dart';
import '../section_title.dart';
import '../totals_row.dart';

class InvoiceTotalsSection extends StatelessWidget {
  final double subtotal;
  final double taxTotal;
  final double grandTotal;

  const InvoiceTotalsSection({
    super.key,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Totals"),
        TotalsRow(title: "Subtotal", value: subtotal),
        TotalsRow(title: "Tax Total", value: taxTotal),
        TotalsRow(title: "Grand Total", value: grandTotal, bold: true),
      ],
    );
  }
}
