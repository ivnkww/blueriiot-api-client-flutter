import 'dart:convert';

import 'package:blueriiot_api_client/blueriiot_api_client.dart';
import 'package:test/test.dart';

Map<String, dynamic> _tokenJson(String expiration) {
  return jsonDecode('''
{
  "identity_id": "eu-west-1:11111111-2222-3333-4444-555555555555",
  "token": "test-token",
  "credentials": {
    "access_key": "ASIA_TEST",
    "secret_key": "secret",
    "session_token": "session",
    "expiration": "$expiration"
  }
}
''') as Map<String, dynamic>;
}

void main() {
  group('BlueToken.fromJson', () {
    test('parses login response', () {
      final token = BlueToken.fromJson(_tokenJson('2030-01-01T00:00:00.000Z'));

      expect(
        token.identityId,
        'eu-west-1:11111111-2222-3333-4444-555555555555',
      );
      expect(token.token, 'test-token');
      expect(token.credentials.accessKey, 'ASIA_TEST');
      expect(token.credentials.secretKey, 'secret');
      expect(token.credentials.sessionToken, 'session');
      expect(token.credentials.expiration.isUtc, isTrue);
      expect(token.credentials.expiration, DateTime.utc(2030));
    });
  });

  group('BlueCredentials.isExpired', () {
    test('is false for a future expiration', () {
      final token = BlueToken.fromJson(_tokenJson('2030-01-01T00:00:00.000Z'));
      expect(token.credentials.isExpired, isFalse);
    });

    test('is true for a past expiration', () {
      final token = BlueToken.fromJson(_tokenJson('2020-01-01T00:00:00.000Z'));
      expect(token.credentials.isExpired, isTrue);
    });
  });
}
