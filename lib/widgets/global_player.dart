import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/audio_controller.dart';
import 'fullscreen_player.dart';
import 'miniplayer.dart';

class GlobalPlayerPage extends StatefulWidget {
  const GlobalPlayerPage({super.key});

  static final ValueNotifier<double> progressNotifier = ValueNotifier<double>(
    0.0,
  );

  @override
  State<GlobalPlayerPage> createState() => _GlobalPlayerPageState();
}

class _GlobalPlayerPageState extends State<GlobalPlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _isDragging = false;

  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 0.0,
    );

    _controller.addListener(_publishProgress);
  }

  @override
  void dispose() {
    _controller.removeListener(_publishProgress);
    _controller.dispose();
    super.dispose();
  }

  void _publishProgress() {
    GlobalPlayerPage.progressNotifier.value = _controller.value;
  }

  // ============================================================
  // PUBLIC
  // ============================================================

  void expand() {
    _animateTo(1.0);
  }

  void collapse() {
    _animateTo(0.0);
  }

  // ============================================================
  // ANIMATION
  // ============================================================

  void _animateTo(double target) {
    if (!mounted) return;

    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // DRAG
  // ============================================================

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;

    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _screenHeight <= 0) {
      return;
    }

    final delta = details.primaryDelta ?? 0.0;

    final value = (_controller.value - (delta / _screenHeight)).clamp(0.0, 1.0);

    _controller.value = value;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;

    // Fast swipe UP
    if (velocity < -500) {
      expand();
      return;
    }

    // Fast swipe DOWN
    if (velocity > 500) {
      collapse();
      return;
    }

    // Normal release
    if (_controller.value >= 0.5) {
      expand();
    } else {
      collapse();
    }
  }

  void _onDragCancel() {
    if (!_isDragging) return;

    _isDragging = false;

    if (_controller.value >= 0.5) {
      expand();
    } else {
      collapse();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    _screenHeight = size.height;

    final audioController = Get.find<AudioController>();

    return Obx(() {
      final song = audioController.currentSong.value;

      if (song == null) {
        return const SizedBox.shrink();
      }

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _buildPlayer(context, size, bottomSafeArea, _controller.value);
        },
      );
    });
  }

  // ============================================================
  // PLAYER
  // ============================================================

  Widget _buildPlayer(
    BuildContext context,
    Size screenSize,
    double bottomSafeArea,
    double progress,
  ) {
    const double miniHeight = 64;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final collapsedBottom = bottomSafeArea > 0 ? bottomSafeArea + 64 : 70;

    final left = lerpDouble(12, 0, progress)!;

    final right = lerpDouble(12, 0, progress)!;

    final bottom = lerpDouble(collapsedBottom, 0, progress)!;

    final height = lerpDouble(miniHeight, screenSize.height, progress)!;

    final radius = lerpDouble(28, 0, progress)!;

    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _buildContent(context, screenSize, progress, isDark),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    BuildContext context,
    Size screenSize,
    double progress,
    bool isDark,
  ) {
    final backgroundColor =
        isDark
            ? Color.lerp(
              Colors.white.withValues(alpha: 0.08),
              const Color(0xFF101010),
              progress,
            )!
            : Color.lerp(
              Colors.white.withValues(alpha: 0.94),
              Colors.white,
              progress,
            )!;

    return Material(
      color: Colors.transparent,

      child: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          color: backgroundColor,

          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.12 * (1 - progress))
                    : Colors.black.withValues(alpha: 0.06 * (1 - progress)),
            width: 0.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12 * (1 - progress)),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================================================
            // FULLSCREEN PLAYER
            // ==================================================
            Positioned.fill(
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),

                child: OverflowBox(
                  alignment: Alignment.topCenter,

                  minWidth: screenSize.width,
                  maxWidth: screenSize.width,

                  minHeight: screenSize.height,
                  maxHeight: screenSize.height,

                  child: const FullScreenPlayer(),
                ),
              ),
            ),

            // ==================================================
            // MINI PLAYER
            //
            // Rendered ABOVE fullscreen player while collapsed.
            // ==================================================
            if (progress < 0.95)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 64,

                child: Opacity(
                  opacity: (1 - progress * 4).clamp(0.0, 1.0),

                  child: MiniPlayer(showDecoration: false, onTap: expand),
                ),
              ),

            // ==================================================
            // MINI PLAYER DRAG LAYER
            //
            // THIS IS THE IMPORTANT PART.
            //
            // It sits ABOVE MiniPlayer and captures ONLY
            // vertical gestures.
            //
            // Therefore dragging from ANYWHERE on the mini
            // player works.
            // ==================================================
            if (progress < 0.95)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 64,

                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,

                  onVerticalDragStart: _onDragStart,

                  onVerticalDragUpdate: _onDragUpdate,

                  onVerticalDragEnd: _onDragEnd,

                  onVerticalDragCancel: _onDragCancel,

                  // Tap also opens fullscreen.
                  onTap: expand,

                  child: const SizedBox.expand(),
                ),
              ),

            // ==================================================
            // FULLSCREEN DRAG AREA
            //
            // Only active after the player has started opening.
            // ==================================================
            if (progress >= 0.05)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 80,

                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,

                  onVerticalDragStart: _onDragStart,

                  onVerticalDragUpdate: _onDragUpdate,

                  onVerticalDragEnd: _onDragEnd,

                  onVerticalDragCancel: _onDragCancel,

                  child: const SizedBox.expand(),
                ),
              ),

            // ==================================================
            // FULLSCREEN HANDLE
            // ==================================================
            if (progress > 0.75)
              Positioned(
                top: 8,
                left: 0,
                right: 0,

                child: IgnorePointer(
                  child: Opacity(
                    opacity: ((progress - 0.75) / 0.25).clamp(0.0, 1.0),

                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,

                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
