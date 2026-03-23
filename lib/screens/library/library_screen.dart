import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tabs/songs_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/playlists_tab.dart';

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
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE + TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rhythm',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.2,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// SEGMENTED CONTROL
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _segmentedControlValue,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      thumbColor:
                          isDark ? const Color(0xFF636366) : Colors.white,
                      children: {
                        0: _buildSegmentText('Songs', 0, theme),
                        1: _buildSegmentText('Albums', 1, theme),
                        2: _buildSegmentText('Artists', 2, theme),
                        3: _buildSegmentText('Lists', 3, theme),
                      },
                      onValueChanged: (v) {
                        setState(() => _segmentedControlValue = v!);
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

  Widget _buildSegmentText(String text, int index, ThemeData theme) {
    final isSelected = _segmentedControlValue == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? (theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black)
              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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