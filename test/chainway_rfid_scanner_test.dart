import 'package:flutter_test/flutter_test.dart';
import 'package:chainway_rfid_scanner/chainway_rfid_scanner.dart';
import 'package:chainway_rfid_scanner/chainway_rfid_scanner_platform_interface.dart';
import 'package:chainway_rfid_scanner/chainway_rfid_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChainwayRfidScannerPlatform
    with MockPlatformInterfaceMixin
    implements ChainwayRfidScannerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ChainwayRfidScannerPlatform initialPlatform = ChainwayRfidScannerPlatform.instance;

  test('$MethodChannelChainwayRfidScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChainwayRfidScanner>());
  });

  test('getPlatformVersion', () async {
    ChainwayRfidScanner chainwayRfidScannerPlugin = ChainwayRfidScanner();
    MockChainwayRfidScannerPlatform fakePlatform = MockChainwayRfidScannerPlatform();
    ChainwayRfidScannerPlatform.instance = fakePlatform;

    expect(await chainwayRfidScannerPlugin.getPlatformVersion(), '42');
  });
}
