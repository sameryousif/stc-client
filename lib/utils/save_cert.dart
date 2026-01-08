import 'dart:io';

Future<void> saveCertificateAsPem(String certificateContent) async {
  final pemPath = r'C:\openssl_keys\merchant.pem';

  await File(pemPath).writeAsString(certificateContent, mode: FileMode.write);

  print('✔ Certificate saved as-is at: $pemPath');
}
