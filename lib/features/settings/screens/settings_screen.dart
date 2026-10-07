import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/native_blocker_service.dart';
import '../../../data/services/session_storage_service.dart';
import '../../app_selection/state/app_selection_state.dart';

final permissionsStatusProvider =
    FutureProvider.autoDispose<Map<String, bool>>((ref) async {
  final service = ref.watch(nativeBlockerServiceProvider);
  return service.getPermissionsStatus();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmResetData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Focus Data?'),
        content: const Text(
          'This will clear your completed sessions history and reset focus stats to zero.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final storage = ref.read(sessionStorageServiceProvider);
              await storage.clearActiveSession();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Focus data reset successfully.')),
                );
              }
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(permissionsStatusProvider);
    final appSelectionState = ref.watch(appSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: Device & Permissions
          const Text(
            'PERMISSIONS & PRIVACY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              onTap: () async {
                await context.push('/onboarding');
                ref.invalidate(permissionsStatusProvider);
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary),
              ),
              title: const Text(
                'Permissions & System Setup',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Usage access, overlay, notifications & battery',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: permsAsync.when(
                data: (perms) {
                  final allGranted =
                      perms.values.isNotEmpty && perms.values.every((v) => v);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (allGranted ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      allGranted ? 'All Set' : 'Check',
                      style: TextStyle(
                        color: allGranted ? AppColors.success : AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: App Management
          const Text(
            'BLOCKING PREFERENCES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              onTap: () => context.push('/app-selection'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apps_rounded, color: AppColors.secondary),
              ),
              title: const Text(
                'Configure Distraction Apps',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${appSelectionState.selectedCount} apps currently selected',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Data & Storage
          const Text(
            'DATA & STORAGE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              onTap: () => _confirmResetData(context, ref),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
              title: const Text(
                'Reset Focus History',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Clear completed session records and offline stats',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
          ),

          const SizedBox(height: 24),

          // Section: About
          const Text(
            'ABOUT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus App',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Milestone 2 — Full Offline App Core',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Focus App runs 100% locally on your Android device. It uses native Android UsageStatsManager and WindowManager overlay to block distracting apps without sending any personal data to external servers.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
