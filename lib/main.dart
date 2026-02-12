import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/app.dart';
import 'package:stc_client/services/invoicePrepService.dart';
import 'package:stc_client/state/providers/CertificateProvider.dart';
import 'package:stc_client/state/providers/InvoiceProvider.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';
import 'services/certificateEnrollService.dart';
import 'services/file_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await ToolPaths.ensureToolsReady();
  final fileService = FileService();
  final certEnrollService = CertEnrollService(fileService: fileService);
  final invoicePrepService = InvoicePrepService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => CertificateProvider(certEnrollService: certEnrollService),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(prepService: invoicePrepService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
