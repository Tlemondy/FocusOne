import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const GradientButton({super.key, required this.text, required this.onTap});

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : 1.0;
    final glowAlpha = _hovered ? 0.48 : 0.36;

    return AnimatedScale(
      scale: scale,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: glowAlpha),
              blurRadius: _hovered ? 28 : 20,
              offset: Offset(0, _hovered ? 14 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            onHover: (value) => setState(() => _hovered = value),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _hovered ? 17.2 : 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                child: Text(widget.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
