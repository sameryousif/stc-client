import 'package:flutter/material.dart';
import '../section_title.dart';
import '../totals_row.dart';

// Widget that displays the totals information for an invoice, including the subtotal, tax total, and grand total, using the TotalsRow widget to display each row of information and the SectionTitle widget to label the section
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
