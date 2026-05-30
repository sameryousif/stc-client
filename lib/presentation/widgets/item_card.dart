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
      if (qty == null || qty <= 0) _qtyError = "Must be > 0";

      final price = double.tryParse(_priceCtrl.text);
      if (price == null || price <= 0) _priceError = "Must be > 0";

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
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      labelStyle: const TextStyle(fontSize: 10),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _qtyCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Qty",
                      labelStyle: const TextStyle(fontSize: 10),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      errorText: _qtyError,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Price",
                      labelStyle: const TextStyle(fontSize: 10),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      errorText: _priceError,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Description",
                      labelStyle: const TextStyle(fontSize: 10),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _taxCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Tax (%)",
                      labelStyle: const TextStyle(fontSize: 10),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      errorText: _taxError,
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
