import 'package:flutter/material.dart';
import 'package:stc_client/application/controllers/enrollment_controller.dart';
import 'package:stc_client/core/enrollment_subject.dart';
import 'package:stc_client/services/certificateEnrollService.dart';
import 'package:stc_client/services/crypto_service.dart';
import 'package:stc_client/services/enrollment_service.dart';
import 'package:stc_client/services/file_service.dart';
import 'package:stc_client/presentation/widgets/panel_widget.dart';

// Widget that displays the enrollment page, allowing users to generate a CSR and enroll for a certificate by providing the necessary information and interacting with the EnrollmentController to handle the logic of generating the CSR and enrolling for the certificate, while also providing feedback to the user through the UI
class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({Key? key}) : super(key: key);

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  late final EnrollmentController controller;

  String privateKey = '';
  String csr = '';
  String certificate = '';

  final cnCtrl = TextEditingController(text: 'My.Company.com');
  final oCtrl = TextEditingController(text: 'Organization');
  final ouCtrl = TextEditingController(text: 'IT');
  final cCtrl = TextEditingController(text: 'SD');
  final stCtrl = TextEditingController(text: 'Khartoum');
  final lCtrl = TextEditingController(text: 'Khartoum');
  final serialCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final cryptoService = CryptoService();
    final enrollmentService = EnrollmentService(cryptoService);

    final fileService = FileService();
    final certEnrollService = CertEnrollService(fileService: fileService);

    controller = EnrollmentController(enrollmentService, certEnrollService);
    controller.loadInitialData();
  }

  @override
  void dispose() {
    cnCtrl.dispose();
    oCtrl.dispose();
    ouCtrl.dispose();
    cCtrl.dispose();
    stCtrl.dispose();
    lCtrl.dispose();
    serialCtrl.dispose();
    tokenCtrl.dispose();
    super.dispose();
  }

  /// Generate CSR + private key
  Future<void> generateCsr() async {
    late final subject = EnrollmentSubject(
      cn: cnCtrl.text,
      o: oCtrl.text,
      ou: ouCtrl.text,
      c: cCtrl.text,
      st: stCtrl.text,
      l: lCtrl.text,
      serialNumber: serialCtrl.text,
    );

    final result = await controller.generateCsr(subject);

    controller.privateKey.value = result.privateKey;
    controller.csr.value = result.csrBase64;
  }

  Future<void> generateCertificate() async {
    final cert = await controller.enrollCertificate(tokenCtrl.text);

    controller.certificate.value = cert;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Certificate Generator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C365A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: controller.privateKey,
          builder: (_, __, ___) {
            return screenWidth > 800
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LeftPanel(
                        privateKey: controller.privateKey.value,
                        cnCtrl: cnCtrl,
                        oCtrl: oCtrl,
                        ouCtrl: ouCtrl,
                        cCtrl: cCtrl,
                        stCtrl: stCtrl,
                        lCtrl: lCtrl,
                        serialCtrl: serialCtrl,
                        onGenerateCsr: generateCsr,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RightPanel(
                        csr: controller.csr.value,
                        certificate: controller.certificate.value,
                        tokenCtrl: tokenCtrl,
                        onGenerateCert: generateCertificate,
                      ),
                    ),
                  ],
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      LeftPanel(
                        privateKey: controller.privateKey.value,
                        cnCtrl: cnCtrl,
                        oCtrl: oCtrl,
                        ouCtrl: ouCtrl,
                        cCtrl: cCtrl,
                        stCtrl: stCtrl,
                        lCtrl: lCtrl,
                        serialCtrl: serialCtrl,
                        onGenerateCsr: generateCsr,
                      ),
                      const SizedBox(height: 20),
                      RightPanel(
                        csr: controller.csr.value,
                        certificate: controller.certificate.value,
                        tokenCtrl: tokenCtrl,
                        onGenerateCert: generateCertificate,
                      ),
                    ],
                  ),
                );
          },
        ),
      ),
    );
  }
}
