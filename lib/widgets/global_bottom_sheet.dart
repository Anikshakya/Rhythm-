import 'package:flutter/material.dart';
import 'package:melo/main.dart';

OverlayEntry? _globalBottomSheetEntry;
VoidCallback? _globalBottomSheetClose;

void showGlobalQueueSheet({
  required Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )
  builder,
}) {
  if (_globalBottomSheetEntry != null) return;

  final overlay = globalOverlayKey.currentState;

  if (overlay == null) return;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return _GlobalBottomSheetOverlay(
        builder: builder,
        onDismiss: () {
          _removeGlobalBottomSheet(entry);
        },
      );
    },
  );

  _globalBottomSheetEntry = entry;

  overlay.insert(entry);
}

void closeGlobalQueueSheet() {
  _globalBottomSheetClose?.call();
}

void _removeGlobalBottomSheet(OverlayEntry entry) {
  if (_globalBottomSheetEntry != entry) {
    return;
  }

  _globalBottomSheetEntry = null;
  _globalBottomSheetClose = null;

  if (entry.mounted) {
    entry.remove();
  }
}

class _GlobalBottomSheetOverlay extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController scrollController)
  builder;

  final VoidCallback onDismiss;

  const _GlobalBottomSheetOverlay({
    required this.builder,
    required this.onDismiss,
  });

  @override
  State<_GlobalBottomSheetOverlay> createState() =>
      _GlobalBottomSheetOverlayState();
}

class _GlobalBottomSheetOverlayState extends State<_GlobalBottomSheetOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  late final DraggableScrollableController _sheetController;

  bool _closing = false;

  bool _dismissRequested = false;

  static const double _initialSize = 0.85;

  static const double _maxSize = 1.0;

  // The sheet can be dragged almost completely away.
  //
  // Once it reaches this point we remove the overlay.
  static const double _minSize = 0.10;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _sheetController = DraggableScrollableController();

    _sheetController.addListener(_onSheetChanged);

    _globalBottomSheetClose = _close;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _entranceController.forward();
    });
  }

  // ==========================================================================
  // SHEET EXTENT CHANGED
  // ==========================================================================

  void _onSheetChanged() {
    if (!mounted || _closing) {
      return;
    }

    if (!_sheetController.isAttached) {
      return;
    }

    final size = _sheetController.size;

    // Once the user drags the sheet almost completely down,
    // dismiss the global overlay.
    if (size <= _minSize + 0.005) {
      _dismissFromDrag();
    }
  }

  // ==========================================================================
  // CLOSE
  // ==========================================================================

  Future<void> _close() async {
    if (_closing) {
      return;
    }

    _closing = true;

    // First move the actual sheet down.
    if (_sheetController.isAttached) {
      try {
        await _sheetController.animateTo(
          _minSize,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeIn,
        );
      } catch (_) {
        // Controller may detach during dispose.
      }
    }

    // Then fade the overlay.
    if (mounted) {
      await _entranceController.reverse();
    }

    if (!mounted) {
      return;
    }

    widget.onDismiss();
  }

  // ==========================================================================
  // CLOSE FROM DRAG
  // ==========================================================================

  void _dismissFromDrag() {
    if (_dismissRequested || _closing) {
      return;
    }

    _dismissRequested = true;

    _close();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================================
          // BACKDROP
          // ==================================================================
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _entranceController,
                  _sheetController,
                ]),
                builder: (context, child) {
                  double entrance = _entranceController.value;

                  double sheetProgress = 1.0;

                  if (_sheetController.isAttached) {
                    final size = _sheetController.size;

                    sheetProgress = ((size - _minSize) / (_maxSize - _minSize))
                        .clamp(0.0, 1.0);
                  }

                  final opacity = 0.35 * entrance * sheetProgress;

                  return ColoredBox(
                    color: Colors.black.withValues(alpha: opacity),
                  );
                },
              ),
            ),
          ),

          // ==================================================================
          // REAL BOTTOM SHEET
          // ==================================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              controller: _sheetController,

              initialChildSize: _initialSize,

              minChildSize: _minSize,

              maxChildSize: _maxSize,

              expand: false,

              // IMPORTANT:
              //
              // No snap.
              //
              // The finger should continuously control
              // the sheet position.
              snap: false,

              builder: (context, scrollController) {
                return AnimatedBuilder(
                  animation: _entranceController,
                  child: widget.builder(context, scrollController),
                  builder: (context, child) {
                    final value = Curves.easeOutCubic.transform(
                      _entranceController.value,
                    );

                    final height = MediaQuery.of(context).size.height;

                    return Transform.translate(
                      offset: Offset(0, height * (1.0 - value)),
                      child: child,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (identical(_globalBottomSheetClose, _close)) {
      _globalBottomSheetClose = null;
    }

    _sheetController.removeListener(_onSheetChanged);

    _sheetController.dispose();

    _entranceController.dispose();

    super.dispose();
  }
}
