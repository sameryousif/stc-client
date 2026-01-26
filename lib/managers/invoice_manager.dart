import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:stc_client/models/invoice_item.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/utils/ubl_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../utils/constants.dart';

class InvoiceManager {
  static const String workingDir = r"C:\Users\sam\stc_client";
  static const String inputXmlPath = r"C:\Users\sam\stc_client\input.xml";
  static const String outputXmlPath = r"C:\Users\sam\stc_client\output.xml";

  Future<XmlDocument> generateUnsignedInvoice({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    final uuid = const Uuid().v4();
    final now = DateTime.now();

    final xmlString = generateUBLInvoice(
      invoiceNumber: invoiceNumber,
      uuid: uuid,
      issueDate: now.toIso8601String().split('T')[0],
      issueTime: now.toIso8601String().split('T')[1].split('.').first,
      icv: 1,
      previousInvoiceHash: base64.encode(List.filled(32, 0)),
      supplierName: supplierInfo['name']!,
      supplierVAT: supplierInfo['vat']!,
      customerName: customerInfo['name']!,
      customerVAT: customerInfo['vat']!,
      items: items,
    );

    return XmlDocument.parse(xmlString);
  }

  Future<void> writeXml(String path, String xmlContent) async {
    final dir = Directory(workingDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(path).writeAsString(xmlContent);
  }

  Future<void> runCanonicalizationCli(
    String inputPath,
    String outputPath,
  ) async {
    final result = await Process.run(
      Constants.cliToolPath,
      [inputPath, outputPath],
      workingDirectory: workingDir,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Canonicalization failed\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}',
      );
    }
  }

  Future<String> computeHashBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  Future<String> signXml(String xmlPath) async {
    final signaturePath = xmlPath.replaceAll('.xml', '.sig');
    final result = await Process.run(Constants.opensslPath, [
      'dgst',
      '-sha256',
      '-sign',
      Constants.privateKeyPath,
      '-out',
      signaturePath,
      xmlPath,
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to sign XML: ${result.stderr}');
    }
    return signaturePath;
  }

  Future<XmlDocument> injectXadesSignature({
    required XmlDocument invoice,
    required String certificatePath,
  }) async {
    /// hash of the canonicalized unsigned invoice
    final invoiceHashBase64 = await computeHashBase64(outputXmlPath);

    //// SignedProperties
    final signedProperties = XmlDocument.parse(
      '<SignedProperties Id="xadesSignedProperties"/>',
    );

    final tempPropsPath = '$workingDir/signed_props.xml';
    await File(
      tempPropsPath,
    ).writeAsString(signedProperties.toXmlString(pretty: false));
    await runCanonicalizationCli(tempPropsPath, tempPropsPath);

    //final canonicalSignedPropsXml = await File(tempPropsPath).readAsString();

    final signedPropertiesHashBase64 = await computeHashBase64(tempPropsPath);

    final signedInfo = buildSignedInfo(
      invoiceHashBase64: invoiceHashBase64,
      signedPropertiesHashBase64: signedPropertiesHashBase64,
    );

    // save SignedInfo
    final signedInfoPath = '$workingDir/signedInfo.xml';
    await File(
      signedInfoPath,
    ).writeAsString(signedInfo.toXmlString(pretty: false));

    ////  Canonicalize SignedInfo
    await runCanonicalizationCli(signedInfoPath, signedInfoPath);

    //// Read the canonical SignedInfo
    final canonicalSignedInfoXml = await File(signedInfoPath).readAsString();

    final canonicalSignedInfo = XmlDocument.parse(canonicalSignedInfoXml);

    //  Sign the canonical SignedInfo
    final signaturePath = await signXml(signedInfoPath);
    final signatureBytes = await File(signaturePath).readAsBytes();
    final signatureBase64 = base64.encode(signatureBytes);

    // Read certificate and encode in Base64
    final certBytes = await File(certificatePath).readAsBytes();
    final certificateBase64 = base64.encode(certBytes);

    //  Build final XAdES signature USING CANONICAL SignedInfo
    final xadesSignature = buildXadesSignature(
      signedInfo: canonicalSignedInfo,
      signatureValueBase64: signatureBase64,
      certificateBase64: certificateBase64,
      signedProperties: signedProperties,
    );

    //  Inject into invoice
    return injectSignature(invoice: invoice, signature: xadesSignature);
  }

  Future<Map<String, String>> generateSignAndSubmitInvoice({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    final invoice = await generateUnsignedInvoice(
      invoiceNumber: invoiceNumber,
      items: items,
      supplierInfo: supplierInfo,
      customerInfo: customerInfo,
    );

    /// write invoice to input.xml
    await writeXml(inputXmlPath, invoice.toXmlString(pretty: false));

    // Canonicalize unsigned XML using cli tool
    await runCanonicalizationCli(inputXmlPath, outputXmlPath);
    final unsignedInvoiceHash = await computeHashBase64(outputXmlPath);

    //  Inject XAdES signature
    final signedInvoice = await injectXadesSignature(
      invoice: invoice,
      certificatePath: Constants.certPath,
    );

    // Save signed invoice
    final signedPath = '${Constants.invoicesDir}/invoice_$invoiceNumber.xml';
    await writeXml(signedPath, signedInvoice.toXmlString(pretty: false));

    final dto = {
      "uuid": const Uuid().v4(),
      "invoice_hash": unsignedInvoiceHash,
      "invoice": base64.encode(
        signedInvoice.toXmlString(pretty: false).codeUnits,
      ),
    };
    // print(signedInvoice.toXmlString(pretty: true));
    await ApiService.sendToServerDto(dto);

    return dto;
  }

  Future<Response?> sendInvoice(Map<String, String> dto) async {
    return await ApiService.sendToServerDto(dto);
  }
}
