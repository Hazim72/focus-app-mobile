import 'package:flutter/material.dart';
import 'data/services/native_blocker_service.dart';

void main() {
  runApp(const FocusApp());
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NativeBlockerService _blockerService = NativeBlockerService();
  bool _isSessionActive = false;
  bool _hasPermissions = false;

  final List<String> _targetApps = [
    'com.instagram.android',
    'com.whatsapp',
    'com.android.chrome',
  ];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final active = await _blockerService.isSessionActive();
    final permissions = await _blockerService.hasPermissions();
    if (mounted) {
      setState(() {
        _isSessionActive = active;
        _hasPermissions = permissions;
      });
    }
  }

  Future<void> _startSession() async {
    if (!_hasPermissions) {
      await _blockerService.requestPermissions();
      await _checkStatus();
      return;
    }

    // Absolute end timestamp: 10 minutes from now
    final endTime = DateTime.now().add(const Duration(minutes: 10));
    final success = await _blockerService.startSession(
      packages: _targetApps,
      endTime: endTime,
    );

    if (success) {
      setState(() => _isSessionActive = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus session started! Target apps are now blocked.')),
        );
      }
    }
  }

  Future<void> _stopSession() async {
    final success = await _blockerService.stopSession();
    if (success) {
      setState(() => _isSessionActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus session stopped. All apps unblocked!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isSessionActive
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSessionActive ? const Color(0xFF6366F1) : Colors.grey.shade800,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isSessionActive ? Icons.lock : Icons.lock_open,
                    size: 64,
                    color: _isSessionActive ? const Color(0xFF818CF8) : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSessionActive ? 'Focus Session Active' : 'No Active Session',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSessionActive
                        ? 'Instagram, WhatsApp, and Chrome are currently BLOCKED.'
                        : 'Apps can be used normally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Start Button
            if (!_isSessionActive)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Start 10-Minute Focus Session',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            // Stop Button
            if (_isSessionActive)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.tonalIcon(
                  onPressed: _stopSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text(
                    'Stop Session (Unblock Apps)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _checkStatus,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
