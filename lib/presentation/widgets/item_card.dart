import 'package:flutter/material.dart';
import '../../domain/invoice/invoice_item.dart';
import 'custom_field.dart';

class ItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;

  const ItemCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CustomField(controller: item.nameController, label: "Item Name"),
            CustomField(
              controller: item.descriptionController,
              label: "Description",
            ),
            Row(
              children: [
                Expanded(
                  child: CustomField(
                    controller: item.quantityController,
                    label: "Qty",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomField(
                    controller: item.unitPriceController,
                    label: "Price",
                  ),
                ),
              ],
            ),
            CustomField(controller: item.taxRateController, label: "Tax (%)"),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
