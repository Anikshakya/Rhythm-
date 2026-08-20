import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'library/library_screen.dart';
import 'online/online_screen.dart';
import 'playlists/playlists_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/miniplayer.dart';
import '../widgets/fullscreen_player.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _navigateToPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const FullScreenPlayer(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      LibraryScreen(onNavigateToPlayer: _navigateToPlayer),
      const OnlineScreen(),
      PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer),
      const SettingsScreen(),
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          /// SWIPEABLE MAIN PAGES
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            children: screens,
          ),

          /// GLOBAL MINI PLAYER WITH SWIPE GESTURES
          Positioned(
            left: 0,
            right: 0,
            bottom: (!Platform.isIOS && MediaQuery.of(context).viewInsets.bottom > 0)
                ? 10.0
                : Platform.isIOS
                    ? (bottomPadding > 0 ? bottomPadding * 2.2 + 4 : 6 * 2)
                    : (bottomPadding > 0 ? bottomPadding * 2 : 58 + 10),
            child: MiniPlayer(
              onTap: _navigateToPlayer,
              onSwipeUp: _navigateToPlayer,
            ),
          )
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          NavBarItemData(icon: CupertinoIcons.music_albums, label: 'Library'),
          NavBarItemData(icon: CupertinoIcons.globe, label: 'Online'),
          NavBarItemData(icon: CupertinoIcons.music_note_list, label: 'Playlists'),
          NavBarItemData(icon: CupertinoIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

/// CUPERTINO SEGMENTED FLOATING NAVBAR WITH REAL-TIME DRAG TRACKING
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

                // Calculate current thumb position based on drag state
                final double currentLeft =
                    _isDragging
                        ? (_dragX - (itemWidth / 2)).clamp(0.0, maxLeft)
                        : widget.selectedIndex * itemWidth;

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
                      _dragX = details.localPosition.dx;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    setState(() {
                      _isDragging = false;
                    });
                    // Calculate nearest segment target upon finger release
                    final targetIndex = (_dragX / itemWidth).floor().clamp(
                      0,
                      widget.items.length - 1,
                    );
                    widget.onTap(targetIndex);
                  },
                  onHorizontalDragCancel: () {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: Stack(
                    children: [
                      /// REAL-TIME SLIDING THUMB / PILL
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

                      /// TAB CONTENT ITEMS
                      Row(
                        children: List.generate(widget.items.length, (index) {
                          // Highlight item based on current thumb center position during drag
                          final currentActiveIndex =
                              _isDragging
                                  ? (_dragX / itemWidth).floor().clamp(
                                    0,
                                    widget.items.length - 1,
                                  )
                                  : widget.selectedIndex;

                          final isSelected = currentActiveIndex == index;
                          final item = widget.items[index];

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTap(index),
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
