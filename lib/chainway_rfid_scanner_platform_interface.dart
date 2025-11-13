import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chainway_rfid_scanner_method_channel.dart';

abstract class ChainwayRfidScannerPlatform extends PlatformInterface {
  /// Constructs a ChainwayRfidScannerPlatform.
  ChainwayRfidScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChainwayRfidScannerPlatform _instance = MethodChannelChainwayRfidScanner();

  /// The default instance of [ChainwayRfidScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelChainwayRfidScanner].
  static ChainwayRfidScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChainwayRfidScannerPlatform] when
  /// they register themselves.
  static set instance(ChainwayRfidScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  // init scanner service
  Future<String?> initReader() {
    throw UnimplementedError('initReader() has not been implemented.');
  }

  // connect to device
  Future<bool?> connect(String address) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  // disconnect to device
  Future<bool?> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  // get device connection status
  Future<String?> getConnectState() {
    throw UnimplementedError('getConnectState() has not been implemented.');
  }


  // scan rfids
  Stream<List<Map<Object?, Object?>>?> performChainwayInventory() {
    throw UnimplementedError('performChainwayInventory() has not been implemented.');
  }

  // clear rfids
  Future<String?> clearInventory() {
    throw UnimplementedError('clearInventory() has not been implemented.');
  }

  // set scanner mode
  Future<bool?> setScanMode(String scanMode) {
    throw UnimplementedError('setScanMode() has not been implemented.');
  }

  // set power level
  Future<bool?> setScanPower(int scanPower) {
    throw UnimplementedError('setScanPower() has not been implemented.');
  }

  // set scanner name
}
