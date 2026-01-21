import 'package:flutter/material.dart';

/// A cute animated robot avatar widget for the kid-friendly chatbot
class RobotAvatar extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final bool isListening;
  final bool isSpeaking;

  const RobotAvatar({
    super.key,
    this.size = 100,
    this.isAnimating = false,
    this.isListening = false,
    this.isSpeaking = false,
  });

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _blinkController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation for general movement
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Blink animation for eyes
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
    _startBlinking();
  }

  void _startAnimations() {
    if (widget.isAnimating || widget.isListening || widget.isSpeaking) {
      _bounceController.repeat(reverse: true);
    }

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startBlinking() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(
        Duration(milliseconds: 2000 + (DateTime.now().millisecond % 2000)),
      );
      if (!mounted) return false;
      await _blinkController.forward();
      await _blinkController.reverse();
      return true;
    });
  }

  @override
  void didUpdateWidget(RobotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating != oldWidget.isAnimating ||
        widget.isListening != oldWidget.isListening ||
        widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isAnimating || widget.isListening || widget.isSpeaking) {
        _bounceController.repeat(reverse: true);
      } else {
        _bounceController.stop();
        _bounceController.reset();
      }

      if (widget.isListening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Transform.scale(
            scale: widget.isListening ? _pulseAnimation.value : 1.0,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isListening
                ? [Colors.purple.shade300, Colors.blue.shade400]
                : [Colors.blue.shade300, Colors.purple.shade400],
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isListening ? Colors.purple : Colors.blue)
                  .withValues(alpha: 0.4),
              blurRadius: widget.isListening ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Robot face background
            Container(
              width: widget.size * 0.85,
              height: widget.size * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 3),
              ),
            ),

            // Robot face
            CustomPaint(
              size: Size(widget.size * 0.7, widget.size * 0.7),
              painter: _RobotFacePainter(
                blinkValue: _blinkAnimation.value,
                isListening: widget.isListening,
                isSpeaking: widget.isSpeaking,
              ),
            ),

            // Antenna
            Positioned(
              top: 0,
              child: Container(
                width: 12,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.isListening
                          ? Colors.green
                          : Colors.red.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.isListening ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Listening waves (when listening)
            if (widget.isListening) ...[
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final adjustedValue =
                        ((_pulseController.value + delay) % 1.0);
                    return Container(
                      width: widget.size + (adjustedValue * 40) + (index * 15),
                      height: widget.size + (adjustedValue * 40) + (index * 15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.purple.withValues(
                            alpha: 0.3 - (adjustedValue * 0.3),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the robot face
class _RobotFacePainter extends CustomPainter {
  final double blinkValue;
  final bool isListening;
  final bool isSpeaking;

  _RobotFacePainter({
    required this.blinkValue,
    this.isListening = false,
    this.isSpeaking = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Eyes
    final eyePaint = Paint()
      ..color = isListening ? Colors.purple : Colors.blue.shade600
      ..style = PaintingStyle.fill;

    final eyeWidth = size.width * 0.18;
    final eyeHeight = size.height * 0.22 * blinkValue;
    final eyeY = centerY - size.height * 0.1;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - size.width * 0.22, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      eyePaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + size.width * 0.22, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      eyePaint,
    );

    // Eye shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    if (blinkValue > 0.5) {
      canvas.drawCircle(
        Offset(centerX - size.width * 0.25, eyeY - size.height * 0.04),
        size.width * 0.04,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(centerX + size.width * 0.19, eyeY - size.height * 0.04),
        size.width * 0.04,
        shinePaint,
      );
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = isListening ? Colors.purple.shade400 : Colors.pink.shade400
      ..style = PaintingStyle.fill;

    final mouthY = centerY + size.height * 0.2;
    final mouthWidth = size.width * (isSpeaking ? 0.35 : 0.4);
    final mouthHeight = size.height * (isSpeaking ? 0.18 : 0.12);

    // Happy smile or speaking "O"
    if (isSpeaking) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, mouthY),
          width: mouthWidth * 0.6,
          height: mouthHeight * 1.5,
        ),
        mouthPaint,
      );
    } else {
      // Smile arc
      final smilePath = Path();
      smilePath.moveTo(centerX - mouthWidth / 2, mouthY - mouthHeight / 2);
      smilePath.quadraticBezierTo(
        centerX,
        mouthY + mouthHeight,
        centerX + mouthWidth / 2,
        mouthY - mouthHeight / 2,
      );
      smilePath.close();
      canvas.drawPath(smilePath, mouthPaint);
    }

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = Colors.pink.shade200.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          centerX - size.width * 0.35,
          centerY + size.height * 0.05,
        ),
        width: size.width * 0.12,
        height: size.height * 0.08,
      ),
      cheekPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          centerX + size.width * 0.35,
          centerY + size.height * 0.05,
        ),
        width: size.width * 0.12,
        height: size.height * 0.08,
      ),
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RobotFacePainter oldDelegate) {
    return oldDelegate.blinkValue != blinkValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.isSpeaking != isSpeaking;
  }
}
