import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/models/controllers/enrollment_controller.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
import 'package:stc_client/widgets/panel_widget.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final controller = EnrollmentController();

  @override
  void initState() {
    super.initState();
    controller.loadAllFiles(
      (key) => setState(() => controller.privateKey = key),
      (csr) => setState(() => controller.csr = csr),
      (cert) => setState(() => controller.certificate = cert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CertificateProvider>(context, listen: false);
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
        child:
            screenWidth > 800
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LeftPanel(
                        privateKey: controller.privateKey,
                        cnCtrl: controller.cnCtrl,
                        oCtrl: controller.oCtrl,
                        ouCtrl: controller.ouCtrl,
                        cCtrl: controller.cCtrl,
                        stCtrl: controller.stCtrl,
                        lCtrl: controller.lCtrl,
                        serialCtrl: controller.serialCtrl,
                        onGenerateCsr:
                            () => controller.generateCsr(
                              (key) =>
                                  setState(() => controller.privateKey = key),
                              (csr) => setState(() => controller.csr = csr),
                            ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RightPanel(
                        csr: controller.csr,
                        certificate: controller.certificate,
                        tokenCtrl: controller.tokenCtrl,
                        onGenerateCert:
                            () => controller.generateCertificate(
                              provider,
                              (cert) =>
                                  setState(() => controller.certificate = cert),
                            ),
                      ),
                    ),
                  ],
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      LeftPanel(
                        privateKey: controller.privateKey,
                        cnCtrl: controller.cnCtrl,
                        oCtrl: controller.oCtrl,
                        ouCtrl: controller.ouCtrl,
                        cCtrl: controller.cCtrl,
                        stCtrl: controller.stCtrl,
                        lCtrl: controller.lCtrl,
                        serialCtrl: controller.serialCtrl,
                        onGenerateCsr:
                            () => controller.generateCsr(
                              (key) =>
                                  setState(() => controller.privateKey = key),
                              (csr) => setState(() => controller.csr = csr),
                            ),
                      ),
                      const SizedBox(height: 20),
                      RightPanel(
                        csr: controller.csr,
                        certificate: controller.certificate,
                        tokenCtrl: controller.tokenCtrl,
                        onGenerateCert:
                            () => controller.generateCertificate(
                              provider,
                              (cert) =>
                                  setState(() => controller.certificate = cert),
                            ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
