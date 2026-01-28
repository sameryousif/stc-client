import 'dart:io';
import 'package:path/path.dart' as p;

class ToolPaths {
  /// Directory where app executable exists
  static String get exeDir => File(Platform.resolvedExecutable).parent.path;

  /// tools folder bundled with the app
  static String get toolsDir => p.join(exeDir, "tools");

  static String get opensslPath => p.join(toolsDir, "openssl.exe");

  static String get cliToolPath => p.join(toolsDir, "stc-cli.exe");

  static Future<bool> verifyToolsExist() async {
    final cli = File(cliToolPath);
    final openssl = File(opensslPath);

    if (!await cli.exists()) {
      throw Exception("stc-cli.exe not found at: ${cli.path}");
    }

    if (!await openssl.exists()) {
      throw Exception("openssl.exe not found at: ${openssl.path}");
    }
    if (await cli.exists() && await openssl.exists()) {
      print("✔ All required tools are present.");
      return true;
    }
    return false;
  }
}
