import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/core/providers/app_settings_provider.dart';
import 'package:rumboapp/core/providers/onboarding_page_provider.dart';
import 'package:rumboapp/core/widgets/rumbo_brand.dart';

class _OnboardingPageData {
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final IconData secondaryIcon;

  const _OnboardingPageData({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.secondaryIcon,
  });
}

const List<_OnboardingPageData> _onboardingPages = [
  _OnboardingPageData(
    label: 'ORGANIZACIÓN',
    title: 'Tus documentos, siempre en orden.',
    description:
        'Registra los documentos que necesitas para viajar, '
        'organiza sus fechas importantes y consulta tus pendientes '
        'antes de salir.',
    icon: Icons.folder_copy_outlined,
    secondaryIcon: Icons.verified_user_outlined,
  ),
  _OnboardingPageData(
    label: 'PLANEACIÓN',
    title: 'Planea mejor tus recorridos.',
    description:
        'Organiza rutas, conoce los puntos de peaje disponibles '
        'y prepara tus trayectos con información útil para '
        'cada destino.',
    icon: Icons.route_rounded,
    secondaryIcon: Icons.location_on_outlined,
  ),
  _OnboardingPageData(
    label: 'PRESUPUESTO',
    title: 'Calcula cuánto puede costar tu viaje.',
    description:
        'Estima gastos de combustible, peajes y hospedaje. '
        'Organiza presupuestos en distintas monedas y consulta '
        'el costo aproximado de tus recorridos.',
    icon: Icons.account_balance_wallet_outlined,
    secondaryIcon: Icons.currency_exchange_rounded,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final int currentPage = ref.read(onboardingPageProvider);

    if (currentPage < _onboardingPages.length - 1) {
      await _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(appSettingsProvider.notifier).completeOnboarding();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible guardar tus preferencias. '
            'Intenta nuevamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentPage = ref.watch(onboardingPageProvider);

    // final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    final bool isLastPage = currentPage == _onboardingPages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth > 900
                ? 40
                : 22;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _onboardingPages.length,
                          onPageChanged: (index) {
                            ref
                                .read(onboardingPageProvider.notifier)
                                .setPage(index);
                          },
                          itemBuilder: (context, index) {
                            return _OnboardingSlide(
                              data: _onboardingPages[index],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFooter(
                        currentPage: currentPage,
                        isLastPage: isLastPage,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const RumboBrand(iconSize: 42, textSize: 22),
        const Spacer(),
        TextButton(onPressed: _completeOnboarding, child: const Text('Omitir')),
      ],
    );
  }

  Widget _buildFooter({required int currentPage, required bool isLastPage}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Row(
          children: List.generate(_onboardingPages.length, (index) {
            final bool isSelected = currentPage == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 7),
              width: isSelected ? 25 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isLastPage ? 'Comenzar' : 'Continuar'),
              const SizedBox(width: 9),
              Icon(
                isLastPage
                    ? Icons.arrow_forward_rounded
                    : Icons.chevron_right_rounded,
                size: 19,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 690;

        final Widget artwork = _OnboardingArtwork(
          icon: data.icon,
          secondaryIcon: data.secondaryIcon,
          size: isWide ? 280 : 218,
        );

        final Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isWide
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Text(
              data.label,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              data.title,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.description,
              textAlign: isWide ? TextAlign.start : TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.65,
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 40
                  ? constraints.maxHeight - 40
                  : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 5, child: Center(child: artwork)),
                          const SizedBox(width: 48),
                          Expanded(flex: 6, child: content),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          artwork,
                          const SizedBox(height: 36),
                          content,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingArtwork extends StatelessWidget {
  final IconData icon;
  final IconData secondaryIcon;
  final double size;

  const _OnboardingArtwork({
    required this.icon,
    required this.secondaryIcon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(size * 0.18),
            ),
            child: Icon(
              icon,
              size: size * 0.40,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          Positioned(
            right: 0,
            top: size * 0.10,
            child: _FloatingIcon(
              icon: Icons.check_rounded,
              background: colorScheme.primary,
              foreground: colorScheme.onPrimary,
              size: size * 0.23,
            ),
          ),
          Positioned(
            left: 0,
            bottom: size * 0.12,
            child: _FloatingIcon(
              icon: secondaryIcon,
              background: colorScheme.surface,
              foreground: colorScheme.primary,
              size: size * 0.26,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  const _FloatingIcon({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: size * 0.48),
    );
  }
}
