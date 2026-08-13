import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ad_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'result_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  bool _didAutoSubmit = false;
  bool _timeWarningPlayed = false;
  final AudioPlayer _warningPlayer = AudioPlayer();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quiz = Provider.of<QuizProvider>(context);

    if (quiz.mode == QuizMode.exam && quiz.examRemainingSeconds == 0 && !_didAutoSubmit && quiz.questions.isNotEmpty) {
      _didAutoSubmit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitExam(context, quiz, auto: true);
      });
    }

    if (quiz.mode == QuizMode.exam && quiz.examRemainingSeconds <= 60 && quiz.examRemainingSeconds > 0 && !_timeWarningPlayed) {
      _timeWarningPlayed = true;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.settings.soundOn) {
        _playWarningSound();
      }
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _warningPlayer.dispose();
    super.dispose();
  }

  Future<void> _playWarningSound() async {
    try {
      await _warningPlayer.play(AssetSource('sounds/wrong.wav'));
    } catch (e) {
      debugPrint('Warning sound error: $e');
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _submitExam(BuildContext context, QuizProvider quiz, {bool auto = false}) {
    final course = quiz.activeCourse;
    if (course == null) return;
    final results = quiz.submitExam();

    if (auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time expired! Exam auto-submitted.'), backgroundColor: AppColors.destructive),
      );
    }

    void _navigateToResult() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            totalQuestions: results['totalQuestions'] as int,
            correctAnswers: results['correctAnswers'] as int,
            scorePercentage: results['scorePercentage'] as int,
            timeSpentSeconds: results['timeSpentSeconds'] as int,
            courseCode: course.code,
            courseId: course.id,
          ),
        ),
      );
    }

    final adsRemoved = Provider.of<SettingsProvider>(context, listen: false).settings.adsRemoved;

    // Always navigate to results immediately — never block on ads
    _navigateToResult();

    // Show interstitial after navigation (non-blocking, no context needed)
    if (!adsRemoved) {
      AdService.instance.showInterstitial(onComplete: () {
        AdService.instance.preloadInterstitial();
      });
    }
  }

  void _showQuestionGrid(BuildContext context, QuizProvider quiz) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      backgroundColor: AppColors.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Questions Navigator', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 18.0),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: quiz.questions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemBuilder: (context, idx) {
                  final isAnswered = quiz.examAnswers.containsKey(idx);
                  final isCurrent = quiz.currentIndex == idx;

                  Color color = AppColors.glassBg;
                  Color border = AppColors.glassBorder;
                  Color text = AppColors.textPrimary;

                  if (isCurrent) {
                    border = AppColors.accent;
                    color = AppColors.accent.withOpacity(0.1);
                  } else if (isAnswered) {
                    color = AppColors.primary;
                    text = AppColors.onPrimary;
                  }

                  return GestureDetector(
                    onTap: () {
                      quiz.navigateToQuestion(idx);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: border, width: isCurrent ? 2.0 : 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text('${idx + 1}', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final quizProvider = Provider.of<QuizProvider>(context);
    final activeCourse = quizProvider.activeCourse;
    final questions = quizProvider.questions;
    final currentQ = quizProvider.currentQuestion;

    if (activeCourse == null || quizProvider.isLoading) {
      return Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (questions.isEmpty || currentQ == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(activeCourse.code)),
        body: const Center(child: Text('No questions loaded')),
      );
    }

    final hasAnsweredCurrent = quizProvider.examAnswers.containsKey(quizProvider.currentIndex);
    final selectedOption = quizProvider.examAnswers[quizProvider.currentIndex];
    final isTimeLow = quizProvider.examRemainingSeconds <= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(activeCourse.code, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16.0)),
            const Text('Exam Mode', style: TextStyle(color: AppColors.destructive, fontSize: 11.0, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            margin: const EdgeInsets.only(right: 14.0),
            decoration: BoxDecoration(
              color: isTimeLow ? AppColors.destructive.withOpacity(0.15) : AppColors.destructive.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.0),
              border: isTimeLow ? Border.all(color: AppColors.destructive, width: 1.5) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: isTimeLow ? AppColors.destructive : AppColors.secondary, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  _formatDuration(quizProvider.examRemainingSeconds),
                  style: TextStyle(
                    color: isTimeLow ? AppColors.destructive : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${quizProvider.currentIndex + 1} of ${questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12.0),
                  ),
                  Row(
                    children: [
                      Text(
                        '${quizProvider.examAnswers.length}/${questions.length} answered',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12.0),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton.icon(
                        onPressed: () => _showQuestionGrid(context, quizProvider),
                        icon: const Icon(Icons.grid_on_rounded, size: 14),
                        label: const Text('View All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.glassBg,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: AppColors.glassBorder, width: 1),
                      ),
                      padding: const EdgeInsets.all(22.0),
                      child: Text(
                        currentQ!.text,
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    ...List.generate(currentQ.options.length, (idx) {
                      final optionText = currentQ.options[idx];
                      final isSelected = selectedOption == idx;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.glassBg,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder, width: 2.0),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                          onTap: () => quizProvider.selectOption(idx),
                          leading: CircleAvatar(
                            radius: 14.0,
                            backgroundColor: isSelected ? AppColors.primary : AppColors.muted,
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          title: Text(optionText, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.0)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quizProvider.currentIndex > 0
                        ? () => quizProvider.navigateToQuestion(quizProvider.currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: AppColors.glassBg,
                      foregroundColor: quizProvider.currentIndex > 0 ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                      child: SizedBox(
                        height: 56.0,
                        child: ElevatedButton(
                          onPressed: () {
                            if (quizProvider.currentIndex < questions.length - 1) {
                              quizProvider.navigateToQuestion(quizProvider.currentIndex + 1);
                            } else {
                              _confirmSubmit(context, quizProvider);
                            }
                          },
                          child: Text(
                            quizProvider.currentIndex < questions.length - 1 ? 'Next' : 'Submit Exam',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSubmit(BuildContext context, QuizProvider quiz) {
    final unanswered = quiz.questions.length - quiz.examAnswers.length;
    final alertText = unanswered > 0
        ? 'You have $unanswered unanswered questions left. Are you sure you want to submit?'
        : 'Are you sure you want to complete and submit this exam?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        title: const Text('Submit Exam?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Text(alertText, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam(context, quiz);
            },
            child: const Text('Submit', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Exam?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: const Text('Your answers will be lost and this attempt will not be recorded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Exam', style: TextStyle(color: AppColors.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel Exam', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
