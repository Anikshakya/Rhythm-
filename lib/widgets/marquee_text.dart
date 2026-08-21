import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Height of the marquee.
  final double height;

  /// Movement speed in pixels per second.
  final double velocity;

  /// Pause before the first movement.
  final Duration pauseDuration;

  /// Space between the end and beginning of the repeated text.
  final double blankSpace;

  /// Width of the fade at both edges.
  final double fadeWidth;
  final TextAlign textAlign;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.height = 28,
    this.velocity = 30,
    this.pauseDuration = const Duration(milliseconds: 1200),
    this.blankSpace = 50,
    this.fadeWidth = 24,
    this.textAlign = TextAlign.left,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  TextPainter? _textPainter;

  double _textWidth = 0;
  double _loopWidth = 0;
  double _containerWidth = 0;

  double _offset = 0;

  Duration? _startTime;

  bool _needsScroll = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration timestamp) {
    if (!_needsScroll) return;

    if (_startTime == null) {
      _startTime = timestamp;
      return;
    }

    final elapsed = timestamp - _startTime!;

    // Initial pause.
    if (elapsed < widget.pauseDuration) {
      return;
    }

    final movementElapsed =
        elapsed - widget.pauseDuration;

    final seconds =
        movementElapsed.inMicroseconds / 1000000.0;

    // IMPORTANT:
    // modulo means there is NO animation reset.
    //
    // The position continuously wraps around mathematically.
    final distance =
        (seconds * widget.velocity) % _loopWidth;

    if ((distance - _offset).abs() < 0.01) {
      return;
    }

    _offset = distance;

    if (mounted) {
      setState(() {});
    }
  }

  void _stopTicker() {
    _ticker.stop();
    _startTime = null;
    _offset = 0;
  }

  void _calculate(double width) {
    if (width <= 0 || widget.text.isEmpty) {
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    _textPainter = painter;
    _textWidth = painter.width;
    _containerWidth = width;

    final needsScroll = _textWidth > width;

    if (!needsScroll) {
      _stopTicker();

      _needsScroll = false;
      _ready = true;

      if (mounted) {
        setState(() {});
      }

      return;
    }

    _loopWidth =
        _textWidth + widget.blankSpace;

    _needsScroll = true;
    _ready = true;

    _stopTicker();

    // Start the ticker.
    _ticker.start();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.velocity != widget.velocity ||
        oldWidget.blankSpace != widget.blankSpace ||
        oldWidget.pauseDuration != widget.pauseDuration) {
      _stopTicker();

      _textPainter = null;
      _textWidth = 0;
      _loopWidth = 0;
      _needsScroll = false;
      _ready = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _containerWidth > 0) {
          _calculate(_containerWidth);
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width > 0 &&
              (_containerWidth - width).abs() > 0.5) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _calculate(width);
              }
            });
          }

          if (!_ready || _textPainter == null) {
            return const SizedBox.shrink();
          }

          // Text fits. No marquee required.
          if (!_needsScroll) {
            return Align(
              alignment:
                  widget.textAlign == TextAlign.center
                      ? Alignment.center
                      : Alignment.centerLeft,
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: widget.textAlign,
                style: widget.style,
              ),
            );
          }

          return ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect rect) {
                final fade =
                    math.min(
                      widget.fadeWidth,
                      rect.width / 2,
                    );

                final fadePercent =
                    fade / rect.width;

                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    fadePercent,
                    1.0 - fadePercent,
                    1.0,
                  ],
                ).createShader(rect);
              },
              child: RepaintBoundary(
                child: _MarqueeContent(
                  textPainter: _textPainter!,
                  offset: _offset,
                  loopWidth: _loopWidth,
                  height: widget.height,
                  width: width,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarqueeContent extends StatelessWidget {
  final TextPainter textPainter;
  final double offset;
  final double loopWidth;
  final double height;
  final double width;

  const _MarqueeContent({
    required this.textPainter,
    required this.offset,
    required this.loopWidth,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textY =
        (height - textPainter.height) / 2;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: CustomPaint(
          painter: _MarqueePainter(
            textPainter: textPainter,
            offset: offset,
            loopWidth: loopWidth,
            textY: textY,
            viewportWidth: width,
          ),
        ),
      ),
    );
  }
}

class _MarqueePainter extends CustomPainter {
  final TextPainter textPainter;
  final double offset;
  final double loopWidth;
  final double textY;
  final double viewportWidth;

  const _MarqueePainter({
    required this.textPainter,
    required this.offset,
    required this.loopWidth,
    required this.textY,
    required this.viewportWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = -offset;

    // Always draw enough copies to cover the viewport.
    final count =
        (viewportWidth / loopWidth).ceil() + 2;

    for (int i = 0; i < count; i++) {
      final drawX =
          x + (i * loopWidth);

      textPainter.paint(
        canvas,
        Offset(drawX, textY),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _MarqueePainter oldDelegate,
  ) {
    return oldDelegate.offset != offset;
  }
}