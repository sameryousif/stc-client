import 'dart:convert';
import 'dart:typed_data';

String generateQr({
  required String sellerName,
  required String vatNumber,
  required DateTime issueDate,
  required double total,
  required double vatTotal,
  required String xmlHash,
  required Uint8List signature,
  required Uint8List certificate,
}) {
  List<int> encodeTLVBytes(int tag, Uint8List valueBytes) {
    final length = valueBytes.length;
    Uint8List lengthBytes = Uint8List(2);
    ByteData.view(lengthBytes.buffer).setUint16(0, length, Endian.big);

    return [tag, ...lengthBytes, ...valueBytes];
  }

  List<int> encodeTLVText(int tag, String value) {
    final valueBytes = utf8.encode(value);
    return encodeTLVBytes(tag, Uint8List.fromList(valueBytes));
  }

  List<int> tlvBytes = [];

  tlvBytes.addAll(encodeTLVText(1, sellerName));
  tlvBytes.addAll(encodeTLVText(2, vatNumber));
  tlvBytes.addAll(encodeTLVText(3, issueDate.toIso8601String()));
  tlvBytes.addAll(encodeTLVText(4, total.toStringAsFixed(2)));
  tlvBytes.addAll(encodeTLVText(5, vatTotal.toStringAsFixed(2)));
  tlvBytes.addAll(encodeTLVText(6, xmlHash));

  tlvBytes.addAll(encodeTLVBytes(7, signature));
  tlvBytes.addAll(encodeTLVBytes(8, certificate));

  return base64Encode(tlvBytes);
}
