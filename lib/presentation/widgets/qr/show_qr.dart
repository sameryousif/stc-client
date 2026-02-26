import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQr extends StatelessWidget {
  const ShowQr({super.key,required this.qrBase64});

  final String qrBase64;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: QrImageView(
          data: qrBase64,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
}