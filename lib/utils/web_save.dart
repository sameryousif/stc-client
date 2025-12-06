import 'dart:html' as html;

void saveXmlWeb(String xmlContent, String fileName) {
  final bytes = html.Blob([xmlContent], 'text/xml');

  final url = html.Url.createObjectUrlFromBlob(bytes);

  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

  html.Url.revokeObjectUrl(url);
}
