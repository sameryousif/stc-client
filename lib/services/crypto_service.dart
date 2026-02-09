import 'dart:io';
import 'package:stc_client/utils/tools_paths.dart';
import '../utils/app_paths.dart';

class CryptoService {
  final Future<String> csrPath = AppPaths.csrPath();
  final Future<String> keyPath = AppPaths.privateKeyPath();

  Future<File> getCsrFile() async {
    final csrFile = File(await csrPath);
    if (!await csrFile.exists()) {
      await generateKeyAndCsr({});
    }

    return csrFile;
  }

  Future<File> getPrivateKeyFile() async {
    final keyFile = File(await keyPath);

    if (!await keyFile.exists()) {
      await generateKeyAndCsr({});
    }

    return keyFile;
  }

  Future<String> readPrivateKey() async {
    final file = await getPrivateKeyFile();
    return file.readAsString();
  }

  Future<String> readCsr() async {
    final file = await getCsrFile();
    return file.readAsString();
  }

  Future<String> readCertificate() async {
    final certFile = File(await AppPaths.certPath());
    if (!await certFile.exists()) return '';
    return certFile.readAsString();
  }

  Future<void> generateKeyAndCsr(Map<String, String> subject) async {
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

    final subj = subject.entries.map((e) => '/${e.key}=${e.value}').join();

    final csrResult = await Process.run(await opensslPath, [
      'req',
      '-new',
      '-key',
      await keyPath,
      '-out',
      await csrPath,
      '-subj',
      subj.isEmpty
          ? '/C=SD/ST=Khartoum/L=Khartoum/O=Organization/CN=My.Company.com/serialNumber=12345'
          : subj,
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
