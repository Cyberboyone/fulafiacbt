import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import 'streak_bubbles.dart';

class StreakCard extends StatelessWidget {
  final int streakCount;
  final VoidCallback? onTapViewCalendar;

  const StreakCard({
    super.key,
    required this.streakCount,
    this.onTapViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    String streakLabel;
    if (streakCount == 0) {
      streakLabel = 'Start your streak today!';
    } else if (streakCount < 3) {
      streakLabel = 'Keep going!';
    } else if (streakCount < 7) {
      streakLabel = 'Nice work!';
    } else if (streakCount < 14) {
      streakLabel = 'On fire!';
    } else if (streakCount < 30) {
      streakLabel = 'Unstoppable!';
    } else {
      streakLabel = 'Legendary!';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: AppColors.streakLight,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  streakCount > 0 ? '\u{1F525}' : '\u{1F4AB}',
                  style: const TextStyle(fontSize: 22.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$streakCount',
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            'day${streakCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      streakLabel,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (streakCount >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'x${AppConstants.getStreakMultiplier(streakCount).toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14.0),
          StreakBubbles(streakCount: streakCount),
        ],
      ),
    );
  }
}
