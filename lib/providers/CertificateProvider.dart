import 'package:flutter/material.dart';
import '../managers/certificate_manager.dart';

class CertificateProvider extends ChangeNotifier {
  final CertificateManager manager;

  bool _isCertificateValid = false;
  bool get isCertificateValid => _isCertificateValid;

  CertificateProvider({required this.manager});

  Future<void> checkCertificate() async {
    _isCertificateValid = await manager.isCertificateValid();
    notifyListeners();
  }

  Future<void> enrollCertificate() async {
    await manager.enrollCertificate();
    await checkCertificate();
  }
}
