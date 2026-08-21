import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import 'miniplayer.dart';
import 'fullscreen_player.dart';

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

class GlobalPlayerPanelController extends GetxController {
  // 0.0 = collapsed (miniplayer), 1.0 = expanded (fullscreen)
  final RxDouble panelPosition = 0.0.obs;
  late AnimationController animationController;
  TickerProvider? vsyncProvider;

  void expand() {
    animateToTarget(1.0, 0.0);
  }

  void collapse() {
    animateToTarget(0.0, 0.0);
  }

  void animateToTarget(double target, double velocity) {
    final double currentVal = animationController.value;
    if ((currentVal - target).abs() < 0.0001) return;

    final simulation = SpringSimulation(
      const SpringDescription(
        mass: 1.0,
        stiffness: 320.0,
        damping: 30.0,
      ),
      currentVal,
      target,
      velocity,
    );

    animationController.animateWith(simulation);
  }
}

class GlobalPlayerPanel extends StatefulWidget {
  final Widget child;

  const GlobalPlayerPanel({super.key, required this.child});

  @override
  State<GlobalPlayerPanel> createState() => _GlobalPlayerPanelState();
}

class _GlobalPlayerPanelState extends State<GlobalPlayerPanel>
    with SingleTickerProviderStateMixin {
  late GlobalPlayerPanelController _panelController;
  double _screenHeight = 0;
  bool _isDraggingPanel = false;

  @override
  void initState() {
    super.initState();
    _panelController = Get.isRegistered<GlobalPlayerPanelController>()
        ? Get.find<GlobalPlayerPanelController>()
        : Get.put(GlobalPlayerPanelController(), permanent: true);

    _panelController.vsyncProvider = this;
    _panelController.animationController = AnimationController.unbounded(
      value: 0.0,
      vsync: this,
    );

    _panelController.animationController.addListener(() {
      final clamped = _panelController.animationController.value.clamp(0.0, 1.0);
      _panelController.panelPosition.value = clamped;
    });
  }

  @override
  void dispose() {
    _panelController.animationController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_screenHeight <= 0) return;
    _isDraggingPanel = true;
    _panelController.animationController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingPanel || _screenHeight <= 0) return;
    final delta = details.primaryDelta ?? 0.0;
    final double currentVal = _panelController.animationController.value;
    final double newVal = (currentVal - delta / _screenHeight).clamp(0.0, 1.0);
    _panelController.animationController.value = newVal;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDraggingPanel) return;
    _isDraggingPanel = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final normalizedVelocity = -velocity / (_screenHeight > 0 ? _screenHeight : 800);
    final currentPos = _panelController.panelPosition.value;

    double target = 0.0;
    if (velocity < -350) {
      target = 1.0;
    } else if (velocity > 350) {
      target = 0.0;
    } else if (currentPos > 0.4) {
      target = 1.0;
    } else {
      target = 0.0;
    }

    _panelController.animateToTarget(target, normalizedVelocity);
  }

  void _onDragCancel() {
    if (!_isDraggingPanel) return;
    _isDraggingPanel = false;
    final currentPos = _panelController.panelPosition.value;
    final target = currentPos > 0.5 ? 1.0 : 0.0;
    _panelController.animateToTarget(target, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (overlayContext) {
            final bottomPadding = MediaQuery.of(overlayContext).padding.bottom;
            const double miniPlayerHeight = 64.0;

            return Stack(
              children: [
                // 1. App Content (Main Navigation / Screens) - 100% UNTOUCHED scrolling
                Positioned.fill(child: widget.child),

                // 2. Global Player Panel Layer
                Obx(() {
                  final audioController = Get.find<AudioController>();
                  final currentSong = audioController.currentSong.value;
                  if (currentSong == null) return const SizedBox.shrink();

                  final pos = _panelController.panelPosition.value;
                  final route = GlobalRouteObserver.currentRoute.value;
                  final bool hasBottomBar = route == '/' || route.isEmpty;

                  final double collapsedBottomOffset = hasBottomBar
                      ? (bottomPadding > 0 ? bottomPadding * 0.5 + 64 : 70)
                      : (bottomPadding > 0 ? bottomPadding + 10 : 16);

                  final double currentBottom = lerpDouble(collapsedBottomOffset, 0.0, pos)!;
                  final double currentMargin = lerpDouble(20.0, 0.0, pos)!;
                  final double currentRadius = lerpDouble(30.0, 0.0, pos)!;
                  final double currentHeight = lerpDouble(
                    miniPlayerHeight,
                    _screenHeight,
                    pos,
                  )!;

                  return Positioned(
                    left: currentMargin,
                    right: currentMargin,
                    bottom: currentBottom,
                    height: currentHeight.clamp(miniPlayerHeight, _screenHeight),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(currentRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          color: pos < 0.2
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.08 + pos * 0.5)
                                  : Colors.black.withValues(alpha: 0.05 + pos * 0.5))
                              : (isDark
                                  ? const Color.fromARGB(255, 16, 16, 16)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(currentRadius),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: (0.12 * (1 - pos)).clamp(0.0, 1.0))
                                : Colors.black.withValues(alpha: (0.06 * (1 - pos)).clamp(0.0, 1.0)),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 25 * (1.0 - pos),
                            sigmaY: 25 * (1.0 - pos),
                          ),
                          child: Stack(
                            clipBehavior: Clip.antiAlias,
                            children: [
                              // ── 1. Full Screen Player (Interactive Content) ────────────
                              Positioned.fill(
                                child: Opacity(
                                  opacity: ((pos - 0.05) / 0.95).clamp(0.0, 1.0),
                                  child: IgnorePointer(
                                    ignoring: pos < 0.35,
                                    child: OverflowBox(
                                      alignment: Alignment.topCenter,
                                      minHeight: _screenHeight,
                                      maxHeight: _screenHeight,
                                      child: const FullScreenPlayer(),
                                    ),
                                  ),
                                ),
                              ),

                              // ── 2. Top Header Drag Down Handle (Active when expanded) ──
                              if (pos >= 0.9)
                                Positioned(
                                  top: 0,
                                  left: 60,
                                  right: 60,
                                  height: 60,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onVerticalDragStart: _onDragStart,
                                    onVerticalDragUpdate: _onDragUpdate,
                                    onVerticalDragEnd: _onDragEnd,
                                    onVerticalDragCancel: _onDragCancel,
                                  ),
                                ),

                              // ── 3. Mini Player Drag Handle & View (Active when collapsed) ──
                              if (pos < 0.92)
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
                                      opacity: (1.0 - pos * 3.5).clamp(0.0, 1.0),
                                      child: IgnorePointer(
                                        ignoring: pos > 0.15,
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
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}
