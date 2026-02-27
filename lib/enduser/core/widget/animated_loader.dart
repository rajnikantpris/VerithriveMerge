import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated loader widget that rotates an SVG image
class AnimatedLoader extends StatefulWidget {
  /// Path to the SVG asset
  final String assetPath;
  
  /// Width of the loader
  final double? width;
  
  /// Height of the loader
  final double? height;
  
  /// Color of the loader (optional)
  final Color? color;
  
  /// Duration of one rotation (default: 2 seconds)
  final Duration duration;
  
  /// Whether to start animation automatically (default: true)
  final bool autoStart;

  const AnimatedLoader({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.duration = const Duration(seconds: 2),
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.autoStart) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Start the animation
  void start() {
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  /// Stop the animation
  void stop() {
    _controller.stop();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: SvgPicture.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}

