import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../models/course.dart';
import '../providers/profile_provider.dart';
import '../providers/course_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/progress_ring.dart';
import '../widgets/streak_card.dart';
import '../widgets/course_card.dart';
import '../widgets/nav_bar.dart';
import '../widgets/powered_by_footer.dart';

import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    return Scaffold(
      body: _buildActiveTab(),
      bottomNavigationBar: NavBar(
        currentIndex: _currentTab,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTab) {
      case 0:
        return const _HomeTab();
      case 1:
        return const _PracticeTab();
      case 2:
        return const LeaderboardScreen(isEmbedded: true);
      default:
        return const _HomeTab();
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    final profile = profileProvider.profile;
    if (profile == null) return const SizedBox.shrink();

    final filteredCourses = courseProvider.courses;
    final questionsDone = profile.questionsToday;
    final dailyGoal = AppConstants.dailyGoalQuestions;
    final todayGoalPct = (questionsDone / dailyGoal).clamp(0.0, 1.0);

    final levelInfo = profileProvider.levelInfo;
    final levelProgress = profileProvider.levelProgress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8.0),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46.0,
                        height: 46.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          profile.nickname.isNotEmpty ? profile.nickname[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Hello, ${profile.nickname}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                          settingsProvider.toggleDarkMode(!AppThemeScope.of(context));
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.glassBg,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            AppThemeScope.of(context) ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: AppColors.primary,
                            size: 20.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () => _showAnnouncementsDialog(context),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.glassBg,
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20.0),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 7.0,
                                height: 7.0,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18.0),

              // Level Card
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: AppColors.clayShadowLarge,
                ),
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Text(levelInfo['icon'], style: const TextStyle(fontSize: 32.0)),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                levelInfo['title'],
                                style: const TextStyle(
                                  color: AppColors.onPrimary,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '${profile.xp} XP',
                                  style: const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LinearProgressIndicator(
                              value: levelProgress,
                              color: AppColors.onPrimary,
                              backgroundColor: AppColors.onPrimary.withOpacity(0.2),
                              minHeight: 6.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${profile.xp}/${profileProvider.nextLevelXp} XP to next level',
                            style: TextStyle(
                              color: AppColors.onPrimary.withOpacity(0.7),
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Today's Goal Ring
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: Row(
                  children: [
                    ProgressRing(
                      percentage: todayGoalPct == 0.0 ? 0.05 : todayGoalPct,
                      size: 46.0,
                      strokeWidth: 5.0,
                      child: Text(
                        '${(todayGoalPct * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s goal',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${questionsDone.clamp(0, dailyGoal)} of $dailyGoal questions done',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (todayGoalPct >= 1.0)
                      const Icon(Icons.check_circle, color: AppColors.correct, size: 24.0),
                  ],
                ),
              ),
              const SizedBox(height: 26.0),

              // Streak Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    'Your Streak',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => _showStreakDetails(context, profile.streakCount, profile.streakFreezeActive),
                    child: const Text(
                      'View info',
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              StreakCard(streakCount: profile.streakCount),
              const SizedBox(height: 26.0),

              // Courses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    'Courses',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                    child: const Text(
                      'About App',
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Start Session Cards
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                        if (courseProvider.courses.isNotEmpty) {
                          _showCoursePicker(context, courseProvider.courses, quizProvider, QuizMode.practice);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 28.0),
                            const SizedBox(height: 10.0),
                            Text(
                              'Practice',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15.0, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              'Learn at your own pace',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                        if (courseProvider.courses.isNotEmpty) {
                          _showCoursePicker(context, courseProvider.courses, quizProvider, QuizMode.exam);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 28.0),
                            const SizedBox(height: 10.0),
                            Text(
                              'Exam',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15.0, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              'Timed test simulation',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              ..._buildCourseListWithBanners(context, courseProvider, filteredCourses),

              const PoweredByFooter(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCourseListWithBanners(BuildContext context, CourseProvider courseProvider, List<Course> filteredCourses) {
    final List<Widget> widgets = [];
    final adsRemoved = Provider.of<SettingsProvider>(context, listen: false).settings.adsRemoved;

    var courseIndex = 0;
    for (final course in filteredCourses) {
      final completion = courseProvider.getCompletionPercentage(course.id);
      widgets.add(
        CourseCard(
          course: course,
          progressPercentage: completion,
          onTap: () => _startCourseQuiz(context, course),
        ),
      );
      courseIndex++;
      // Insert one banner after every 4 course cards (and one at the end),
      // but never if the user has ads removed.
      if (!adsRemoved && courseIndex % 4 == 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: const _BannerAdWidget(),
          ),
        );
      }
    }

    return widgets;
  }

  void _startCourseQuiz(BuildContext context, Course course) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    quizProvider.startSession(course: course, mode: QuizMode.practice, soundOn: settingsProvider.settings.soundOn).then((_) {
      Navigator.pushNamed(context, AppRoutes.practice);
    });
  }

  void _showStreakDetails(BuildContext context, int streakCount, bool hasFreeze) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        title: const Text('Streak System', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        content: Text(
          'You have a streak of $streakCount days!\n\n'
          'Answer at least 1 question every day to maintain your streak. '
          '${hasFreeze ? "You have a streak freeze active, which will protect your streak for 1 missed day." : "Buy a streak freeze from the Shop to protect your streak."}\n\n'
          'Streak multipliers:\n'
          '3-6 days: 1.2x XP\n'
          '7-13 days: 1.5x XP\n'
          '14-29 days: 2x XP\n'
          '30+ days: 3x XP',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        title: const Text('Announcements', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        content: Text(
          'Welcome to the Fulafia CBT App!\n\nAll features are 100% offline. Pick a course and start practicing to prepare for your exams.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCoursePicker(BuildContext context, List<Course> courses, QuizProvider quizProvider, QuizMode mode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      backgroundColor: AppColors.surface,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
          children: [
            Text(
              mode == QuizMode.practice ? 'Select Course' : 'Select Course',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
            const SizedBox(height: 18.0),
            ...courses.map((course) => Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: course.color.withOpacity(0.2),
                      child: Text(course.icon),
                    ),
                    title: Text(course.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    subtitle: Text(course.name, style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    tileColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: AppColors.border),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      quizProvider.startSession(course: course, mode: mode, soundOn: settingsProvider.settings.soundOn).then((_) {
                        if (mode == QuizMode.practice) {
                          Navigator.pushNamed(context, AppRoutes.practice);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.exam);
                        }
                      });
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget({super.key});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_retryCount >= 3) return;
    BannerAd(
      adUnitId: AppConstants.admobBannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[Banner] Loaded');
          if (mounted) {
            setState(() { _bannerAd = ad as BannerAd; _loaded = true; });
          } else {
            // Widget was disposed before the ad arrived - do not leak it.
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Banner] Failed: $error - retry ${_retryCount + 1}/3');
          ad.dispose();
          _retryCount++;
          // Bounded retries only (max 3), and only after a failure -
          // never a periodic refresh of a loaded banner.
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _loadAd();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab();

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Practice & Exam Center', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          children: [
            Text(
              'Select a course to begin your study session. You can practice untimed with instant feedback, or take a timed exam simulation.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 24.0),

            _buildModeCard(
              context,
              title: 'Untimed Practice Mode',
              subtitle: 'Learn at your own pace with instant correct answer explanations.',
              icon: Icons.quiz_rounded,
              color: AppColors.primary,
              onTap: () => _chooseCourseForSession(context, QuizMode.practice),
            ),
            const SizedBox(height: 16.0),

            _buildModeCard(
              context,
              title: 'Timed Exam Simulation',
              subtitle: 'Simulate the real computer-based test with time limits.',
              icon: Icons.timer_outlined,
              color: AppColors.secondary,
              onTap: () => _chooseCourseForSession(context, QuizMode.exam),
            ),
            const SizedBox(height: 28.0),

            Text(
              'Quick Stats',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12.0),

            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    'Coins Balance',
                    '${profileProvider.profile?.coins ?? 0}',
                    Icons.monetization_on_rounded,
                    AppColors.coinsLight,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _buildStatTile(
                    'XP Earned',
                    '${profileProvider.profile?.xp ?? 0} XP',
                    Icons.bolt_rounded,
                    AppColors.xpLight,
                    AppColors.xp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.coinsLight,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.store_rounded, color: AppColors.accent, size: 24.0),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coin Shop', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14.0)),
                          SizedBox(height: 2.0),
                          Text('Spend coins on hints and streak freezes', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            const PoweredByFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32.0),
            const SizedBox(width: 18.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4.0),
                  Text(subtitle, style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20.0),
          const SizedBox(height: 8.0),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(value, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _chooseCourseForSession(BuildContext context, QuizMode mode) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final filtered = courseProvider.courses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      backgroundColor: AppColors.surface,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
          children: [
            Text(
              mode == QuizMode.practice ? 'Select Practice Course' : 'Select Exam Course',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
            const SizedBox(height: 18.0),
            ...filtered.map((course) => Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: course.color.withOpacity(0.2),
                      child: Text(course.icon),
                    ),
                    title: Text(course.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    subtitle: Text(course.name, style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    tileColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: AppColors.border),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      quizProvider.startSession(course: course, mode: mode, soundOn: settingsProvider.settings.soundOn).then((_) {
                        if (mode == QuizMode.practice) {
                          Navigator.pushNamed(context, AppRoutes.practice);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.exam);
                        }
                      });
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
