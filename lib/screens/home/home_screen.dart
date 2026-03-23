import 'package:dhun/widgets/fullscreen_player.dart';
import 'package:dhun/widgets/miniplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../library/library_screen.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // int _selectedIndex = 0;

  // final List<String> _titles = const [
  //   'Library',
  //   'Now Playing',
  //   'Playlists',
  //   'Settings',
  // ];

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  void _navigateToPlayer() {
   Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => const FullScreenPlayer(),
      ),
    );
    // setState(() {
    //   _selectedIndex = 1;
    // });
  }

  @override
  Widget build(BuildContext context) {
    // final List<Widget> screens = [
    //   LibraryScreen(onNavigateToPlayer: _navigateToPlayer),
    //   const FullScreenPlayer(),
    //   PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer),
    //   SettingsScreen(themeNotifier: widget.themeNotifier),
    // ];

    return Scaffold(
      body: Stack(
        children: [
          /// MAIN SCREEN
          LibraryScreen(onNavigateToPlayer: _navigateToPlayer),

          /// GLOBAL MINI PLAYER
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: MiniPlayer(
              onTap: _navigateToPlayer,
            ),
          ),
        ],
      ),

      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.library_music),
      //       label: 'Library',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.music_note),
      //       label: 'Player',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.playlist_play),
      //       label: 'Playlists',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.settings),
      //       label: 'Settings',
      //     ),
      //   ],
      // ),
    );
  }
}