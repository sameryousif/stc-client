import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../managers/invoice_manager.dart';

class InvoiceProcessingService {
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
    InvoiceManager manager,
  ) async {
    final decodedXml = utf8.decode(base64.decode(base64Invoice));
    final xmlDoc = XmlDocument.parse(decodedXml);

    // Remove unwanted sections
    _discardUnwantedSections(xmlDoc);

    // Canonicalize & compute hash
    final File tempFile = File('${Directory.systemTemp.path}/temp_invoice.xml');
    await tempFile.writeAsString(xmlDoc.toString());
    await manager.runCanonicalizationCli(tempFile.path, tempFile.path);

    final invoiceHash = await manager.computeHashBase64(tempFile.path);

    // Save to SQLite
    await _saveInvoice(base64Invoice, invoiceHash);
  }

  static void _discardUnwantedSections(XmlDocument doc) {
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
    final invoices = await InvoiceProcessingService.getAllInvoices();

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
}
