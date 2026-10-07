import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../state/onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned from Android Settings: refresh all checkmarks!
      ref.read(permissionsProvider.notifier).checkAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsProvider);
    final notifier = ref.read(permissionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Required for Blocking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Focus App runs fully offline. Grant these permissions so the app can detect and restrict target apps.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 18),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${permissions.grantedCount} of 4 Granted',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (permissions.allGranted)
                    const Text(
                      'All Set! 🎉',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: permissions.grantedCount / 4,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),

              // Permissions List
              Expanded(
                child: ListView(
                  children: [
                    _PermissionCard(
                      icon: Icons.query_stats_rounded,
                      title: 'Usage Access',
                      description: 'Detects when a blocked app is brought to foreground.',
                      isGranted: permissions.usageAccess,
                      onGrant: () => notifier.requestUsageAccess(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.layers_rounded,
                      title: 'Display Over Other Apps',
                      description: 'Shows the full-screen blocked screen over restricted apps.',
                      isGranted: permissions.overlay,
                      onGrant: () => notifier.requestOverlay(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notifications',
                      description: 'Keeps the background blocking engine alive and responsive.',
                      isGranted: permissions.notification,
                      onGrant: () => notifier.requestNotification(),
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Battery Optimization',
                      description: 'Prevents the phone from killing the background service.',
                      isGranted: permissions.batteryOptimization,
                      onGrant: () => notifier.requestBatteryOptimization(),
                    ),
                  ],
                ),
              ),

              // Continue Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: permissions.criticalGranted
                      ? () => context.go('/')
                      : null,
                  child: Text(
                    permissions.criticalGranted
                        ? 'Continue to Focus App'
                        : 'Grant Critical Permissions to Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onGrant;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? AppColors.success : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isGranted)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, right: 4.0),
                child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              )
            else
              FilledButton(
                onPressed: onGrant,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Grant', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
