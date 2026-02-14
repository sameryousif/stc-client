import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:stc_client/core/enrollment_subject.dart';
import 'package:stc_client/services/crypto_service.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';

/// Service responsible for managing the entire enrollment process, including CSR generation and certificate loading
class EnrollmentService {
  final CryptoService cryptoService;

  EnrollmentService(this.cryptoService);

  /// Generates private key + CSR and returns Base64 CSR
  Future<String> generateCsr(EnrollmentSubject subject) async {
    await ToolPaths.ensureToolsReady();
    await ToolPaths.verifyToolsExist();

    await cryptoService.generateKeyAndCsr({
      'CN': subject.cn,
      'O': subject.o,
      'OU': subject.ou,
      'C': subject.c,
      'ST': subject.st,
      'L': subject.l,
      'serialNumber': subject.serialNumber,
    });

    final Uint8List? csrBytes = await cryptoService.readCsr();
    return base64Encode(csrBytes!);
  }

  Future<String> loadPrivateKey() async {
    return await cryptoService.readPrivateKey();
  }

  Future<String?> loadCertificate() async {
    final Uint8List? certBytes = await cryptoService.readCertificate();
    if (certBytes == null) {
      return null;
    }
    return base64Encode(certBytes);
  }

  Future<File?> getCsrFile() async {
    final file = await cryptoService.getCsrFile();
    if (file == null) {
      return null;
    }
    return file;
  }
}
