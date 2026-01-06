import 'dart:io';
import 'dart:convert';

Future<void> saveCertificateAsPemAndDer(String certificateBase64) async {
  // 1️⃣ Decode Base64 to bytes
  final certificateBytes = base64.decode(certificateBase64);

  // 2️⃣ Save as PEM file
  final pemPath = r'C:\openssl_keys\merchant.crt';
  await File(pemPath).writeAsBytes(certificateBytes);
  print('✔ Certificate PEM saved at: $pemPath');

  // 3️⃣ Convert PEM -> DER using OpenSSL
  final derPath = r'C:\openssl_keys\merchant.der';
  final opensslPath = r"C:\Program Files\OpenSSL-Win64\bin\openssl.exe";

  final result = Process.runSync(opensslPath, [
    'x509',
    '-in',
    pemPath,
    '-outform',
    'DER',
    '-out',
    derPath,
  ]);

  if (result.exitCode != 0) {
    print('❌ Failed to convert certificate to DER: ${result.stderr}');
    return;
  }

  print('✔ Certificate DER saved at: $derPath');

  // 4️⃣ Optional: read DER bytes and encode to Base64
  final derBytes = File(derPath).readAsBytesSync();
  final derBase64 = base64.encode(derBytes);
  print('✔ DER Base64 ready for sending: $derBase64');
}
