import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'user_setup_screen.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardPage({required this.icon, required this.title, required this.subtitle});
}

const _pages = [
  _OnboardPage(
    icon: Icons.favorite_rounded,
    title: 'مناسبة',
    subtitle: 'كل مناسبة تستحق أن تُنظم بأجمل طريقة',
  ),
  _OnboardPage(
    icon: Icons.event_note_rounded,
    title: 'أنشئ مناسباتك بسهولة',
    subtitle: 'أضف تفاصيل مناسبتك من تاريخ ومكان ووصف في خطوات بسيطة',
  ),
  _OnboardPage(
    icon: Icons.mail_rounded,
    title: 'شارك دعوتك مع من تحب',
    subtitle: 'أرسل بطاقات الدعوة لمدعويك وشاركها بضغطة واحدة',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UserSetupScreen()),
    );
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _PageContent(page: _pages[i], isFirst: i == 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('تخطي', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.accentPink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _next,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            if (_index == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('لنبدأ رحلتنا'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final bool isFirst;
  const _PageContent({required this.page, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.accentPink.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: Icon(page.icon, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }
}
