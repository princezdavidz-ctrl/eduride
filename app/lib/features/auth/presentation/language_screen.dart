import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import 'controllers/language_controller.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  late final LanguageController _controller;
  late final AnimationController _animationController;
  late final Animation<Offset> _englishSlide;
  late final Animation<Offset> _swahiliSlide;

  @override
  void initState() {
    super.initState();
    _controller = LanguageController();
    _controller.addListener(_handleLocaleChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _englishSlide =
        Tween<Offset>(begin: const Offset(-0.45, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _swahiliSlide =
        Tween<Offset>(begin: const Offset(0.45, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.22, 0.88, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleLocaleChanged);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLocaleChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocale = _controller.locale;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/language.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const ColoredBox(color: Color(0xDFFFFFFF)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: Color(0xFF1769E0),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Choose your language',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can change this later in Settings.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: _englishSlide,
                        child: _LanguageOption(
                          label: 'English',
                          selected: selectedLocale.languageCode == 'en',
                          onTap: () =>
                              _controller.setLocale(const Locale('en')),
                        ),
                      ),
                      SlideTransition(
                        position: _swahiliSlide,
                        child: _LanguageOption(
                          label: 'Kiswahili',
                          selected: selectedLocale.languageCode == 'sw',
                          onTap: () =>
                              _controller.setLocale(const Locale('sw')),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () async {
                            final locale = _controller.locale;
                            await _controller.setLocale(locale);
                            if (!context.mounted) return;
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.login);
                          },
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF1769E0) : const Color(0xFFE4E7EC),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? const Color(0xFF1769E0) : const Color(0xFF98A2B3),
          ),
        ],
      ),
    ),
  );
}
