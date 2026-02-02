import 'dart:convert';

String generateQr({
  required String sellerName,
  required String vatNumber,
  required DateTime issueDate,
  required double total,
  required double vatTotal,
}) {
  // Helper to encode TLV
  List<int> encodeTLV(int tag, String value) {
    List<int> bytes = utf8.encode(value);
    return [tag, bytes.length, ...bytes];
  }

  List<int> tlvBytes = [];
  tlvBytes.addAll(encodeTLV(1, sellerName));
  tlvBytes.addAll(encodeTLV(2, vatNumber));
  tlvBytes.addAll(encodeTLV(3, issueDate.toIso8601String()));
  tlvBytes.addAll(encodeTLV(4, total.toStringAsFixed(2)));
  tlvBytes.addAll(encodeTLV(5, vatTotal.toStringAsFixed(2)));

  // Base64 encode
  return base64.encode(tlvBytes);
}
