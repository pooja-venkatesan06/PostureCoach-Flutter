// PostureCoach - Posture Status Widget
// Large visual indicator for current posture state with pulsing animation for slouching

import 'package:flutter/material.dart';
import '../models/posture_model.dart';

/// Widget displaying the current posture state with icon, color, and animation
class PostureStatusWidget extends StatefulWidget {
  final PostureState postureState;

  const PostureStatusWidget({super.key, required this.postureState});

  @override
  State<PostureStatusWidget> createState() => _PostureStatusWidgetState();
}

class _PostureStatusWidgetState extends State<PostureStatusWidget>
    with SingleTickerProviderStateMixin {
  // Animation controller for the pulsing red alert when slouching
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulsing if already in slouching state
    if (widget.postureState == PostureState.slouching) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PostureStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Toggle animation based on posture state changes
    if (widget.postureState == PostureState.slouching) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _buildStatusContent(),
    );
  }

  Widget _buildStatusContent() {
    switch (widget.postureState) {
      case PostureState.good:
        return _buildGoodPostureIndicator();
      case PostureState.slouching:
        return _buildSlouchingIndicator();
      case PostureState.unknown:
        return _buildUnknownIndicator();
    }
  }

  /// Green indicator for good posture
  Widget _buildGoodPostureIndicator() {
    return Container(
      key: const ValueKey('good'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(51),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 96, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(
            'Good Posture!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep it up! Your posture is excellent.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  /// Red pulsing indicator for slouching
  Widget _buildSlouchingIndicator() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        key: const ValueKey('slouching'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(77),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 96, color: Colors.red.shade600),
            const SizedBox(height: 16),
            Text(
              'Slouching!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sit up straight and correct your posture.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Grey indicator shown before data is received
  Widget _buildUnknownIndicator() {
    return Container(
      key: const ValueKey('unknown'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors, size: 96, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Waiting for data...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receiving posture data from PostureCoach.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
