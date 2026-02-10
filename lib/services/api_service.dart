import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  ApiService._();

  static final Dio _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(' REQUEST :${options.method} ${options.uri}');
          print('HEADERS: ${options.headers}');
          print('BODY: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(' RESPONSE : ${response.statusCode}');
          print('BODY: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ DIO ERROR');
          print('STATUS: ${error.response?.statusCode}');
          print('BODY: ${error.response?.data}');
          print('MESSAGE: ${error.message}');
          handler.next(error);
        },
      ),
    );

  ///endpoints
  static const String _submitInvoiceUrl =
      'https://stc-server.onrender.com/submit_invoice';

  static const String _enrollCsrUrl = 'https://stc-server.onrender.com/enroll';

  ///send invoice DTO to server and return response
  static Future<Response?> sendInvoiceDto(Map<String, String> dto) async {
    try {
      final response = await _dio.post(
        _submitInvoiceUrl,
        data: jsonEncode(dto),
      );
      return response;
    } on DioException catch (e) {
      print(' NETWORK / DIO EXCEPTION');
      return e.response;
    } catch (e) {
      print(' UNKNOWN ERROR: $e');
      return null;
    }
  }

  /// send CSR and get certificate
  static Future<String> sendCsr({
    required File csrFile,
    required String token,
  }) async {
    final csr = await csrFile.readAsBytes();
    final response = await _dio.post(
      _enrollCsrUrl,
      data: {'csr': base64.encode(csr), 'token': token},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'CSR enrollment failed (${response.statusCode}): ${response.data}',
      );
    }

    if (response.data is! Map) {
      throw Exception('Invalid response format: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;

    if (!data.containsKey('certificate')) {
      throw Exception('Certificate not found in response');
    }

    return data['certificate'] as String;
  }
}
