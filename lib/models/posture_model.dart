// PostureCoach Data Models
// Defines data structures used throughout the app

/// Represents the current posture state received from the ESP32
enum PostureState {
  good,      // Value 0 from BLE - good posture
  slouching, // Value 1 from BLE - slouching detected
  unknown,   // Initial state before data is received
}

/// Represents a single slouch event with a timestamp
class SlouchEvent {
  final DateTime timestamp;

  const SlouchEvent({required this.timestamp});

  /// Returns a human-readable time string for the event
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Returns formatted date + time string
  String get formattedDateTime {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${formattedTime}';
  }
}

/// Represents the overall posture data model maintained by the provider
class PostureData {
  final PostureState state;
  final int slouchCount;
  final SlouchEvent? lastSlouchEvent;
  final bool isConnected;

  const PostureData({
    this.state = PostureState.unknown,
    this.slouchCount = 0,
    this.lastSlouchEvent,
    this.isConnected = false,
  });

  /// Creates a copy with updated fields
  PostureData copyWith({
    PostureState? state,
    int? slouchCount,
    SlouchEvent? lastSlouchEvent,
    bool? isConnected,
    bool clearLastSlouch = false,
  }) {
    return PostureData(
      state: state ?? this.state,
      slouchCount: slouchCount ?? this.slouchCount,
      lastSlouchEvent: clearLastSlouch ? null : (lastSlouchEvent ?? this.lastSlouchEvent),
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Parse raw BLE byte value (0 = good, 1 = slouching)
  static PostureState parseByteValue(int value) {
    if (value == 1) return PostureState.slouching;
    if (value == 0) return PostureState.good;
    return PostureState.unknown;
  }
}
