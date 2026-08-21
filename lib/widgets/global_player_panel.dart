import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';

import '../controllers/audio_controller.dart';
import 'fullscreen_player.dart';
import 'miniplayer.dart';

/// ============================================================
/// GLOBAL ROUTE OBSERVER
/// ============================================================

class GlobalRouteObserver extends NavigatorObserver {
  static final RxString currentRoute = '/'.obs;

  void _updateRoute(Route? route) {
    if (route != null && route.settings.name != null) {
      currentRoute.value = route.settings.name!;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    _updateRoute(newRoute);
  }
}

/// ============================================================
/// GLOBAL PLAYER PANEL CONTROLLER
/// ============================================================

class GlobalPlayerPanelController extends GetxController {
  /// 0 = mini player
  /// 1 = fullscreen
  final RxDouble panelPosition = 0.0.obs;

  late AnimationController animationController;

  TickerProvider? vsyncProvider;

  void expand() {
    animateToTarget(1.0, 0.0);
  }

  void collapse() {
    animateToTarget(0.0, 0.0);
  }

  void toggle() {
    if (panelPosition.value > 0.5) {
      collapse();
    } else {
      expand();
    }
  }

  void animateToTarget(double target, double velocity) {
    if (!animationController.isAnimating &&
        (animationController.value - target).abs() < 0.0001) {
      return;
    }

    final simulation = SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 320.0, damping: 30.0),
      animationController.value,
      target,
      velocity,
    );

    animationController.animateWith(simulation);
  }
}

/// ============================================================
/// GLOBAL PLAYER PANEL
/// ============================================================

class GlobalPlayerPanel extends StatefulWidget {
  final Widget child;

  const GlobalPlayerPanel({super.key, required this.child});

  @override
  State<GlobalPlayerPanel> createState() => _GlobalPlayerPanelState();
}

class _GlobalPlayerPanelState extends State<GlobalPlayerPanel>
    with SingleTickerProviderStateMixin {
  late GlobalPlayerPanelController _panelController;

  double _screenHeight = 0.0;

  bool _isDraggingPanel = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // GET CONTROLLER
    // ----------------------------------------------------------

    if (Get.isRegistered<GlobalPlayerPanelController>()) {
      _panelController = Get.find<GlobalPlayerPanelController>();
    } else {
      _panelController = Get.put(
        GlobalPlayerPanelController(),
        permanent: true,
      );
    }

    // ----------------------------------------------------------
    // ANIMATION CONTROLLER
    // ----------------------------------------------------------

    _panelController.vsyncProvider = this;

    _panelController.animationController = AnimationController.unbounded(
      vsync: this,
      value: 0.0,
    );

    _panelController.animationController.addListener(_handleAnimationTick);
  }

  // ==========================================================
  // ANIMATION
  // ==========================================================

  void _handleAnimationTick() {
    if (!mounted) {
      return;
    }

    final value = _panelController.animationController.value.clamp(0.0, 1.0);

    _panelController.panelPosition.value = value;

    setState(() {});
  }

  // ==========================================================
  // DRAG START
  // ==========================================================

  void _onDragStart(DragStartDetails details) {
    if (_screenHeight <= 0) {
      return;
    }

    _isDraggingPanel = true;

    _panelController.animationController.stop();
  }

  // ==========================================================
  // DRAG UPDATE
  // ==========================================================

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingPanel || _screenHeight <= 0) {
      return;
    }

    final delta = details.primaryDelta ?? 0.0;

    final currentValue = _panelController.animationController.value;

    final newValue = (currentValue - delta / _screenHeight).clamp(0.0, 1.0);

    _panelController.animationController.value = newValue;
  }

  // ==========================================================
  // DRAG END
  // ==========================================================

  void _onDragEnd(DragEndDetails details) {
    if (!_isDraggingPanel) {
      return;
    }

    _isDraggingPanel = false;

    final velocity = details.primaryVelocity ?? 0.0;

    final normalizedVelocity =
        -velocity / (_screenHeight > 0 ? _screenHeight : 800.0);

    final currentPosition = _panelController.panelPosition.value;

    double target;

    if (velocity < -350) {
      target = 1.0;
    } else if (velocity > 350) {
      target = 0.0;
    } else if (currentPosition > 0.4) {
      target = 1.0;
    } else {
      target = 0.0;
    }

    _panelController.animateToTarget(target, normalizedVelocity);
  }

  // ==========================================================
  // DRAG CANCEL
  // ==========================================================

  void _onDragCancel() {
    if (!_isDraggingPanel) {
      return;
    }

    _isDraggingPanel = false;

    final currentPosition = _panelController.panelPosition.value;

    _panelController.animateToTarget(currentPosition > 0.5 ? 1.0 : 0.0, 0.0);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ======================================================
        // APP CONTENT
        // ======================================================
        widget.child,

        // ======================================================
        // PLAYER
        // ======================================================
        _buildPlayer(context),
      ],
    );
  }

  // ==========================================================
  // PLAYER
  // ==========================================================

  Widget _buildPlayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (!Get.isRegistered<AudioController>()) {
        return const SizedBox.shrink();
      }

      final audioController = Get.find<AudioController>();

      final currentSong = audioController.currentSong.value;

      if (currentSong == null) {
        return const SizedBox.shrink();
      }

      final position = _panelController.panelPosition.value.clamp(0.0, 1.0);

      final route = GlobalRouteObserver.currentRoute.value;

      final hasBottomBar = route == '/' || route.isEmpty;

      final bottomPadding = MediaQuery.of(context).padding.bottom;

      const miniPlayerHeight = 64.0;

      // ========================================================
      // MINI PLAYER POSITION
      // ========================================================

      final collapsedBottomOffset =
          hasBottomBar
              ? (bottomPadding > 0 ? bottomPadding * 0.5 + 64 : 70)
              : (bottomPadding > 0 ? bottomPadding + 10 : 16);

      final currentBottom = lerpDouble(collapsedBottomOffset, 0.0, position)!;

      final currentMargin = lerpDouble(20.0, 0.0, position)!;

      final currentRadius = lerpDouble(30.0, 0.0, position)!;

      final currentHeight =
          lerpDouble(miniPlayerHeight, _screenHeight, position)!;

      // ========================================================
      // PLAYER
      // ========================================================

      return Positioned(
        left: currentMargin,
        right: currentMargin,
        bottom: currentBottom,
        height: currentHeight.clamp(miniPlayerHeight, _screenHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(currentRadius),
          child: Container(
            decoration: BoxDecoration(
              color: _backgroundColor(isDark, position),
              borderRadius: BorderRadius.circular(currentRadius),
              border: Border.all(
                color: _borderColor(isDark, position),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 25 * (1.0 - position),
                sigmaY: 25 * (1.0 - position),
              ),

              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // ==================================================
                  // FULL SCREEN PLAYER
                  // ==================================================
                  Positioned.fill(
                    child: Opacity(
                      opacity: ((position - 0.05) / 0.95).clamp(0.0, 1.0),
                      child: IgnorePointer(
                        ignoring: position < 0.35,
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: _screenHeight,
                          maxHeight: _screenHeight,
                          child: const FullScreenPlayer(),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // FULLSCREEN DRAG HANDLE
                  // ==================================================
                  if (position >= 0.9)
                    Positioned(
                      top: 0,
                      left: 40,
                      right: 40,
                      height: 60,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragStart: _onDragStart,
                        onVerticalDragUpdate: _onDragUpdate,
                        onVerticalDragEnd: _onDragEnd,
                        onVerticalDragCancel: _onDragCancel,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ==================================================
                  // MINI PLAYER
                  // ==================================================
                  if (position < 0.92)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: miniPlayerHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragStart: _onDragStart,
                        onVerticalDragUpdate: _onDragUpdate,
                        onVerticalDragEnd: _onDragEnd,
                        onVerticalDragCancel: _onDragCancel,
                        child: Opacity(
                          opacity: (1.0 - position * 3.5).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: position > 0.15,
                            child: MiniPlayer(
                              showDecoration: false,
                              onTap: _panelController.expand,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ==========================================================
  // BACKGROUND COLOR
  // ==========================================================

  Color _backgroundColor(bool isDark, double position) {
    if (position < 0.2) {
      return isDark
          ? Colors.white.withValues(alpha: 0.08 + position * 0.5)
          : Colors.black.withValues(alpha: 0.05 + position * 0.5);
    }

    return isDark ? const Color.fromARGB(255, 16, 16, 16) : Colors.white;
  }

  // ==========================================================
  // BORDER COLOR
  // ==========================================================

  Color _borderColor(bool isDark, double position) {
    return isDark
        ? Colors.white.withValues(
          alpha: (0.12 * (1 - position)).clamp(0.0, 1.0),
        )
        : Colors.black.withValues(
          alpha: (0.06 * (1 - position)).clamp(0.0, 1.0),
        );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _panelController.animationController.removeListener(_handleAnimationTick);

    _panelController.animationController.dispose();

    super.dispose();
  }
}
