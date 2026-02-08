import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/models/controllers/invoice_controller.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';
import 'package:stc_client/utils/tools_paths.dart';

class SignInvoiceButton extends StatelessWidget {
  final InvoiceFormController c;
  final TextEditingController xmlController;

  final Color? color;

  const SignInvoiceButton({
    super.key,
    required this.c,
    required this.xmlController,
    required this.color,
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
          provider.isGenerating
              ? null
              : () async {
                await ToolPaths.ensureToolsReady();
                await ToolPaths.verifyToolsExist();
                final result = await provider.generateAndSign(
                  invoiceNumber: c.invoiceNumber.text,
                  items: c.items,
                  supplierInfo: c.supplierInfo,
                  customerInfo: c.customerInfo,
                );

                xmlController.text = provider.signedXml ?? "";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
                print(result.message);
              },
      child:
          provider.isGenerating
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                "Generate & Sign Invoice",
                style: TextStyle(color: Colors.white),
              ),
    );
  }
}
