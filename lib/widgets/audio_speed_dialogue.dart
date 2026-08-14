import 'package:Melo/controllers/audio_controller.dart';
import 'package:Melo/widgets/ios_pop_over.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void showIosSpeedDialog(
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
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      ...IosPopoverMenu.buildActionList(
        isDark: isDark,
        isFirstGroup: false,
        isLastGroup: false,
        actions:
            [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
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
                },
              );
            }).toList(),
      ),
    ],
  );
}
