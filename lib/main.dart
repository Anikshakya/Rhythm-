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

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
  };

  try {
    debugPrint('🟡 [1/7] Starting initialization...');
    
    debugPrint('🟡 [2/7] Initializing AudioService...');
    await initAudioService();
    debugPrint('✅ [2/7] AudioService initialized');

    debugPrint('🟡 [3/7] Injecting ThemeController...');
    Get.put(ThemeController(), permanent: true);
    debugPrint('✅ [3/7] ThemeController injected');

    debugPrint('🟡 [4/7] Injecting AudioController...');
    Get.put(AudioController(), permanent: true);
    debugPrint('✅ [4/7] AudioController injected');

    debugPrint('🟡 [5/7] Injecting LibraryController...');
    Get.put(LibraryController(), permanent: true);
    debugPrint('✅ [5/7] LibraryController injected');

    debugPrint('🟡 [6/7] Injecting OnlineController...');
    Get.put(OnlineController(), permanent: true);
    debugPrint('✅ [6/7] OnlineController injected');

    debugPrint('🟡 [7/7] Injecting remaining controllers...');
    Get.put(PlaylistController(), permanent: true);
    Get.put(FavoritesController(), permanent: true);
    Get.put(UnifiedSearchController(), permanent: true);
    debugPrint('✅ [7/7] All controllers injected');

    debugPrint('✅ Launching RhythmApp...');
    runApp(const RhythmApp());
  } catch (e, stack) {
    debugPrint('❌ FATAL ERROR: $e');
    debugPrint('Stack: $stack');
    runApp(ErrorApp(error: e.toString(), stack: stack.toString()));
  }
}

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(
      () => GetMaterialApp(
        title: 'Melo',
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

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;

  const ErrorApp({super.key, 
    required this.error,
    required this.stack,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The app failed to start:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error:',
                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                    ),
                    SelectableText(error),
                    const SizedBox(height: 12),
                    Text(
                      'Stack Trace:',
                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                    ),
                    SelectableText(
                      stack,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}