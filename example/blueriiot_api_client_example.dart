import 'dart:convert';

import 'package:blueriiot_api_client/blueriiot_api_client.dart';

/// Usage:
///   `dart run example/blueriiot_api_client_example.dart <email> <password>`
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart run example/blueriiot_api_client_example.dart '
        '<email> <password>');
    return;
  }

  final api = BlueriiotApi(email: args[0], password: args[1]);
  const encoder = JsonEncoder.withIndent(' ');

  try {
    await api.authenticate();
    print('Authentication success!');

    final user = await api.getUser();
    print(encoder.convert(user));

    final pools = await api.getSwimmingPools();
    print(encoder.convert(pools));

    final poolList = pools['data'];
    if (poolList is List && poolList.isNotEmpty) {
      final first = poolList.first as Map<String, dynamic>;
      final poolId = first['swimming_pool_id'] as String;

      print(encoder.convert(await api.getSwimmingPool(poolId)));
      print(encoder.convert(await api.getWeather(poolId, 'en')));

      final devices = await api.getSwimmingPoolBlueDevices(poolId);
      final deviceList = devices['data'];
      if (deviceList is List && deviceList.isNotEmpty) {
        final device = deviceList.first as Map<String, dynamic>;
        final serial = device['blue_device_serial'] as String;
        print(encoder.convert(await api.getLastMeasurements(poolId, serial)));
      }
    }
  } on BlueriiotException catch (e) {
    print('Blueriiot error: ${e.message}');
  } finally {
    api.close();
  }
}
