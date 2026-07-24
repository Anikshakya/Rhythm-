import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_config/app_theme.dart';
import 'controllers/audio_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/library_controller.dart';
import 'controllers/online_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/search_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/services/audio_handler.dart';
import 'screens/home/home_screen.dart';
import 'widgets/fullscreen_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize AudioService & RhythmAudioHandler
  await initAudioService();

  // 2. Inject Controllers
  Get.put(ThemeController(), permanent: true);
  Get.put(AudioController(), permanent: true);
  Get.put(LibraryController(), permanent: true);
  Get.put(OnlineController(), permanent: true);
  Get.put(PlaylistController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  Get.put(UnifiedSearchController(), permanent: true);

  runApp(const RhythmApp());
}

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(
      () => GetMaterialApp(
        title: 'Rhythm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        initialRoute: '/',
        defaultTransition: Transition.cupertino,
        getPages: [
          GetPage(
            name: '/',
            page: () => const HomeScreen(),
          ),
          GetPage(
            name: '/player',
            page: () => const FullScreenPlayer(),
            transition: Transition.downToUp,
            transitionDuration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}