import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/models/controllers/invoice_controller.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';

class SendInvoiceButton extends StatelessWidget {
  final InvoiceFormController c;
  final TextEditingController xmlController;
  final Color? color;

  const SendInvoiceButton({
    super.key,
    required this.c,
    required this.color,
    required this.xmlController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed:
          provider.isSending
              ? null
              : () async {
                provider.signedXml = xmlController.text;
                final result = await provider.sendInvoice();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
      child:
          provider.isSending
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                "Send Invoice",
                style: TextStyle(color: Colors.white),
              ),
    );
  }
}
