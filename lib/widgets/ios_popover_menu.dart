import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    if (icon != null) {
      if (iconOnRight) {
        content = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: resolvedTextColor,
              ),
            ),
            Icon(icon, size: 20, color: activeIconColor),
          ],
        );
      } else {
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
            if (trailing != null) trailing!,
          ],
        );
      }
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: resolvedTextColor,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: inkWellBorderRadius,
        onTap: () {
          // Dismiss the route first to ensure overlay goes away reliably,
          // then invoke user callback.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          onTap();
        },
        splashColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.15)
                : (isDark ? Colors.white12 : Colors.black12),
        highlightColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
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

class IosPopoverMenu extends StatelessWidget {
  final List<Widget> children;
  final double width;
  final bool isDestructive;

  const IosPopoverMenu({
    super.key,
    required this.children,
    this.width = 250,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDestructive
        ? CupertinoColors.destructiveRed.withValues(alpha: 0.3)
        : (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05));

    final backgroundColor = isDestructive
        ? (isDark
            ? const Color(0xFF321313).withValues(alpha: 0.88)
            : const Color(0xFFFFF0F0).withValues(alpha: 0.92))
        : (isDark
            ? const Color(0xFF252525).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85));

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }

  /// Helper to build list of action items with divider line between them
  static List<Widget> buildActionList({
    required List<IosPopoverAction> actions,
    required bool isDark,
    bool isFirstGroup = true,
    bool isLastGroup = true,
    bool isDestructive = false,
  }) {
    List<Widget> list = [];
    for (int i = 0; i < actions.length; i++) {
      final isFirst = isFirstGroup && (i == 0);
      final isLast = isLastGroup && (i == actions.length - 1);
      final action = actions[i];

      final actionDestructive = action.isDestructive || isDestructive;

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
            color: actionDestructive
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

/// Dynamic Layout Delegate that auto-positions popover to stay within bounds
class _PopoverPositionDelegate extends SingleChildLayoutDelegate {
  final Offset targetOffset;
  final EdgeInsets padding;

  _PopoverPositionDelegate({required this.targetOffset, required this.padding});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.copyWith(
      maxHeight: constraints.maxHeight - padding.top - padding.bottom - 32,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const double rightEdgePadding = 16.0;
    final double bottomMargin = padding.bottom + 16.0;
    final double topMargin = padding.top + 16.0;

    double x = size.width - childSize.width - rightEdgePadding;
    double y = targetOffset.dy;

    // Shift popover upwards if it overflows screen height
    if (y + childSize.height > size.height - bottomMargin) {
      y = size.height - childSize.height - bottomMargin;
    }

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

/// Animated Popover Overlay Wrapper
class _IosAnimatedPopoverOverlay extends StatelessWidget {
  final List<Widget> children;
  final Offset? position;
  final bool isCentered;
  final bool isDestructive;
  final double width;
  final Animation<double> animation;

  const _IosAnimatedPopoverOverlay({
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

    final scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInBack,
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOut),
    );

    Widget menuWidget = AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            alignment: isCentered ? Alignment.center : Alignment.topRight,
            child: IosPopoverMenu(
              width: width,
              isDestructive: isDestructive,
              children: children,
            ),
          ),
        );
      },
    );

    final barrierColor = isDestructive
        ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: isCentered ? 0.4 : 0.01);

    return Stack(
      children: [
        // Barrier backdrop tap listener
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) {
              return Container(
                color: barrierColor.withOpacity(barrierColor.opacity * fadeAnimation.value),
              );
            },
          ),
        ),
        if (isCentered)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: menuWidget,
            ),
          )
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
  }
}

/// SHOW POPOVER MENU WITH iOS SPRING ANIMATIONS
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
    barrierDismissible: true,
    barrierLabel: 'Dismiss Popover',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _IosAnimatedPopoverOverlay(
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