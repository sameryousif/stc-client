import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveInvoiceXml(String xml, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}\\$fileName';
  final file = File(filePath);

  await file.writeAsString(xml);

  print('Saved XML at: $filePath');
}
