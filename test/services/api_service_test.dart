import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stc_client/services/api_service.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
import 'api_service_test.mocks.dart';

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    ApiService.dio = mockDio;
  });

  group('sendClear', () {
    test('returns response on success', () async {
      when(
        mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'message': 'cleared'},
        ),
      );

      final result = await ApiService.sendClear({
        'uuid': 'test-uuid',
        'invoice_hash': 'abc',
        'invoice': 'xyz',
      });

      expect(result?.statusCode, equals(200));
      expect(result?.data['message'], equals('cleared'));
    });

    test('returns error response on DioException', () async {
      when(
        mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'error': 'bad request'},
          ),
        ),
      );

      final result = await ApiService.sendClear({
        'uuid': 'test-uuid',
        'invoice_hash': 'abc',
        'invoice': 'xyz',
      });

      expect(result?.statusCode, equals(400));
      expect(result?.data['error'], equals('bad request'));
    });
  });

  group('sendReport', () {
    test('returns response on success', () async {
      when(
        mockDio.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'message': 'reported'},
        ),
      );

      final result = await ApiService.sendReport({
        'uuid': 'test-uuid',
        'invoice_hash': 'abc',
        'invoice': 'xyz',
      });

      expect(result?.statusCode, equals(200));
    });
  });

  group('sendCsr', () {
    test('throws on invalid response format', () async {
      when(
        mockDio.post(any, data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: 'not a map',
        ),
      );

      final file = File(
        '${Directory.systemTemp.path}/test-csr.der',
      );
      await file.writeAsBytes([1, 2, 3]);

      expect(
        () => ApiService.sendCsr(csrFile: file, token: 'test'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data field is missing', () async {
      when(
        mockDio.post(any, data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'something': 'else'},
        ),
      );

      final file = File(
        '${Directory.systemTemp.path}/test-csr2.der',
      );
      await file.writeAsBytes([4, 5, 6]);

      expect(
        () => ApiService.sendCsr(csrFile: file, token: 'test'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns certificate on success', () async {
      when(
        mockDio.post(any, data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'data': {
              'certificate': 'MIID3jCCA4Sg...',
            },
          },
        ),
      );

      final file = File(
        '${Directory.systemTemp.path}/test-csr3.der',
      );
      await file.writeAsBytes([7, 8, 9]);

      final result = await ApiService.sendCsr(csrFile: file, token: 'test');
      expect(result, equals('MIID3jCCA4Sg...'));
    });
  });
}
