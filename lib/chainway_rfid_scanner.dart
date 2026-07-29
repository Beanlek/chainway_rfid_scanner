import 'chainway_rfid_scanner_platform_interface.dart';

class ChainwayRfidScanner {
  Future<String?> getPlatformVersion() {
    return ChainwayRfidScannerPlatform.instance.getPlatformVersion();
  }

  // init scanner service
  Future<String?> initReader() {
    return ChainwayRfidScannerPlatform.instance.initReader();
  }

  /// Discovers nearby Chainway BLE readers.
  ///
  /// Each reader contains `id`, `name`, `address`, and `rssi`. Pass `id` to
  /// [connect] on iOS. Android callers may continue to pass a BLE MAC address.
  Stream<List<Map<Object?, Object?>>> discoverReaders() {
    return ChainwayRfidScannerPlatform.instance.discoverReaders();
  }

  Future<bool?> startDiscovery() {
    return ChainwayRfidScannerPlatform.instance.startDiscovery();
  }

  Future<bool?> stopDiscovery() {
    return ChainwayRfidScannerPlatform.instance.stopDiscovery();
  }

  // connect to device
  Future<bool?> connect(String address) {
    return ChainwayRfidScannerPlatform.instance.connect(address);
  }

  // disconnect to device
  Future<bool?> disconnect() {
    return ChainwayRfidScannerPlatform.instance.disconnect();
  }

  // get device connection status
  Future<String?> getConnectState() {
    return ChainwayRfidScannerPlatform.instance.getConnectState();
  }

  // scan rfids
  Stream<List<Map<Object?, Object?>>?> performChainwayInventory() {
    return ChainwayRfidScannerPlatform.instance.performChainwayInventory();
  }

  Future<bool?> startInventory() {
    return ChainwayRfidScannerPlatform.instance.startInventory();
  }

  Future<bool?> stopInventory() {
    return ChainwayRfidScannerPlatform.instance.stopInventory();
  }

  // clear rfids
  Future<String?> clearInventory() {
    return ChainwayRfidScannerPlatform.instance.clearInventory();
  }

  // set scanner mode
  Future<bool?> setScanMode(String scanMode) {
    return ChainwayRfidScannerPlatform.instance.setScanMode(scanMode);
  }

  // set power level
  Future<bool?> setScanPower(int scanPower) {
    return ChainwayRfidScannerPlatform.instance.setScanPower(scanPower);
  }

  // get power level
  Future<int?> getScanPower() {
    return ChainwayRfidScannerPlatform.instance.getScanPower();
  }

  // set scanner name
}
