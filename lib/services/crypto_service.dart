import 'dart:io';
import 'package:stc_client/utils/tools_paths.dart';

import '../utils/app_paths.dart';

class CryptoService {
  final Future<String> csrPath = AppPaths.csrPath();
  final Future<String> keyPath = AppPaths.privateKeyPath();

  /// Returns the CSR file
  Future<File> getCsrFile() async {
    final csrFile = File(await csrPath);

    // If CSR doesn't exist, generate key and CSR first
    if (!await csrFile.exists()) {
      await generateKeyAndCsr();
    }

    return csrFile;
  }

  /// Generates RSA private key and CSR using OpenSSL
  Future<void> generateKeyAndCsr() async {
    // Ensure the folder exists
    // Directory('../openssl_keys').createSync(recursive: true);

    final opensslPath = ToolPaths.opensslPath;

    // Generate RSA private key
    final keyResult = await Process.run(await opensslPath, [
      'genpkey',
      '-algorithm',
      'RSA',
      '-out',
      await keyPath,
      '-pkeyopt',
      'rsa_keygen_bits:2048',
    ]);

    if (keyResult.exitCode != 0) {
      print('❌ Failed to generate private key: ${keyResult.stderr}');
      return;
    }
    print('✔ Private key generated at $keyPath');

    // Generate CSR in PEM format
    final subj = '/C=SD/O=My Company Ltd/OU=IT/CN=merchant.mycompany.sd';
    final csrResult = await Process.run(await opensslPath, [
      'req',
      '-new',
      '-key',
      await keyPath,
      '-out',
      await csrPath,
      '-subj',
      subj,
      '-outform',
      'PEM',
    ]);

    if (csrResult.exitCode != 0) {
      print('❌ Failed to generate CSR: ${csrResult.stderr}');
      return;
    }
    print('✔ CSR generated at $csrPath');
  }
}
