import 'package:flutter/material.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';

class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinished;

  const TutorialOverlay({
    required this.steps,
    required this.onFinished,
    super.key,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  Rect? _targetRect;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) return;

    final step = widget.steps[_currentStepIndex];
    final context = step.targetKey.currentContext;

    if (context != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      setState(() {
        _targetRect = Rect.fromLTWH(
          position.dx - 8,
          position.dy - 8,
          size.width + 16,
          size.height + 16,
        );
      });
      _fadeController.forward(from: 0.0);
    } else {
      // Retry after rendering frame
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _updateTargetRect();
      });
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _targetRect = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTargetRect();
      });
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty || _currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStepIndex];
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    final bool isTargetOnTop = _targetRect != null && _targetRect!.top < screenHeight / 2;

    // Card details showing tutorial description
    final cardWidget = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.color.secondaryColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.color.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.color.territoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  step.title,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                  color: context.color.textColorDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomText(
            step.description,
            fontSize: context.font.normal,
            color: context.color.textColorDark.withValues(alpha: 0.8),
            height: 1.5,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onFinished,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: CustomText(
                  "skipForNow".translate(context),
                  color: context.color.textLightColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.color.territoryColor,
                      context.color.territoryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: context.color.territoryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: CustomText(
                    _currentStepIndex == widget.steps.length - 1
                        ? "ok".translate(context).toUpperCase()
                        : "next".translate(context),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Dimming with Cutout
          if (_targetRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: HolePainter(
                  holeRect: _targetRect!,
                  overlayColor: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),

          // Glowing border effect around target Rect
          if (_targetRect != null)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double pulse = _pulseController.value;
                return Positioned.fromRect(
                  rect: _targetRect!.inflate(pulse * 4.0),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.color.territoryColor.withValues(alpha: 1.0 - pulse * 0.5),
                          width: 2.5 + pulse * 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.color.territoryColor.withValues(alpha: 0.4 * (1.0 - pulse)),
                            blurRadius: 8 + pulse * 8,
                            spreadRadius: pulse * 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Dialog Info Box Placement
          Positioned(
            top: isTargetOnTop ? null : mediaQuery.padding.top + 40,
            bottom: isTargetOnTop ? mediaQuery.padding.bottom + 40 : null,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _fadeController,
              child: cardWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  final Rect holeRect;
  final Color overlayColor;

  HolePainter({required this.holeRect, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(16)));

    final paint = Paint()..color = overlayColor;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) {
    return oldDelegate.holeRect != holeRect || oldDelegate.overlayColor != overlayColor;
  }
}
