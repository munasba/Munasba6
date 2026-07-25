import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentPink.withOpacity(0.6),
                  backgroundImage: (user?.imagePath != null && File(user!.imagePath!).existsSync())
                      ? FileImage(File(user.imagePath!))
                      : null,
                  child: user?.imagePath == null
                      ? Icon(user?.gender.name == 'female' ? Icons.face_3_rounded : Icons.face_6_rounded, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'ضيف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user?.gender.name == 'female' ? 'أنثى' : 'ذكر', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'الوضع الداكن',
            trailing: Switch(
              value: userProvider.darkMode,
              activeColor: AppColors.primary,
              onChanged: (v) => userProvider.toggleDarkMode(v),
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'مساعدة',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'عن التطبيق',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'مناسبة',
              applicationVersion: '1.0.0',
              applicationLegalese: 'تطبيق لتنظيم المناسبات وإدارة الدعوات والمدعوين.',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            color: AppColors.danger,
            onTap: () async {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: c),
        title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        trailing: trailing ?? const Icon(Icons.chevron_left, color: AppColors.textMuted),
      ),
    );
  }
}
