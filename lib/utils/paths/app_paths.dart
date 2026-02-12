import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

//// Utility class that defines all file paths used in the app, ensuring a consistent structure for storing certificates, invoices, and working files
class AppPaths {
  static const appName = "stc_client";

  /// folder for app data
  static Future<Directory> appDir() async {
    final dir = await getApplicationSupportDirectory();
    final appFolder = Directory(p.join(dir.path, appName));
    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
    }
    return appFolder;
  }

  static Future<String> invoicesDir() async {
    final dir = await appDir();
    final invoices = Directory(p.join(dir.path, "invoices"));
    if (!await invoices.exists()) await invoices.create(recursive: true);
    return invoices.path;
  }

  static Future<String> certPath() async {
    final dir = await appDir();
    return p.join(dir.path, "merchant.der");
  }

  static Future<String> csrPath() async {
    final dir = await appDir();
    return p.join(dir.path, "csr.der");
  }

  static Future<String> privateKeyPath() async {
    final dir = await appDir();
    return p.join(dir.path, "private_key.pem");
  }

  static Future<String> signaturePath() async {
    final dir = await appDir();
    final sig = Directory(p.join(dir.path, "signatures"));
    if (!await sig.exists()) await sig.create(recursive: true);
    return sig.path;
  }

  static Future<Directory> workingDir() async {
    final base = await AppPaths.appDir();
    final dir = Directory(p.join(base.path, "work"));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> clearedDir() async {
    final base = await AppPaths.appDir();
    final dir = Directory(p.join(base.path, "cleared"));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> inputXmlPath() async {
    final dir = await workingDir();
    return p.join(dir.path, "input.xml");
  }

  static Future<String> outputXmlPath() async {
    final dir = await workingDir();
    return p.join(dir.path, "output.xml");
  }

  static Future<String> signedPropsPath() async {
    final dir = await workingDir();
    return p.join(dir.path, "signed_props.xml");
  }

  static Future<String> signedInfoPath() async {
    final dir = await workingDir();
    return p.join(dir.path, "signedInfo.xml");
  }

  static Future<String> tempInvoicePath() async {
    final dir = await workingDir();
    return p.join(dir.path, "temp_invoice.xml");
  }
}
