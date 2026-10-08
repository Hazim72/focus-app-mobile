import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/native_blocker_service.dart';
import '../../../data/services/session_storage_service.dart';

class SessionState {
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final int initialDurationMinutes;
  final List<String> blockedPackages;
  final int remainingSeconds;
  final double progress; // 0.0 (just started) to 1.0 (completed)
  final bool hasPermissions;
  final bool isCompleted;

  const SessionState({
    this.isActive = false,
    this.startTime,
    this.endTime,
    this.initialDurationMinutes = 25,
    this.blockedPackages = const [],
    this.remainingSeconds = 0,
    this.progress = 0.0,
    this.hasPermissions = false,
    this.isCompleted = false,
  });

  SessionState copyWith({
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    int? initialDurationMinutes,
    List<String>? blockedPackages,
    int? remainingSeconds,
    double? progress,
    bool? hasPermissions,
    bool? isCompleted,
  }) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialDurationMinutes:
          initialDurationMinutes ?? this.initialDurationMinutes,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      progress: progress ?? this.progress,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final NativeBlockerService _service;
  final SessionStorageService _storage;
  final Ref _ref;
  Timer? _tickerTimer;

  SessionNotifier(this._service, this._storage, this._ref)
      : super(const SessionState()) {
    refresh();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final isNativeActive = await _service.isSessionActive();
    final hasPerms = await _service.hasPermissions();
    final stored = await _storage.getActiveSession();

    if (stored != null) {
      final now = DateTime.now();

      if (now.isBefore(stored.endTime)) {
        // Session is still ongoing: resume state and start countdown timer
        final remaining = stored.endTime.difference(now).inSeconds;
        final totalSeconds =
            stored.endTime.difference(stored.startTime).inSeconds;
        final progress = totalSeconds > 0
            ? (1.0 - (remaining / totalSeconds)).clamp(0.0, 1.0)
            : 0.0;

        state = state.copyWith(
          isActive: true,
          startTime: stored.startTime,
          endTime: stored.endTime,
          initialDurationMinutes: stored.initialDurationMinutes,
          blockedPackages: stored.blockedPackages,
          remainingSeconds: remaining,
          progress: progress,
          hasPermissions: hasPerms,
          isCompleted: false,
        );

        _startTicker(stored.endTime, stored.startTime);
        return;
      } else {
        // Session finished while app was closed: finalize and clean up
        await _service.stopSession();
        await _storage.recordCompletedSession(stored.initialDurationMinutes);
        await _storage.clearActiveSession();
        _ref.invalidate(focusStatsProvider);

        state = state.copyWith(
          isActive: false,
          remainingSeconds: 0,
          progress: 1.0,
          hasPermissions: hasPerms,
          isCompleted: true,
        );
        return;
      }
    }

    state = state.copyWith(
      isActive: isNativeActive,
      hasPermissions: hasPerms,
    );
  }

  Future<bool> startSession({
    required List<String> packages,
    required DateTime endTime,
    int? initialDurationMinutes,
  }) async {
    final now = DateTime.now();
    final durationMins = initialDurationMinutes ??
        endTime.difference(now).inMinutes.clamp(1, 1440);

    final success = await _service.startSession(
      packages: packages,
      endTime: endTime,
    );

    if (success) {
      await _storage.saveActiveSession(
        startTime: now,
        endTime: endTime,
        initialDurationMinutes: durationMins,
        blockedPackages: packages,
      );

      final totalSeconds = endTime.difference(now).inSeconds;

      state = state.copyWith(
        isActive: true,
        startTime: now,
        endTime: endTime,
        initialDurationMinutes: durationMins,
        blockedPackages: packages,
        remainingSeconds: totalSeconds,
        progress: 0.0,
        isCompleted: false,
      );

      _startTicker(endTime, now);
    }
    return success;
  }

  Future<bool> stopSession() async {
    _tickerTimer?.cancel();

    // Calculate actual elapsed focus time
    final now = DateTime.now();
    final stored = await _storage.getActiveSession();
    final effectiveStartTime = state.startTime ?? stored?.startTime;

    if (effectiveStartTime != null) {
      final elapsedSeconds = now.difference(effectiveStartTime).inSeconds;
      // If user focused for at least 30 seconds, credit it to focus stats
      if (elapsedSeconds >= 30) {
        final elapsedMinutes = (elapsedSeconds / 60).round();
        final minsToRecord = elapsedMinutes > 0 ? elapsedMinutes : 1;
        await _storage.recordCompletedSession(minsToRecord);
        _ref.invalidate(focusStatsProvider);
      }
    }

    final success = await _service.stopSession();
    await _storage.clearActiveSession();

    state = state.copyWith(
      isActive: false,
      startTime: null,
      endTime: null,
      remainingSeconds: 0,
      progress: 0.0,
      isCompleted: false,
    );
    return success;
  }

  void acknowledgeCompleted() {
    state = state.copyWith(isCompleted: false);
  }

  Future<void> requestPermissions() async {
    await _service.requestPermissions();
    await refresh();
  }

  void _startTicker(DateTime endTime, DateTime startTime) {
    _tickerTimer?.cancel();
    _tick(endTime, startTime);
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick(endTime, startTime);
    });
  }

  void _tick(DateTime endTime, DateTime startTime) {
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      _tickerTimer?.cancel();
      _handleSessionCompleted();
    } else {
      final remaining = endTime.difference(now).inSeconds;
      final totalSeconds = endTime.difference(startTime).inSeconds;
      final progress = totalSeconds > 0
          ? (1.0 - (remaining / totalSeconds)).clamp(0.0, 1.0)
          : 0.0;

      state = state.copyWith(
        remainingSeconds: remaining,
        progress: progress,
      );
    }
  }

  Future<void> _handleSessionCompleted() async {
    await _service.stopSession();
    await _storage.recordCompletedSession(state.initialDurationMinutes);
    await _storage.clearActiveSession();
    _ref.invalidate(focusStatsProvider);

    state = state.copyWith(
      isActive: false,
      remainingSeconds: 0,
      progress: 1.0,
      isCompleted: true,
    );
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final service = ref.watch(nativeBlockerServiceProvider);
  final storage = ref.watch(sessionStorageServiceProvider);
  return SessionNotifier(service, storage, ref);
});
