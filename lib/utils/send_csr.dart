import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stc_client/utils/save_cert.dart';

Future<void> sendCsrAndSaveCert(File csrFile) async {
  final dio = Dio();

  final csrText = await csrFile.readAsString();
  /////////remove encoding
  // final csrBase64 = base64.encode(utf8.encode(csrText));

  try {
    final response = await dio.post(
      'https://stc-server.onrender.com/enroll',
      data: {'csr': csrText},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    print('CSR sent successfully');
    print('STC response: ${response.data}');

    // Save certificate
    final certificateContent = response.data['certificate'];
    await saveCertificateAsPem(certificateContent);
  } on DioException catch (e) {
    print('Failed to send CSR: ${e.response?.data ?? e.message}');
  }
}
