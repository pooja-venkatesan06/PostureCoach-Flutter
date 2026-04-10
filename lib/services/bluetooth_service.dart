// PostureCoach BLE Service Layer
// Handles all Bluetooth Low Energy communication with the ESP32 PostureCoach device

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE identifiers for the PostureCoach ESP32 device
class BleConstants {
  static const String deviceName = 'PostureCoach';
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
}

/// Service class managing all BLE operations for PostureCoach
class BluetoothService {
  // Currently connected device
  BluetoothDevice? _connectedDevice;

  // BLE characteristic for posture data notifications
  BluetoothCharacteristic? _postureCharacteristic;

  // Stream subscriptions for cleanup
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // Callback invoked when a posture byte is received (0 or 1)
  void Function(int value)? onPostureDataReceived;

  // Callback invoked when connection state changes
  void Function(bool isConnected)? onConnectionStateChanged;

  // Callback for error messages
  void Function(String error)? onError;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  bool get isConnected =>
      _connectedDevice != null &&
      _connectedDevice!.isConnected;

  /// Starts BLE scan and returns a stream of discovered PostureCoach scan results
  Stream<ScanResult> scanForPostureCoach() {
    // Stop any existing scan first
    FlutterBluePlus.stopScan();

    // Start scanning with 10-second timeout
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withNames: [BleConstants.deviceName],
    );

    // Filter scan results for PostureCoach device
    return FlutterBluePlus.scanResults.expand((results) => results).where(
          (result) => result.device.platformName == BleConstants.deviceName,
        );
  }

  /// Stops an active BLE scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connects to the PostureCoach device and subscribes to posture notifications
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Connect with auto-connect disabled for immediate connection
      await device.connect(autoConnect: false);
      _connectedDevice = device;

      // Listen for connection state changes (handles unexpected disconnects)
      _connectionStateSubscription = device.connectionState.listen(
        (state) {
          final connected = state == BluetoothConnectionState.connected;
          onConnectionStateChanged?.call(connected);

          if (!connected) {
            // Clean up characteristic subscription on disconnect
            _characteristicSubscription?.cancel();
            _postureCharacteristic = null;
          }
        },
      );

      // Discover BLE services on the device
      await _discoverServicesAndSubscribe(device);
    } catch (e) {
      onError?.call('Failed to connect: ${e.toString()}');
      rethrow;
    }
  }

  /// Discovers services and subscribes to posture characteristic notifications
  Future<void> _discoverServicesAndSubscribe(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      // Find the PostureCoach BLE service by UUID
      final targetService = services.firstWhere(
        (s) => s.serviceUuid.toString().toLowerCase() ==
            BleConstants.serviceUuid.toLowerCase(),
        orElse: () => throw Exception(
            'PostureCoach service not found. Make sure device is running correct firmware.'),
      );

      // Find the posture data characteristic
      _postureCharacteristic = targetService.characteristics.firstWhere(
        (c) =>
            c.characteristicUuid.toString().toLowerCase() ==
            BleConstants.characteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Posture characteristic not found.'),
      );

      // Enable notifications so ESP32 pushes data every ~120ms
      await _postureCharacteristic!.setNotifyValue(true);

      // Subscribe to incoming posture data bytes
      _characteristicSubscription =
          _postureCharacteristic!.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            // Parse single byte: 0 = good posture, 1 = slouching
            final byteValue = value[0];
            onPostureDataReceived?.call(byteValue);
          }
        },
      );
    } catch (e) {
      onError?.call('Service discovery failed: ${e.toString()}');
      rethrow;
    }
  }

  /// Disconnects from the currently connected device and cleans up resources
  Future<void> disconnect() async {
    try {
      await _characteristicSubscription?.cancel();
      _characteristicSubscription = null;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _postureCharacteristic = null;
      }
    } catch (e) {
      onError?.call('Disconnect error: ${e.toString()}');
    }
  }

  /// Returns a stream of Bluetooth adapter state changes
  Stream<BluetoothAdapterState> get adapterStateStream =>
      FlutterBluePlus.adapterState;

  /// Returns the current Bluetooth adapter state
  Future<BluetoothAdapterState> get adapterState async =>
      await FlutterBluePlus.adapterState.first;

  /// Cleans up all resources - call when app is closing
  Future<void> dispose() async {
    await disconnect();
  }
}
