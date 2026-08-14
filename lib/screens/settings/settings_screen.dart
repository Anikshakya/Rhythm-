import 'package:Melo/widgets/audio_speed_dialogue.dart';
import 'package:Melo/widgets/sleep_timer_dialogue.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/theme_controller.dart';

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
                    activeTrackColor: primaryColor,
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
                  showIosSpeedDialog(
                    context,
                    audioController,
                    primaryColor,
                  );
                },
                buildIcon: _buildIosIcon,
              ),

              // Sleep Timer Reactive Tile
              _SleepTimerListTile(
                audioController: audioController,
                primaryColor: primaryColor,
                isDark: isDark,
                onOpenPopover: (context) {
                  showIosSleepTimerDialog(
                    context,
                    audioController,
                    primaryColor,
                  );
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
