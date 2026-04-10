// PostureCoach - Dashboard Screen
// Main monitoring screen showing real-time posture status after BLE connection

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/posture_provider.dart';
import '../models/posture_model.dart';
import '../widgets/posture_status_widget.dart';
import '../widgets/connection_status_widget.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Watch for unexpected disconnects and offer auto-reconnect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watchConnectionState();
    });
  }

  /// Monitors connection state and shows reconnect dialog on unexpected disconnect
  void _watchConnectionState() {
    context.read<PostureProvider>().addListener(_onProviderUpdate);
  }

  bool _wasConnected = true;

  void _onProviderUpdate() {
    final provider = context.read<PostureProvider>();
    final isConnected = provider.isConnected;

    // Detect transition from connected → disconnected
    if (_wasConnected && !isConnected && mounted) {
      _showDisconnectedDialog();
    }
    _wasConnected = isConnected;
  }

  /// Shows dialog when device disconnects unexpectedly
  void _showDisconnectedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.bluetooth_disabled,
            color: Colors.orange.shade600, size: 48),
        title: const Text('Device Disconnected',
            textAlign: TextAlign.center),
        content: const Text(
          'PostureCoach has disconnected. Would you like to scan for it again?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            },
            child: const Text('Go to Scan'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove listener to avoid callbacks after disposal
    context.read<PostureProvider>().removeListener(_onProviderUpdate);
    super.dispose();
  }

  /// Disconnects and returns to the scan screen
  Future<void> _disconnect() async {
    final provider = context.read<PostureProvider>();
    await provider.disconnect();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
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
        automaticallyImplyLeading: false,
        title: const Text(
          'PostureCoach',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          // Disconnect button in app bar
          TextButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.bluetooth_disabled, color: Colors.white70),
            label: const Text('Disconnect',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Consumer<PostureProvider>(
        builder: (context, provider, _) {
          final data = provider.postureData;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Connection Status ────────────────────────────────────────
                Center(
                  child: ConnectionStatusWidget(isConnected: data.isConnected),
                ),

                const SizedBox(height: 24),

                // ── Main Posture Indicator ───────────────────────────────────
                PostureStatusWidget(postureState: data.state),

                const SizedBox(height: 28),

                // ── Statistics Row ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.orange.shade600,
                        label: 'Slouch Count',
                        value: '${data.slouchCount}',
                        valueColor: data.slouchCount > 0
                            ? Colors.orange.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.access_time_rounded,
                        iconColor: Colors.blue.shade600,
                        label: 'Last Slouch',
                        value: data.lastSlouchEvent != null
                            ? data.lastSlouchEvent!.formattedTime
                            : '—',
                        valueColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Last Slouch Date (full) ───────────────────────────────────
                if (data.lastSlouchEvent != null)
                  _InfoBanner(
                    icon: Icons.history,
                    message:
                        'Last slouch detected at ${data.lastSlouchEvent!.formattedDateTime}',
                  ),

                const SizedBox(height: 20),

                // ── Posture Tips ────────────────────────────────────────────
                _PostureTips(postureState: data.state),

                const SizedBox(height: 20),

                // ── Disconnect Button ────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect from PostureCoach',
                      style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
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

/// Card for displaying a single numeric statistic
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informational banner with an icon and message
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 14, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contextual posture tips based on current state
class _PostureTips extends StatelessWidget {
  final PostureState postureState;

  const _PostureTips({required this.postureState});

  @override
  Widget build(BuildContext context) {
    final tips = _getTips();
    if (tips.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Posture Tips',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 15)),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getTips() {
    switch (postureState) {
      case PostureState.slouching:
        return [
          'Sit back in your chair with your back fully supported.',
          'Keep your shoulders relaxed and pulled back.',
          'Position your screen at eye level to reduce neck strain.',
          'Keep both feet flat on the floor.',
        ];
      case PostureState.good:
        return [
          'Great job! Maintain this posture throughout the day.',
          'Take a short break every 30 minutes to stretch.',
          'Stay hydrated — dehydration can cause muscle fatigue.',
        ];
      case PostureState.unknown:
        return [];
    }
  }
}
