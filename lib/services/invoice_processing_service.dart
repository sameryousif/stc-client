import 'dart:convert';
import 'dart:io';
import 'package:stc_client/utils/paths/app_paths.dart';
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'invoicePrepService.dart';

class DBService {
  static Future<Directory> get clearedDir => AppPaths.clearedDir();
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'invoices.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE invoices(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            base64Invoice TEXT,
            hash TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> processClearedInvoice(
    String base64Invoice,
    InvoicePrepService prepService,
  ) async {
    final decodedXml = utf8.decode(base64.decode(base64Invoice));
    final xmlDoc = XmlDocument.parse(decodedXml);

    //save cleared invoice to file
    final dir = await AppPaths.clearedDir();
    final clearedPath =
        '${dir.path}\\invoice_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xml';
    await saveClearedInvoice(clearedPath, xmlDoc.toXmlString(pretty: false));

    // Remove unwanted sections
    removeSections(xmlDoc);
    String xmlString = xmlDoc.toXmlString(pretty: true);
    if (xmlString.startsWith('<?xml')) {
      xmlString = xmlString.substring(xmlString.indexOf('?>') + 2).trim();
    }

    // Canonicalize & compute hash
    final tempFilePath = await AppPaths.tempInvoicePath();
    final tempFile = File(tempFilePath);
    await tempFile.writeAsString(xmlString);
    await prepService.runCanonicalizationCli(tempFilePath, tempFilePath);

    final invoiceHash = await prepService.computeHashBase64(tempFilePath);

    // Save to SQLite
    await _saveInvoice(base64Invoice, invoiceHash);
  }

  static void removeSections(XmlDocument doc) {
    doc
        .findAllElements('UBLExtensions', namespace: '*')
        .toList()
        .forEach((e) => e.remove());
    doc
        .findAllElements('Signature', namespace: '*')
        .toList()
        .forEach((e) => e.remove());
    doc
        .findAllElements('AdditionalDocumentReference', namespace: '*')
        .where(
          (adr) => adr
              .findElements('ID', namespace: '*')
              .any((id) => id.text.trim() == 'QR'),
        )
        .toList()
        .forEach((e) => e.remove());
  }

  static Future<void> _saveInvoice(String base64Invoice, String hash) async {
    final db = await database;
    await db.insert('invoices', {
      'base64Invoice': base64Invoice,
      'hash': hash,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<void> printAllInvoices() async {
    final invoices = await DBService.getAllInvoices();

    if (invoices.isEmpty) {
      print("No invoices found in the database.");
      return;
    }

    for (var inv in invoices) {
      print('Invoice ID: ${inv['id']}');
      print('Hash: ${inv['hash']}');
      print(
        'Base64 (first 50 chars): ${inv['base64Invoice'].substring(0, 50)}',
      );
      print('Created At: ${inv['createdAt']}');
      print('---------------------------');
    }
  }

  Future<String?> getLastInvoiceHash() async {
    final invoices = await getAllInvoices();
    if (invoices.isEmpty) return null;
    return invoices.first['hash'] as String;
  }

  Future<int?> getLastInvoiceID() async {
    final invoices = await getAllInvoices();
    if (invoices.isEmpty) return null;
    return invoices.first['id'] as int?;
  }

  static Future<void> saveClearedInvoice(String path, String xmlContent) async {
    final dir = await clearedDir;
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(path).writeAsString(xmlContent);
  }
}
