import 'package:flutter/material.dart';
import '../../../components/gradient_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/glass_container.dart';

class SessionFeedbackModal extends StatefulWidget {
  final Function(int rating, String? note) onSubmit;
  final String? initialNote;

  const SessionFeedbackModal({
    super.key,
    required this.onSubmit,
    this.initialNote,
  });

  @override
  State<SessionFeedbackModal> createState() => _SessionFeedbackModalState();
}

class _SessionFeedbackModalState extends State<SessionFeedbackModal> {
  int selectedRating = 3;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: GlassContainer(
          padding: const EdgeInsets.all(30),
          borderRadius: BorderRadius.circular(34),
          opacity: 0.14,
          child: _buildContent(context, desktop: true),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {bool desktop = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!desktop)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        if (!desktop) const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Finish session',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            if (desktop)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Quick reflection, then save. Keep this step short.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = selectedRating == rating;
            return GestureDetector(
              onTap: () => setState(() => selectedRating = rating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: desktop ? 94 : 58,
                height: desktop ? 94 : 58,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(desktop ? 24 : 18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.10),
                    width: 1.6,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rating',
                    style: TextStyle(
                      fontSize: desktop ? 30 : 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'What worked? What got in the way?',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
            maxLines: desktop ? 5 : 3,
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Save Session',
          onTap: () {
            widget.onSubmit(
              selectedRating,
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
          },
        ),
        if (!desktop) const SizedBox(height: 12),
      ],
    );
  }
}
