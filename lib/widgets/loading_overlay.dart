import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingOverlay extends StatefulWidget {
  final String initialMessage;

  const LoadingOverlay({
    Key? key,
    required this.initialMessage,
  }) : super(key: key);

  @override
  _LoadingOverlayState createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late String _message;
  int _dots = 0;
  int _tipIndex = 0;
  Timer? _dotsTimer;
  Timer? _messageTimer;
  late AnimationController _pulseController;

  final List<String> _tips = [
    'Our AI is working hard to create quality content',
    'We use multiple AI servers for the best results',
    'Quality thesis generation takes time',
    'Optimizing your chapter structure',
    'Creating academic content requires precision',
    'Your patience ensures better results',
    'High traffic may cause slight delays',
  ];

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    _startDotAnimation();
    _startTipRotation();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  void _startDotAnimation() {
    _dotsTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dots = (_dots + 1) % 4;
        });
      }
    });
  }

  void _startTipRotation() {
    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2D2D2D),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF48B0).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Color(0xFFFF48B0).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated spinner
              _buildAnimatedSpinner(),
              SizedBox(height: 24),

              // Main message with animated dots
              RichText(
                text: TextSpan(
                  text: '$_message${'.' * _dots}',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                textAlign: TextAlign.center,
              ).animate()
                  .fadeIn(duration: 300.ms)
                  .then(delay: 200.ms)
                  .slide(begin: Offset(0, 0.2), duration: 400.ms),

              SizedBox(height: 16),

              // Rotating tips with fade transition
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: RichText(
                  key: ValueKey<int>(_tipIndex),
                  text: TextSpan(
                    text: _tips[_tipIndex],
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),

              SizedBox(height: 24),

              // Stylish progress indicator
              _buildStylishProgressIndicator(),
            ],
          ),
        ).animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildAnimatedSpinner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFFFF48B0).withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ).animate(controller: _pulseController)
            .scale(begin: Offset(0.9, 0.9), end: Offset(1.1, 1.1)),

        // Spinner
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF48B0)),
            strokeWidth: 3,
            backgroundColor: Colors.grey[800]?.withOpacity(0.3),
          ),
        ),

        // Center dot
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF48B0),
          ),
        ),
      ],
    );
  }

  Widget _buildStylishProgressIndicator() {
    return Column(
      children: [
        // Animated dots row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF48B0).withOpacity(
                    _dots % 5 == index ? 1.0 : 0.3
                ),
              ),
            ).animate(
              target: _dots % 5 == index ? 1 : 0,
            ).scale(
              begin: Offset(1, 1),
              end: Offset(1.3, 1.3),
              duration: 300.ms,
            );
          }),
        ),

        SizedBox(height: 16),

        // Gradient progress bar
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey[800],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 500),
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.7, // Simulated progress
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF48B0),
                          Color(0xFF9D4EDD),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Shimmer effect
              Positioned.fill(
                child: ShimmerEffect(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Shimmer effect for progress bar
class ShimmerEffect extends StatefulWidget {
  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 0.5, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0),
              ],
            ),
          ),
        );
      },
    );
  }
}
