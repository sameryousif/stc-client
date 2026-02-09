import 'dart:io';
import 'package:dio/dio.dart';

class NetworkService {
  final Dio dio = Dio();
  final String apiUrl = 'https://stc-server.onrender.com/enroll';

  /// Sends CSR to STC server and returns the certificate content
  Future<String> sendCsr(File csrFile, String token) async {
    final csrText = await csrFile.readAsString();

    try {
      final response = await dio.post(
        apiUrl,
        data: {'csr': csrText, 'token': token},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('CSR sent successfully');
      return response.data['certificate'];
    } on DioException catch (e) {
      print('Failed to send CSR: ${e.response?.data ?? e.message}');
      print('csr: $csrText, token: $token');
      rethrow; // so manager can handle it if needed
    }
  }
}
