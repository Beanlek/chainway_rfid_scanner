import 'dart:async';
import 'dart:io';

import 'package:chainway_rfid_scanner/chainway_rfid_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const R2TestApp());
}

class R2TestApp extends StatelessWidget {
  const R2TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const R2TestPage(),
    );
  }
}

class R2TestPage extends StatefulWidget {
  const R2TestPage({super.key});

  @override
  State<R2TestPage> createState() => _R2TestPageState();
}

class _R2TestPageState extends State<R2TestPage> {
  final ChainwayRfidScanner _scanner = ChainwayRfidScanner();
  final TextEditingController _androidAddressController =
      TextEditingController(text: 'D3:C3:DA:26:34:15');

  late final Stream<List<Map<Object?, Object?>>> _readerStream;
  late final Stream<List<Map<Object?, Object?>>?> _inventoryStream;

  String _platformVersion = 'Initializing';
  String _connectionState = 'Disconnected';
  String? _selectedReaderId;
  bool _busy = false;
  bool _connected = false;
  bool _inventoryRunning = false;
  String _scanMode = 'auto';
  int _power = 20;

  @override
  void initState() {
    super.initState();
    _readerStream = _scanner.discoverReaders();
    _inventoryStream = _scanner.performChainwayInventory();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _androidAddressController.dispose();
    if (Platform.isIOS) {
      unawaited(_scanner.stopDiscovery());
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    await _run(
      () async {
        await _scanner.initReader();
        _platformVersion =
            await _scanner.getPlatformVersion() ?? 'Unknown platform';
        await _scanner.setScanMode(_scanMode);
        if (Platform.isIOS) {
          await _scanner.startDiscovery();
        }
      },
      showBusy: false,
    );
  }

  Future<bool> _ensureAndroidBluetoothPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final statuses = await <Permission>[
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _connect() async {
    final hasPermission = await _ensureAndroidBluetoothPermission();
    if (!hasPermission) {
      _showMessage('Bluetooth permission was denied.');
      return;
    }

    final deviceId = Platform.isIOS
        ? _selectedReaderId
        : _androidAddressController.text.trim();
    if (deviceId == null || deviceId.isEmpty) {
      _showMessage(Platform.isIOS
          ? 'Select a discovered R2 reader first.'
          : 'Enter the R2 Bluetooth address.');
      return;
    }

    await _run(() async {
      _connectionState = 'Connecting';
      _connected = await _scanner.connect(deviceId) ?? false;
      _connectionState =
          await _scanner.getConnectState() ?? 'Unknown connection state';
      if (_connected) {
        _power = await _scanner.getScanPower() ?? _power;
      }
    });
  }

  Future<void> _disconnect() async {
    await _run(() async {
      final disconnected = await _scanner.disconnect() ?? false;
      _connected = !disconnected;
      _inventoryRunning = false;
      _connectionState =
          await _scanner.getConnectState() ?? 'Unknown connection state';
      if (Platform.isIOS) {
        await _scanner.startDiscovery();
      }
    });
  }

  Future<void> _startInventory() async {
    await _run(() async {
      _inventoryRunning = await _scanner.startInventory() ?? false;
    });
  }

  Future<void> _stopInventory() async {
    await _run(() async {
      final stopped = await _scanner.stopInventory() ?? false;
      if (stopped) {
        _inventoryRunning = false;
      }
    });
  }

  Future<void> _clearInventory() async {
    await _run(() => _scanner.clearInventory());
  }

  Future<void> _setPower() async {
    await _run(() async {
      final changed = await _scanner.setScanPower(_power) ?? false;
      if (!changed) {
        throw PlatformException(
          code: 'set_power_failed',
          message: 'The R2 rejected the requested power.',
        );
      }
      _power = await _scanner.getScanPower() ?? _power;
    });
  }

  Future<void> _setScanMode(String? mode) async {
    if (mode == null) {
      return;
    }
    await _run(() async {
      final changed = await _scanner.setScanMode(mode) ?? false;
      if (changed) {
        _scanMode = mode;
      }
    });
  }

  Future<void> _refreshConnectionState() async {
    await _run(() async {
      _connectionState =
          await _scanner.getConnectState() ?? 'Unknown connection state';
      _connected = _connectionState == 'Connected';
    });
  }

  Future<void> _run(
    Future<void> Function() operation, {
    bool showBusy = true,
  }) async {
    if (showBusy && mounted) {
      setState(() => _busy = true);
    }
    try {
      await operation();
    } on PlatformException catch (error) {
      _showMessage(error.message ?? error.code);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chainway R2 Test App'),
        actions: [
          IconButton(
            tooltip: 'Refresh connection state',
            onPressed: _busy ? null : _refreshConnectionState,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildStatusCard(),
                if (!_connected) _buildConnectionPanel(),
                if (_connected) _buildReaderControls(),
                const Divider(height: 1),
                Expanded(child: _buildInventory()),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x55000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 14,
              color: _connected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _connectionState,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(_platformVersion),
                ],
              ),
            ),
            if (_connected)
              FilledButton.tonal(
                onPressed: _busy ? null : _disconnect,
                child: const Text('Disconnect'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPanel() {
    if (Platform.isAndroid) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _androidAddressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'R2 Bluetooth address',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _connect,
              child: const Text('Connect'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                Text(
                  'Nearby R2 readers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Scan again',
                  onPressed: _busy ? null : () => _scanner.startDiscovery(),
                  icon: const Icon(Icons.bluetooth_searching),
                ),
                FilledButton(
                  onPressed:
                      _busy || _selectedReaderId == null ? null : _connect,
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<Object?, Object?>>>(
              stream: _readerStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Discovery: ${snapshot.error}'));
                }
                final readers = snapshot.data ?? const [];
                if (readers.isEmpty) {
                  return const Center(
                    child: Text('Scanning for Chainway BLE readers…'),
                  );
                }
                return ListView.builder(
                  itemCount: readers.length,
                  itemBuilder: (context, index) {
                    final reader = readers[index];
                    final id = reader['id']?.toString() ?? '';
                    final selected = id == _selectedReaderId;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      leading: Icon(selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      title: Text(reader['name']?.toString() ?? 'Unknown R2'),
                      subtitle: Text(
                        '${reader['address'] ?? id} • RSSI ${reader['rssi'] ?? '-'}',
                      ),
                      onTap: () => setState(() => _selectedReaderId = id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _scanMode,
                  decoration: const InputDecoration(labelText: 'Trigger mode'),
                  items: const [
                    DropdownMenuItem(
                      value: 'auto',
                      child: Text('Continuous / toggle'),
                    ),
                    DropdownMenuItem(
                      value: 'single',
                      child: Text('Single tag'),
                    ),
                  ],
                  onChanged: _busy ? null : _setScanMode,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : (_inventoryRunning ? _stopInventory : _startInventory),
                icon: Icon(
                  _inventoryRunning ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(_inventoryRunning ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : _clearInventory,
                child: const Text('Clear'),
              ),
            ],
          ),
          Row(
            children: [
              Text('Power: $_power dBm'),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 30,
                  divisions: 29,
                  value: _power.toDouble(),
                  label: '$_power dBm',
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _power = value.round()),
                ),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _setPower,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return StreamBuilder<List<Map<Object?, Object?>>?>(
      stream: _inventoryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Inventory: ${snapshot.error}'));
        }
        final tags = snapshot.data ?? const [];
        if (tags.isEmpty) {
          return const Center(
            child: Text('Connect and press Start or the R2 trigger.'),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${tags.length} unique tag${tags.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: tags.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final count = tag['readCount'] ?? tag['dupCount'] ?? 1;
                  final rssi = tag['rssi'] ?? tag['info'] ?? '-';
                  return ListTile(
                    leading: const Icon(Icons.nfc),
                    title: Text(tag['epc']?.toString() ?? 'Unknown EPC'),
                    subtitle: Text(
                      'RSSI $rssi'
                      '${(tag['tid']?.toString() ?? '').isEmpty ? '' : ' • TID ${tag['tid']}'}',
                    ),
                    trailing: Text('×$count'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
