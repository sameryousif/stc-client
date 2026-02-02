import 'dart:io';

class CertInfo {
  final String issuerName;
  final String serialNumberDecimal;

  CertInfo({required this.issuerName, required this.serialNumberDecimal});
}

//extract issuer name and serial number (decimal) from cert
Future<CertInfo> extractIssuerAndSerialFromCert({
  required String opensslPath,
  required String certPath,
}) async {
  // issuer
  final issuerRes = await Process.run(opensslPath, [
    "x509",
    "-in",
    certPath,
    "-noout",
    "-issuer",
  ]);

  if (issuerRes.exitCode != 0) {
    throw Exception("OpenSSL issuer failed: ${issuerRes.stderr}");
  }

  // serial (hex)
  final serialRes = await Process.run(opensslPath, [
    "x509",
    "-in",
    certPath,
    "-noout",
    "-serial",
  ]);

  if (serialRes.exitCode != 0) {
    throw Exception("OpenSSL serial failed: ${serialRes.stderr}");
  }

  // issuer output example:
  String issuer = issuerRes.stdout.toString().trim();
  issuer = issuer.replaceFirst("issuer=", "").trim();

  // serial output example:
  String serialHex = serialRes.stdout.toString().trim();
  serialHex = serialHex.replaceFirst("serial=", "").trim();

  // Convert HEX -> Decimal
  final serialDecimal = BigInt.parse(serialHex, radix: 16).toString();

  return CertInfo(issuerName: issuer, serialNumberDecimal: serialDecimal);
}
