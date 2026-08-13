import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final double progressPercentage;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.progressPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pctText = '${(progressPercentage * 100).toInt()}% complete';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14.0),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -18.0,
              top: -18.0,
              child: Container(
                width: 70.0,
                height: 70.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: course.color.withOpacity(0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: course.color.withOpacity(0.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      course.icon,
                      style: const TextStyle(fontSize: 18.0),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course.code,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          course.name,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: progressPercentage.clamp(0.0, 1.0),
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            color: AppColors.primary,
                            minHeight: 5.0,
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          pctText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.onPrimary,
                      size: 16.0,
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
}
