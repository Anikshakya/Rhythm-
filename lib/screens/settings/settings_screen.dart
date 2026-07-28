import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final libraryController = Get.find<LibraryController>();
    final audioController = Get.find<AudioController>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          /// APPEARANCE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Obx(() {
            return ListTile(
              leading: const Icon(CupertinoIcons.moon_stars_fill),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeController.themeMode.value == ThemeMode.dark,
                onChanged: (val) => themeController.toggleTheme(),
              ),
            );
          }),

          const Divider(height: 1),

          /// AUDIO ENGINE & LIBRARY
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Audio & Library',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.refresh_bold),
            title: const Text('Rescan Local Library'),
            subtitle: const Text('Scan device for new music files'),
            onTap: () async {
              await libraryController.scanLibrary();
              Get.snackbar(
                'Library',
                'Local library rescanned successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          // ── Default Playback Speed ──────────────────────────────
          Obx(() {
            final speed = audioController.speed.value;
            final isCustom = speed != 1.0;
            return ListTile(
              leading: Icon(
                CupertinoIcons.speedometer,
                color: isCustom ? primaryColor : null,
              ),
              title: const Text('Default Playback Speed'),
              trailing: Text(
                '${speed}x',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCustom ? primaryColor : null,
                ),
              ),
              onTap: () => _showSpeedDialog(context, audioController),
            );
          }),

          // ── Sleep Timer (live countdown) ────────────────────────
          Obx(() {
            final timer = audioController.sleepTimer.value;
            final isActive = timer != null && timer > Duration.zero;

            return ListTile(
              leading: Icon(
                CupertinoIcons.timer,
                color: isActive ? primaryColor : null,
              ),
              title: const Text('Sleep Timer'),
              trailing: Text(
                isActive ? _formatCountdown(timer) : 'Off',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? primaryColor : Colors.grey,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              onTap: () => _showSleepTimerDialog(context, audioController),
            );
          }),

          const Divider(height: 1),

          /// ABOUT
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About Rhythm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(CupertinoIcons.info_circle_fill),
            title: Text('Version'),
            trailing: Text('1.0.0 (Production)'),
          ),
          const ListTile(
            leading: Icon(CupertinoIcons.music_note_2),
            title: Text('Audio Engine'),
            trailing: Text('just_audio + audio_service'),
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, AudioController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Playback Speed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                  return Obx(() {
                    return ChoiceChip(
                      label: Text('${s}x'),
                      selected: controller.speed.value == s,
                      onSelected: (val) {
                        if (val) {
                          controller.setSpeed(s);
                          Navigator.pop(context);
                        }
                      },
                    );
                  });
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context, AudioController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sleep Timer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Off'),
                onTap: () {
                  controller.setSleepTimer(null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('15 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('30 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('60 Minutes'),
                onTap: () {
                  controller.setSleepTimer(const Duration(minutes: 60));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}