import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('creates user with required fields', () {
      final user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.id, equals('user-123'));
      expect(user.email, equals('test@example.com'));
    });

    test('has correct default values', () {
      final user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.isActive, isTrue);
      expect(user.isVerified, isFalse);
      expect(user.createdAt, isNull);
    });

    test('can be created with all fields', () {
      final createdAt = DateTime(2025, 12, 18, 10, 30);

      final user = UserModel(
        id: 'user-456',
        email: 'complete@example.com',
        isActive: false,
        isVerified: true,
        createdAt: createdAt,
      );

      expect(user.id, equals('user-456'));
      expect(user.email, equals('complete@example.com'));
      expect(user.isActive, isFalse);
      expect(user.isVerified, isTrue);
      expect(user.createdAt, equals(createdAt));
    });

    group('JSON serialization', () {
      test('fromJson deserializes correctly', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'is_active': true,
          'is_verified': false,
          'created_at': '2025-12-18T10:30:00.000Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, equals('user-123'));
        expect(user.email, equals('test@example.com'));
        expect(user.isActive, isTrue);
        expect(user.isVerified, isFalse);
        expect(user.createdAt, isNotNull);
      });

      test('fromJson handles snake_case fields', () {
        final json = {
          'id': 'user-789',
          'email': 'snake@example.com',
          'is_active': false,
          'is_verified': true,
        };

        final user = UserModel.fromJson(json);

        expect(user.isActive, isFalse);
        expect(user.isVerified, isTrue);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'user-minimal',
          'email': 'minimal@example.com',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, equals('user-minimal'));
        expect(user.email, equals('minimal@example.com'));
        expect(user.isActive, isTrue); // Default
        expect(user.isVerified, isFalse); // Default
        expect(user.createdAt, isNull);
      });

      test('toJson serializes correctly', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          isActive: true,
          isVerified: false,
        );

        final json = user.toJson();

        expect(json['id'], equals('user-123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['is_active'], isTrue);
        expect(json['is_verified'], isFalse);
      });

      test('toJson includes createdAt when set', () {
        final createdAt = DateTime.utc(2025, 12, 18, 10, 30);

        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          createdAt: createdAt,
        );

        final json = user.toJson();

        expect(json['created_at'], isNotNull);
      });
    });

    group('equality', () {
      test('users with same data are equal', () {
        final user1 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final user2 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        expect(user1, equals(user2));
      });

      test('users with different id are not equal', () {
        final user1 = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final user2 = UserModel(
          id: 'user-456',
          email: 'test@example.com',
        );

        expect(user1, isNot(equals(user2)));
      });

      test('users with different email are not equal', () {
        final user1 = UserModel(
          id: 'user-123',
          email: 'test1@example.com',
        );

        final user2 = UserModel(
          id: 'user-123',
          email: 'test2@example.com',
        );

        expect(user1, isNot(equals(user2)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated email', () {
        final original = UserModel(
          id: 'user-123',
          email: 'original@example.com',
        );

        final updated = original.copyWith(email: 'updated@example.com');

        expect(updated.email, equals('updated@example.com'));
        expect(updated.id, equals(original.id)); // Unchanged
        expect(original.email, equals('original@example.com')); // Immutable
      });

      test('creates copy with updated isVerified', () {
        final original = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          isVerified: false,
        );

        final updated = original.copyWith(isVerified: true);

        expect(updated.isVerified, isTrue);
        expect(original.isVerified, isFalse); // Immutable
      });
    });
  });
}
