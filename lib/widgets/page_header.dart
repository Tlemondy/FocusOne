import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;

  const PageHeader({super.key, required this.title, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
