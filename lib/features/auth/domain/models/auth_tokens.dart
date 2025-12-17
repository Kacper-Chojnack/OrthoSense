import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

/// Token response from login endpoint.
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'token_type') @Default('bearer') String tokenType,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
