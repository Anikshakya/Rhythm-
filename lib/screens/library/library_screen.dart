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

  const LibraryScreen({
    super.key,
    required this.onNavigateToPlayer,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final themeController = Get.find<ThemeController>();
  int _segmentedControlValue = 0;

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

                  /// APPLE MUSIC SEGMENTED CONTROL (4 TABS)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _segmentedControlValue,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
                      children: {
                        0: _buildSegmentText('Songs', 0, theme, isDark),
                        1: _buildSegmentText('Albums', 1, theme, isDark),
                        2: _buildSegmentText('Artists', 2, theme, isDark),
                        3: _buildSegmentText('Playlists', 3, theme, isDark),
                      },
                      onValueChanged: (v) {
                        if (v != null) setState(() => _segmentedControlValue = v);
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// TAB CONTENT
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentText(String text, int index, ThemeData theme, bool isDark) {
    final isSelected = _segmentedControlValue == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_segmentedControlValue) {
      case 0:
        return SongsTab(onNavigateToPlayer: widget.onNavigateToPlayer);
      case 1:
        return const AlbumsTab();
      case 2:
        return const ArtistsTab();
      case 3:
        return PlaylistsTab(onNavigateToPlayer: widget.onNavigateToPlayer);
      default:
        return const SizedBox.shrink();
    }
  }
}