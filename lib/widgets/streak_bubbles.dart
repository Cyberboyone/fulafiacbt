import 'package:flutter/material.dart';
import '../config/theme.dart';

class StreakBubbles extends StatelessWidget {
  final int streakCount;

  const StreakBubbles({
    super.key,
    required this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = streakCount > 0 ? (streakCount % 7 == 0 ? 7 : streakCount % 7) : 0;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isFilled = index < filledCount;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28.0,
              height: 28.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.accent : AppColors.background,
                boxShadow: isFilled
                    ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 6.0, offset: const Offset(0, 2))]
                    : null,
              ),
              alignment: Alignment.center,
              child: isFilled
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14.0)
                  : null,
            ),
            const SizedBox(height: 4.0),
            Text(
              dayLabels[index],
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                color: isFilled ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
