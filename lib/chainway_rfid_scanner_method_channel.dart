import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chainway_rfid_scanner_platform_interface.dart';

/// An implementation of [ChainwayRfidScannerPlatform] that uses method channels.
class MethodChannelChainwayRfidScanner extends ChainwayRfidScannerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chainway_rfid_scanner');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  // init scanner service
  @override
  Future<String?> initReader() async {
    final result = await methodChannel.invokeMethod<String>('initReader');
    return result;
  }

  // connect to device
  @override
  Future<bool?> connect(String address) async {
    final result = await methodChannel.invokeMethod<bool>('connect', 
      {
        "address": address
      }
    );
    return result;
  }

  // disconnect to device
  @override
  Future<bool?> disconnect() async {
    final result = await methodChannel.invokeMethod<bool>('disconnect');
    return result;
  }

  // get device connection status
  @override
  Future<String?> getConnectState() async {
    final result = await methodChannel.invokeMethod<String>('getConnectState');
    return result;
  }


  // scan rfids
  static const ePerformChainwayInventory = EventChannel('performChainwayInventory');
  @override
  Stream<List<Map<Object?, Object?>>?> performChainwayInventory() {
    debugPrint('Flutter: performChainwayInventory');
    return ePerformChainwayInventory.receiveBroadcastStream().map((event) => List.from(event));
  }

  // clear rfids
  @override
  Future<String?> clearInventory() async {
    final result = await methodChannel.invokeMethod<String>('clearInventory');
    return result;
  }

  // set scanner mode
  @override
  Future<bool?> setScanMode(String scanMode) async {
    final result = await methodChannel.invokeMethod('setScanMode',
      {
        "scanMode": scanMode
      }
    );

    return result;
  }

  // set power level
  @override
  Future<bool?> setScanPower(int scanPower) async {
    final result = await methodChannel.invokeMethod('setScanPower',
      {
        "scanPower": scanPower
      }
    );

    return result;
  }

  // set scanner name
}
