
import 'chainway_rfid_scanner_platform_interface.dart';

class ChainwayRfidScanner {
  Future<String?> getPlatformVersion() {
    return ChainwayRfidScannerPlatform.instance.getPlatformVersion();
  }

  // init scanner service
  Future<String?> initReader() {
    return ChainwayRfidScannerPlatform.instance.initReader();
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

  // set scanner name
}
