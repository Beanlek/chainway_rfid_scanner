# Chainway R2 iOS source

The Objective-C files in this directory are the transport and parser classes
from Chainway's `demo-uhf-ble_ios` package dated February 2024. They remain
copyright Chainway and are used by this private Flutter plugin for R2 BLE
communication.

Only the classes required for Bluetooth discovery, connection, UHF inventory,
hardware-key events, and reader power configuration are included. The vendor
demo application's UI, firmware images, barcode screens, and tag-writing
screens are intentionally excluded.

Local changes:

- Bluetooth scanning can be stopped independently of disconnecting.
- The parsed hardware-key code is passed to the delegate.
- Verbose packet logging is disabled.
