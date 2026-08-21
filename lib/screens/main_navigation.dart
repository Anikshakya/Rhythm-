import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'library/library_screen.dart';
import 'online/online_screen.dart';
import 'playlists/playlists_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/global_player.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with RouteAware {
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _isRouteActive = true;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      _isRouteActive = route.isCurrent;
      routeObserver.subscribe(this, route);
    }

    if (_isRouteActive) {
      _publishMiniPlayerOffset();
    }
  }

  void _publishMiniPlayerOffset() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin =
        Platform.isIOS
            ? (bottomInset > 0 ? bottomInset * 0.50 : 6.0)
            : (bottomInset > 0 ? bottomInset * 0.24 : 6.0);

    GlobalPlayerPage.miniPlayerBottomNotifier.value = bottomMargin + 58 + 4;
    GlobalPlayerPage.bottomNavVisibleNotifier.value = true;
  }

  void _onBottomNavVisibilityChanged(VisibilityInfo info) {
    if (GlobalPlayerPage.progressNotifier.value > 0.01) {
      return;
    }

    final isVisible = _isRouteActive && info.visibleFraction > 0.1;
    GlobalPlayerPage.bottomNavVisibleNotifier.value = isVisible;

    if (isVisible) {
      _publishMiniPlayerOffset();
    }
  }

  @override
  void didPushNext() {
    _isRouteActive = false;
    GlobalPlayerPage.bottomNavVisibleNotifier.value = false;
  }

  @override
  void didPopNext() {
    _isRouteActive = true;
    _publishMiniPlayerOffset();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    GlobalPlayerPage.bottomNavVisibleNotifier.value = false;
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.fastOutSlowIn,
    );
  }

  /// Opens the full-screen player directly.
  ///
  void _navigateToPlayer() {
    GlobalPlayerPage.openCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      LibraryScreen(onNavigateToPlayer: _navigateToPlayer),
      const OnlineScreen(),
      PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer),
      const SettingsScreen(),
    ];

    return ValueListenableBuilder<double>(
      valueListenable: GlobalPlayerPage.progressNotifier,
      builder: (context, playerProgress, child) {
        return PopScope(
          canPop: playerProgress <= 0.001,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && playerProgress > 0.001) {
              GlobalPlayerPage.collapseCallback?.call();
            }
          },
          child: Scaffold(
            extendBody: true,

            body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        children: screens,
        ),

        bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: GlobalPlayerPage.progressNotifier,
        builder: (context, playerProgress, child) {
          return Transform.translate(
            offset: Offset(0, playerProgress * 100),
            child: child,
          );
        },
        child: VisibilityDetector(
          key: const Key('main-bottom-navigation'),
          onVisibilityChanged: _onBottomNavVisibilityChanged,
          child: CustomFloatingNavBar(
            selectedIndex: _selectedIndex,
            onTap: _onTabTapped,
            items: const [
              NavBarItemData(icon: CupertinoIcons.music_albums, label: 'Library'),
              NavBarItemData(icon: CupertinoIcons.globe, label: 'Online'),
              NavBarItemData(
                icon: CupertinoIcons.music_note_list,
                label: 'Playlists',
              ),
              NavBarItemData(icon: CupertinoIcons.settings, label: 'Settings'),
            ],
          ),
        ),
            ),
          ),
        );
      },
    );
  }
}

/// CUPERTINO SEGMENTED FLOATING NAVBAR
class CustomFloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItemData> items;

  const CustomFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomFloatingNavBar> createState() => _CustomFloatingNavBarState();
}

class _CustomFloatingNavBarState extends State<CustomFloatingNavBar> {
  bool _isDragging = false;
  double _dragX = 0.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom:
            Platform.isIOS
                ? (bottomInset > 0 ? bottomInset * 0.50 : 6)
                : (bottomInset > 0 ? bottomInset * 0.24 : 6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / widget.items.length;

                final maxLeft = constraints.maxWidth - itemWidth;

                final double currentLeft =
                    _isDragging
                        ? (_dragX - (itemWidth / 2)).clamp(0.0, maxLeft)
                        : widget.selectedIndex * itemWidth;

                final int currentActiveIndex =
                    _isDragging
                        ? (_dragX / itemWidth).floor().clamp(
                          0,
                          widget.items.length - 1,
                        )
                        : widget.selectedIndex;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragX = details.localPosition.dx;
                    });
                  },

                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragX = details.localPosition.dx.clamp(
                        0.0,
                        constraints.maxWidth,
                      );
                    });
                  },

                  onHorizontalDragEnd: (details) {
                    final targetIndex = (_dragX / itemWidth).floor().clamp(
                      0,
                      widget.items.length - 1,
                    );

                    setState(() {
                      _isDragging = false;
                    });

                    widget.onTap(targetIndex);
                  },

                  onHorizontalDragCancel: () {
                    setState(() {
                      _isDragging = false;
                    });
                  },

                  child: Stack(
                    children: [
                      /// SLIDING THUMB
                      AnimatedPositioned(
                        duration: Duration(milliseconds: _isDragging ? 0 : 280),
                        curve: Curves.fastOutSlowIn,
                        left: currentLeft,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF636366) : Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.12,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// TAB CONTENT
                      Row(
                        children: List.generate(widget.items.length, (index) {
                          final isSelected = currentActiveIndex == index;

                          final item = widget.items[index];

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                widget.onTap(index);
                              },
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.1 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color:
                                            isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                : (isDark
                                                    ? Colors.white54
                                                    : Colors.black45),
                                        size: 19,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                        color:
                                            isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                : (isDark
                                                    ? Colors.white54
                                                    : Colors.black45),
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarItemData {
  final IconData icon;
  final String label;

  const NavBarItemData({required this.icon, required this.label});
}
