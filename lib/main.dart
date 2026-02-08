import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/app.dart';
import 'package:stc_client/managers/invoice_manager.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
import 'package:stc_client/providers/InvoiceProvider.dart';
import 'package:stc_client/utils/tools_paths.dart';
import 'managers/certificate_manager.dart';
import 'services/file_service.dart';
import 'services/network_service.dart';
import 'services/crypto_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final fileService = FileService();
  final networkService = NetworkService();
  final cryptoService = CryptoService();
  final manager = CertificateManager(
    fileService: fileService,
    networkService: networkService,
    cryptoService: cryptoService,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await ToolPaths.ensureToolsReady();
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
