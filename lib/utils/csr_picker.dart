import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<File?> pickCsrFile() async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select CSR file',
    initialDirectory: r'C:\openssl_keys',
    type: FileType.custom,
    allowedExtensions: ['csr', 'pem'],
  );

  if (result == null) return null;

  return File(result.files.single.path!);
}
