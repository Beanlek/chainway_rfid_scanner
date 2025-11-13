import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chainway_rfid_scanner/chainway_rfid_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelChainwayRfidScanner platform = MethodChannelChainwayRfidScanner();
  const MethodChannel channel = MethodChannel('chainway_rfid_scanner');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
