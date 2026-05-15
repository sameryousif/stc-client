import 'package:flutter/material.dart';
import '../../../core/invoice/invoice_item.dart';
import '../item_card.dart';
import '../section_title.dart';

class InvoiceItemsSection extends StatelessWidget {
  final List<InvoiceItem> items;
  final void Function(int index) onDelete;
  final VoidCallback onChanged;

  const InvoiceItemsSection({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Invoice Items"),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder:
              (context, index) => ItemCard(
                item: items[index],
                onDelete: () => onDelete(index),
                onChanged: onChanged,
              ),
        ),
      ],
    );
  }
}
