import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              onTap: () => context.push('/onboarding'),
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Permissions & Setup'),
              subtitle: const Text('Manage Usage Access, Overlay, Notifications & Battery'),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: Text('About Focus App'),
              subtitle: Text('Version 1.0.0 (Offline Mode)'),
            ),
          ),
        ],
      ),
    );
  }
}
