// PostureCoach - Unit Tests
// Tests for data models and state logic

import 'package:flutter_test/flutter_test.dart';
import 'package:posturecoach/models/posture_model.dart';

void main() {
  group('PostureData.parseByteValue', () {
    test('returns good for value 0', () {
      expect(PostureData.parseByteValue(0), PostureState.good);
    });

    test('returns slouching for value 1', () {
      expect(PostureData.parseByteValue(1), PostureState.slouching);
    });

    test('returns unknown for unexpected value', () {
      expect(PostureData.parseByteValue(99), PostureState.unknown);
    });
  });

  group('PostureData.copyWith', () {
    test('updates state only', () {
      const data = PostureData(state: PostureState.good, slouchCount: 3);
      final updated = data.copyWith(state: PostureState.slouching);
      expect(updated.state, PostureState.slouching);
      expect(updated.slouchCount, 3);
    });

    test('increments slouch count', () {
      const data = PostureData(slouchCount: 2);
      final updated = data.copyWith(slouchCount: 3);
      expect(updated.slouchCount, 3);
    });

    test('clears last slouch event when clearLastSlouch is true', () {
      final event = SlouchEvent(timestamp: DateTime.now());
      final data = PostureData(lastSlouchEvent: event);
      final updated = data.copyWith(clearLastSlouch: true);
      expect(updated.lastSlouchEvent, isNull);
    });

    test('updates connection status', () {
      const data = PostureData(isConnected: false);
      final updated = data.copyWith(isConnected: true);
      expect(updated.isConnected, true);
    });
  });

  group('SlouchEvent', () {
    test('formattedTime returns HH:MM:SS format', () {
      final event = SlouchEvent(
        timestamp: DateTime(2024, 3, 15, 9, 5, 7),
      );
      expect(event.formattedTime, '09:05:07');
    });

    test('formattedDateTime returns date and time', () {
      final event = SlouchEvent(
        timestamp: DateTime(2024, 3, 15, 9, 5, 7),
      );
      expect(event.formattedDateTime, '15/3/2024 09:05:07');
    });
  });
}
