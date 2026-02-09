import '../services/file_service.dart';
import '../services/network_service.dart';
import '../services/crypto_service.dart';
import 'dart:io';

class CertificateManager {
  final FileService fileService;
  final NetworkService networkService;
  final CryptoService cryptoService;

  CertificateManager({
    required this.fileService,
    required this.networkService,
    required this.cryptoService,
  });

  /// Checks certificate validity
  Future<bool> isCertificateValid() async {
    return fileService.isCertificateStillValid();
  }

  /// Main enrollment logic
  Future<void> enrollCertificate(String tokenCtrl) async {
    //  Check certificate first
    if (await isCertificateValid()) {
      print('✔ Existing certificate still valid. No need to re-enroll.');
      return;
    }

    //  Get CSR file
    final File csrFile = await cryptoService.getCsrFile();

    //  Send CSR to server and get new certificate
    final String certificateContent = await networkService.sendCsr(
      csrFile,
      tokenCtrl,
    );

    //  Save the certificate as PEM
    await fileService.saveCertificate(certificateContent);
    print('✔ New certificate saved successfully.');
  }
}
