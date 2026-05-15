import 'package:flutter/material.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';

class ItemCard extends StatefulWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const ItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _taxCtrl;

  String? _qtyError;
  String? _priceError;
  String? _taxError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(text: widget.item.unitPrice.toString());
    _taxCtrl = TextEditingController(text: widget.item.taxRate.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _qtyError = null;
      _priceError = null;
      _taxError = null;

      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty < 0) _qtyError = "Must be >= 0";

      final price = double.tryParse(_priceCtrl.text);
      if (price == null || price < 0) _priceError = "Must be >= 0";

      final tax = double.tryParse(_taxCtrl.text);
      if (tax == null || tax < 0 || tax > 100) _taxError = "Must be 0-100";
    });
    return _qtyError == null && _priceError == null && _taxError == null;
  }

  void _updateItem() {
    if (!_validate()) return;
    widget.item.name = _nameCtrl.text;
    widget.item.description = _descCtrl.text;
    widget.item.quantity = int.tryParse(_qtyCtrl.text) ?? 0;
    widget.item.unitPrice = double.tryParse(_priceCtrl.text) ?? 0;
    widget.item.taxRate = double.tryParse(_taxCtrl.text) ?? 0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateItem(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateItem(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: InputDecoration(
                      labelText: "Qty",
                      border: const OutlineInputBorder(),
                      errorText: _qtyError,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: InputDecoration(
                      labelText: "Price",
                      border: const OutlineInputBorder(),
                      errorText: _priceError,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taxCtrl,
              decoration: InputDecoration(
                labelText: "Tax (%)",
                border: const OutlineInputBorder(),
                errorText: _taxError,
              ),
              onChanged: (_) => _updateItem(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
