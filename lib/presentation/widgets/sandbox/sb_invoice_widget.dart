import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/application/controllers/sandbox_controller.dart';
import 'package:stc_client/presentation/widgets/custom_field.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/presentation/widgets/sandbox/sandbox_card.dart';
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

    return SingleChildScrollView(
      child: SandboxCard(
        title: "📄 Invoice Submission",
        child: Column(
          children: [
            CustomField(
              value: "X-Sandbox-Mode",
              label: "Headers",
              onChanged: (v) => v,
              readOnly: true,
            ),
            const SizedBox(height: 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed:
                            provider.isSendingClear
                                ? null
                                : () => controller.clearInvoice(
                                  provider,
                                  jsonCtrl.text,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2C365A),
                        ),
                        child:
                            provider.isSendingClear
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Clear",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ApiService.clearanceUrl,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed:
                            provider.isSendingReport
                                ? null
                                : () => controller.reportInvoice(
                                  provider,
                                  jsonCtrl.text,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2C365A),
                        ),
                        child:
                            provider.isSendingReport
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Report",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ApiService.reportingUrl,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            ResponseBox(notifier: controller.submitResponse),
          ],
        ),
      ),
    );
  }
}
