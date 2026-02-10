import 'dart:io';
import 'dart:typed_data';
import '../utils/app_paths.dart';

class FileService {
  final Future<String> certPath = AppPaths.certPath();

  /// Saves certificate to PEM file
  Future<void> saveCertificate(Uint8List certificateContent) async {
    await File(await certPath).writeAsBytes(certificateContent);
    print('✔ Certificate saved at: $certPath');
  }

  /// Checks if the certificate file exists and is still valid
  Future<bool> isCertificateStillValid({int maxDays = 30}) async {
    final certFile = File(await certPath);

    if (!await certFile.exists()) return false;

    final lastModified = await certFile.lastModified();
    final daysOld = DateTime.now().difference(lastModified).inDays;

    return daysOld < maxDays;
  }
}
