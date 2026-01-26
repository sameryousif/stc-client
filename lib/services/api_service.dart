import 'package:dio/dio.dart';
import 'dart:convert';

class ApiService {
  static final Dio _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),

        //  allow Dio to return 4xx / 5xx responses **otherwise it throws exceptions
        validateStatus: (status) => status != null && status < 600,

        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )
    // Interceptor to see everything
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print(' REQUEST ${options.method} ${options.uri}');
          print(' HEADERS: ${options.headers}');
          print(' BODY: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(' RESPONSE STATUS: ${response.statusCode}');
          print(' RESPONSE BODY: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ DIO ERROR');
          print('❌ STATUS: ${error.response?.statusCode}');
          print('❌ BODY: ${error.response?.data}');
          print('❌ MESSAGE: ${error.message}');
          handler.next(error);
        },
      ),
    );

  /// Sends the invoice DTO to the STC server
  static Future<Response?> sendToServerDto(Map<String, String> dto) async {
    const url = "https://stc-server.onrender.com/submit_invoice";

    try {
      final response = await _dio.post(url, data: jsonEncode(dto));

      return response;
    } on DioException catch (e) {
      // This will only trigger on connection / timeout / TLS errors
      print('❌ NETWORK / DIO EXCEPTION');
      print('❌ STATUS: ${e.response?.statusCode}');
      print('❌ BODY: ${e.response?.data}');
      print('❌ MESSAGE: ${e.message}');
      return e.response;
    } catch (e) {
      print('❌ UNKNOWN ERROR: $e');
      return null;
    }
  }
}
