import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:stc_client/utils/paths/app_paths.dart';

//// Service responsible for handling all API interactions, including invoice submission and certificate enrollment
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
          print('DIO ERROR');
          print('STATUS: ${error.response?.statusCode}');
          print('BODY: ${error.response?.data}');
          print('MESSAGE: ${error.message}');
          handler.next(error);
        },
      ),
    );

  ///endpoints
  static const String _baserUrl = 'https://stc-server.onrender.com';
  static const String _clearanceUrl = '$_baserUrl/clear';
  static const String _reportingUrl = '$_baserUrl/reporting';

  static const String _enrollCsrUrl = '$_baserUrl/enroll';
  // static const String _qrUrl = '$_baserUrl/verify_qr';

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
  //////////////////////

  /// send CSR and get certificate
  static Future<String?> sendCsr({
    required File csrFile,
    required String token,
    // required bool sandbox,
  }) async {
    late String csrBase64;

    /*if (csrFile.path.endsWith('.der')) {
     
    }*/
    /* else {
      final text = await csrFile.readAsString();
      csrBase64 = text
          .replaceAll('-----BEGIN CERTIFICATE REQUEST-----', '')
          .replaceAll('-----END CERTIFICATE REQUEST-----', '')
          .replaceAll(RegExp(r'\s+'), '');
    }*/
    final bytes = await csrFile.readAsBytes();
    csrBase64 = base64Encode(bytes);
    final response = await _dio.post(
      _enrollCsrUrl,
      data: {'csr': csrBase64, 'token': token},
    );

    final statusCode = response.statusCode ?? 0;
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

    /*  if (!sandbox) {
      final certBytes = base64Decode(
        certificate
            .replaceAll('-----BEGIN CERTIFICATE-----', '')
            .replaceAll('-----END CERTIFICATE-----', '')
            .replaceAll(RegExp(r'\s+'), ''),
      );

      final path = await AppPaths.certPath();
      await File(path).writeAsBytes(certBytes, flush: true);

      return certificate.toString();
    }*/
    return certificate.toString();
    //return "Response code: $statusCode\nBody:\n${const JsonEncoder.withIndent('  ').convert(body)}";
  }

  static Future<Response?> sendCsrSandbox({required String csr}) async {
    try {
      return await _dio.post(_enrollCsrUrl, data: csr);
    } on DioException catch (e) {
      return e.response;
    }
  }

  /* static Future<void> sendQr({required String qrbase64}) async {
    final response = await _dio.post(_qrUrl, data: {'qr_b64': qrbase64});

    if (response.statusCode != 200) {
      throw Exception(
        'qr not valid (${response.statusCode}): ${response.data}',
      );
    } else {
      print("valid");
    }
  }*/
}
