import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melo/main.dart';

/// ============================================================
/// SHOW IOS POPOVER
/// ============================================================
///
/// IMPORTANT:
/// This uses the application's ROOT overlay.
///
/// Do NOT use:
///   Navigator.of(context).overlay
///   Get.key.currentState?.overlay
///   Overlay.of(context)
///
/// because those can place the popup underneath GlobalPlayerPage.
///
void showIosPopoverMenu({
  required BuildContext context,
  required List<Widget> children,
  Offset? position,
  bool isCentered = false,
  bool isDestructive = false,
  double width = 250,
}) {
  final overlay = globalOverlayKey.currentState;

  if (overlay == null) {
    debugPrint('❌ ROOT OVERLAY IS NULL');
    return;
  }

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (overlayContext) {
      return IosAnimatedPopoverOverlay(
        position: position,
        isCentered: isCentered,
        isDestructive: isDestructive,
        width: width,
        children: children,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      );
    },
  );

  debugPrint('🟢 Inserting iOS popover into ROOT overlay');

  overlay.insert(entry);
}

/// ============================================================
/// POPOVER ACTION
/// ============================================================

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

    Color defaultTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black87);

    if (isDestructive) {
      defaultIconColor = CupertinoColors.destructiveRed;

      defaultTextColor = CupertinoColors.destructiveRed;
    }

    final resolvedIconColor = iconColor ?? defaultIconColor;

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(22) : Radius.zero,
      bottom: isLast ? const Radius.circular(22) : Radius.zero,
    );

    Widget content;

    // ==========================================================
    // ICON ON RIGHT
    // ==========================================================

    if (icon != null && iconOnRight) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: defaultTextColor,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Icon(icon, size: 20, color: resolvedIconColor),
        ],
      );
    }
    // ==========================================================
    // ICON ON LEFT
    // ==========================================================
    else if (icon != null) {
      content = Row(
        children: [
          Icon(icon, size: 20, color: resolvedIconColor),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: defaultTextColor,
              ),
            ),
          ),

          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      );
    }
    // ==========================================================
    // NO ICON
    // ==========================================================
    else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: defaultTextColor,
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
        borderRadius: radius,

        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },

        splashColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.15)
                : isDark
                ? Colors.white12
                : Colors.black12,

        highlightColor:
            isDestructive
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.10)
                : isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: content,
        ),
      ),
    );
  }
}

/// ============================================================
/// IOS POPOVER MENU
/// ============================================================

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

    final borderColor =
        isDestructive
            ? CupertinoColors.destructiveRed.withValues(alpha: 0.30)
            : isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);

    final backgroundColor =
        isDestructive
            ? isDark
                ? const Color(
                  0xFF321313,
                ).withValues(alpha: enableBlur ? 0.88 : 0.98)
                : const Color(
                  0xFFFFF0F0,
                ).withValues(alpha: enableBlur ? 0.92 : 0.98)
            : isDark
            ? const Color(
              0xFF252525,
            ).withValues(alpha: enableBlur ? 0.85 : 0.96)
            : Colors.white.withValues(alpha: enableBlur ? 0.88 : 0.98);

    final body = Container(
      width: width,

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: borderColor, width: 0.5),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,

        child:
            enableBlur
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: body,
                  ),
                )
                : body,
      ),
    );
  }

  /// ==========================================================
  /// ACTION LIST
  /// ==========================================================

  static List<Widget> buildActionList({
    required List<IosPopoverAction> actions,
    required bool isDark,
    bool isFirstGroup = true,
    bool isLastGroup = true,
    bool isDestructive = false,
  }) {
    final list = <Widget>[];

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      final isFirst = isFirstGroup && i == 0;

      final isLast = isLastGroup && i == actions.length - 1;

      final destructive = action.isDestructive || isDestructive;

      list.add(
        IosPopoverAction(
          title: action.title,
          icon: action.icon,
          trailing: action.trailing,
          iconOnRight: action.iconOnRight,
          isDestructive: destructive,
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
                destructive
                    ? CupertinoColors.destructiveRed.withValues(alpha: 0.20)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.10),
          ),
        );
      }
    }

    return list;
  }
}

/// ============================================================
/// POSITION DELEGATE
/// ============================================================

class _PopoverPositionDelegate extends SingleChildLayoutDelegate {
  final Offset targetOffset;

  final EdgeInsets padding;

  _PopoverPositionDelegate({required this.targetOffset, required this.padding});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxHeight = (constraints.maxHeight -
            padding.top -
            padding.bottom -
            32)
        .clamp(0.0, constraints.maxHeight);

    final maxWidth = (constraints.maxWidth - 32).clamp(
      0.0,
      constraints.maxWidth,
    );

    return BoxConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const horizontalPadding = 16.0;

    const verticalGap = 8.0;

    // ==========================================================
    // RIGHT ALIGN
    // ==========================================================

    double x = size.width - childSize.width - horizontalPadding;

    x = x.clamp(
      horizontalPadding,
      size.width - childSize.width - horizontalPadding,
    );

    // ==========================================================
    // TRY BELOW BUTTON
    // ==========================================================

    double y = targetOffset.dy + 44;

    final maxY = size.height - childSize.height - padding.bottom - 16;

    // ==========================================================
    // NOT ENOUGH SPACE BELOW
    // PUT ABOVE BUTTON
    // ==========================================================

    if (y > maxY) {
      y = targetOffset.dy - childSize.height - verticalGap;
    }

    // ==========================================================
    // FINAL CLAMP
    // ==========================================================

    final minY = padding.top + 16;

    y = y.clamp(minY, maxY < minY ? minY : maxY);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopoverPositionDelegate oldDelegate) {
    return targetOffset != oldDelegate.targetOffset ||
        padding != oldDelegate.padding;
  }
}

/// ============================================================
/// ANIMATED POPOVER OVERLAY
/// ============================================================

class IosAnimatedPopoverOverlay extends StatefulWidget {
  final List<Widget> children;

  final Offset? position;

  final bool isCentered;

  final bool isDestructive;

  final double width;

  final VoidCallback onDismiss;

  const IosAnimatedPopoverOverlay({
    super.key,
    required this.children,
    this.position,
    required this.isCentered,
    required this.isDestructive,
    required this.width,
    required this.onDismiss,
  });

  @override
  State<IosAnimatedPopoverOverlay> createState() =>
      _IosAnimatedPopoverOverlayState();
}

class _IosAnimatedPopoverOverlayState extends State<IosAnimatedPopoverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fade;

  late final Animation<double> _scale;

  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
      reverseCurve: Curves.easeInCubic,
    );

    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(curve);

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  /// ==========================================================
  /// DISMISS
  /// ==========================================================

  Future<void> _dismiss() async {
    if (_isDismissing) {
      return;
    }

    _isDismissing = true;

    await _controller.reverse();

    if (mounted) {
      widget.onDismiss();
    }
  }

  /// ==========================================================
  /// BUILD
  /// ==========================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final barrierAlpha =
        widget.isDestructive
            ? 0.10
            : widget.isCentered
            ? 0.40
            : 0.01;

    final barrierColor =
        widget.isDestructive ? CupertinoColors.destructiveRed : Colors.black;

    final menu = FadeTransition(
      opacity: _fade,

      child: ScaleTransition(
        scale: _scale,

        alignment: widget.isCentered ? Alignment.center : Alignment.topRight,

        child: IosPopoverMenu(
          width: widget.width,
          isDestructive: widget.isDestructive,
          children: widget.children,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,

      child: Stack(
        fit: StackFit.expand,

        children: [
          // ======================================================
          // DISMISS BACKDROP
          // ======================================================
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,

              onTap: _dismiss,

              child: AnimatedBuilder(
                animation: _fade,

                builder: (context, child) {
                  return ColoredBox(
                    color: barrierColor.withValues(
                      alpha: barrierAlpha * _fade.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // ======================================================
          // MENU
          // ======================================================
          if (widget.isCentered)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: menu,
              ),
            )
          else
            CustomSingleChildLayout(
              delegate: _PopoverPositionDelegate(
                targetOffset: widget.position ?? const Offset(0, 100),
                padding: media.padding,
              ),
              child: menu,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
