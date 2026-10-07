import 'package:flutter/material.dart';
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
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: AppColors.primary),
              title: Text('Permissions Status'),
              subtitle: Text('Usage access, overlay, and notifications active'),
              trailing: Icon(Icons.check_circle, color: AppColors.success),
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
