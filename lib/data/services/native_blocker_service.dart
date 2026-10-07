import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeBlockerServiceProvider = Provider<NativeBlockerService>((ref) {
  return NativeBlockerService();
});

/// Single boundary service for Flutter to communicate with native Android blocking.
class NativeBlockerService {
  static const MethodChannel _channel = MethodChannel('com.focusapp.app/blocker');

  /// Starts a focus session with selected app package names and an absolute end time.
  Future<bool> startSession({
    required List<String> packages,
    required DateTime endTime,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('startSession', {
        'packages': packages,
        // Rule: Always store session end time as an absolute timestamp, never minutes left.
        'endTimeEpochMs': endTime.millisecondsSinceEpoch,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeBlockerService: startSession error: ${e.message}');
      return false;
    }
  }

  /// Stops the active focus session immediately, unblocking all apps.
  Future<bool> stopSession() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('stopSession');
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeBlockerService: stopSession error: ${e.message}');
      return false;
    }
  }

  /// Checks if a focus blocking session is currently running in the background.
  Future<bool> isSessionActive() async {
    try {
      final bool? active = await _channel.invokeMethod<bool>('isSessionActive');
      return active ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks whether both required permissions (Usage Access + Overlay) are granted.
  Future<bool> hasPermissions() async {
    try {
      final bool? has = await _channel.invokeMethod<bool>('hasPermissions');
      return has ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns detailed status for all 4 permissions.
  Future<Map<String, bool>> getPermissionsStatus() async {
    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getPermissionsStatus');
      if (res == null) return {};
      return res.map((key, value) => MapEntry(key.toString(), value as bool));
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeBlockerService: getPermissionsStatus error: ${e.message}');
      return {};
    }
  }

  Future<void> requestUsageAccess() async {
    try {
      await _channel.invokeMethod('requestUsageAccess');
    } catch (_) {}
  }

  Future<void> requestOverlay() async {
    try {
      await _channel.invokeMethod('requestOverlay');
    } catch (_) {}
  }

  Future<void> requestNotification() async {
    try {
      await _channel.invokeMethod('requestNotification');
    } catch (_) {}
  }

  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  /// Prompts the user with system settings to grant missing permissions.
  Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeBlockerService: requestPermissions error: ${e.message}');
    }
  }
}
