import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/sandBox_controller.dart';
import 'package:stc_client/presentation/widgets/sandbox/sandBox_card.dart';
import 'response_box.dart';

class EnrollSection extends StatelessWidget {
  final SandboxController controller;
  final TextEditingController csrCtrl;
  final TextEditingController tokenCtrl;
  final Color? color;

  const EnrollSection({
    super.key,
    required this.controller,
    required this.csrCtrl,
    required this.tokenCtrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SandboxCard(
        title: "🔐 Certificate Enrollment",
        child: Column(
          children: [
            TextField(
              controller: csrCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "CSR",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(
                labelText: "Token",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    controller.isEnrolling
                        ? null
                        : () async {
                          await controller.enroll(csrCtrl.text, tokenCtrl.text);
                        },

                style: ElevatedButton.styleFrom(
                  backgroundColor: color ?? Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    controller.isEnrolling
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Enroll",
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),

            const SizedBox(height: 12),
            ResponseBox(notifier: controller.enrollResponse),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                backgroundColor: Color(0xFF2C365A),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/enrollment');
              },
              child: const Text(
                'Full Experience Mode',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
