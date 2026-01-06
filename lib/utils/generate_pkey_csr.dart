import 'dart:convert';
import 'dart:io';

void generateKeyandCSR() {
  final keyPath = 'C:/openssl_keys/private_key.pem';
  final csrPath = 'C:/openssl_keys/csr.pem';
  final derKeyPath = 'C:/openssl_keys/merchant.der';
  final certpath = 'C:/openssl_keys/merchant.crt';
  // Make sure the folder exists
  Directory('C:/openssl_keys').createSync(recursive: true);

  final opensslPath = r"C:\Program Files\OpenSSL-Win64\bin\openssl.exe";

  // 1️⃣ Generate RSA private key
  final keyResult = Process.runSync(opensslPath, [
    'genpkey',
    '-algorithm',
    'RSA',
    '-out',
    keyPath,
    '-pkeyopt',
    'rsa_keygen_bits:2048',
  ]);

  if (keyResult.exitCode != 0) {
    print('Failed to generate private key: ${keyResult.stderr}');
    return;
  }
  print('✔ Private key generated at $keyPath');

  // 2️⃣ Generate CSR in PEM format
  final subj = '/C=SD/O=My Company Ltd/OU=IT/CN=merchant.mycompany.sd';
  final csrResult = Process.runSync(opensslPath, [
    'req',
    '-new',
    '-key',
    keyPath,
    '-out',
    csrPath,
    '-subj',
    subj,
    '-outform',
    'PEM', // <- this forces PEM format
  ]);

  if (csrResult.exitCode != 0) {
    print('Failed to generate CSR: ${csrResult.stderr}');
    return;
  }
  print('✔ CSR generated at $csrPath');
  /////////////////////////
  void convertPemToDer() {
    final certResult = Process.runSync(opensslPath, [
      'x509', // working with certificates
      '-in',
      certpath, // input PEM
      '-outform',
      'DER', // output DER
      '-out',
      derKeyPath, // output file
    ]);

    if (certResult.exitCode != 0) {
      print('Failed to convert certificate to DER: ${certResult.stderr}');
    } else {
      print('✔ Certificate converted to DER at $derKeyPath');
    }

    // Now read DER bytes and encode to Base64
    final certificateBytes = File(derKeyPath).readAsBytesSync();
    final certificateBase64 = base64.encode(certificateBytes);

    print('✔ Certificate Base64 ready for sending to server');
  }
}
