import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/infrastructure/networking/dio_provider.dart';

part 'account_service.g.dart';

/// Service for GDPR-compliant account management.
/// Handles profile updates, account deletion, and data export.
class AccountService {
  AccountService({
    required Dio dio,
    required TokenStorage tokenStorage,
  }) : _dio = dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Update user profile (name, email).
  Future<void> updateProfile({
    String? fullName,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;

    if (data.isEmpty) return;

    await _dio.put<Map<String, dynamic>>(
      '/api/v1/auth/me',
      data: data,
    );

    // Update cached email if changed
    if (email != null) {
      await _tokenStorage.saveUserInfo(
        userId: await _tokenStorage.getUserId() ?? '',
        email: email,
      );
    }
  }

  /// Delete current user account and all associated data.
  /// GDPR: Right to be Forgotten.
  Future<void> deleteAccount() async {
    await _dio.delete<void>('/api/v1/auth/me');
    await _tokenStorage.clearAll();
  }

  /// Export all user data as JSON.
  /// GDPR: Right to Data Portability.
  Future<Map<String, dynamic>> exportData() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/auth/me/export',
    );
    return response.data ?? {};
  }

  /// Export data and save to file, then share.
  Future<void> exportAndShareData() async {
    final data = await exportData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Get temp directory and save file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/orthosense_data_$timestamp.json');
    await file.writeAsString(jsonString);

    // Share the file and ensure it is cleaned up afterwards
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'OrthoSense Data Export',
        text: 'Your OrthoSense data export (GDPR compliant)',
      );
    } finally {
      // Best-effort cleanup of the temporary export file
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }
}

@Riverpod(keepAlive: true)
AccountService accountService(Ref ref) {
  return AccountService(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}

/// State for account operations.
sealed class AccountOperationState {
  const AccountOperationState();
}

class AccountOperationIdle extends AccountOperationState {
  const AccountOperationIdle();
}

class AccountOperationLoading extends AccountOperationState {
  const AccountOperationLoading();
}

class AccountOperationSuccess extends AccountOperationState {
  const AccountOperationSuccess(this.message);
  final String message;
}

class AccountOperationError extends AccountOperationState {
  const AccountOperationError(this.message);
  final String message;
}

/// Notifier for account operations with loading state.
@riverpod
class AccountOperationNotifier extends _$AccountOperationNotifier {
  @override
  AccountOperationState build() => const AccountOperationIdle();

  Future<void> updateProfile({String? fullName, String? email}) async {
    state = const AccountOperationLoading();
    try {
      await ref
          .read(accountServiceProvider)
          .updateProfile(
            fullName: fullName,
            email: email,
          );
      state = const AccountOperationSuccess('Profile updated successfully');
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = AccountOperationError(message);
    } catch (e) {
      state = AccountOperationError(e.toString());
    }
  }

  Future<bool> deleteAccount() async {
    state = const AccountOperationLoading();
    try {
      await ref.read(accountServiceProvider).deleteAccount();
      state = const AccountOperationSuccess('Account deleted');
      return true;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = AccountOperationError(message);
      return false;
    } catch (e) {
      state = AccountOperationError(e.toString());
      return false;
    }
  }

  Future<void> exportData() async {
    state = const AccountOperationLoading();
    try {
      await ref.read(accountServiceProvider).exportAndShareData();
      state = const AccountOperationSuccess('Data exported successfully');
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = AccountOperationError(message);
    } catch (e) {
      state = AccountOperationError(e.toString());
    }
  }

  void reset() {
    state = const AccountOperationIdle();
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      return data['detail'].toString();
    }
    return 'An error occurred. Please try again.';
  }
}
