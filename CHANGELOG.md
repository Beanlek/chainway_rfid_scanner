## 0.1.0

* Added Chainway R2 support for iOS 13 and later.
* Added iOS reader discovery and Bluetooth lifecycle handling.
* Added software inventory start/stop controls and batched tag updates.
* Added the interactive R2 test app and opt-in hardware integration test.
* Added reliable discovery for advertising and already-connected R2 readers.
* Delayed iOS connection readiness until the BLE UART characteristics are ready.
* Fixed iOS power and disconnect result types.
* Verified discovery, connection, power configuration, inventory, and disconnect
  on a physical Chainway R2.
* Corrected Android scan-mode and power validation.
