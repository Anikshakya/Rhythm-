import 'dart:ui';
import 'package:Melo/controllers/audio_controller.dart';
import 'package:Melo/widgets/ios_pop_over.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showIosSleepTimerDialog(
  BuildContext context,
  AudioController controller,
  Color primaryColor,
) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

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
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      ...IosPopoverMenu.buildActionList(
        isDark: isDark,
        isFirstGroup: false,
        isLastGroup: false,
        actions: [
          IosPopoverAction(
            title: 'Off',
            icon: CupertinoIcons.clear_circled,
            isDestructive: true,
            onTap: () {
              controller.setSleepTimer(null);
            },
          ),
          IosPopoverAction(
            title: '15 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 15));
            },
          ),
          IosPopoverAction(
            title: '30 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 30));
            },
          ),
          IosPopoverAction(
            title: '60 Minutes',
            icon: CupertinoIcons.timer,
            onTap: () {
              controller.setSleepTimer(const Duration(minutes: 60));
            },
          ),
          IosPopoverAction(
            title: 'Custom...',
            icon: CupertinoIcons.time,
            onTap: () {
              _showCustomTimerPicker(context, controller, primaryColor);
            },
          ),
        ],
      ),
    ],
  );
}

void _showCustomTimerPicker(
  BuildContext context,
  AudioController controller,
  Color primaryColor,
) {
  // Default picker initial duration (e.g., 20 minutes)
  Duration selectedDuration = const Duration(minutes: 20);

  showCupertinoModalPopup<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Material(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 310,
              color: isDark
                  ? const Color(0xE61C1C1E) // iOS Dark Elevated Surface
                  : const Color(0xF5F2F2F7), // iOS Light Grouped Surface
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // --- Custom Action Bar ---
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? CupertinoColors.systemGrey5.darkColor
                                : CupertinoColors.systemGrey4.color,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            'Custom Timer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (selectedDuration.inSeconds > 0) {
                                controller.setSleepTimer(selectedDuration);
                              }
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Set',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        
                    // --- Duration Picker with Seconds Enabled ---
                    Expanded(
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hms, // Hours, Minutes, Seconds
                        initialTimerDuration: selectedDuration,
                        onTimerDurationChanged: (Duration newDuration) {
                          selectedDuration = newDuration;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}