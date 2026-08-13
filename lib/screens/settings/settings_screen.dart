import 'dart:ui';
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

  /// Custom Frosted Glass Popover Menu
  void _showIOSPopoverMenu({
    required BuildContext context,
    required Offset position,
    required List<Widget> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              right: 16,
              top: position.dy,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 230,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2E).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
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
                onOpenPopover: (context, offset) {
                  _showSpeedPopover(context, offset, audioController, isDark);
                },
                buildIcon: _buildIosIcon,
              ),

              // Sleep Timer Reactive Tile
              _SleepTimerListTile(
                audioController: audioController,
                primaryColor: primaryColor,
                isDark: isDark,
                onOpenPopover: (context, offset) {
                  _showSleepTimerPopover(
                    context,
                    offset,
                    audioController,
                    isDark,
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

  /// Speed Popover Builder
  void _showSpeedPopover(
    BuildContext context,
    Offset position,
    AudioController controller,
    bool isDark,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    List<Widget> items = [];
    for (int i = 0; i < speeds.length; i++) {
      final s = speeds[i];
      final isFirst = i == 0;
      final isLast = i == speeds.length - 1;

      items.add(
        Obx(() {
          final isSelected = controller.speed.value == s;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              onTap: () {
                controller.setSpeed(s);
                controller.speed.refresh(); // Forces GetX trigger
                Navigator.pop(context);
              },
              splashColor: isDark ? Colors.white12 : Colors.black12,
              highlightColor:
                  isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${s}x',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      );

      if (!isLast) {
        items.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
          ),
        );
      }
    }

    _showIOSPopoverMenu(context: context, position: position, items: items);
  }

  /// Sleep Timer Popover Builder
  void _showSleepTimerPopover(
    BuildContext context,
    Offset position,
    AudioController controller,
    bool isDark,
  ) {
    final options = [
      {'label': 'Off', 'duration': null},
      {'label': '15 Minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 Minutes', 'duration': const Duration(minutes: 30)},
      {'label': '60 Minutes', 'duration': const Duration(minutes: 60)},
    ];

    List<Widget> items = [];
    for (int i = 0; i < options.length; i++) {
      final duration = options[i]['duration'] as Duration?;
      final label = options[i]['label'] as String;
      final isFirst = i == 0;
      final isLast = i == options.length - 1;

      items.add(
        Obx(() {
          final currentTimer = controller.sleepTimer.value;
          final bool isSelected =
              (duration == null && currentTimer == null) ||
              (duration != null &&
                  currentTimer != null &&
                  currentTimer.inMinutes == duration.inMinutes);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              onTap: () {
                controller.setSleepTimer(duration);
                controller.sleepTimer.refresh(); // Forces GetX trigger
                Navigator.pop(context);
              },
              splashColor:
                  duration == null
                      ? CupertinoColors.destructiveRed.withValues(alpha: 0.15)
                      : (isDark ? Colors.white12 : Colors.black12),
              highlightColor:
                  duration == null
                      ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            duration == null
                                ? CupertinoColors.destructiveRed
                                : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color:
                            duration == null
                                ? CupertinoColors.destructiveRed
                                : (isDark ? Colors.white : Colors.black),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      );

      if (!isLast) {
        items.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
          ),
        );
      }
    }

    _showIOSPopoverMenu(context: context, position: position, items: items);
  }
}

/// Dedicated Playback Speed ListTile Widget for isolated Obx rebuilds
class _SpeedListTile extends StatelessWidget {
  final AudioController audioController;
  final Color primaryColor;
  final bool isDark;
  final Function(BuildContext, Offset) onOpenPopover;
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
              final box = tileContext.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);
              onOpenPopover(context, offset);
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
  final Function(BuildContext, Offset) onOpenPopover;
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
              final box = tileContext.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);
              onOpenPopover(context, offset);
            },
          );
        });
      },
    );
  }
}
