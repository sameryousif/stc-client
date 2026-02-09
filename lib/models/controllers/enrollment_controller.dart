import 'package:flutter/material.dart';
import 'package:stc_client/services/crypto_service.dart';
import 'package:stc_client/utils/tools_paths.dart';
import 'package:stc_client/providers/CertificateProvider.dart';

class EnrollmentController {
  final CryptoService cryptoService = CryptoService();

  // Subject Fields with defaults
  final TextEditingController cnCtrl = TextEditingController(
    text: "My.Company.com",
  );
  final TextEditingController oCtrl = TextEditingController(
    text: "Organization",
  );
  final TextEditingController ouCtrl = TextEditingController(text: "IT");
  final TextEditingController cCtrl = TextEditingController(text: "SD");
  final TextEditingController stCtrl = TextEditingController(text: "Khartoum");
  final TextEditingController lCtrl = TextEditingController(text: "Khartoum");
  final TextEditingController serialCtrl = TextEditingController(text: "5003");

  final TextEditingController tokenCtrl = TextEditingController();

  // State Variables
  String privateKey = '';
  String csr = '';
  String certificate = '';

  // Load all files
  Future<void> loadAllFiles(
    Function(String) setPrivateKey,
    Function(String) setCsr,
    Function(String) setCert,
  ) async {
    await loadPrivateKey(setPrivateKey);
    await loadCsr(setCsr);
    await loadCertificate(setCert);
  }

  Future<void> loadPrivateKey(Function(String) setPrivateKey) async {
    final key = await cryptoService.readPrivateKey();
    setPrivateKey(key);
  }

  Future<void> loadCsr(Function(String) setCsr) async {
    final value = await cryptoService.readCsr();
    setCsr(value);
  }

  Future<void> loadCertificate(Function(String) setCert) async {
    final cert = await cryptoService.readCertificate();
    setCert(cert);
  }

  // Generate CSR
  Future<void> generateCsr(
    Function(String) setPrivateKey,
    Function(String) setCsr,
  ) async {
    await ToolPaths.ensureToolsReady();
    await ToolPaths.verifyToolsExist();

    await cryptoService.generateKeyAndCsr({
      'CN': cnCtrl.text,
      'O': oCtrl.text,
      'OU': ouCtrl.text,
      'C': cCtrl.text,
      'ST': stCtrl.text,
      'L': lCtrl.text,
      'serialNumber': serialCtrl.text,
    });

    await loadCsr(setCsr);
    await loadPrivateKey(setPrivateKey);
  }

  // Generate Certificate
  Future<void> generateCertificate(
    CertificateProvider provider,
    Function(String) setCert, {
    required String token,
  }) async {
    await provider.enrollCertificate(token);
    await loadCertificate(setCert);
  }
}
