import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../state/app_selection_state.dart';

class AppSelectionScreen extends ConsumerWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appSelectionProvider);
    final notifier = ref.read(appSelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => notifier.toggleApp(app.package),
              leading: CircleAvatar(
                backgroundColor: app.isBlocked
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                foregroundColor: Colors.white,
                child: Text(
                  app.name[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                app.name,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                app.package,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: Switch(
                value: app.isBlocked,
                activeColor: AppColors.primary,
                onChanged: (_) => notifier.toggleApp(app.package),
              ),
            ),
          );
        },
      ),
    );
  }
}
