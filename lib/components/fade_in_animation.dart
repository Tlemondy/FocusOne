import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = AppMotion.slow,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.035),
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasized),
    );
    _offsetAnimation =
        Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.emphasized),
        );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}
