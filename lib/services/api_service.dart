import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

//// Service responsible for handling all API interactions, including invoice submission and certificate enrollment
class ApiService {
  ApiService._();

  /// Test-only: allows injecting a mock Dio instance
  @visibleForTesting
  static Dio get dio => _dio;
  @visibleForTesting
  static set dio(Dio value) => _dio = value;

  static Dio _dio = Dio(
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
          if (kDebugMode) {
            print(' REQUEST :${options.method} ${options.uri}');
            print('HEADERS: ${options.headers}');
            print('BODY: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(' RESPONSE : ${response.statusCode}');
            print('BODY: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('DIO ERROR');
            print('STATUS: ${error.response?.statusCode}');
            print('BODY: ${error.response?.data}');
            print('MESSAGE: ${error.message}');
          }
          handler.next(error);
        },
      ),
    );

  ///endpoints
  static const String _baserUrl = 'https://stc-server.onrender.com';
  static const String _clearanceUrl = '$_baserUrl/clear';
  static const String _reportingUrl = '$_baserUrl/report';

  static const String _enrollCsrUrl = '$_baserUrl/enroll';

  ///////////////////////////
  ///
  static Future<Response?> sendClear(
    Map<String, dynamic> dto, {
    bool isSandbox = false,
  }) async {
    try {
      return await _dio.post(
        _clearanceUrl,
        data: dto,
        options:
            isSandbox ? Options(headers: {"X-Sandbox-Mode": "true"}) : null,
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  /// ============================
  /// REPORT
  /// ============================
  static Future<Response?> sendReport(
    Map<String, dynamic> dto, {
    bool isSandbox = false,
  }) async {
    try {
      return await _dio.post(
        _reportingUrl,
        data: dto,
        options:
            isSandbox ? Options(headers: {"X-Sandbox-Mode": "true"}) : null,
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  /// send CSR and get certificate
  static Future<String?> sendCsr({
    required File csrFile,
    required String token,
  }) async {
    late String csrBase64;

    final bytes = await csrFile.readAsBytes();
    csrBase64 = base64Encode(bytes);
    final response = await _dio.post(
      _enrollCsrUrl,
      data: {'csr': csrBase64, 'token': token},
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid response format: $data');
    }

    final body = Map<String, dynamic>.from(data);
    final innerData = body['data'];

    if (innerData == null || innerData is! Map) {
      throw Exception('Missing "data" field in response');
    }

    final certificate = innerData['certificate'];

    if (certificate == null || certificate.toString().isEmpty) {
      throw Exception('Certificate not found in response');
    }

    return certificate.toString();
  }

  static Future<Response?> sendCsrSandbox({required String csr}) async {
    try {
      return await _dio.post(_enrollCsrUrl, data: csr);
    } on DioException catch (e) {
      return e.response;
    }
  }

}
