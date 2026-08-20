import 'dart:convert';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;

import 'blue_token.dart';
import 'blueriiot_exception.dart';

const _awsRegion = 'eu-west-1';
const _awsService = AWSService('execute-api');
const _baseUrl = 'https://api.riiotlabs.com/prod/';
const _baseHeaders = <String, String>{
  'User-Agent': 'BlueConnect/3.2.1',
  'Accept-Language': 'en-DK;q=1.0, da-DK;q=0.9',
  'Accept': '**',
};

/// Unofficial client for the Blue Riiot (Blue Connect) API.
///
/// All endpoints return the raw JSON response as `Map<String, dynamic>`.
class BlueriiotApi {
  BlueriiotApi({
    required this.email,
    required this.password,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final String email;
  final String password;
  final http.Client _httpClient;
  final bool _ownsClient;

  BlueToken? _token;

  /// The current session, or `null` when not authenticated yet.
  BlueToken? get token => _token;

  /// Logs in and stores a new [BlueToken].
  Future<void> getToken() async {
    _token = null;
    final response = await _httpClient.post(
      Uri.parse('${_baseUrl}user/login'),
      headers: {..._baseHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decode(response.body, response.statusCode);
    if (response.statusCode >= 400) {
      throw BlueriiotException(
        body['errorMessage'] as String? ?? response.body,
        statusCode: response.statusCode,
      );
    }
    _token = BlueToken.fromJson(body);
  }

  /// Logs in if there is no token yet or the current one has expired.
  Future<void> authenticate() async {
    final token = _token;
    if (token == null || token.credentials.isExpired) {
      await getToken();
    }
  }

  /// Performs a signed GET request against [pathTemplate].
  ///
  /// Placeholders like `{swimming_pool_id}` in [pathTemplate] are replaced
  /// with the matching entry of [pathParams].
  Future<Map<String, dynamic>> getData(
    String pathTemplate, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
  }) async {
    await authenticate();
    final credentials = _token!.credentials;

    var path = pathTemplate;
    pathParams.forEach((key, value) {
      path = path.replaceAll('{$key}', Uri.encodeComponent(value));
    });

    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(
          credentials.accessKey,
          credentials.secretKey,
          credentials.sessionToken,
          credentials.expiration,
        ),
      ),
    );
    final signed = await signer.sign(
      AWSHttpRequest.get(uri, headers: _baseHeaders),
      credentialScope: AWSCredentialScope(
        region: _awsRegion,
        service: _awsService,
      ),
    );

    final response = await _httpClient.get(signed.uri, headers: signed.headers);
    final body = _decode(response.body, response.statusCode);
    if (response.statusCode >= 400) {
      throw BlueriiotException(
        body['errorMessage'] as String? ?? response.body,
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> getUser() => getData('user/');

  Future<Map<String, dynamic>> getBlueDevice(String blueDeviceSerial) =>
      getData(
        'blue/{blue_device_serial}/',
        pathParams: {'blue_device_serial': blueDeviceSerial},
      );

  Future<Map<String, dynamic>> getSwimmingPools() => getData('swimming_pool/');

  Future<Map<String, dynamic>> getSwimmingPool(String swimmingPoolId) => getData(
        'swimming_pool/{swimming_pool_id}/',
        pathParams: {'swimming_pool_id': swimmingPoolId},
      );

  /// Deprecated by the Blue Riiot API.
  @Deprecated('The Blue Riiot API no longer supports this endpoint')
  Future<Map<String, dynamic>> getSwimmingPoolStatus(String swimmingPoolId) =>
      getData(
        'swimming_pool/{swimming_pool_id}/status/',
        pathParams: {'swimming_pool_id': swimmingPoolId},
      );

  Future<Map<String, dynamic>> getSwimmingPoolBlueDevices(
    String swimmingPoolId,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/blue/',
        pathParams: {'swimming_pool_id': swimmingPoolId},
      );

  Future<Map<String, dynamic>> getSwimmingPoolFeed(
    String swimmingPoolId,
    String language,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/feed',
        pathParams: {'swimming_pool_id': swimmingPoolId},
        queryParams: {'lang': language},
      );

  Future<Map<String, dynamic>> getLastMeasurements(
    String swimmingPoolId,
    String blueDeviceSerial,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/blue/{blue_device_serial}/lastMeasurements',
        pathParams: {
          'swimming_pool_id': swimmingPoolId,
          'blue_device_serial': blueDeviceSerial,
        },
        queryParams: {'mode': 'blue_and_strip'},
      );

  Future<Map<String, dynamic>> getGuidance(
    String swimmingPoolId,
    String language,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/guidance',
        pathParams: {'swimming_pool_id': swimmingPoolId},
        queryParams: {'lang': language, 'mode': 'interactive_v03'},
      );

  Future<Map<String, dynamic>> getGuidanceHistory(
    String swimmingPoolId,
    String language,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/guidance/history',
        pathParams: {'swimming_pool_id': swimmingPoolId},
        queryParams: {'lang': language},
      );

  Future<Map<String, dynamic>> getChemistry(String swimmingPoolId) => getData(
        'swimming_pool/{swimming_pool_id}/chemistry',
        pathParams: {'swimming_pool_id': swimmingPoolId},
      );

  Future<Map<String, dynamic>> getWeather(
    String swimmingPoolId,
    String language,
  ) =>
      getData(
        'swimming_pool/{swimming_pool_id}/weather',
        pathParams: {'swimming_pool_id': swimmingPoolId},
        queryParams: {'lang': language},
      );

  Future<Map<String, dynamic>> getBlueDeviceCompatibility(
    String blueDeviceSerial,
  ) =>
      getData(
        'blue/{blue_device_serial}/compatibility',
        pathParams: {'blue_device_serial': blueDeviceSerial},
      );

  /// Closes the underlying HTTP client when it was created by this instance.
  void close() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  Map<String, dynamic> _decode(String body, int statusCode) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw BlueriiotException(
        'Unexpected response body: $body',
        statusCode: statusCode,
      );
    }
  }
}
