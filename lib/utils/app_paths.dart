import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    return p.join(dir.path, "merchant.pem");
  }

  static Future<String> csrPath() async {
    final dir = await appDir();
    return p.join(dir.path, "csr.pem");
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
}
