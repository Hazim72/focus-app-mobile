import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/native_blocker_service.dart';

class BlockableApp {
  final String name;
  final String package;
  final Uint8List? iconBytes;
  final bool isBlocked;
  final bool isSystemApp;

  const BlockableApp({
    required this.name,
    required this.package,
    this.iconBytes,
    this.isBlocked = false,
    this.isSystemApp = false,
  });

  BlockableApp copyWith({
    String? name,
    String? package,
    Uint8List? iconBytes,
    bool? isBlocked,
    bool? isSystemApp,
  }) {
    return BlockableApp(
      name: name ?? this.name,
      package: package ?? this.package,
      iconBytes: iconBytes ?? this.iconBytes,
      isBlocked: isBlocked ?? this.isBlocked,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }
}

class AppSelectionState {
  final List<BlockableApp> apps;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const AppSelectionState({
    this.apps = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<BlockableApp> get filteredApps {
    if (searchQuery.trim().isEmpty) {
      return apps;
    }
    final query = searchQuery.trim().toLowerCase();
    return apps.where((app) {
      return app.name.toLowerCase().contains(query) ||
          app.package.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get selectedPackageNames {
    return apps.where((app) => app.isBlocked).map((app) => app.package).toList();
  }

  int get selectedCount => apps.where((app) => app.isBlocked).length;

  AppSelectionState copyWith({
    List<BlockableApp>? apps,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return AppSelectionState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppSelectionNotifier extends StateNotifier<AppSelectionState> {
  final NativeBlockerService _blockerService;

  static const Set<String> _defaultDistractingApps = {
    'com.instagram.android',
    'com.whatsapp',
    'com.android.chrome',
    'com.google.android.youtube',
    'com.snapchat.android',
    'com.zhiliaoapp.musically',
    'com.facebook.katana',
    'com.twitter.android',
    'com.reddit.frontpage',
  };

  AppSelectionNotifier(this._blockerService) : super(const AppSelectionState(isLoading: true)) {
    loadInstalledApps();
  }

  List<String> get selectedPackageNames => state.selectedPackageNames;

  Future<void> loadInstalledApps() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rawApps = await _blockerService.getInstalledApps();

      final previouslyBlocked = state.apps.isNotEmpty
          ? state.apps.where((a) => a.isBlocked).map((a) => a.package).toSet()
          : null;

      final apps = rawApps.map((map) {
        final pkg = map['packageName'] as String? ?? '';
        final name = map['name'] as String? ?? pkg;
        final icon = map['icon'] as Uint8List?;
        final isSystem = map['isSystemApp'] as bool? ?? false;

        final isBlocked = previouslyBlocked != null
            ? previouslyBlocked.contains(pkg)
            : _defaultDistractingApps.contains(pkg);

        return BlockableApp(
          name: name,
          package: pkg,
          iconBytes: icon,
          isBlocked: isBlocked,
          isSystemApp: isSystem,
        );
      }).toList();

      state = state.copyWith(
        apps: apps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load apps: $e',
      );
    }
  }

  void toggleApp(String package) {
    state = state.copyWith(
      apps: [
        for (final app in state.apps)
          if (app.package == package)
            app.copyWith(isBlocked: !app.isBlocked)
          else
            app
      ],
    );
  }

  void selectAll() {
    state = state.copyWith(
      apps: [
        for (final app in state.apps)
          app.copyWith(isBlocked: true)
      ],
    );
  }

  void deselectAll() {
    state = state.copyWith(
      apps: [
        for (final app in state.apps)
          app.copyWith(isBlocked: false)
      ],
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

final appSelectionProvider =
    StateNotifierProvider<AppSelectionNotifier, AppSelectionState>((ref) {
  final blockerService = ref.watch(nativeBlockerServiceProvider);
  return AppSelectionNotifier(blockerService);
});
