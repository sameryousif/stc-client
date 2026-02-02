import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ToolPaths {
  /// Directory where app data exists
  static Future<String> get exeDir async =>
      (await getApplicationSupportDirectory()).path;

  /// Tools folder inside application support directory
  static Future<String> get toolsDir async => p.join(await exeDir, "tools");

  /// Path to OpenSSL executable
  static Future<String> get opensslPath async =>
      Platform.isWindows
          ? p.join(await toolsDir, "openssl.exe")
          : "/usr/bin/openssl";

  /// Path to CLI tool
  static Future<String> get cliToolPath async =>
      Platform.isWindows
          ? p.join(await toolsDir, "stc-cli.exe")
          : p.join(await toolsDir, "stc-cli");

  /// Ensure tools are copied from assets into toolsDir
  static Future<void> ensureToolsReady() async {
    final dirPath = await toolsDir;
    final dir = Directory(dirPath);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    if (Platform.isWindows) {
      await _copyAssetIfMissing(
        assetPath: "assets/tools/windows/stc-cli.exe",
        outPath: p.join(dirPath, "stc-cli.exe"),
      );
      await _copyAssetIfMissing(
        assetPath: "assets/tools/windows/openssl.exe",
        outPath: p.join(dirPath, "openssl.exe"),
      );
    } else {
      /// Linux or Mac
      await _copyAssetIfMissing(
        assetPath: "assets/tools/linux/stc-cli",
        outPath: p.join(dirPath, "stc-cli"),
      );

      /// Make it executable if its not
      final cliFile = File(p.join(dirPath, "stc-cli"));
      if (cliFile.existsSync()) {
        await Process.run("chmod", ["+x", cliFile.path]);
      }
    }
  }

  ///helper function to copy asset to file only if it does not exist
  static Future<void> _copyAssetIfMissing({
    required String assetPath,
    required String outPath,
  }) async {
    final file = File(outPath);
    if (file.existsSync() && file.lengthSync() > 0) return;

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Verify tools exist, throw exception if missing
  static Future<void> verifyToolsExist() async {
    final cli = File(await cliToolPath);
    final openssl = File(await opensslPath);

    if (!cli.existsSync()) {
      throw Exception("stc-cli not found at: ${cli.path}");
    }
    if (!openssl.existsSync()) {
      throw Exception("openssl not found at: ${openssl.path}");
    }

    print("✔ All required tools are present.");
  }
}
