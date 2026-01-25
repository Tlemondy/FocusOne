import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../components/custom_text_field.dart';
import '../../../components/gradient_button.dart';
import '../../../providers/focus_provider.dart';

class SetFocusModal extends ConsumerStatefulWidget {
  const SetFocusModal({super.key});

  @override
  ConsumerState<SetFocusModal> createState() => _SetFocusModalState();
}

class _SetFocusModalState extends ConsumerState<SetFocusModal> {
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Set Your Focus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What\'s the one thing you want to accomplish today?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _titleController,
                  hint: 'Your focus for today',
                  icon: Icons.center_focus_strong_rounded,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _reasonController,
                  hint: 'Why is this important? (optional)',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Set Focus',
                  onTap: _handleSetFocus,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSetFocus() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your focus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(dailyFocusProvider.notifier).setFocus(
      _titleController.text.trim(),
      _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
