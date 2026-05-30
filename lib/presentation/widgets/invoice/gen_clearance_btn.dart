import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/invoice_controller.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';

// Widget that displays a button to generate and sign the invoice, using the InvoiceProvider to handle the generation and signing process, and providing feedback to the user through a SnackBar with the result of the operation
class GenerateClearanceInvoice extends StatelessWidget {
  final InvoiceFormController c;
  final TextEditingController xmlController;

  final Color? color;

  const GenerateClearanceInvoice({
    super.key,
    required this.c,
    required this.xmlController,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

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
                provider.isGeneratingB2B
                    ? null
                    : () async {
                      await ToolPaths.ensureToolsReady();
                      await ToolPaths.verifyToolsExist();
                      final result = await provider.generateAndSign(
                        invoiceNumber: c.invoiceNumber,
                        items: c.items,
                        supplierInfo: c.supplierInfo,
                        customerInfo: c.customerInfo,
                        clearance: true,
                      );

                      xmlController.text = provider.signedXml ?? "";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      if (kDebugMode) print(result.message);
                    },
            child:
                provider.isGeneratingB2B
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      "Generate B2B Invoice",
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Endpoint: ${ApiService.clearanceUrl}",
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
