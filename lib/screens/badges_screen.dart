import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../widgets/powered_by_footer.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final unlockedIds = Set<String>.from(profile?.unlockedBadgeIds ?? []);
    final totalBadges = AppConstants.badgeCatalog.length;
    final unlockedCount = unlockedIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: AppColors.clayShadowLarge,
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    '$unlockedCount / $totalBadges',
                    style: const TextStyle(color: AppColors.onPrimary, fontSize: 28.0, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4.0),
                  Text('Badges Unlocked', style: TextStyle(color: AppColors.onPrimary.withOpacity(0.7), fontSize: 13.0, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: totalBadges > 0 ? unlockedCount / totalBadges : 0,
                      color: AppColors.onPrimary,
                      backgroundColor: AppColors.onPrimary.withOpacity(0.2),
                      minHeight: 8.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            ...AppConstants.badgeCatalog.map((badgeData) {
              final isUnlocked = unlockedIds.contains(badgeData['id']);
              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isUnlocked ? AppColors.correct.withOpacity(0.3) : AppColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppColors.correctLight : AppColors.muted,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeData['icon']!,
                      style: TextStyle(fontSize: 24.0, color: isUnlocked ? null : AppColors.textMuted),
                    ),
                  ),
                  title: Text(
                    badgeData['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 14.0,
                    ),
                  ),
                  subtitle: Text(
                    badgeData['description']!,
                    style: TextStyle(
                      color: isUnlocked ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.7),
                      fontSize: 12.0,
                    ),
                  ),
                  trailing: isUnlocked
                      ? const Icon(Icons.check_circle, color: AppColors.correct, size: 22.0)
                      : Icon(Icons.lock_outline, color: AppColors.textMuted.withOpacity(0.5), size: 20.0),
                ),
              );
            }),
            const PoweredByFooter(),
          ],
        ),
      ),
    );
  }
}
