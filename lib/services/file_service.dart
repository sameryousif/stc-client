import 'dart:io';
import '../utils/constants.dart';

class FileService {
  final String certPath = Constants.certPath;

  /// Saves certificate to PEM file
  Future<void> saveCertificate(String certificateContent) async {
    await File(certPath).writeAsString(certificateContent);
    print('✔ Certificate saved at: $certPath');
  }

  /// Checks if the certificate file exists and is still valid
  Future<bool> isCertificateStillValid({int maxDays = 30}) async {
    final certFile = File(certPath);

    if (!await certFile.exists()) return false;

    final lastModified = await certFile.lastModified();
    final daysOld = DateTime.now().difference(lastModified).inDays;

    return daysOld < maxDays;
  }
}
