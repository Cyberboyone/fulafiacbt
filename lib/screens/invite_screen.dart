import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/profile_provider.dart';
import '../services/hive_service.dart';
import '../widgets/powered_by_footer.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _friendCodeController = TextEditingController();
  final HiveService _hiveService = HiveService();
  bool _isClaiming = false;
  bool _claimed = false;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  void _shareReferral(String code) {
    final msg = 'Join me on CBT to practice and pass your courses offline!\n'
        'Use my invite code: $code to unlock 20 bonus coins instantly.\n'
        'Download the app now!';
    Share.share(msg);
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code copied to clipboard!')),
      );
    });
  }

  void _claimBonus() {
    final code = _friendCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isClaiming = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (code == profileProvider.profile?.referralCode) {
        setState(() {
          _isClaiming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot enter your own referral code!'), backgroundColor: AppColors.destructive),
        );
        return;
      }

      final codePattern = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$');
      if (!codePattern.hasMatch(code)) {
        setState(() {
          _isClaiming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code format. Use format: XXXX-XXXX'), backgroundColor: AppColors.destructive),
        );
        return;
      }

      if (_hiveService.isReferralCodeClaimed(code)) {
        setState(() {
          _isClaiming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This code has already been claimed!'), backgroundColor: AppColors.destructive),
        );
        return;
      }

      _hiveService.markReferralCodeClaimed(code);
      profileProvider.addCoins(AppConstants.referralBonusCoins);

      setState(() {
        _isClaiming = false;
        _claimed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully claimed! +20 Coins added to balance.'),
          backgroundColor: AppColors.correct,
        ),
      );
      _friendCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final profile = context.watch<ProfileProvider>().profile;
    final code = profile?.referralCode ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invite & Referrals', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          children: [
            Container(
              height: 140.0,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: AppColors.clayShadowLarge,
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, color: AppColors.onPrimary, size: 40.0),
                  SizedBox(width: 12.0),
                  Icon(Icons.people_rounded, color: AppColors.onPrimary, size: 40.0),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            Text('Share the Knowledge', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 8.0),
            Text(
              'Invite your classmates to practice on CBT. You both receive 20 bonus coins when they enter your code!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 24.0),

            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text('YOUR REFERRAL CODE', style: TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.0),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.accent),
                          onPressed: () => _copyCode(code),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareReferral(code),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Code via WhatsApp / SMS'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            if (!_claimed) ...[
              Text('Enter Invite Code', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Paste a friend\'s code (format: XXXX-XXXX) to unlock 20 starter coins immediately.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.0, height: 1.3),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _friendCodeController,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g., MUSA-A1B2',
                              hintStyle: TextStyle(fontSize: 13.0, color: AppColors.textMuted),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        SizedBox(
                          height: 48.0,
                          child: ElevatedButton(
                            onPressed: _isClaiming ? null : _claimBonus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              elevation: 0,
                            ),
                            child: _isClaiming
                                ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.onPrimary))
                                : const Text('Claim', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],

            const PoweredByFooter(),
          ],
        ),
      ),
    );
  }
}
