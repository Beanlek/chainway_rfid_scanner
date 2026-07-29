import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chainway_rfid_scanner/chainway_rfid_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelChainwayRfidScanner();
  const MethodChannel channel = MethodChannel('chainway_rfid_scanner');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        calls.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return 'iOS test';
          case 'startDiscovery':
          case 'stopDiscovery':
          case 'startInventory':
          case 'stopInventory':
          case 'setScanMode':
          case 'setScanPower':
            return true;
          case 'getScanPower':
            return 20;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), 'iOS test');
  });

  test('discovery and inventory controls use the expected methods', () async {
    expect(await platform.startDiscovery(), isTrue);
    expect(await platform.stopDiscovery(), isTrue);
    expect(await platform.startInventory(), isTrue);
    expect(await platform.stopInventory(), isTrue);

    expect(
      calls.map((call) => call.method),
      [
        'startDiscovery',
        'stopDiscovery',
        'startInventory',
        'stopInventory',
      ],
    );
  });

  test('scan configuration forwards typed arguments', () async {
    expect(await platform.setScanMode('single'), isTrue);
    expect(await platform.setScanPower(20), isTrue);
    expect(await platform.getScanPower(), 20);

    expect(calls[0].arguments, {'scanMode': 'single'});
    expect(calls[1].arguments, {'scanPower': 20});
  });
}
