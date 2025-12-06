import 'package:http/http.dart' as http;

class ApiService {
  static Future<void> sendToServer(String xmlInvoice) async {
    final url = Uri.parse("https://stc-server.onrender.com/submit_invoice");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/xml"},
      body: xmlInvoice,
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");
  }
}
