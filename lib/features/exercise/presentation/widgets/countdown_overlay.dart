import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated countdown overlay with TTS support.
/// Displays 5-4-3-2-1-GO!
class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({
    required this.onComplete,
    this.onCountdown,
    this.startFrom = 5,
    super.key,
  });

  /// Called when countdown reaches 0
  final VoidCallback onComplete;

  /// Called on each countdown tick with the current number
  final void Function(int count)? onCountdown;

  /// Starting number (default: 5)
  final int startFrom;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  late int _currentCount;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _countdownTimer;
  bool _showGo = false;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.startFrom;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(seconds: widget.startFrom),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_scaleController);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _progressController.forward();
    _animateNumber();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCount > 1) {
        setState(() {
          _currentCount--;
        });
        widget.onCountdown?.call(_currentCount);
        _animateNumber();
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        _showGoAnimation();
      }
    });

    widget.onCountdown?.call(_currentCount);
    HapticFeedback.heavyImpact();
  }

  void _animateNumber() {
    _scaleController.reset();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _showGoAnimation() {
    setState(() {
      _showGo = true;
    });
    _scaleController.reset();
    _scaleController.forward();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scaleController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BackgroundPainter(
                  progress: _progressController.value,
                  primaryColor: colorScheme.primary,
                  secondaryColor: colorScheme.secondary,
                ),
              );
            },
          ),

          // Circular progress ring
          Center(
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: 1 - _progressController.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      progressColor: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          // Main countdown number or GO
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value * _pulseAnimation.value,
                  child: Opacity(
                    opacity: _showGo
                        ? 1.0
                        : _fadeAnimation.value.clamp(0.3, 1.0),
                    child: _showGo
                        ? _buildGoWidget(colorScheme)
                        : _buildNumberWidget(colorScheme),
                  ),
                );
              },
            ),
          ),

          // Instruction text at bottom
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showGo ? 0.0 : 1.0,
              child: Column(
                children: [
                  Text(
                    'Get into position',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Make sure your full body is visible',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Decorative elements
          ..._buildDecorativeElements(colorScheme),
        ],
      ),
    );
  }

  Widget _buildNumberWidget(ColorScheme colorScheme) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colorScheme.primary.withOpacity(0.3),
            colorScheme.primary.withOpacity(0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              colorScheme.primary.withOpacity(0.9),
            ],
          ).createShader(bounds),
          child: Text(
            '$_currentCount',
            style: const TextStyle(
              fontSize: 140,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoWidget(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Text(
        'GO!',
        style: TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8,
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeElements(ColorScheme colorScheme) {
    return [
      // Top left decoration
      Positioned(
        top: 60,
        left: 30,
        child: _PulsingDot(color: colorScheme.primary.withOpacity(0.5)),
      ),
      // Top right decoration
      Positioned(
        top: 100,
        right: 50,
        child: _PulsingDot(
          color: colorScheme.secondary.withOpacity(0.5),
          delay: const Duration(milliseconds: 300),
        ),
      ),
      // Bottom decorations
      Positioned(
        bottom: 200,
        left: 60,
        child: _PulsingDot(
          color: colorScheme.primary.withOpacity(0.3),
          delay: const Duration(milliseconds: 600),
          size: 12,
        ),
      ),
      Positioned(
        bottom: 250,
        right: 40,
        child: _PulsingDot(
          color: colorScheme.secondary.withOpacity(0.4),
          delay: const Duration(milliseconds: 900),
          size: 8,
        ),
      ),
    ];
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    this.size = 16,
    this.delay = Duration.zero,
  });

  final Color color;
  final double size;
  final Duration delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color,
                blurRadius: 10 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Animated radial gradient
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2 + (progress * 0.3),
        colors: [
          primaryColor.withOpacity(0.15 * (1 - progress)),
          secondaryColor.withOpacity(0.1 * (1 - progress)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle rotating lines
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (progress * math.pi * 2);
      final startRadius = size.width * 0.3;
      final endRadius = size.width * 0.8;

      canvas.drawLine(
        Offset(
          center.dx + startRadius * math.cos(angle),
          center.dy + startRadius * math.sin(angle),
        ),
        Offset(
          center.dx + endRadius * math.cos(angle),
          center.dy + endRadius * math.sin(angle),
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          progressColor,
          progressColor.withOpacity(0.7),
          progressColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glowing dot at the end of progress
    if (progress > 0) {
      final angle = -math.pi / 2 + (2 * math.pi * progress);
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final dotPaint = Paint()
        ..color = progressColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(dotCenter, strokeWidth / 2 + 4, dotPaint);

      final solidDotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotCenter, strokeWidth / 2, solidDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
