import 'package:dhun/app_config/app_theme.dart';
import 'package:dhun/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:dhun/widgets/fullscreen_player.dart';
import 'package:dhun/core/services/audio_handler.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initAudioService();

  /// Inject ThemeController globally
  Get.put(ThemeController(), permanent: true);

  runApp(const RhythmApp());
}

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Access controller
    final ThemeController themeController = Get.find();

    return Obx(
      () => GetMaterialApp(
        title: 'Rhythm',
        debugShowCheckedModeBanner: false,

        /// THEME CONTROLLED BY CONTROLLER
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,

        /// ROUTING
        initialRoute: '/',
        getPages: [
          GetPage(
            name: '/',
            page: () => HomeScreen(),
          ),
          GetPage(
            name: '/player',
            page: () => const FullScreenPlayer(),
          ),
        ],
      ),
    );
  }
}