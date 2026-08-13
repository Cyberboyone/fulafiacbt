import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../widgets/powered_by_footer.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    final coins = profile?.coins ?? 0;
    final hasFreeze = profile?.streakFreezeActive ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Coin Shop', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.coinsLight,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$coins', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 14.0)),
                const Text(' coins', style: TextStyle(fontSize: 14.0, color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text('COINS', style: TextStyle(color: AppColors.onPrimary, fontSize: 32.0, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Balance', style: TextStyle(color: AppColors.onPrimary.withOpacity(0.7), fontSize: 12.0, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2.0),
                      Text(
                        '$coins coins',
                        style: const TextStyle(color: AppColors.onPrimary, fontSize: 26.0, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Text('Power-ups', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4.0),
            Text('Spend your earned coins on useful items', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 14.0),
            _buildShopItem(
              context,
              icon: Icons.lightbulb_rounded,
              title: 'Answer Hint',
              description: 'Eliminates wrong answers during practice.',
              cost: AppConstants.coinsForHint,
              canAfford: coins >= AppConstants.coinsForHint,
              color: AppColors.primary,
              onBuy: () async {
                final spent = await profileProvider.spendCoins(AppConstants.coinsForHint);
                if (spent && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hint purchased!'), backgroundColor: AppColors.primary),
                  );
                }
              },
            ),
            const SizedBox(height: 14.0),
            _buildShopItem(
              context,
              icon: Icons.ac_unit_rounded,
              title: 'Streak Freeze',
              description: 'Protects your streak for 1 missed day.',
              cost: AppConstants.coinsForStreakFreeze,
              canAfford: coins >= AppConstants.coinsForStreakFreeze && !hasFreeze,
              color: AppColors.xp,
              onBuy: () async {
                final spent = await profileProvider.spendCoins(AppConstants.coinsForStreakFreeze);
                if (spent) {
                  profileProvider.activateStreakFreeze();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Streak Freeze activated!'), backgroundColor: AppColors.primary),
                    );
                  }
                }
              },
              badge: hasFreeze ? 'ACTIVE' : null,
            ),
            const SizedBox(height: 24.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.coinsLight,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to earn more coins', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14.0)),
                  const SizedBox(height: 10.0),
                  _buildEarnRow('Answer questions correctly', '+1 coin each'),
                  _buildEarnRow('Pass an exam (45%+)', '+5 bonus coins'),
                  _buildEarnRow('Perfect exam score (100%)', '+15 bonus coins'),
                  _buildEarnRow('Invite a friend', '+20 bonus coins'),
                ],
              ),
            ),
            const PoweredByFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int cost,
    required bool canAfford,
    required Color color,
    required VoidCallback onBuy,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.0),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15.0)),
                    if (badge != null) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(color: AppColors.correctLight, borderRadius: BorderRadius.circular(6.0)),
                        child: Text(badge, style: const TextStyle(color: AppColors.correct, fontSize: 9.0, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.0, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          GestureDetector(
            onTap: canAfford ? onBuy : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: canAfford ? AppColors.accent : AppColors.muted,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '$cost coins',
                style: TextStyle(
                  color: canAfford ? AppColors.onPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          Text(amount, style: const TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
