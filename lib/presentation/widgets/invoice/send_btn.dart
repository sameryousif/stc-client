import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';

// Widget that displays a button to send the invoice, using the InvoiceProvider to handle the sending process, and providing feedback to the user through a SnackBar with the result of the operation
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
    late InvoiceResult result = InvoiceResult(success: false, message: ""); 

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
                result = await provider.sendInvoice();
                print(result.message);
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
