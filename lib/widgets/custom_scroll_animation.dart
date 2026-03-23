import 'package:flutter/material.dart';

class CustomScrollAnimation extends StatefulWidget {
  final Widget child;
  final int index;

  const CustomScrollAnimation({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<CustomScrollAnimation> createState() => _CustomScrollAnimationState();
}

class _CustomScrollAnimationState extends State<CustomScrollAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // iOS-style elastic curve
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curve);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(curve);

    // Adding a slight delay based on index so they "pop" in one by one
    Future.delayed(Duration(milliseconds: widget.index * 4), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}