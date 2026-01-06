import 'package:dio/dio.dart';
import 'dart:convert';

class ApiService {
  static final Dio _dio = Dio();

  /// Sends the invoice DTO to the STC server
  static Future<Response?> sendToServerDto(Map<String, String> dto) async {
    final url = "https://stc-server.onrender.com/submit_invoice";

    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(dto), // send as JSON
        options: Options(
          headers: {
            "Content-Type": "application/json", // now JSON
          },
        ),
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.data}");

      return response; // Return response for further handling
    } catch (e) {
      print("Error sending invoice: $e");
      return null;
    }
  }
}
