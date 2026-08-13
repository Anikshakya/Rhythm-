import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/ios_popover_menu.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Helper widget to render iOS colored icon containers
  Widget _buildIosIcon(
    IconData icon,
    Color backgroundColor, {
    Color iconColor = Colors.white,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(child: Icon(icon, color: iconColor, size: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final libraryController = Get.find<LibraryController>();
    final audioController = Get.find<AudioController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor:
          isDark
              ? CupertinoColors.systemGroupedBackground.darkColor
              : CupertinoColors.systemGroupedBackground.color,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          /// APPEARANCE SECTION
          CupertinoListSection.insetGrouped(
            header: const Text(
              'APPEARANCE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              Obx(() {
                final isDarkMode =
                    themeController.themeMode.value == ThemeMode.dark;
                return CupertinoListTile(
                  leading: _buildIosIcon(
                    CupertinoIcons.moon_fill,
                    CupertinoColors.systemIndigo,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: CupertinoSwitch(
                    value: isDarkMode,
                    activeColor: primaryColor,
                    onChanged: (val) => themeController.toggleTheme(),
                  ),
                );
              }),
            ],
          ),

          /// AUDIO & LIBRARY SECTION
          CupertinoListSection.insetGrouped(
            header: const Text(
              'AUDIO & LIBRARY',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              CupertinoListTile(
                leading: _buildIosIcon(
                  CupertinoIcons.arrow_clockwise,
                  CupertinoColors.activeBlue,
                ),
                title: const Text(
                  'Rescan Local Library',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: const Text('Scan device for new music files'),
                trailing: const CupertinoListTileChevron(),
                onTap: () async {
                  await libraryController.scanLibrary();
                  Get.snackbar(
                    'Library',
                    'Local library rescanned successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),

              // Default Playback Speed Reactive Tile
              _SpeedListTile(
                audioController: audioController,
                primaryColor: primaryColor,
                isDark: isDark,
                onOpenPopover: (context) {
                  _showSpeedPopover(context, audioController, isDark);
                },
                buildIcon: _buildIosIcon,
              ),

              // Sleep Timer Reactive Tile
              _SleepTimerListTile(
                audioController: audioController,
                primaryColor: primaryColor,
                isDark: isDark,
                onOpenPopover: (context) {
                  _showSleepTimerPopover(context, audioController, isDark);
                },
                buildIcon: _buildIosIcon,
              ),
            ],
          ),

          /// ABOUT SECTION
          CupertinoListSection.insetGrouped(
            header: const Text(
              'ABOUT RHYTHM',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              CupertinoListTile(
                leading: _buildIosIcon(
                  CupertinoIcons.info,
                  CupertinoColors.systemGrey,
                ),
                title: const Text('Version', style: TextStyle(fontSize: 16)),
                additionalInfo: const Text('1.0.0 (Production)'),
              ),
              CupertinoListTile(
                leading: _buildIosIcon(
                  CupertinoIcons.music_note,
                  CupertinoColors.systemPink,
                ),
                title: const Text(
                  'Audio Engine',
                  style: TextStyle(fontSize: 16),
                ),
                additionalInfo: const Text('just_audio + audio_service'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Speed Popover Builder
  void _showSpeedPopover(
    BuildContext context,
    AudioController controller,
    bool isDark,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final primaryColor = Theme.of(context).colorScheme.primary;

    showIosPopoverMenu(
      context: context,
      isCentered: true,
      width: 260,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Playback Speed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
        ),
        ...IosPopoverMenu.buildActionList(
          isDark: isDark,
          isFirstGroup: false,
          isLastGroup: false,
          actions:
              speeds.map((s) {
                return IosPopoverAction(
                  title: '${s}x Speed',
                  icon: CupertinoIcons.speedometer,
                  trailing: Obx(() {
                    final isSelected = controller.speed.value == s;
                    return isSelected
                        ? Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color: primaryColor,
                        )
                        : const SizedBox.shrink();
                  }),
                  onTap: () {
                    controller.setSpeed(s);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Sleep Timer Popover Builder
  void _showSleepTimerPopover(
    BuildContext context,
    AudioController controller,
    bool isDark,
  ) {
    final options = [
      {'label': 'Off', 'duration': null},
      {'label': '15 Minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 Minutes', 'duration': const Duration(minutes: 30)},
      {'label': '60 Minutes', 'duration': const Duration(minutes: 60)},
    ];
    final primaryColor = Theme.of(context).colorScheme.primary;

    showIosPopoverMenu(
      context: context,
      isCentered: true,
      width: 260,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Sleep Timer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
        ),
        ...IosPopoverMenu.buildActionList(
          isDark: isDark,
          isFirstGroup: false,
          isLastGroup: false,
          actions:
              options.map((opt) {
                final duration = opt['duration'] as Duration?;
                final label = opt['label'] as String;

                return IosPopoverAction(
                  title: label,
                  icon: CupertinoIcons.timer,
                  isDestructive: duration == null,
                  trailing: Obx(() {
                    final currentTimer = controller.sleepTimer.value;
                    final bool isSelected =
                        (duration == null && currentTimer == null) ||
                        (duration != null &&
                            currentTimer != null &&
                            currentTimer.inMinutes == duration.inMinutes);
                    return isSelected
                        ? Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color:
                              duration == null
                                  ? CupertinoColors.destructiveRed
                                  : primaryColor,
                        )
                        : const SizedBox.shrink();
                  }),
                  onTap: () {
                    controller.setSleepTimer(duration);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// Dedicated Playback Speed ListTile Widget for isolated Obx rebuilds
class _SpeedListTile extends StatelessWidget {
  final AudioController audioController;
  final Color primaryColor;
  final bool isDark;
  final Function(BuildContext) onOpenPopover;
  final Widget Function(IconData, Color) buildIcon;

  const _SpeedListTile({
    required this.audioController,
    required this.primaryColor,
    required this.isDark,
    required this.onOpenPopover,
    required this.buildIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (tileContext) {
        return Obx(() {
          final speed = audioController.speed.value;
          final isCustom = speed != 1.0;

          return CupertinoListTile(
            leading: buildIcon(
              CupertinoIcons.speedometer,
              CupertinoColors.systemOrange,
            ),
            title: const Text(
              'Default Playback Speed',
              style: TextStyle(fontSize: 16),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${speed}x',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isCustom
                            ? primaryColor
                            : CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(width: 6),
                const CupertinoListTileChevron(),
              ],
            ),
            onTap: () {
              onOpenPopover(context);
            },
          );
        });
      },
    );
  }
}

/// Dedicated Sleep Timer ListTile Widget for isolated Obx rebuilds
class _SleepTimerListTile extends StatelessWidget {
  final AudioController audioController;
  final Color primaryColor;
  final bool isDark;
  final Function(BuildContext) onOpenPopover;
  final Widget Function(IconData, Color) buildIcon;

  const _SleepTimerListTile({
    required this.audioController,
    required this.primaryColor,
    required this.isDark,
    required this.onOpenPopover,
    required this.buildIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (tileContext) {
        return Obx(() {
          final timer = audioController.sleepTimer.value;
          final isActive = timer != null && timer > Duration.zero;

          return CupertinoListTile(
            leading: buildIcon(
              CupertinoIcons.timer,
              CupertinoColors.systemPurple,
            ),
            title: const Text('Sleep Timer', style: TextStyle(fontSize: 16)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isActive ? SettingsScreen._formatCountdown(timer) : 'Off',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isActive
                            ? primaryColor
                            : CupertinoColors.secondaryLabel,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                const CupertinoListTileChevron(),
              ],
            ),
            onTap: () {
              onOpenPopover(context);
            },
          );
        });
      },
    );
  }
}
