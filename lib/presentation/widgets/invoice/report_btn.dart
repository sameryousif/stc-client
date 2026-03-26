import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';

class ReportInvoiceButton extends StatelessWidget {
  final InvoiceFormController c;
  final TextEditingController xmlController;
  final TextEditingController responseController;
  final Color? color;

  const ReportInvoiceButton({
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

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed:
          provider.isSendingReport
              ? null
              : () async {
                provider.signedXml = xmlController.text;

                // Clear previous response
                responseController.text = "Sending invoice...";

                result = await provider.reportInvoice();

                // Update the response area instead of showing SnackBar
                responseController.text = result.message;
              },
      child:
          provider.isSendingReport
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                "Report Invoice",
                style: TextStyle(color: Colors.white),
              ),
    );
  }
}
