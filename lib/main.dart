import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stc_client/app.dart';
import 'package:stc_client/providers/CertificateProvider.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}
