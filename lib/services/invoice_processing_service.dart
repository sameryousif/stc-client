import 'dart:convert';
import 'dart:io';
import 'package:stc_client/utils/paths/app_paths.dart';
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'invoicePrepService.dart';

/// Service responsible for managing the SQLite database that stores cleared invoices, including saving and retrieving invoice data
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
  entityId TEXT,
  icv INTEGER,
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
    String entityId,
  ) async {
    final decodedXml = utf8.decode(base64.decode(base64Invoice));
    final xmlDoc = XmlDocument.parse(decodedXml);

    //save cleared invoice to file
    final dir = await AppPaths.clearedDir();
    final clearedPath =
        Platform.isLinux
            ? '${dir.path}/invoice_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xml'
            : '${dir.path}\\invoice_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xml';
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
    final db = await database;

    final result = await db.rawQuery(
      'SELECT MAX(icv) as maxIcv FROM invoices WHERE entityId = ?',
      [entityId],
    );

    final icv = (result.first['maxIcv'] as int? ?? 0) + 1;

    await _saveInvoice(base64Invoice, invoiceHash, entityId, icv);
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

  static Future<void> _saveInvoice(
    String base64Invoice,
    String hash,
    String entityId,
    int icv,
  ) async {
    final db = await database;
    await db.insert('invoices', {
      'entityId': entityId,
      'base64Invoice': base64Invoice,
      'hash': hash,
      'icv': icv,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'entityId ASC, icv DESC');
  }

  Future<void> printAllInvoices() async {
    final invoices = await DBService.getAllInvoices();

    if (invoices.isEmpty) {
      print("No invoices found in the database.");
      return;
    }

    for (var inv in invoices) {
      final base64 = inv['base64Invoice'] as String? ?? '';
      final preview = base64.length > 50 ? base64.substring(0, 50) : base64;

      print('Entity ID: ${inv['entityId']}');
      print('ICV: ${inv['icv']}');
      print('Hash: ${inv['hash']}');
      print('Base64 (first 50 chars): $preview');
      print('Created At: ${inv['createdAt']}');
      print('---------------------------');
    }
  }

  static Future<void> saveClearedInvoice(String path, String xmlContent) async {
    final dir = await clearedDir;
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(path).writeAsString(xmlContent);
  }

  Future<Map<String, dynamic>?> getLastInvoiceForEntity(String entityId) async {
    final db = await database;
    final invoices = await db.query(
      'invoices',
      where: 'entityId = ?',
      whereArgs: [entityId],
      orderBy: 'icv DESC',
      limit: 1,
    );
    if (invoices.isEmpty) return null;
    return invoices.first;
  }
}
