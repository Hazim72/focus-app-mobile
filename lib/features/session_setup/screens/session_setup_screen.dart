import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../app_selection/state/app_selection_state.dart';

enum DurationSelectionMode { presets, custom, targetTime }

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  DurationSelectionMode _mode = DurationSelectionMode.presets;

  // Selected duration in minutes (default Pomodoro 25 mins)
  int _selectedMinutes = 25;

  // Custom duration pickers
  int _customHours = 0;
  int _customMinutes = 25;

  // Target end time
  TimeOfDay? _targetTime;

  final List<Map<String, dynamic>> _presetOptions = const [
    {'mins': 15, 'label': '15 min', 'sub': 'Quick Burst'},
    {'mins': 25, 'label': '25 min', 'sub': 'Pomodoro'},
    {'mins': 45, 'label': '45 min', 'sub': 'Deep Focus'},
    {'mins': 60, 'label': '1 hour', 'sub': 'Full Block'},
    {'mins': 90, 'label': '90 min', 'sub': 'Intensive'},
    {'mins': 120, 'label': '2 hours', 'sub': 'Extended'},
  ];

  DateTime get _estimatedEndTime =>
      DateTime.now().add(Duration(minutes: _selectedMinutes));

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '$hours hr $mins min';
    if (hours > 0) return '$hours hr';
    return '$mins min';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _onPresetSelected(int mins) {
    setState(() {
      _selectedMinutes = mins;
      _customHours = mins ~/ 60;
      _customMinutes = mins % 60;
    });
  }

  void _updateCustomDuration() {
    final total = (_customHours * 60) + _customMinutes;
    setState(() {
      _selectedMinutes = total < 5 ? 5 : total;
    });
  }

  Future<void> _pickTargetTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _targetTime ??
          TimeOfDay(
            hour: (now.hour + 1) % 24,
            minute: now.minute,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surface,
              dialBackgroundColor: AppColors.surfaceVariant,
              hourMinuteColor: AppColors.surfaceVariant,
              dayPeriodColor: AppColors.surfaceVariant,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final nowDateTime = DateTime.now();
      var targetDateTime = DateTime(
        nowDateTime.year,
        nowDateTime.month,
        nowDateTime.day,
        picked.hour,
        picked.minute,
      );

      // If target time is earlier today, assume next day
      if (targetDateTime.isBefore(nowDateTime)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      final diffMinutes = targetDateTime.difference(nowDateTime).inMinutes;

      setState(() {
        _targetTime = picked;
        _selectedMinutes = diffMinutes > 0 ? diffMinutes : 5;
        _customHours = _selectedMinutes ~/ 60;
        _customMinutes = _selectedMinutes % 60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSelectionState = ref.watch(appSelectionProvider);
    final blockedApps =
        appSelectionState.apps.where((a) => a.isBlocked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Setup'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Mode Selector Segmented Buttons
                  SegmentedButton<DurationSelectionMode>(
                    segments: const [
                      ButtonSegment(
                        value: DurationSelectionMode.presets,
                        label: Text('Presets'),
                        icon: Icon(Icons.flash_on_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: DurationSelectionMode.custom,
                        label: Text('Custom'),
                        icon: Icon(Icons.tune_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: DurationSelectionMode.targetTime,
                        label: Text('Target Time'),
                        icon: Icon(Icons.schedule_rounded, size: 16),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _mode = newSelection.first;
                        if (_mode == DurationSelectionMode.targetTime && _targetTime == null) {
                          _pickTargetTime();
                        }
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary,
                      selectedForegroundColor: Colors.white,
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Presets Mode
                  if (_mode == DurationSelectionMode.presets) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _presetOptions.length,
                      itemBuilder: (context, index) {
                        final option = _presetOptions[index];
                        final isSelected = _selectedMinutes == option['mins'];

                        return InkWell(
                          onTap: () => _onPresetSelected(option['mins'] as int),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option['sub'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                  // Custom Hours & Minutes Mode
                  else if (_mode == DurationSelectionMode.custom) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Hours',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$_customHours hr',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _customHours.toDouble(),
                            min: 0,
                            max: 8,
                            divisions: 8,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.surfaceVariant,
                            label: '$_customHours hr',
                            onChanged: (val) {
                              setState(() {
                                _customHours = val.round();
                                _updateCustomDuration();
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Minutes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$_customMinutes min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _customMinutes.toDouble(),
                            min: 0,
                            max: 55,
                            divisions: 11,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.surfaceVariant,
                            label: '$_customMinutes min',
                            onChanged: (val) {
                              setState(() {
                                _customMinutes = val.round();
                                _updateCustomDuration();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ]
                  // Target End Time Mode
                  else ...[
                    InkWell(
                      onTap: _pickTargetTime,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.alarm_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Focus Until Target Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _targetTime != null
                                        ? '${_targetTime!.format(context)} (${_formatDuration(_selectedMinutes)})'
                                        : 'Tap to select target finish time',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Session Summary Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ends at ${_formatTime(_estimatedEndTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total duration: ${_formatDuration(_selectedMinutes)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Apps to Block Card with Horizontal Avatar Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Apps to Block',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/app-selection'),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Change', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () => context.push('/app-selection'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: blockedApps.isEmpty
                              ? AppColors.warning.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: blockedApps.isEmpty
                                      ? AppColors.warning.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${blockedApps.length} apps selected',
                                  style: TextStyle(
                                    color: blockedApps.isEmpty
                                        ? AppColors.warning
                                        : AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (blockedApps.isEmpty)
                            const Text(
                              '⚠️ No apps selected. Tap here to select apps before starting.',
                              style: TextStyle(color: AppColors.warning, fontSize: 13),
                            )
                          else
                            // Horizontal Icons preview
                            SizedBox(
                              height: 38,
                              child: Row(
                                children: [
                                  for (int i = 0; i < blockedApps.length && i < 5; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: AppColors.surfaceVariant,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: blockedApps[i].iconBytes != null
                                            ? Image.memory(
                                                blockedApps[i].iconBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Text(
                                                  blockedApps[i].name.isNotEmpty
                                                      ? blockedApps[i].name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  if (blockedApps.length > 5)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+${blockedApps.length - 5} more',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Continue to Confirmation Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceVariant, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    if (blockedApps.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one app to block.'),
                        ),
                      );
                      context.push('/app-selection');
                      return;
                    }

                    context.push('/session-confirm', extra: _selectedMinutes);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'Review & Confirm (${_formatDuration(_selectedMinutes)})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
