import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../providers/course_provider.dart';
import '../models/profile.dart';
import '../widgets/powered_by_footer.dart';

class LeaderboardScreen extends StatelessWidget {
  final bool isEmbedded;

  const LeaderboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final profile = profileProvider.profile;

    final body = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
      children: [
        if (profile != null) ...[
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: AppColors.clayShadowLarge,
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30.0,
                  backgroundColor: AppColors.onPrimary.withOpacity(0.2),
                  child: Text(
                    profile.nickname.isNotEmpty ? profile.nickname[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppColors.onPrimary, fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 18.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.nickname, style: const TextStyle(color: AppColors.onPrimary, fontSize: 18.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2.0),
                      Text(
                        '${profileProvider.levelInfo['icon']} ${profileProvider.levelInfo['title']}',
                        style: TextStyle(color: AppColors.onPrimary.withOpacity(0.8), fontSize: 14.0, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        _getRankTitle(profile),
                        style: TextStyle(color: AppColors.onPrimary.withOpacity(0.6), fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${profile.xp}',
                      style: const TextStyle(color: AppColors.onPrimary, fontSize: 24.0, fontWeight: FontWeight.w900),
                    ),
                    const Text('Total XP', style: TextStyle(color: AppColors.onPrimary, fontSize: 11.0, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          Row(
            children: [
              Expanded(child: _buildMiniStat('Total Correct', '${profile.totalCorrectEver}', AppColors.correctLight, AppColors.correct)),
              const SizedBox(width: 10.0),
              Expanded(child: _buildMiniStat('Best Combo', '${profile.bestCombo} \u{1F525}', AppColors.streakLight, AppColors.streak)),
              const SizedBox(width: 10.0),
              Expanded(child: _buildMiniStat('Days Active', '${profile.daysGoalCompleted}', AppColors.xpLight, AppColors.xp)),
            ],
          ),
          const SizedBox(height: 24.0),
        ],

        Text('Your Best High Scores', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12.0),

        ...courseProvider.courses.map((course) {
          final progress = courseProvider.getProgressForCourse(course.id);
          final accuracy = progress.questionsAttempted > 0
              ? ((progress.correctCount / progress.questionsAttempted) * 100).round()
              : 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: course.color.withOpacity(0.2),
                child: Text(course.icon),
              ),
              title: Text(course.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              subtitle: Text(
                'Attempted: ${progress.questionsAttempted} | Accuracy: $accuracy%',
                style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: progress.bestScore >= 70
                      ? AppColors.correctLight
                      : (progress.bestScore >= 45 ? AppColors.xpLight : AppColors.incorrectLight),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${progress.bestScore}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: progress.bestScore >= 70
                        ? AppColors.correct
                        : (progress.bestScore >= 45 ? AppColors.xp : AppColors.destructive),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20.0),

        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.xpLight,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.xp.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.xp, size: 24.0),
              const SizedBox(width: 14.0),
              Expanded(
                child: Text(
                  'Your rank is based on XP earned from practice and exams. Complete more sessions and maintain streaks to climb higher!',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.0, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const PoweredByFooter(),
      ],
    );

    if (isEmbedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Ranks & Standings', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent, elevation: 0),
      body: body,
    );
  }

  String _getRankTitle(Profile profile) {
    if (profile.totalCorrectEver >= 1000) return 'Top Scholar';
    if (profile.totalCorrectEver >= 500) return 'Expert';
    if (profile.totalCorrectEver >= 100) return 'Advanced';
    if (profile.totalCorrectEver >= 50) return 'Intermediate';
    if (profile.totalCorrectEver >= 10) return 'Beginner';
    return 'Newcomer';
  }

  Widget _buildMiniStat(String label, String value, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: iconColor, fontSize: 16.0, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2.0),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
