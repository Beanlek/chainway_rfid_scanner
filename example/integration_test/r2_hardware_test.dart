import 'package:chainway_rfid_scanner/chainway_rfid_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const bool _runHardwareTests = bool.fromEnvironment('RUN_R2_HARDWARE_TESTS');
const String _readerName = String.fromEnvironment(
  'R2_DEVICE_NAME',
  defaultValue: 'R2',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'discovers, connects, configures, and inventories with an R2',
    (WidgetTester tester) async {
      final scanner = ChainwayRfidScanner();
      await scanner.initReader();

      bool isR2(Map<Object?, Object?> reader) =>
          (reader['name']?.toString().toUpperCase() ?? '')
              .contains(_readerName.toUpperCase());
      final discoveredNames = <String>{};
      final readers = await scanner
          .discoverReaders()
          .map((items) {
            discoveredNames.addAll(
              items.map((reader) => reader['name']?.toString() ?? 'Unknown'),
            );
            return items;
          })
          .firstWhere((items) => items.any(isR2))
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw StateError(
              'No reader matching "$_readerName" was discovered. '
              'Names seen: ${discoveredNames.toList()..sort()}.',
            ),
          );
      final r2 = readers.firstWhere(
        isR2,
      );

      final deviceId = r2['id']?.toString();
      expect(deviceId, isNotNull);
      expect(await scanner.connect(deviceId!), isTrue);
      expect(await scanner.getConnectState(), 'Connected');

      expect(await scanner.setScanPower(20), isTrue);
      expect(await scanner.getScanPower(), 20);

      final firstTags = scanner
          .performChainwayInventory()
          .firstWhere((tags) => tags != null && tags.isNotEmpty);
      expect(await scanner.startInventory(), isTrue);
      final tags = await firstTags.timeout(const Duration(seconds: 20));
      expect(tags, isNotEmpty);

      expect(await scanner.stopInventory(), isTrue);
      expect(await scanner.disconnect(), isTrue);
    },
    skip: !_runHardwareTests,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
