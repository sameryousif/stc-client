import 'package:flutter/material.dart';

//// Widget that displays a single row of totals information, used in the invoice totals section to show subtotal, tax total, and grand total
class TotalsRow extends StatelessWidget {
  final String title;
  final double value;
  final bool bold;

  const TotalsRow({
    super.key,
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${value.toStringAsFixed(2)} SDG",
            style: TextStyle(
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
