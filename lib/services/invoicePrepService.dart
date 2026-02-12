import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:stc_client/core/invoice/invoice_item.dart';
import 'package:stc_client/services/api_service.dart';
import 'package:stc_client/services/invoice_processing_service.dart';
import 'package:stc_client/core/certificate/cert_info.dart';
import 'package:stc_client/core/qr/qr_genrator.dart';
import 'package:stc_client/utils/paths/tools_paths.dart';
import 'package:stc_client/core/invoice/xml_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../utils/paths/app_paths.dart';

/// Service responsible for preparing invoices, including generating unsigned invoices, canonicalization, signing, and XAdES signature injection
class InvoicePrepService {
  static Future<Directory> get workingDir => AppPaths.workingDir();
  static Future<String> get inputXmlPath => AppPaths.inputXmlPath();
  static Future<String> get outputXmlPath => AppPaths.outputXmlPath();

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
      icv: (await DBService().getLastInvoiceID() ?? 0) + 1,
      previousInvoiceHash: await DBService().getLastInvoiceHash() ?? 'first',
      supplierName: supplierInfo['name']!,
      supplierVAT: supplierInfo['vat']!,
      customerName: customerInfo['name']!,
      customerVAT: customerInfo['vat']!,
      items: items,
    );

    return XmlDocument.parse(xmlString);
  }

  Future<void> writeXml(String path, String xmlContent) async {
    final dir = await workingDir;
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(path).writeAsString(xmlContent);
  }

  Future<void> runCanonicalizationCli(
    String inputPath,
    String outputPath,
  ) async {
    final dir = await workingDir;
    await ToolPaths.ensureToolsReady(); // copy assets if missing
    await ToolPaths.verifyToolsExist(); // confirm they exist
    final result = await Process.run(
      await ToolPaths.cliToolPath,
      [inputPath, outputPath],
      workingDirectory: dir.path,
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
    final result = await Process.run(await ToolPaths.opensslPath, [
      'dgst',
      '-sha256',
      '-sign',
      await AppPaths.privateKeyPath(),
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
    final invoiceHashBase64 = await computeHashBase64(await outputXmlPath);

    //////extract cert info
    final certInfo = await extractCertDetails(
      opensslPath: await ToolPaths.opensslPath,
      certPath: certificatePath,
    );
    ///////generate signing time
    String generateSigningTimeUtc() =>
        '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

    //// SignedProperties
    final signedProperties = buildSignedProperties(
      signatureId: "signature",
      signingTime: generateSigningTimeUtc(),
      certDigestBase64: await computeHashBase64(certificatePath),
      issuerName: certInfo.issuerName,
      serialNumber: certInfo.serialNumberDecimal,
    );

    // final dir = await workingDir;
    final tempPropsPath = await AppPaths.signedPropsPath();
    await File(
      tempPropsPath,
    ).writeAsString(signedProperties.toXmlString(pretty: true));
    await runCanonicalizationCli(tempPropsPath, tempPropsPath);

    //final canonicalSignedPropsXml = await File(tempPropsPath).readAsString();

    final signedPropertiesHashBase64 = await computeHashBase64(tempPropsPath);

    final signedInfo = buildSignedInfo(
      invoiceHashBase64: invoiceHashBase64,
      signedPropertiesHashBase64: signedPropertiesHashBase64,
    );

    // save SignedInfo
    final signedInfoPath = await AppPaths.signedInfoPath();
    await File(
      signedInfoPath,
    ).writeAsString(signedInfo.toXmlString(pretty: true));

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
    // print(certificateBase64);
    //  Build final XAdES signature USING CANONICAL SignedInfo
    final xadesSignature = buildXadesSignature(
      signedInfo: XmlDocument.parse(
        canonicalSignedInfo.toXmlString(pretty: true),
      ),
      signatureValueBase64: signatureBase64,
      certificateBase64: certificateBase64,
      signedProperties: signedProperties,
    );

    return injectSignature(invoice: invoice, signature: xadesSignature);
  }

  Future<String> generateAndSignInvoice({
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required Map<String, String> supplierInfo,
    required Map<String, String> customerInfo,
  }) async {
    /// Generate unsigned invoice
    final invoice = await generateUnsignedInvoice(
      invoiceNumber: invoiceNumber,
      items: items,
      supplierInfo: supplierInfo,
      customerInfo: customerInfo,
    );

    /// Save invoice to input.xml
    await writeXml(await inputXmlPath, invoice.toXmlString(pretty: true));

    /// Canonicalize
    await runCanonicalizationCli(await inputXmlPath, await outputXmlPath);
    //final unsignedInvoiceHash = await computeHashBase64(await outputXmlPath);

    /// Inject signature
    final signedInvoice = await injectXadesSignature(
      invoice: invoice,
      certificatePath: await AppPaths.certPath(),
    );

    /// Save signed XML locally
    final signedPath =
        '${await AppPaths.invoicesDir()}/invoice_$invoiceNumber.xml';
    await writeXml(signedPath, signedInvoice.toXmlString(pretty: false));

    // Add QR code to the signed XML
    await addQrToInvoice(
      signedInvoicePath: signedPath,
      qrBase64: generateQr(
        sellerName: supplierInfo['name']!,
        vatNumber: supplierInfo['vat']!,
        issueDate: DateTime.now(),
        total: items.fold(
          0.0,
          (previousValue, item) =>
              previousValue + (item.quantity * item.unitPrice),
        ),
        vatTotal: items.fold(
          0.0,
          (previousValue, item) =>
              previousValue +
              (item.quantity * item.unitPrice * item.taxRate / 100),
        ),
      ),
    );

    return signedPath;
  }

  Future<Map<String, String>> sendSignedInvoice({
    required String xmlContent,
    required uuid,
  }) async {
    final dto = {
      "uuid": uuid.toString(),
      "invoice_hash": await computeHashBase64(await outputXmlPath),
      "invoice": base64.encode(utf8.encode(xmlContent)),
    };
    return dto;
  }

  Future<Response?> sendInvoice(Map<String, String> dto) async {
    return await ApiService.sendInvoiceDto(dto);
  }
}
