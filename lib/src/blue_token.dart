/// Temporary AWS credentials returned by the Blue Riiot login endpoint.
class BlueCredentials {
  BlueCredentials({
    required this.accessKey,
    required this.secretKey,
    required this.sessionToken,
    required this.expiration,
  });

  factory BlueCredentials.fromJson(Map<String, dynamic> json) {
    return BlueCredentials(
      accessKey: json['access_key'] as String,
      secretKey: json['secret_key'] as String,
      sessionToken: json['session_token'] as String,
      expiration: DateTime.parse(json['expiration'] as String).toUtc(),
    );
  }

  final String accessKey;
  final String secretKey;
  final String sessionToken;
  final DateTime expiration;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiration);
}

/// Session returned by the Blue Riiot login endpoint.
class BlueToken {
  BlueToken({
    required this.identityId,
    required this.token,
    required this.credentials,
  });

  factory BlueToken.fromJson(Map<String, dynamic> json) {
    return BlueToken(
      identityId: json['identity_id'] as String,
      token: json['token'] as String,
      credentials: BlueCredentials.fromJson(
        json['credentials'] as Map<String, dynamic>,
      ),
    );
  }

  final String identityId;
  final String token;
  final BlueCredentials credentials;
}
