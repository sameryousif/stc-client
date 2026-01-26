import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/app.dart';
import 'package:stc_client/managers/invoice_manager.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';
import 'managers/certificate_manager.dart';
import 'services/file_service.dart';
import 'services/network_service.dart';
import 'services/crypto_service.dart';

void main() {
  final fileService = FileService();
  final networkService = NetworkService();
  final cryptoService = CryptoService();
  final manager = CertificateManager(
    fileService: fileService,
    networkService: networkService,
    cryptoService: cryptoService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CertificateProvider(manager: manager),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(manager: InvoiceManager()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
/*import 'dart:io';
import 'package:xml/xml.dart';


Future<void> main() async {
  // 1️⃣ Read input.xml
  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    print('Error: input.xml not found');
    return;
  }
  final xmlString = await inputFile.readAsString();

  // 2️⃣ Canonicalize manually
  final canonicalXml = canonicalizeXml(xmlString);

  // 3️⃣ Save canonical XML to a temp file
  final canonicalFile = File(canonicalPath);
  await canonicalFile.writeAsString(canonicalXml);

  print('Canonical XML saved to: $canonicalPath');

  // 4️⃣ Run your CLI tool (it will read input.xml and generate output.xml)
  final result = await Process.run(
    cliToolPath,
    [],
    workingDirectory: workingDir,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    print('CLI failed:\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}');
    return;
  }

  final outputFile = File(outputPath);
  if (!await outputFile.exists()) {
    print('Error: output.xml was not generated');
    return;
  }

  print('CLI ran successfully, output.xml exists at: $outputPath');
}
*/