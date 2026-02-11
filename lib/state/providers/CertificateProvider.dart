import 'package:flutter/material.dart';
import '../../services/certificateEnrollService.dart';

class CertificateProvider extends ChangeNotifier {
  final CertEnrollservice certEnrollService;

  bool _isCertificateValid = false;
  bool get isCertificateValid => _isCertificateValid;

  CertificateProvider({required this.certEnrollService});

  Future<void> checkCertificate() async {
    _isCertificateValid = await certEnrollService.isCertificateValid();
    notifyListeners();
  }

  Future<void> enrollCertificate(String token) async {
    await certEnrollService.enrollCertificate(token);
    await checkCertificate();
  }
}
