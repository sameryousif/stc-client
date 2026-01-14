import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/src/response.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../models/invoice_item.dart';
import '../utils/ubl_generator.dart';

class InvoiceManager {
  Future<String> generateInvoiceXml({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    final uuid = const Uuid().v4();
    final now = DateTime.now();
    final issueDate = now.toIso8601String().split("T")[0];
    final issueTime = now.toIso8601String().split("T")[1].split(".")[0];

    final xml = generateUBLInvoice(
      invoiceNumber: invoiceNumber,
      uuid: uuid,
      issueDate: issueDate,
      issueTime: issueTime,
      icv: 1,
      previousInvoiceHash: base64.encode(List.filled(32, 0)),
      supplierName: supplierInfo['name']!,
      supplierVAT: supplierInfo['vat']!,
      customerName: customerInfo['name']!,
      customerVAT: customerInfo['vat']!,
      items: items,
    );

    return xml;
  }

  Future<String> saveInvoiceXml(String xml, String invoiceNumber) async {
    final directory = await Directory(
      Constants.invoicesDir,
    ).create(recursive: true);
    final path = '${directory.path}/invoice_$invoiceNumber.xml';
    final file = File(path);
    await file.writeAsString(xml);
    return path;
  }

  Future<String> signInvoice(String invoicePath) async {
    final signaturePath = invoicePath.replaceAll('.xml', '.sig');
    final result = await Process.run(Constants.opensslPath, [
      'dgst',
      '-sha256',
      '-sign',
      Constants.privateKeyPath,
      '-out',
      signaturePath,
      invoicePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to sign invoice: ${result.stderr}');
    }

    return signaturePath;
  }

  Future<Map<String, String>> prepareInvoiceSubmission({
    required String xmlPath,
    required String signaturePath,
    required String certificatePath,
  }) async {
    final xml = await File(xmlPath).readAsString();
    final xmlBytes = await File(xmlPath).readAsBytes();
    final hash = sha256.convert(xmlBytes);

    final signatureBytes = await File(signaturePath).readAsBytes();
    final signatureBase64 = base64.encode(signatureBytes);

    final certificateString = await File(certificatePath).readAsString();
    final xmlBase64 = base64.encode(utf8.encode(xml));

    return {
      "invoice_base64": xmlBase64,
      "invoice_hash": hash.toString(),
      "signature_base64": signatureBase64,
      "certificate": certificateString,
    };
  }

  Future<Response?> sendInvoice(Map<String, String> dto) async {
    return await ApiService.sendToServerDto(dto);
  }
}
