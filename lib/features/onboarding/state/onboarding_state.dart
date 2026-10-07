import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/native_blocker_service.dart';

class PermissionsState {
  final bool usageAccess;
  final bool overlay;
  final bool notification;
  final bool batteryOptimization;
  final bool isLoading;

  const PermissionsState({
    this.usageAccess = false,
    this.overlay = false,
    this.notification = false,
    this.batteryOptimization = false,
    this.isLoading = true,
  });

  bool get allGranted =>
      usageAccess && overlay && notification && batteryOptimization;

  bool get criticalGranted => usageAccess && overlay;

  int get grantedCount =>
      (usageAccess ? 1 : 0) +
      (overlay ? 1 : 0) +
      (notification ? 1 : 0) +
      (batteryOptimization ? 1 : 0);

  PermissionsState copyWith({
    bool? usageAccess,
    bool? overlay,
    bool? notification,
    bool? batteryOptimization,
    bool? isLoading,
  }) {
    return PermissionsState(
      usageAccess: usageAccess ?? this.usageAccess,
      overlay: overlay ?? this.overlay,
      notification: notification ?? this.notification,
      batteryOptimization: batteryOptimization ?? this.batteryOptimization,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  final NativeBlockerService _service;

  PermissionsNotifier(this._service) : super(const PermissionsState()) {
    checkAll();
  }

  Future<void> checkAll() async {
    final status = await _service.getPermissionsStatus();
    state = state.copyWith(
      usageAccess: status['usageAccess'] ?? false,
      overlay: status['overlay'] ?? false,
      notification: status['notification'] ?? false,
      batteryOptimization: status['batteryOptimization'] ?? false,
      isLoading: false,
    );
  }

  Future<void> requestUsageAccess() async {
    await _service.requestUsageAccess();
    await checkAll();
  }

  Future<void> requestOverlay() async {
    await _service.requestOverlay();
    await checkAll();
  }

  Future<void> requestNotification() async {
    await _service.requestNotification();
    await checkAll();
  }

  Future<void> requestBatteryOptimization() async {
    await _service.requestBatteryOptimization();
    await checkAll();
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  final service = ref.watch(nativeBlockerServiceProvider);
  return PermissionsNotifier(service);
});
