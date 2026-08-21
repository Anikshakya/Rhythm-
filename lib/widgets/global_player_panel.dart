import 'package:flutter/material.dart';
import 'package:melo/main.dart';

/// ============================================================
/// SHOW GLOBAL QUEUE SHEET
/// ============================================================

void showGlobalQueueSheet({required WidgetBuilder builder}) {
  final context = globalOverlayKey.currentContext;

  if (context == null) {
    debugPrint('❌ Global context is not mounted.');
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return builder(context);
        },
      );
    },
  );
}

/// ============================================================
/// CLOSE FROM ANYWHERE
/// ============================================================

void closeGlobalQueueSheet() {
  final context = globalOverlayKey.currentContext;
  if (context != null && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}
