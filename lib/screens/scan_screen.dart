// PostureCoach - Scan Screen
// Scans for nearby PostureCoach BLE devices and shows connect button

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/posture_provider.dart';
import 'dashboard_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions and start initial scan after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndScan();
    });
  }

  /// Requests required BLE permissions then starts scanning
  Future<void> _requestPermissionsAndScan() async {
    if (Platform.isAndroid) {
      // Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final denied = statuses.values.any(
        (s) => s == PermissionStatus.denied || s == PermissionStatus.permanentlyDenied,
      );

      if (denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bluetooth permissions are required to find PostureCoach.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (mounted) {
      await context.read<PostureProvider>().startScan();
    }
  }

  /// Connects to selected device and navigates to dashboard
  Future<void> _connectToDevice(BluetoothDevice device) async {
    final provider = context.read<PostureProvider>();
    await provider.connectToDevice(device);

    if (provider.isConnected && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'PostureCoach',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          // Bluetooth adapter state icon
          StreamBuilder<BluetoothAdapterState>(
            stream: FlutterBluePlus.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final isOn = state == BluetoothAdapterState.on;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                  color: isOn ? Colors.lightBlueAccent : Colors.grey.shade300,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PostureProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.bluetooth_searching,
                          size: 64, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Find Your PostureCoach',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure your PostureCoach device is powered on and nearby.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Error Message ───────────────────────────────────────────
                if (provider.errorMessage != null)
                  _ErrorBanner(
                    message: provider.errorMessage!,
                    onDismiss: provider.clearError,
                  ),

                // ── Scan Button ─────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: provider.isScanning
                      ? () => provider.stopScan()
                      : _requestPermissionsAndScan,
                  icon: provider.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    provider.isScanning ? 'Scanning...' : 'Scan for Device',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Results List ────────────────────────────────────────────
                Expanded(
                  child: provider.scanResults.isEmpty
                      ? _EmptyResultsView(isScanning: provider.isScanning)
                      : ListView.separated(
                          itemCount: provider.scanResults.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final result = provider.scanResults[index];
                            return _DeviceCard(
                              scanResult: result,
                              isConnecting: provider.isConnecting,
                              onConnect: () =>
                                  _connectToDevice(result.device),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Card displayed for a discovered PostureCoach device
class _DeviceCard extends StatelessWidget {
  final ScanResult scanResult;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.scanResult,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final rssi = scanResult.rssi;
    final signalLabel = _rssiLabel(rssi);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // BLE device icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sensors, color: Colors.blue.shade600, size: 32),
            ),
            const SizedBox(width: 16),

            // Device name + signal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanResult.device.platformName.isNotEmpty
                        ? scanResult.device.platformName
                        : 'Unknown Device',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt,
                          size: 16, color: _rssiColor(rssi)),
                      const SizedBox(width: 4),
                      Text(
                        '$rssi dBm • $signalLabel',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Connect button
            FilledButton(
              onPressed: isConnecting ? null : onConnect,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              child: isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  /// Human-readable RSSI strength label
  String _rssiLabel(int rssi) {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -70) return 'Good';
    if (rssi >= -80) return 'Fair';
    return 'Weak';
  }

  /// Color-coded RSSI indicator
  Color _rssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }
}

/// Shown when no scan results are found yet
class _EmptyResultsView extends StatelessWidget {
  final bool isScanning;

  const _EmptyResultsView({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScanning ? Icons.radar : Icons.device_unknown,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isScanning
                ? 'Searching for PostureCoach...'
                : 'No devices found.\nTap "Scan for Device" to search.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Red dismissible error banner
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red.shade400,
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
