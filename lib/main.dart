import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:melo/widgets/global_player.dart';

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

final GlobalKey<OverlayState> globalOverlayKey = GlobalKey<OverlayState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');

    debugPrint('${details.stack}');
  };

  try {
    // ==========================================================
    // AUDIO SERVICE
    // ==========================================================

    debugPrint('🟡 Initializing AudioService...');

    await initAudioService();

    debugPrint('✅ AudioService initialized');

    // ==========================================================
    // CONTROLLERS
    // ==========================================================

    Get.put(ThemeController(), permanent: true);

    Get.put(AudioController(), permanent: true);

    Get.put(LibraryController(), permanent: true);

    Get.put(OnlineController(), permanent: true);

    Get.put(PlaylistController(), permanent: true);

    Get.put(FavoritesController(), permanent: true);

    Get.put(UnifiedSearchController(), permanent: true);

    debugPrint('✅ All controllers injected');

    // ==========================================================
    // RUN APP
    // ==========================================================

    runApp(const RhythmApp());
  } catch (e, stack) {
    debugPrint('❌ FATAL ERROR: $e');
    debugPrint('Stack: $stack');

    runApp(ErrorApp(error: e.toString(), stack: stack.toString()));
  }
}

// ============================================================
// RHYTHM APP
// ============================================================

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Melo',

        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,

        initialRoute: '/',

        defaultTransition: Transition.cupertino,
        navigatorObservers: [routeObserver],
        routingCallback: (routing) {
          if (routing != null && routing.current != '/') {
            GlobalPlayerPage.collapseCallback?.call();
            GlobalPlayerPage.bottomNavVisibleNotifier.value = false;
          }
        },

        getPages: [
          // ====================================================
          // HOME
          // ====================================================
          GetPage(name: '/', page: () => const HomeScreen()),

          // ====================================================
          // DO NOT USE THIS ROUTE FOR THE PLAYER
          //
          // The player is now controlled by GlobalPlayerPage.
          // ====================================================
        ],

        // ======================================================
        // GLOBAL APP LAYER
        // ======================================================
        builder: (context, child) {
          return ValueListenableBuilder<double>(
            valueListenable: GlobalPlayerPage.progressNotifier,
            builder: (context, progress, _) {
              return Overlay(
                  key: globalOverlayKey,
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) {
                        return child ?? const SizedBox.shrink();
                      },
                    ),
                    OverlayEntry(
                      builder: (context) {
                        return const GlobalPlayerPage();
                      },
                    ),
                  ],
                );
            },
          );
        },
      ),
    );
  }
}
// ============================================================
// ERROR APP
// ============================================================

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;

  const ErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

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
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SelectableText(error),

                    const SizedBox(height: 12),

                    Text(
                      'Stack Trace:',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SelectableText(
                      stack,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
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
