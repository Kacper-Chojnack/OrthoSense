// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['access_token'] as String,
  tokenType: json['token_type'] as String? ?? 'bearer',
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
    };
