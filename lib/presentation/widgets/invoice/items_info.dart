import 'package:flutter/material.dart';
import '../../../core/invoice/invoice_item.dart';
import '../item_card.dart';
import '../section_title.dart';

class InvoiceItemsSection extends StatelessWidget {
  final List<InvoiceItem> items;
  final void Function(int index) onDelete;
  final VoidCallback onChanged;
  final VoidCallback onAddItem;

  const InvoiceItemsSection({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onChanged,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle("Invoice Items"),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder:
                (context, index) => ItemCard(
                  item: items[index],
                  onDelete: () => onDelete(index),
                  onChanged: onChanged,
                ),
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add, size: 16),
          label: const Text("Add Item", style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }
}
