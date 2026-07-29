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

  @override
  Future<String?> initReader() => Future.value('Reader initialized');

  @override
  Future<bool?> startInventory() => Future.value(true);

  @override
  Future<bool?> stopInventory() => Future.value(true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final ChainwayRfidScannerPlatform initialPlatform =
      ChainwayRfidScannerPlatform.instance;

  tearDown(() {
    ChainwayRfidScannerPlatform.instance = initialPlatform;
  });

  test('$MethodChannelChainwayRfidScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChainwayRfidScanner>());
  });

  test('getPlatformVersion', () async {
    final chainwayRfidScannerPlugin = ChainwayRfidScanner();
    final fakePlatform = MockChainwayRfidScannerPlatform();
    ChainwayRfidScannerPlatform.instance = fakePlatform;

    expect(await chainwayRfidScannerPlugin.getPlatformVersion(), '42');
  });

  test('software inventory controls are forwarded', () async {
    final plugin = ChainwayRfidScanner();
    ChainwayRfidScannerPlatform.instance = MockChainwayRfidScannerPlatform();

    expect(await plugin.startInventory(), isTrue);
    expect(await plugin.stopInventory(), isTrue);
  });
}
