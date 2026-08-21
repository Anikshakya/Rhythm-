import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows an iOS-style popover menu above the global player layer.
///
/// Uses the ROOT navigator so the popover is rendered above global UI
/// such as the global music player.
void showIosPopoverMenu({
  required BuildContext context,
  required List<Widget> children,
  Offset? position,
  bool isCentered = false,
  bool isDestructive = false,
  double width = 250,
}) {
  showGeneralDialog(
    context: context,

    // IMPORTANT:
    // Always use the root navigator so this popup appears above
    // global application layers such as the music player.
    useRootNavigator: true,

    barrierDismissible: true,
    barrierLabel: 'Dismiss Popover',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),

    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return IosAnimatedPopoverOverlay(
        position: position,
        isCentered: isCentered,
        isDestructive: isDestructive,
        width: width,
        animation: animation,
        children: children,
      );
    },
  );
}

/// Individual action inside the iOS popover.
class IosPopoverAction extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  final bool iconOnRight;
  final bool isDestructive;
  final bool isFirst;
  final bool isLast;

  final VoidCallback onTap;

  final Color? iconColor;
  final Color? textColor;

  const IosPopoverAction({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.iconOnRight = false,
    this.isDestructive = false,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color defaultIconColor = isDark ? Colors.white70 : Colors.black87;

    Color resolvedTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black87);

    if (isDestructive) {
      defaultIconColor = CupertinoColors.destructiveRed;
      resolvedTextColor = CupertinoColors.destructiveRed;
    }

    final activeIconColor = iconColor ?? defaultIconColor;

    final inkWellBorderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(22) : Radius.zero,
      bottom: isLast ? const Radius.circular(22) : Radius.zero,
    );

    Widget content;

    // ----------------------------------------------------------
    // ICON
    // ----------------------------------------------------------

    if (icon != null) {
      // Icon on RIGHT
      if (iconOnRight) {
        content = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: resolvedTextColor,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Icon(icon, size: 20, color: activeIconColor),
          ],
        );
      }
      // Icon on LEFT
      else {
        content = Row(
          children: [
            Icon(icon, size: 20, color: activeIconColor),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: resolvedTextColor,
                ),
              ),
            ),

            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        );
      }
    }
    // ----------------------------------------------------------
    // NO ICON
    // ----------------------------------------------------------
    else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: resolvedTextColor,
              ),
            ),
          ),

          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      );
    }

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: inkWellBorderRadius,

        onTap: () {
          // IMPORTANT:
          // Pop the root dialog instead of relying on Get.context.
          //
          // This prevents accidentally popping the underlying route
          // when the popover is shown from a nested navigator.
          final navigator = Navigator.of(context, rootNavigator: true);

          if (navigator.canPop()) {
            navigator.pop();
          }

          onTap();
        },

        splashColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.15)
                : (isDark ? Colors.white12 : Colors.black12),

        highlightColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.10)
                : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: content,
        ),
      ),
    );
  }
}

/// iOS-style translucent popover container.
class IosPopoverMenu extends StatelessWidget {
  final List<Widget> children;
  final double width;
  final bool isDestructive;
  final bool enableBlur;

  const IosPopoverMenu({
    super.key,
    required this.children,
    this.width = 250,
    this.isDestructive = false,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ----------------------------------------------------------
    // BORDER
    // ----------------------------------------------------------

    final borderColor =
        isDestructive
            ? CupertinoColors.destructiveRed.withValues(alpha: 0.3)
            : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08));

    // ----------------------------------------------------------
    // BACKGROUND
    // ----------------------------------------------------------

    final backgroundColor =
        isDestructive
            ? (isDark
                ? const Color(
                  0xFF321313,
                ).withValues(alpha: enableBlur ? 0.88 : 0.98)
                : const Color(
                  0xFFFFF0F0,
                ).withValues(alpha: enableBlur ? 0.92 : 0.98))
            : (isDark
                ? const Color(
                  0xFF252525,
                ).withValues(alpha: enableBlur ? 0.85 : 0.96)
                : Colors.white.withValues(alpha: enableBlur ? 0.88 : 0.98));

    // ----------------------------------------------------------
    // BODY
    // ----------------------------------------------------------

    final body = Container(
      width: width,

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: borderColor, width: 0.5),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,

        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),

          child:
              enableBlur
                  ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: body,
                  )
                  : body,
        ),
      ),
    );
  }

  /// Builds actions and separators.
  static List<Widget> buildActionList({
    required List<IosPopoverAction> actions,
    required bool isDark,
    bool isFirstGroup = true,
    bool isLastGroup = true,
    bool isDestructive = false,
  }) {
    final List<Widget> list = [];

    for (int i = 0; i < actions.length; i++) {
      final bool isFirst = isFirstGroup && i == 0;

      final bool isLast = isLastGroup && i == actions.length - 1;

      final action = actions[i];

      final bool actionDestructive = action.isDestructive || isDestructive;

      list.add(
        IosPopoverAction(
          title: action.title,
          icon: action.icon,
          trailing: action.trailing,
          iconOnRight: action.iconOnRight,
          isDestructive: actionDestructive,
          isFirst: isFirst,
          isLast: isLast,
          onTap: action.onTap,
          iconColor: action.iconColor,
          textColor: action.textColor,
        ),
      );

      if (!isLast) {
        list.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            color:
                actionDestructive
                    ? CupertinoColors.destructiveRed.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1)),
          ),
        );
      }
    }

    return list;
  }
}

/// Controls the position of the non-centered popover.
class _PopoverPositionDelegate extends SingleChildLayoutDelegate {
  final Offset targetOffset;
  final EdgeInsets padding;

  _PopoverPositionDelegate({required this.targetOffset, required this.padding});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The incoming constraints from showGeneralDialog can have
    // minHeight == screen height.
    //
    // We MUST reset minHeight to 0 because the popover is a
    // content-sized widget, not a full-screen widget.
    final double availableHeight = (constraints.maxHeight -
            padding.top -
            padding.bottom -
            32.0)
        .clamp(0.0, constraints.maxHeight);

    final double availableWidth =
        constraints.maxWidth > 32.0
            ? constraints.maxWidth - 32.0
            : constraints.maxWidth;

    return BoxConstraints(
      minWidth: 0.0,
      maxWidth: availableWidth,
      minHeight: 0.0,
      maxHeight: availableHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double rightEdgePadding = 16.0;

    final double topMargin = padding.top + 16.0;

    final double bottomMargin = padding.bottom + 16.0;

    // Right aligned.
    double x = size.width - childSize.width - rightEdgePadding;

    // Never allow the menu to go off the left edge.
    x = x.clamp(16.0, size.width - childSize.width - 16.0);

    double y = targetOffset.dy;

    // ----------------------------------------------------------
    // Prevent bottom overflow
    // ----------------------------------------------------------

    final double maxY = size.height - childSize.height - bottomMargin;

    if (y > maxY) {
      y = maxY;
    }

    // ----------------------------------------------------------
    // Prevent top overflow
    // ----------------------------------------------------------

    if (y < topMargin) {
      y = topMargin;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopoverPositionDelegate oldDelegate) {
    return targetOffset != oldDelegate.targetOffset ||
        padding != oldDelegate.padding;
  }
}

/// Animated root-level popover overlay.
class IosAnimatedPopoverOverlay extends StatelessWidget {
  final List<Widget> children;
  final Offset? position;

  final bool isCentered;
  final bool isDestructive;

  final double width;

  final Animation<double> animation;

  const IosAnimatedPopoverOverlay({
    super.key,
    required this.children,
    this.position,
    required this.isCentered,
    this.isDestructive = false,
    required this.width,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // ----------------------------------------------------------
    // SCALE
    // ----------------------------------------------------------

    final scaleCurve = CurvedAnimation(
      parent: animation,

      curve: const Cubic(0.34, 1.56, 0.64, 1.0),

      reverseCurve: Curves.easeInCubic,
    );

    // ----------------------------------------------------------
    // FADE
    // ----------------------------------------------------------

    final fadeCurve = CurvedAnimation(
      parent: animation,

      curve: Curves.easeOut,

      reverseCurve: Curves.fastOutSlowIn,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(scaleCurve);

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(fadeCurve);

    // ----------------------------------------------------------
    // BARRIER
    // ----------------------------------------------------------

    final double baseBarrierAlpha =
        isDestructive ? 0.1 : (isCentered ? 0.4 : 0.01);

    final barrierColor =
        isDestructive ? CupertinoColors.destructiveRed : Colors.black;

    // ----------------------------------------------------------
    // ANIMATION
    // ----------------------------------------------------------

    return AnimatedBuilder(
      animation: animation,

      builder: (context, child) {
        final bool isClosing = animation.status == AnimationStatus.reverse;

        final menuWidget = RepaintBoundary(
          child: FadeTransition(
            opacity: fadeAnimation,

            child: ScaleTransition(
              scale: scaleAnimation,

              alignment: isCentered ? Alignment.center : Alignment.topRight,

              child: IosPopoverMenu(
                width: width,
                isDestructive: isDestructive,
                enableBlur: !isClosing,
                children: children,
              ),
            ),
          ),
        );

        return Stack(
          fit: StackFit.expand,

          children: [
            // --------------------------------------------------
            // BACKDROP
            // --------------------------------------------------
            GestureDetector(
              onTap: () {
                final navigator = Navigator.of(context, rootNavigator: true);

                if (navigator.canPop()) {
                  navigator.pop();
                }
              },

              behavior: HitTestBehavior.translucent,

              child: Container(
                color: barrierColor.withValues(
                  alpha: baseBarrierAlpha * fadeAnimation.value,
                ),
              ),
            ),

            // --------------------------------------------------
            // CENTERED
            // --------------------------------------------------
            if (isCentered)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: menuWidget,
                ),
              )
            // --------------------------------------------------
            // POSITIONED
            // --------------------------------------------------
            else
              CustomSingleChildLayout(
                delegate: _PopoverPositionDelegate(
                  targetOffset: position ?? const Offset(0, 100),
                  padding: mediaQuery.padding,
                ),

                child: menuWidget,
              ),
          ],
        );
      },
    );
  }
}
