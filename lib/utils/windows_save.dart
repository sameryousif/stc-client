import 'dart:io';

void saveXmlWindows(String xmlContent, String fileName) {
  final file = File(fileName);
  file.writeAsStringSync(xmlContent);
}
