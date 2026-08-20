import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import 'miniplayer.dart';
import 'fullscreen_player.dart';

class GlobalRouteObserver extends NavigatorObserver {
  static final RxString currentRoute = '/'.obs;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute.value = route.settings.name ?? '';
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute.value = previousRoute?.settings.name ?? '';
  }
}

class GlobalPlayerPanelController extends GetxController {
  // 0.0 = collapsed (miniplayer), 1.0 = expanded (fullscreen)
  final RxDouble panelPosition = 0.0.obs;
  late AnimationController animationController;

  void expand() {
    animationController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void collapse() {
    animationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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

  // Cached screen height — set once in build(), read inside gesture callbacks
  // without ever touching context. This is the key to stable mid-drag math.
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _panelController = Get.put(GlobalPlayerPanelController(), permanent: true);
    _panelController.animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelController.animationController.addListener(() {
      _panelController.panelPosition.value =
          _panelController.animationController.value;
    });
  }

  @override
  void dispose() {
    _panelController.animationController.dispose();
    super.dispose();
  }

  // ─── Gesture callbacks (called from stable, non-Obx GestureDetectors) ───────

  void _onDragUpdate(DragUpdateDetails details) {
    if (_screenHeight <= 0) return;
    // Dragging UP  → primaryDelta < 0 → value increases → panel grows  ✓
    // Dragging DOWN → primaryDelta > 0 → value decreases → panel shrinks ✓
    final newVal = (_panelController.animationController.value -
            details.primaryDelta! / _screenHeight)
        .clamp(0.0, 1.0);
    _panelController.animationController.value = newVal;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -400) {
      _panelController.expand();
    } else if (velocity > 400) {
      _panelController.collapse();
    } else if (_panelController.animationController.value > 0.5) {
      _panelController.expand();
    } else {
      _panelController.collapse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cache screen height here — stable across Obx rebuilds.
    _screenHeight = MediaQuery.of(context).size.height;

    // The builder callback in GetMaterialApp runs ABOVE the Navigator,
    // so there is no Overlay in the ancestor tree at that point.
    // Slider uses OverlayPortal internally → needs an Overlay ancestor.
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (overlayContext) {
            final bottomPadding =
                MediaQuery.of(overlayContext).padding.bottom;

            const double miniPlayerHeight = 64.0;

            // ── GestureDetectors live OUTSIDE Obx so they are NEVER rebuilt
            // while a drag is in progress. Rebuilding them mid-drag with null
            // callbacks is what previously killed the real-time tracking.
            return GestureDetector(
              // This detector covers the whole screen but only processes
              // vertical drags that start inside the visible panel area.
              // HitTestBehavior.translucent lets taps reach app content.
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Stack(
                children: [
                  // 1. Main app content (navigator)
                  Positioned.fill(child: widget.child),

                  // 2. Reactive panel — only redraws height / opacity / visibility.
                  //    Gesture handling is already captured by the outer detector.
                  Obx(() {
                    final audioController = Get.find<AudioController>();
                    final currentSong = audioController.currentSong.value;
                    if (currentSong == null) return const SizedBox.shrink();

                    final pos = _panelController.panelPosition.value;
                    final route = GlobalRouteObserver.currentRoute.value;
                    final bool hasBottomBar =
                        route == '/' || route.isEmpty;

                    final double collapsedBottomOffset = hasBottomBar
                        ? (bottomPadding > 0 ? bottomPadding + 64 : 84)
                        : (bottomPadding > 0 ? bottomPadding + 10 : 16);

                    final double collapsedPanelHeight =
                        miniPlayerHeight + collapsedBottomOffset;
                    final double panelHeight = lerpDouble(
                      collapsedPanelHeight,
                      _screenHeight,
                      pos,
                    )!;

                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: panelHeight.clamp(0.0, _screenHeight),
                      child: Stack(
                        clipBehavior: Clip.antiAlias,
                        children: [
                          // ── Full Screen Player ──────────────────────────────
                          Positioned.fill(
                            child: Opacity(
                              opacity: pos.clamp(0.0, 1.0),
                              child: IgnorePointer(
                                // Allow button/slider interaction only once
                                // mostly expanded; still lets drag pass through
                                // the outer GestureDetector regardless.
                                ignoring: pos < 0.5,
                                child: const FullScreenPlayer(),
                              ),
                            ),
                          ),

                          // ── Mini Player ─────────────────────────────────────
                          if (pos < 0.95)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: collapsedBottomOffset,
                              height: miniPlayerHeight,
                              child: Opacity(
                                opacity: (1.0 - pos * 5.0).clamp(0.0, 1.0),
                                child: IgnorePointer(
                                  // Disable mini-player taps once it starts fading
                                  ignoring: pos > 0.15,
                                  child: MiniPlayer(
                                    onTap: _panelController.expand,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
