import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio();

  /// Sends the XML invoice to the STC server
  static Future<Response?> sendToServer(String xmlInvoice) async {
    final url = "https://stc-server.onrender.com/submit_invoice";

    try {
      final response = await _dio.post(
        url,
        data: xmlInvoice,
        options: Options(headers: {"Content-Type": "application/xml"}),
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
