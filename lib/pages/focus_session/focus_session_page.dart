import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../providers/session_provider.dart';
import 'components/session_feedback_modal.dart';

class FocusSessionPage extends ConsumerStatefulWidget {
  final String focusTitle;
  final String? focusReason;
  final String focusDateId;

  const FocusSessionPage({
    super.key,
    required this.focusTitle,
    required this.focusReason,
    required this.focusDateId,
  });

  @override
  ConsumerState<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends ConsumerState<FocusSessionPage> {
  int selectedDuration = 25;

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final isSessionActive = activeSession != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 40),
                Expanded(
                  child: isSessionActive
                      ? _buildActiveSession(activeSession)
                      : _buildDurationSelector(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Focus Session',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.focusTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassContainer(
          child: Column(
            children: [
              const Text(
                'Choose Duration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationOption(15),
                  _buildDurationOption(25),
                  _buildDurationOption(45),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: _startSession,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(int minutes) {
    final isSelected = selectedDuration == minutes;
    return GestureDetector(
      onTap: () => setState(() => selectedDuration = minutes),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession(ActiveSessionState session) {
    final minutes = session.remainingSeconds ~/ 60;
    final seconds = session.remainingSeconds % 60;
    final progress = session.remainingSeconds / (session.selectedDurationMinutes * 60);

    return Column(
      children: [
        GlassContainer(
          child: Column(
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          progress > 0.2 ? AppColors.primary : Colors.orange,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.isRunning ? 'Focus Time' : 'Paused',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSessionButton(
                    icon: session.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: session.isRunning ? 'Pause' : 'Resume',
                    onTap: session.isRunning
                        ? () => ref.read(activeSessionProvider.notifier).pauseSession()
                        : () => ref.read(activeSessionProvider.notifier).resumeSession(),
                  ),
                  const SizedBox(width: 16),
                  _buildSessionButton(
                    icon: Icons.stop_rounded,
                    label: 'End',
                    onTap: _endSession,
                    isPrimary: false,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildNotesSection(session)),
      ],
    );
  }

  Widget _buildSessionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(ActiveSessionState session) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Session Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Add notes about this session...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                ref.read(activeSessionProvider.notifier).updateSessionNote(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startSession() {
    ref.read(activeSessionProvider.notifier).startSession(
          widget.focusDateId,
          selectedDuration,
        );
  }

  void _endSession() {
    final activeSession = ref.read(activeSessionProvider);
    final sessionNote = activeSession?.sessionNote ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionFeedbackModal(
        initialNote: sessionNote,
        onSubmit: (rating, note) {
          ref.read(activeSessionProvider.notifier).endSession(
                rating: rating,
                note: note,
              );
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
