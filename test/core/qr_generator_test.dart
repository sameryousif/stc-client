import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stc_client/core/qr/qr_generator.dart';

void main() {
  group('generateQr', () {
    test('produces deterministic output for identical inputs', () {
      final signature = Uint8List.fromList([1, 2, 3, 4]);
      final certificate = Uint8List.fromList([5, 6, 7, 8]);
      final issueDate = DateTime(2024, 1, 15);

      final result1 = generateQr(
        sellerName: 'Test Seller',
        vatNumber: '399999999900003',
        issueDate: issueDate,
        total: 100.0,
        vatTotal: 15.0,
        xmlHash: 'abc123',
        signature: signature,
        certificate: certificate,
      );

      final result2 = generateQr(
        sellerName: 'Test Seller',
        vatNumber: '399999999900003',
        issueDate: issueDate,
        total: 100.0,
        vatTotal: 15.0,
        xmlHash: 'abc123',
        signature: signature,
        certificate: certificate,
      );

      expect(result1, equals(result2));
    });

    test('produces valid base64 output', () {
      final signature = Uint8List.fromList([1, 2, 3, 4]);
      final certificate = Uint8List.fromList([5, 6, 7, 8]);

      final result = generateQr(
        sellerName: 'Test',
        vatNumber: '12345',
        issueDate: DateTime(2024, 1, 1),
        total: 50.0,
        vatTotal: 7.5,
        xmlHash: 'hash',
        signature: signature,
        certificate: certificate,
      );

      expect(() => base64.decode(result), returnsNormally);
    });

    test('output changes when seller name changes', () {
      final signature = Uint8List.fromList([1, 2, 3, 4]);
      final certificate = Uint8List.fromList([5, 6, 7, 8]);
      final date = DateTime(2024, 1, 1);

      final r1 = generateQr(
        sellerName: 'Seller A',
        vatNumber: '12345',
        issueDate: date,
        total: 50.0,
        vatTotal: 7.5,
        xmlHash: 'hash',
        signature: signature,
        certificate: certificate,
      );

      final r2 = generateQr(
        sellerName: 'Seller B',
        vatNumber: '12345',
        issueDate: date,
        total: 50.0,
        vatTotal: 7.5,
        xmlHash: 'hash',
        signature: signature,
        certificate: certificate,
      );

      expect(r1, isNot(equals(r2)));
    });
  });
}
