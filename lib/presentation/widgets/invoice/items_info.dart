import 'package:flutter/material.dart';
import '../../../core/invoice/invoice_item.dart';
import '../item_card.dart';
import '../section_title.dart';

// Widget that displays the invoice items section of the invoice form, showing a list of invoice items using the ItemCard widget for each item, and allowing users to delete items from the list using the onDelete callback function, while also using the SectionTitle widget to label the section
class InvoiceItemsSection extends StatelessWidget {
  final List<InvoiceItem> items;
  final void Function(int index) onDelete;

  const InvoiceItemsSection({
    super.key,
    required this.items,
    required this.onDelete,
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
              (context, index) =>
                  ItemCard(item: items[index], onDelete: () => onDelete(index)),
        ),
      ],
    );
  }
}
