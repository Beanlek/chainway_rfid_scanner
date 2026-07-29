# chainway_rfid_scanner

Flutter integration for Chainway Bluetooth UHF RFID readers.

## Supported platforms

- Android: existing Chainway `RFIDWithUHFBLE` integration.
- iOS 13 or later: Chainway R2 over Bluetooth Low Energy.

The iOS implementation uses the transport/parser source supplied in Chainway's
February 2024 `demo-uhf-ble_ios` package.

## iOS setup

Add a Bluetooth usage description to the consuming application's
`ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is used to connect to the Chainway R2 RFID reader.</string>
```

The included example already contains this configuration. Bluetooth permission
is requested by CoreBluetooth when discovery starts.

## Basic usage

```dart
final scanner = ChainwayRfidScanner();

await scanner.initReader();

// On iOS, discover the R2 and pass its opaque `id` to connect.
final readers = await scanner
    .discoverReaders()
    .firstWhere((readers) => readers.isNotEmpty);
await scanner.connect(readers.first['id']! as String);

await scanner.setScanPower(20);
await scanner.startInventory();

final subscription = scanner.performChainwayInventory().listen((tags) {
  for (final tag in tags ?? const []) {
    print('${tag['epc']} RSSI=${tag['rssi']} reads=${tag['readCount']}');
  }
});

await scanner.stopInventory();
await subscription.cancel();
await scanner.disconnect();
```

On Android, `connect` continues to accept the reader's Bluetooth MAC address.

## Inventory controls

Inventory can be controlled from Flutter with `startInventory` and
`stopInventory`, or from the physical R2 trigger:

- `auto`: keys 1/2 toggle inventory, key 3 starts, and key 4 stops.
- `single`: keys 1/2/3 perform one inventory operation.

Power is expressed in dBm and must be between 1 and 30.

## Example and hardware test

This repository pins Flutter 3.44.8 through FVM for current iOS and Xcode
compatibility. Install the pinned SDK once with `fvm install`.

Run the interactive test application on a physical iPhone:

```sh
cd example
fvm flutter run -d <iphone-device-id>
```

The app supports discovery, connection, software and hardware-triggered
inventory, power configuration, tag counts, RSSI, and disconnect/reconnect.

With an R2 powered on and RFID tags nearby, run the opt-in hardware integration
test. `fvm flutter drive` supports both USB and wirelessly connected iPhones:

```sh
cd example
fvm flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/r2_hardware_test.dart \
  -d <iphone-device-id> \
  --dart-define=RUN_R2_HARDWARE_TESTS=true \
  --dart-define=R2_DEVICE_NAME=UR-6486
```

`R2_DEVICE_NAME` defaults to `R2` and can be omitted when the advertised name
contains that value. The hardware test is skipped by default so normal CI does
not require a reader.

For physical-device deployment, open `example/ios/Runner.xcworkspace`, enable
**Automatically manage signing**, and select a development team that has a
valid Apple Development certificate. If the iPhone is connected wirelessly,
the macOS application running Flutter also needs Local Network permission for
mDNS; using a USB cable avoids that wireless requirement.
