import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class PoweredByFooter extends StatelessWidget {
  const PoweredByFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/fulafia_logo.png',
              height: 60,
              width: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                children: [
                  const TextSpan(text: 'Powered by '),
                  TextSpan(
                    text: 'Siyayya.com',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(Uri.parse('https://siyayya.com')),
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
