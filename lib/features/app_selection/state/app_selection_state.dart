import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockableApp {
  final String name;
  final String package;
  final bool isBlocked;

  const BlockableApp({
    required this.name,
    required this.package,
    this.isBlocked = true,
  });

  BlockableApp copyWith({bool? isBlocked}) {
    return BlockableApp(
      name: name,
      package: package,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class AppSelectionNotifier extends StateNotifier<List<BlockableApp>> {
  AppSelectionNotifier()
      : super(const [
          BlockableApp(name: 'Instagram', package: 'com.instagram.android', isBlocked: true),
          BlockableApp(name: 'WhatsApp', package: 'com.whatsapp', isBlocked: true),
          BlockableApp(name: 'Chrome', package: 'com.android.chrome', isBlocked: true),
          BlockableApp(name: 'YouTube', package: 'com.google.android.youtube', isBlocked: false),
        ]);

  void toggleApp(String package) {
    state = [
      for (final app in state)
        if (app.package == package)
          app.copyWith(isBlocked: !app.isBlocked)
        else
          app
    ];
  }

  List<String> get selectedPackageNames {
    return state.where((app) => app.isBlocked).map((app) => app.package).toList();
  }
}

final appSelectionProvider =
    StateNotifierProvider<AppSelectionNotifier, List<BlockableApp>>((ref) {
  return AppSelectionNotifier();
});
