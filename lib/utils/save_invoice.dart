import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'web_save.dart';

Future<void> saveInvoiceXml(String xml, String fileName) async {
  // 1️⃣ WEB → download automatically
  if (kIsWeb) {
    saveXmlWeb(xml, fileName);
    return;
  }

  // 2️⃣ ANDROID / IOS → Save using path_provider
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);

  await file.writeAsString(xml);

  print("Saved XML at: $filePath");
}
