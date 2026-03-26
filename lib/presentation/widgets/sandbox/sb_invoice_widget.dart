import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/sandBox_controller.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/presentation/widgets/sandbox/sandBox_card.dart';
import 'response_box.dart';

class InvoiceSection extends StatelessWidget {
  final SandboxController controller;
  final TextEditingController jsonCtrl;

  const InvoiceSection({
    super.key,
    required this.controller,
    required this.jsonCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return SandboxCard(
      title: "📄 Invoice Submission",
      child: Column(
        children: [
          TextField(
            controller: jsonCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: "Signed Invoice JSON",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      provider.isSendingClear
                          ? null
                          : () =>
                              controller.clearInvoice(provider, jsonCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2C365A),
                  ),
                  child:
                      provider.isSendingClear
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Clear",
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      provider.isSendingReport
                          ? null
                          : () =>
                              controller.reportInvoice(provider, jsonCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2C365A),
                  ),
                  child:
                      provider.isSendingReport
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Report",
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          ResponseBox(notifier: controller.submitResponse),
        ],
      ),
    );
  }
}
