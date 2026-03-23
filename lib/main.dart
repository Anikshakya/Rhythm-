import 'package:dhun/widgets/fullscreen_player.dart';
import 'package:flutter/material.dart';
import 'package:dhun/core/services/audio_handler.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();


  runApp(const RhythmApp());
}

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhythm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      home: HomeScreen(),
      routes: {
        '/': (context) => HomeScreen(),
        '/player': (context) => const FullScreenPlayer(),
      },
    );
  }
}
