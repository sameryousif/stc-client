import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/enrollment_controller.dart';
import 'package:stc_client/application/controllers/sandBox_controller.dart';
import 'package:stc_client/presentation/widgets/sandbox/sb_enroll_widget.dart';
import 'package:stc_client/presentation/widgets/sandbox/sb_invoice_widget.dart';
import 'package:stc_client/services/certificateEnrollService.dart';
import 'package:stc_client/services/crypto_service.dart';
import 'package:stc_client/services/enrollment_service.dart';
import 'package:stc_client/services/file_service.dart';

class SandboxPage extends StatefulWidget {
  const SandboxPage({super.key});

  @override
  State<SandboxPage> createState() => _SandboxPageState();
}

class _SandboxPageState extends State<SandboxPage> {
  late SandboxController controller;

  final csrCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();
  final jsonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final crypto = CryptoService();
    final enrollService = EnrollmentService(crypto);
    final fileService = FileService();
    final certService = CertEnrollService(fileService: fileService);

    final enrollmentController = EnrollmentController(
      enrollService,
      certService,
    );

    controller = SandboxController(enrollmentController: enrollmentController);

    enrollmentController.loadInitialData();
  }

  @override
  void dispose() {
    csrCtrl.dispose();
    tokenCtrl.dispose();
    jsonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sandbox Environment",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C365A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            /// Responsive split
            if (constraints.maxWidth > 900) {
              return Row(
                children: [
                  Expanded(
                    child: EnrollSection(
                      controller: controller,
                      csrCtrl: csrCtrl,
                      tokenCtrl: tokenCtrl,
                      color: Color(0xFF2C365A),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: InvoiceSection(
                      controller: controller,
                      jsonCtrl: jsonCtrl,
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  EnrollSection(
                    controller: controller,
                    csrCtrl: csrCtrl,
                    tokenCtrl: tokenCtrl,
                    color: Color(0xFF2C365A),
                  ),
                  const SizedBox(height: 20),
                  InvoiceSection(controller: controller, jsonCtrl: jsonCtrl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
