import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/auth_tokens.dart';

void main() {
  group('AuthTokens', () {
    test('creates tokens with required fields', () {
      const tokens = AuthTokens(accessToken: 'test-jwt-token');

      expect(tokens.accessToken, equals('test-jwt-token'));
    });

    test('has correct default tokenType', () {
      const tokens = AuthTokens(accessToken: 'test-token');

      expect(tokens.tokenType, equals('bearer'));
    });

    test('can override tokenType', () {
      const tokens = AuthTokens(
        accessToken: 'test-token',
        tokenType: 'custom',
      );

      expect(tokens.tokenType, equals('custom'));
    });

    group('JSON serialization', () {
      test('fromJson deserializes correctly', () {
        final json = {
          'access_token': 'jwt-token-value',
          'token_type': 'bearer',
        };

        final tokens = AuthTokens.fromJson(json);

        expect(tokens.accessToken, equals('jwt-token-value'));
        expect(tokens.tokenType, equals('bearer'));
      });

      test('fromJson handles snake_case access_token', () {
        final json = {
          'access_token': 'snake-case-token',
        };

        final tokens = AuthTokens.fromJson(json);

        expect(tokens.accessToken, equals('snake-case-token'));
      });

      test('fromJson uses default tokenType when missing', () {
        final json = {
          'access_token': 'token-only',
        };

        final tokens = AuthTokens.fromJson(json);

        expect(tokens.tokenType, equals('bearer'));
      });

      test('toJson serializes correctly', () {
        const tokens = AuthTokens(
          accessToken: 'my-token',
        );

        final json = tokens.toJson();

        expect(json['access_token'], equals('my-token'));
        expect(json['token_type'], equals('bearer'));
      });
    });

    group('equality', () {
      test('tokens with same data are equal', () {
        const tokens1 = AuthTokens(accessToken: 'same-token');
        const tokens2 = AuthTokens(accessToken: 'same-token');

        expect(tokens1, equals(tokens2));
      });

      test('tokens with different accessToken are not equal', () {
        const tokens1 = AuthTokens(accessToken: 'token-1');
        const tokens2 = AuthTokens(accessToken: 'token-2');

        expect(tokens1, isNot(equals(tokens2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated accessToken', () {
        const original = AuthTokens(accessToken: 'original-token');
        final updated = original.copyWith(accessToken: 'new-token');

        expect(updated.accessToken, equals('new-token'));
        expect(original.accessToken, equals('original-token'));
      });
    });
  });
}
