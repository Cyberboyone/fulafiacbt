import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../widgets/powered_by_footer.dart';
import '../config/routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  final TextEditingController _restoreController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _restoreController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _copyBackupCode(BuildContext context) {
    final code = _backupService.generateBackupCode();
    if (code.isEmpty) return;

    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup code copied to clipboard!')),
      );
    });
  }

  void _restoreProgress() {
    final code = _restoreController.text.trim();
    if (code.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        title: const Text('Overwrite All Data?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Text('This will permanently delete your current progress and replace it with the backup data. Continue?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeRestore(code);
            },
            child: const Text('Restore', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executeRestore(String code) {
    _backupService.restoreFromCode(code).then((success) {
      if (success) {
        Provider.of<ProfileProvider>(context, listen: false).loadProfile();
        Provider.of<SettingsProvider>(context, listen: false).refresh();
        _restoreController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress successfully restored!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid backup code. Please try again.')),
        );
      }
    });
  }

  void _saveNewNickname() {
    final newName = _nicknameController.text.trim();
    if (newName.length < 2 || newName.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname must be 2-15 characters')),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9 _-]+$').hasMatch(newName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only letters, numbers, spaces, _ and - allowed')),
      );
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setNickname(newName);

    setState(() {
      _isEditingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    final profile = profileProvider.profile;
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
          children: [
            if (profile != null) ...[
              Text(
                'Identity',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12.0),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(profile.nickname.isNotEmpty ? profile.nickname[0].toUpperCase() : 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: _isEditingName
                          ? TextField(
                              controller: _nicknameController..text = profile.nickname,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              autofocus: true,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.nickname,
                                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Referral Code: ${profile.referralCode}',
                                  style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingName ? Icons.check_circle : Icons.edit, color: AppColors.accent),
                      onPressed: () {
                        if (_isEditingName) {
                          _saveNewNickname();
                        } else {
                          setState(() {
                            _isEditingName = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],

            Text(
              'App Configurations',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12.0),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text('Switch between light and dark theme', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    value: settings.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      settingsProvider.toggleDarkMode(val);
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  SwitchListTile(
                    title: Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text('Play audio cues for answers', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    value: settings.soundOn,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      settingsProvider.toggleSound(val);
                    },
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  SwitchListTile(
                    title: Text('Low Data Mode', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text('Prompt before loading large assets', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    value: settings.lowDataMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      settingsProvider.toggleLowDataMode(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            Text(
              'Progress Backup & Recovery',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12.0),
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup your offline practice metrics, Streaks, XP, and unlock milestones. Generates an encrypted string code to paste on any new device.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.0, height: 1.4),
                  ),
                  const SizedBox(height: 16.0),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyBackupCode(context),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Generate & Copy Backup Code'),
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),

                  const Text(
                    'Restore Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.0),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _restoreController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Paste backup code here...',
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
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: OutlinedButton(
                      onPressed: _restoreProgress,
                      child: const Text('Restore from Code', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.xpLight,
                  child: Icon(Icons.emoji_events_rounded, color: AppColors.xp),
                ),
                title: Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Text('View your badges and milestones', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.badges);
                },
              ),
            ),
            const SizedBox(height: 12.0),

            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.coinsLight,
                  child: Icon(Icons.monetization_on_rounded, color: AppColors.coins),
                ),
                title: Text('Coin Shop', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Text('Spend coins on hints and streak freezes', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.shop);
                },
              ),
            ),
            const SizedBox(height: 24.0),

            Container(
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.correctLight,
                  child: Icon(Icons.card_giftcard_rounded, color: AppColors.correct),
                ),
                title: Text('Invite Friends', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Text('Share your code and earn 20 bonus coins', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.invite);
                },
              ),
            ),
            const SizedBox(height: 24.0),

            if (!settings.adsRemoved) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.secondary, size: 24.0),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remove Ads Forever', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 2.0),
                          Text('Unlock Premium study without interruptions.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        settingsProvider.setAdsRemoved(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Premium Mode Activated (Simulation)')),
                        );
                      },
                      child: const Text('Unlock', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
                color: AppColors.destructive.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.destructive)),
                  const SizedBox(height: 4.0),
                  Text('Clears all profiles and offline caching progress from this device.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                          backgroundColor: AppColors.surface,
                          title: const Text('Reset All Data?', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
                          content: const Text('This action is irreversible. All offline progress will be lost.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.primary))),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                profileProvider.resetProfile().then((_) {
                                  Navigator.pushReplacementNamed(context, AppRoutes.splash);
                                });
                              },
                              child: const Text('Reset', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.destructive, padding: EdgeInsets.zero),
                    child: const Text('Delete All Progress Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const PoweredByFooter(),
          ],
        ),
      ),
    );
  }
}
