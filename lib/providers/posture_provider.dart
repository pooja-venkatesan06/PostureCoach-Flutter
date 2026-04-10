// PostureCoach State Management - Provider
// Manages posture data state and BLE connection lifecycle

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/posture_model.dart';
import '../services/bluetooth_service.dart';

/// Provider that manages all posture monitoring state and BLE interactions
class PostureProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();

  // Current posture data (state, counter, last slouch, connection)
  PostureData _postureData = const PostureData();

  // BLE scan results - list of discovered PostureCoach devices
  final List<ScanResult> _scanResults = [];

  // Whether a BLE scan is currently active
  bool _isScanning = false;

  // Whether a connection attempt is in progress
  bool _isConnecting = false;

  // User-facing error message (null when no error)
  String? _errorMessage;

  // Previous posture state for detecting state transitions (slouch start/end)
  PostureState _previousState = PostureState.unknown;

  // Subscription to the scan results stream
  StreamSubscription<ScanResult>? _scanSubscription;

  // ─── Getters ────────────────────────────────────────────────────────────────

  PostureData get postureData => _postureData;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _postureData.isConnected;
  String? get errorMessage => _errorMessage;

  PostureProvider() {
    // Wire up BLE service callbacks to provider state updates
    _bluetoothService.onPostureDataReceived = _handlePostureData;
    _bluetoothService.onConnectionStateChanged = _handleConnectionStateChange;
    _bluetoothService.onError = _handleError;
  }

  // ─── BLE Scanning ───────────────────────────────────────────────────────────

  /// Starts scanning for nearby PostureCoach BLE devices
  Future<void> startScan() async {
    _clearError();
    _scanResults.clear();
    _isScanning = true;
    notifyListeners();

    try {
      // Check Bluetooth adapter state before scanning
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _setError('Bluetooth is not enabled. Please turn on Bluetooth.');
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Listen to scan results stream
      _scanSubscription?.cancel();
      _scanSubscription = _bluetoothService.scanForPostureCoach().listen(
        (result) {
          // Avoid duplicates - update existing entry if already found
          final existingIndex = _scanResults.indexWhere(
            (r) => r.device.remoteId == result.device.remoteId,
          );
          if (existingIndex >= 0) {
            _scanResults[existingIndex] = result;
          } else {
            _scanResults.add(result);
          }
          notifyListeners();
        },
        onDone: () {
          // Scan completed (timeout reached)
          _isScanning = false;
          notifyListeners();
        },
        onError: (error) {
          _setError('Scan failed: ${error.toString()}');
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Could not start scan: ${e.toString()}');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stops the current BLE scan
  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  // ─── BLE Connection ─────────────────────────────────────────────────────────

  /// Connects to the given PostureCoach BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    _clearError();
    _isConnecting = true;
    notifyListeners();

    // Stop scanning before connecting
    await stopScan();

    try {
      await _bluetoothService.connectToDevice(device);
      // Connection state updates come via onConnectionStateChanged callback
    } catch (e) {
      _setError('Connection failed: ${e.toString()}');
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Disconnects from the connected device and resets posture state
  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    _postureData = const PostureData(isConnected: false);
    _previousState = PostureState.unknown;
    notifyListeners();
  }

  // ─── Callbacks from BLE Service ─────────────────────────────────────────────

  /// Handles incoming posture byte from ESP32 (0 = good, 1 = slouching)
  void _handlePostureData(int value) {
    final newState = PostureData.parseByteValue(value);
    int newSlouchCount = _postureData.slouchCount;
    SlouchEvent? newSlouchEvent = _postureData.lastSlouchEvent;

    // Detect transition from good/unknown → slouching (increment counter)
    if (newState == PostureState.slouching &&
        _previousState != PostureState.slouching) {
      newSlouchCount++;
      newSlouchEvent = SlouchEvent(timestamp: DateTime.now());
    }

    _previousState = newState;
    _postureData = _postureData.copyWith(
      state: newState,
      slouchCount: newSlouchCount,
      lastSlouchEvent: newSlouchEvent,
    );
    notifyListeners();
  }

  /// Handles BLE connection state changes
  void _handleConnectionStateChange(bool isConnected) {
    _isConnecting = false;
    _postureData = _postureData.copyWith(isConnected: isConnected);

    if (!isConnected) {
      // Reset posture state on disconnect
      _previousState = PostureState.unknown;
      _postureData = _postureData.copyWith(
        state: PostureState.unknown,
        isConnected: false,
      );
    }

    notifyListeners();
  }

  /// Handles errors from the BLE service
  void _handleError(String error) {
    _setError(error);
    _isConnecting = false;
    notifyListeners();
  }

  // ─── Error Handling ─────────────────────────────────────────────────────────

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clears the current error message (called from UI after displaying error)
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}
