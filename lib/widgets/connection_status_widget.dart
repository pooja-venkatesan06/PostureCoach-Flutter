// PostureCoach - Connection Status Widget
// Displays BLE connection state with a blue indicator

import 'package:flutter/material.dart';

/// Compact connection status badge shown in the dashboard app bar / header
class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusWidget({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isConnected ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.blue.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blinking blue dot for connected, grey for disconnected
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.blue.shade600 : Colors.grey.shade400,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withAlpha(102),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isConnected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
