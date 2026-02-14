import 'dart:io';
import 'dart:typed_data';
import 'package:stc_client/utils/paths/tools_paths.dart';
import '../utils/paths/app_paths.dart';

/// Service responsible for cryptographic operations like key and CSR generation, and file management
class CryptoService {
  final Future<String> csrPath = AppPaths.csrPath();
  final Future<String> keyPath = AppPaths.privateKeyPath();
  final Future<String> certPath = AppPaths.certPath();

  Future<File?> getCsrFile() async {
    final file = File(await csrPath);
    return await file.exists() ? file : null;
  }

  Future<File?> getPrivateKeyFile() async {
    final file = File(await keyPath);
    return await file.exists() ? file : null;
  }

  Future<File?> getCertFile() async {
    final file = File(await certPath);
    return await file.exists() ? file : null;
  }

  Future<String> readPrivateKey() async {
    final file = await getPrivateKeyFile();
    return file == null ? '' : await file.readAsString();
  }

  Future<Uint8List?> readCsr() async {
    final file = await getCsrFile();
    if (file == null || !await file.exists()) {
      return null;
    }
    return await file.readAsBytes();
  }

  Future<Uint8List?> readCertificate() async {
    final file = await getCertFile();
    if (file == null || !await file.exists()) {
      return null;
    }
    return await file.readAsBytes();
  }

  Future<void> generateKeyAndCsr(Map<String, String> subject) async {
    await ToolPaths.ensureToolsReady();
    await ToolPaths.verifyToolsExist();

    final opensslPath = ToolPaths.opensslPath;

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
      throw Exception('Failed to generate private key: ${keyResult.stderr}');
    }

    print('Private key generated');

    final subj =
        subject.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => '/${e.key}=${e.value}')
            .join();

    final csrResult = await Process.run(await opensslPath, [
      'req',
      '-new',
      '-key',
      await keyPath,
      '-out',
      await csrPath,
      '-subj',
      subj.isEmpty
          ? '/C=SD/ST=Khartoum/L=Khartoum/O=Organization/CN=My.Company.com/serialNumber=5003'
          : subj,
      '-outform',
      'DER',
    ]);

    if (csrResult.exitCode != 0) {
      throw Exception('Failed to generate CSR: ${csrResult.stderr}');
    }

    print('CSR generated');
  }

  static String normalizeCsr(String csr) {
    return csr.replaceAll('\r\n', '\n').replaceAll('\\n', '\n').trim();
  }
}
