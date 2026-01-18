/// Unit tests for Database Converters.
///
/// Test coverage:
/// 1. JsonMapConverter - toSql
/// 2. JsonMapConverter - fromSql
/// 3. Edge cases
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/database/converters.dart';

void main() {
  group('JsonMapConverter', () {
    late JsonMapConverter converter;

    setUp(() {
      converter = const JsonMapConverter();
    });

    group('toSql', () {
      test('converts empty map to json string', () {
        const input = <String, dynamic>{};
        final result = converter.toSql(input);
        expect(result, equals('{}'));
      });

      test('converts simple map to json string', () {
        const input = {'key': 'value'};
        final result = converter.toSql(input);
        expect(result, equals('{"key":"value"}'));
      });

      test('converts map with int values to json string', () {
        const input = {'count': 42, 'score': 100};
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['count'], equals(42));
        expect(decoded['score'], equals(100));
      });

      test('converts map with bool values to json string', () {
        const input = {'active': true, 'verified': false};
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['active'], isTrue);
        expect(decoded['verified'], isFalse);
      });

      test('converts map with null values to json string', () {
        const input = <String, dynamic>{'name': 'test', 'value': null};
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['name'], equals('test'));
        expect(decoded['value'], isNull);
      });

      test('converts nested map to json string', () {
        const input = {
          'user': {
            'name': 'John',
            'age': 30,
          },
        };
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['user']['name'], equals('John'));
        expect(decoded['user']['age'], equals(30));
      });

      test('converts map with list values to json string', () {
        const input = {
          'items': ['a', 'b', 'c'],
          'numbers': [1, 2, 3],
        };
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['items'], equals(['a', 'b', 'c']));
        expect(decoded['numbers'], equals([1, 2, 3]));
      });

      test('converts map with double values to json string', () {
        const input = {'pi': 3.14159, 'e': 2.71828};
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['pi'], closeTo(3.14159, 0.0001));
        expect(decoded['e'], closeTo(2.71828, 0.0001));
      });

      test('converts complex feedback map to json string', () {
        const input = {
          'errors': {
            'knee_valgus': true,
            'hip_shift': false,
          },
          'score': 85,
          'confidence': 0.92,
        };
        final result = converter.toSql(input);
        final decoded = jsonDecode(result) as Map<String, dynamic>;
        expect(decoded['errors']['knee_valgus'], isTrue);
        expect(decoded['score'], equals(85));
      });
    });

    group('fromSql', () {
      test('converts json string to empty map', () {
        const input = '{}';
        final result = converter.fromSql(input);
        expect(result, isEmpty);
      });

      test('converts json string to simple map', () {
        const input = '{"key":"value"}';
        final result = converter.fromSql(input);
        expect(result['key'], equals('value'));
      });

      test('converts json string with int values to map', () {
        const input = '{"count":42,"score":100}';
        final result = converter.fromSql(input);
        expect(result['count'], equals(42));
        expect(result['score'], equals(100));
      });

      test('converts json string with bool values to map', () {
        const input = '{"active":true,"verified":false}';
        final result = converter.fromSql(input);
        expect(result['active'], isTrue);
        expect(result['verified'], isFalse);
      });

      test('converts json string with null values to map', () {
        const input = '{"name":"test","value":null}';
        final result = converter.fromSql(input);
        expect(result['name'], equals('test'));
        expect(result['value'], isNull);
      });

      test('converts nested json string to map', () {
        const input = '{"user":{"name":"John","age":30}}';
        final result = converter.fromSql(input);
        expect(result['user']['name'], equals('John'));
        expect(result['user']['age'], equals(30));
      });

      test('converts json string with list values to map', () {
        const input = '{"items":["a","b","c"],"numbers":[1,2,3]}';
        final result = converter.fromSql(input);
        expect(result['items'], equals(['a', 'b', 'c']));
        expect(result['numbers'], equals([1, 2, 3]));
      });

      test('converts json string with double values to map', () {
        const input = '{"pi":3.14159,"e":2.71828}';
        final result = converter.fromSql(input);
        expect(result['pi'], closeTo(3.14159, 0.0001));
        expect(result['e'], closeTo(2.71828, 0.0001));
      });

      test('converts complex feedback json to map', () {
        const input =
            '{"errors":{"knee_valgus":true,"hip_shift":false},"score":85}';
        final result = converter.fromSql(input);
        expect(result['errors']['knee_valgus'], isTrue);
        expect(result['score'], equals(85));
      });
    });

    group('round-trip', () {
      test('toSql then fromSql returns equivalent map', () {
        const original = {
          'feedback': {
            'error_type': 'knee_valgus',
            'count': 3,
            'suggestions': ['Keep knees aligned', 'Push knees out'],
          },
          'metadata': {
            'timestamp': '2024-01-15T10:30:00Z',
            'duration': 45.5,
          },
        };

        final sql = converter.toSql(original);
        final restored = converter.fromSql(sql);

        expect(restored['feedback']['error_type'], equals('knee_valgus'));
        expect(restored['feedback']['count'], equals(3));
        expect(
          restored['metadata']['timestamp'],
          equals('2024-01-15T10:30:00Z'),
        );
      });

      test('fromSql then toSql returns equivalent json', () {
        const original = '{"a":1,"b":"test","c":[1,2,3]}';
        final map = converter.fromSql(original);
        final sql = converter.toSql(map);
        final decoded = jsonDecode(sql) as Map<String, dynamic>;

        expect(decoded['a'], equals(1));
        expect(decoded['b'], equals('test'));
        expect(decoded['c'], equals([1, 2, 3]));
      });
    });
  });
}
