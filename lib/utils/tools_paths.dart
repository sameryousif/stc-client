import 'dart:io';
import 'package:path/path.dart' as p;

class ToolPaths {
  /// Directory where your app executable lives
  static String get exeDir => File(Platform.resolvedExecutable).parent.path;

  /// tools folder shipped with the app
  static String get toolsDir => p.join(exeDir, "tools");

  static String get opensslPath => p.join(toolsDir, "openssl.exe");

  static String get cliToolPath => p.join(toolsDir, "stc-cli.exe");

  static Future<void> verifyToolsExist() async {
    final cli = File(cliToolPath);
    final openssl = File(opensslPath);

    if (!await cli.exists()) {
      throw Exception("stc-cli.exe not found at: ${cli.path}");
    }

    if (!await openssl.exists()) {
      throw Exception("openssl.exe not found at: ${openssl.path}");
    }
  }
}
