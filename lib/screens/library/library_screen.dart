import 'package:melo/controllers/library_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/playlists_tab.dart';
import 'tabs/songs_tab.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const LibraryScreen({super.key, required this.onNavigateToPlayer});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final themeController = Get.find<ThemeController>();
  final libraryController = Get.find<LibraryController>();
  final searchController = TextEditingController();
  late final PageController _pageController;
  int _segmentedControlValue = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _segmentedControlValue);
  }

  @override
  void dispose() {
    searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _segmentedControlValue) return;

    setState(() {
      _segmentedControlValue = index;
    });

    if (index == 1 || index == 2) {
      if (libraryController.sortBy.value == 'album' ||
          libraryController.sortBy.value == 'duration') {
        libraryController.sortBy.value = 'title';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            /// APPLE MUSIC LARGE HEADER TITLE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Obx(() {
                        IconData icon;
                        switch (themeController.themeMode.value) {
                          case ThemeMode.light:
                            icon = CupertinoIcons.sun_max_fill;
                            break;
                          case ThemeMode.dark:
                            icon = CupertinoIcons.moon_fill;
                            break;
                          default:
                            icon = CupertinoIcons.circle_lefthalf_fill;
                        }

                        return IconButton(
                          icon: Icon(icon, size: 24),
                          onPressed: () => themeController.toggleTheme(),
                          tooltip: 'Toggle Theme',
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// FLOATING APPLE MUSIC SEGMENTED CONTROL
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _segmentedControlValue,
                      // Added subtle inner padding to give the thumb breathing room
                      padding: const EdgeInsets.all(4),
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                      // Elevated floating color for dark and light modes
                      thumbColor:
                          isDark
                              ? const Color(0xFF636366)
                              : Colors.white,
                      children: {
                        0: _buildSegmentText('Songs', 0, theme, isDark),
                        1: _buildSegmentText('Albums', 1, theme, isDark),
                        2: _buildSegmentText('Artists', 2, theme, isDark),
                        3: _buildSegmentText('Playlists', 3, theme, isDark),
                      },
                      onValueChanged: (v) {
                        if (v != null) {
                          _onTabChanged(v);
                          _pageController.animateToPage(
                            v,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.fastOutSlowIn,
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// APPLE MUSIC STYLE SEARCH & SORT ROW
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (val) {
                              libraryController.searchQuery.value = val;
                            },
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(
                                CupertinoIcons.search,
                                size: 18,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              hintText: 'Search in library...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 0,
                              ),
                              suffixIcon: Obx(() {
                                final query = libraryController.searchQuery.value;
                                if (query.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    searchController.clear();
                                    libraryController.searchQuery.value = '';
                                  },
                                  child: Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: 16,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                );
                              }),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final currentSort = libraryController.sortBy.value;
                        return Theme(
                          data: Theme.of(context).copyWith(
                            cardColor:
                                isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              CupertinoIcons.sort_down,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: 'Sort Options',
                            onSelected: (String value) {
                              libraryController.sortBy.value = value;
                            },
                            itemBuilder:
                                (
                                  BuildContext context,
                                ) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'title',
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark,
                                          size: 16,
                                          color:
                                              currentSort == 'title'
                                                  ? theme.colorScheme.primary
                                                  : Colors.transparent,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Name'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'artist',
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark,
                                          size: 16,
                                          color:
                                              currentSort == 'artist'
                                                  ? theme.colorScheme.primary
                                                  : Colors.transparent,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Artist'),
                                      ],
                                    ),
                                  ),
                                  if (_segmentedControlValue == 0) ...[
                                    PopupMenuItem<String>(
                                      value: 'album',
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.checkmark,
                                            size: 16,
                                            color:
                                                currentSort == 'album'
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Album'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'duration',
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.checkmark,
                                            size: 16,
                                            color:
                                                currentSort == 'duration'
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Duration'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_segmentedControlValue == 1 ||
                                      _segmentedControlValue == 2)
                                    PopupMenuItem<String>(
                                      value: 'tracks',
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.checkmark,
                                            size: 16,
                                            color:
                                                currentSort == 'tracks'
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Track Count'),
                                        ],
                                      ),
                                    ),
                                ],
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            /// SWIPEABLE TAB CONTENT
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onTabChanged,
                children: [
                  SongsTab(onNavigateToPlayer: widget.onNavigateToPlayer),
                  const AlbumsTab(),
                  const ArtistsTab(),
                  PlaylistsTab(onNavigateToPlayer: widget.onNavigateToPlayer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentText(
    String text,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _segmentedControlValue == index;

    return Padding(
      // Increased vertical padding (from 8 to 10) and horizontal padding (from 0 to 12)
      // to lift the active item pill and give it a taller, floating presence.
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color:
              isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}