import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../components/gradient_button.dart';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'How did that go?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => selectedRating = rating),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: selectedRating == rating
                              ? AppColors.primaryGradient
                              : null,
                          color: selectedRating == rating
                              ? null
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedRating == rating
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: selectedRating == rating
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 2,
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
