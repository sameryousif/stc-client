import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ToolPaths {
  /// Directory where app executable exists
  static Future<String> get exeDir async => await getApplicationSupportDirectory().then((dir) => dir.path);


  /// tools folder bundled with the app
  static Future<String> get toolsDir async => p.join(await exeDir, "tools");

  static Future<String> get opensslPath async => Platform.isWindows ? p.join(await toolsDir, "openssl.exe") : "/usr/bin/openssl";

  static Future<String> get cliToolPath async => Platform.isWindows ? p.join(await toolsDir, "stc-cli.exe") : p.join(await toolsDir, "stc-cli");

  static Future<bool> verifyToolsExist() async {
    final cli = File(await cliToolPath);
    final openssl = File(await opensslPath);
    if (!await cli.exists()) {
      
      throw Exception("stc-cli not found at: ${cli.path}");
    }

    if (!await openssl.exists()) {
      throw Exception("openssl not found at: ${openssl.path}");
    }
    if (await cli.exists() && await openssl.exists()) {
      print("✔ All required tools are present.");
      return true;
    }
    return false;
  }
}
