import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredSession {
  final bool isActive;
  final DateTime startTime;
  final DateTime endTime;
  final int initialDurationMinutes;
  final List<String> blockedPackages;

  const StoredSession({
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.initialDurationMinutes,
    required this.blockedPackages,
  });
}

class SessionStorageService {
  static const String _keyIsActive = 'session_is_active';
  static const String _keyStartTime = 'session_start_time_epoch_ms';
  static const String _keyEndTime = 'session_end_time_epoch_ms';
  static const String _keyInitialDuration = 'session_initial_duration_minutes';
  static const String _keyBlockedPackages = 'session_blocked_packages';
  static const String _keyCompletedCount = 'stats_completed_sessions_count';
  static const String _keyTotalFocusMins = 'stats_total_focus_minutes';

  Future<void> saveActiveSession({
    required DateTime startTime,
    required DateTime endTime,
    required int initialDurationMinutes,
    required List<String> blockedPackages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsActive, true);
    await prefs.setInt(_keyStartTime, startTime.millisecondsSinceEpoch);
    await prefs.setInt(_keyEndTime, endTime.millisecondsSinceEpoch);
    await prefs.setInt(_keyInitialDuration, initialDurationMinutes);
    await prefs.setStringList(_keyBlockedPackages, blockedPackages);
  }

  Future<StoredSession?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_keyIsActive) ?? false;
    final endMs = prefs.getInt(_keyEndTime);

    if (!isActive || endMs == null) {
      return null;
    }

    final startMs = prefs.getInt(_keyStartTime) ?? DateTime.now().millisecondsSinceEpoch;
    final duration = prefs.getInt(_keyInitialDuration) ?? 25;
    final packages = prefs.getStringList(_keyBlockedPackages) ?? [];

    return StoredSession(
      isActive: true,
      startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
      endTime: DateTime.fromMillisecondsSinceEpoch(endMs),
      initialDurationMinutes: duration,
      blockedPackages: packages,
    );
  }

  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsActive, false);
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyEndTime);
    await prefs.remove(_keyInitialDuration);
    await prefs.remove(_keyBlockedPackages);
  }

  Future<void> recordCompletedSession(int durationMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyCompletedCount) ?? 0;
    final mins = prefs.getInt(_keyTotalFocusMins) ?? 0;

    await prefs.setInt(_keyCompletedCount, count + 1);
    await prefs.setInt(_keyTotalFocusMins, mins + durationMinutes);
  }

  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyCompletedCount) ?? 0;
    final mins = prefs.getInt(_keyTotalFocusMins) ?? 0;
    return {
      'completedSessions': count,
      'totalFocusMinutes': mins,
    };
  }

  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompletedCount);
    await prefs.remove(_keyTotalFocusMins);
  }
}

final sessionStorageServiceProvider = Provider<SessionStorageService>((ref) {
  return SessionStorageService();
});

final focusStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final storage = ref.watch(sessionStorageServiceProvider);
  return storage.getStats();
});
