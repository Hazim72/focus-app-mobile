import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/native_blocker_service.dart';

class SessionState {
  final bool isActive;
  final DateTime? endTime;
  final List<String> blockedPackages;
  final bool hasPermissions;

  const SessionState({
    this.isActive = false,
    this.endTime,
    this.blockedPackages = const [],
    this.hasPermissions = false,
  });

  SessionState copyWith({
    bool? isActive,
    DateTime? endTime,
    List<String>? blockedPackages,
    bool? hasPermissions,
  }) {
    return SessionState(
      isActive: isActive ?? this.isActive,
      endTime: endTime ?? this.endTime,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      hasPermissions: hasPermissions ?? this.hasPermissions,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final NativeBlockerService _service;

  SessionNotifier(this._service) : super(const SessionState()) {
    refresh();
  }

  Future<void> refresh() async {
    final isActive = await _service.isSessionActive();
    final hasPermissions = await _service.hasPermissions();
    state = state.copyWith(
      isActive: isActive,
      hasPermissions: hasPermissions,
    );
  }

  Future<bool> startSession({
    required List<String> packages,
    required DateTime endTime,
  }) async {
    final success = await _service.startSession(
      packages: packages,
      endTime: endTime,
    );
    if (success) {
      state = state.copyWith(
        isActive: true,
        endTime: endTime,
        blockedPackages: packages,
      );
    }
    return success;
  }

  Future<bool> stopSession() async {
    final success = await _service.stopSession();
    if (success) {
      state = state.copyWith(
        isActive: false,
        endTime: null,
      );
    }
    return success;
  }

  Future<void> requestPermissions() async {
    await _service.requestPermissions();
    await refresh();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final service = ref.watch(nativeBlockerServiceProvider);
  return SessionNotifier(service);
});
