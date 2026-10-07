import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../state/app_selection_state.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSelectionProvider);
    final notifier = ref.read(appSelectionProvider.notifier);
    final filteredApps = state.filteredApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh apps',
            onPressed: state.isLoading ? null : () => notifier.loadInstalledApps(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => notifier.setSearchQuery(query),
              decoration: InputDecoration(
                hintText: 'Search installed apps...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          notifier.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Quick action toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${state.selectedCount} selected',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.apps.length} total apps',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: state.isLoading ? null : () => notifier.selectAll(),
                  child: const Text('Select All', style: TextStyle(fontSize: 13)),
                ),
                TextButton(
                  onPressed: state.isLoading ? null : () => notifier.deselectAll(),
                  child: const Text('Clear', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // App List Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Scanning installed apps...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                if (state.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () => notifier.loadInstalledApps(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredApps.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No apps found matching "${_searchController.text}"'
                                : 'No installed apps found',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: app.isBlocked
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => notifier.toggleApp(app.package),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              // App Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.surfaceVariant,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: app.iconBytes != null
                                    ? Image.memory(
                                        app.iconBytes!,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.medium,
                                        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(app),
                                      )
                                    : _buildFallbackAvatar(app),
                              ),
                              const SizedBox(width: 14),

                              // App Title & Package
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      app.package,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Toggle Switch
                              Switch(
                                value: app.isBlocked,
                                activeThumbColor: AppColors.primary,
                                onChanged: (_) => notifier.toggleApp(app.package),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Done Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceVariant, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    state.selectedCount == 0
                        ? 'Done (No apps selected)'
                        : 'Done (${state.selectedCount} Apps Selected)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(BlockableApp app) {
    return Center(
      child: Text(
        app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
