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
  BytesBuilder builder = BytesBuilder();

  // Helper to add TLV field with proper length encoding
  void addTLV(int tag, List<int> value) {
    builder.addByte(tag);

    final length = value.length;

    if (length < 128) {
      // short form: 1 byte
      builder.addByte(length);
    } else if (length < 256) {
      // long form, 1 byte length indicator + 1 byte length
      builder.addByte(0x81);
      builder.addByte(length);
    } else if (length < 65536) {
      // long form, 1 byte length indicator + 2 byte length
      builder.addByte(0x82);
      builder.addByte((length >> 8) & 0xFF);
      builder.addByte(length & 0xFF);
    } else {
      throw Exception("Value too large for TLV encoding");
    }

    builder.add(value);
  }

  addTLV(1, utf8.encode(sellerName));
  addTLV(2, utf8.encode(vatNumber));
  addTLV(3, utf8.encode(issueDate.toIso8601String()));
  addTLV(4, utf8.encode(total.toStringAsFixed(2)));
  addTLV(5, utf8.encode(vatTotal.toStringAsFixed(2)));
  addTLV(6, utf8.encode(xmlHash));
  addTLV(7, signature);
  addTLV(8, certificate);

  return base64Encode(builder.toBytes());
}
