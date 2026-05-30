import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';

// Widget that displays a button to send the invoice, using the InvoiceProvider to handle the sending process, and providing feedback to the user through a SnackBar with the result of the operation
class ClearInvoiceButton extends StatelessWidget {
  final InvoiceFormController c;
  final TextEditingController xmlController;
  final TextEditingController responseController;
  final Color? color;

  const ClearInvoiceButton({
    super.key,
    required this.c,
    required this.color,
    required this.xmlController,
    required this.responseController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    late InvoiceResult result = InvoiceResult(success: false, message: "");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed:
                provider.isSendingClear
                    ? null
                    : () async {
                      provider.signedXml = xmlController.text;

                      // Clear previous response
                      responseController.text = "Sending invoice...";

                      result = await provider.clearInvoice(isSandBox: false);

                      // Update the response area instead of showing SnackBar
                      responseController.text = result.message;
                    },
            child:
                provider.isSendingClear
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Clear Invoice",
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ApiService.clearanceUrl,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
