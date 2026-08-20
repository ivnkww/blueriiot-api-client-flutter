# blueriiot_api_client

Unofficial Dart/Flutter client for the Blue Riiot (Blue Connect) API.
Dart port of the Node.js package `blueriiot-api-client`.

Not published to pub.dev — add it as a path or git dependency.

## Install

Path dependency:

```yaml
dependencies:
  blueriiot_api_client:
    path: ../blueriiot-api-client-flutter
```

Git dependency:

```yaml
dependencies:
  blueriiot_api_client:
    git:
      url: https://github.com/ludvigaldrin/blueriiot-api-client.git
```

## Usage

```dart
import 'package:blueriiot_api_client/blueriiot_api_client.dart';

Future<void> main() async {
  final api = BlueriiotApi(email: 'you@example.com', password: 'secret');

  try {
    await api.authenticate();
    final pools = await api.getSwimmingPools();
    print(pools);
  } on BlueriiotException catch (e) {
    print('Blueriiot error: ${e.message}');
  } finally {
    api.close();
  }
}
```

Every endpoint returns the raw decoded JSON as `Map<String, dynamic>`.
Sample payloads for each endpoint live in `examples/`.

## Endpoints

```dart
getUser()
getBlueDevice(blueDeviceSerial)
getSwimmingPools()
getSwimmingPool(swimmingPoolId)
getSwimmingPoolStatus(swimmingPoolId) // deprecated
getSwimmingPoolBlueDevices(swimmingPoolId)
getSwimmingPoolFeed(swimmingPoolId, language)
getLastMeasurements(swimmingPoolId, blueDeviceSerial)
getGuidance(swimmingPoolId, language)
getGuidanceHistory(swimmingPoolId, language)
getChemistry(swimmingPoolId)
getWeather(swimmingPoolId, language)
getBlueDeviceCompatibility(blueDeviceSerial)
```

## Auth

`authenticate()` logs in against `user/login` and keeps the returned temporary
AWS credentials in memory. Every other call re-authenticates automatically when
the credentials are missing or expired, then signs the request with AWS
Signature V4 (region `eu-west-1`, service `execute-api`).

## Example

See `example/blueriiot_api_client_example.dart`:

```sh
dart run example/blueriiot_api_client_example.dart you@example.com secret
```
