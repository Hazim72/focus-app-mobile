import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../active_session/state/session_state.dart';
import '../../app_selection/state/app_selection_state.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  int _selectedMinutes = 25; // Default Pomodoro duration

  final List<int> _durationOptions = [10, 15, 25, 45, 60];

  @override
  Widget build(BuildContext context) {
    final appSelectionState = ref.watch(appSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Duration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apps will be restricted until the timer finishes.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Duration chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _durationOptions.map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return ChoiceChip(
                    label: Text('$mins min'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedMinutes = mins);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              const Text(
                'Apps to Block',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.apps_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    '${appSelectionState.selectedCount} apps selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    appSelectionState.selectedCount > 0
                        ? 'Tap to customize blocked apps'
                        : 'No apps selected! Tap to select.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () => context.push('/app-selection'),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () async {
                    final targetPackages =
                        ref.read(appSelectionProvider.notifier).selectedPackageNames;

                    if (targetPackages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one app to block.')),
                      );
                      return;
                    }

                    final endTime = DateTime.now().add(Duration(minutes: _selectedMinutes));
                    final success = await ref.read(sessionProvider.notifier).startSession(
                      packages: targetPackages,
                      endTime: endTime,
                    );

                    if (success && context.mounted) {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.lock_clock_rounded),
                  label: Text('Start $_selectedMinutes-Minute Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
