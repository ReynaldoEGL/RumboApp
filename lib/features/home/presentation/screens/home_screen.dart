import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/app/app_routes.dart';
import 'package:rumboapp/core/providers/theme_mode_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.explore_rounded),
            SizedBox(width: 10),
            Text(
              'Rumbo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: themeMode == ThemeMode.dark
                ? 'Cambiar a tema claro'
                : 'Cambiar a tema oscuro',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxContentWidth = constraints.maxWidth > 1120
                ? 1120
                : constraints.maxWidth;

            final double horizontalPadding = maxContentWidth >= 900 ? 32 : 20;

            final double availableWidth =
                maxContentWidth - (horizontalPadding * 2);

            final double cardWidth = availableWidth >= 720
                ? (availableWidth - 32) / 3
                : availableWidth;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, viajero',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Prepara cada detalle de tu viaje '
                        'desde un solo lugar.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const _WelcomeBanner(),

                      const SizedBox(height: 36),

                      Text(
                        'Planea sin complicarte',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Todo lo que necesitas para organizar '
                        'tu próxima salida.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _FeatureCard(
                              icon: Icons.folder_copy_outlined,
                              title: 'Documentos',
                              description:
                                  'Organiza pasaportes, visas, '
                                  'identificaciones y vigencias.',
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.documents);
                              },
                            ),
                          ),

                          SizedBox(
                            width: cardWidth,
                            child: _FeatureCard(
                              icon: Icons.route_outlined,
                              title: 'Rutas y casetas',
                              description:
                                  'Planea recorridos y consulta '
                                  'estimaciones de peajes.',
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.roadRoutes);
                              },
                            ),
                          ),

                          SizedBox(
                            width: cardWidth,
                            child: _FeatureCard(
                              icon: Icons.luggage_outlined,
                              title: 'Mis viajes',
                              description:
                                  'Agrupa itinerarios, presupuestos '
                                  'y pendientes.',
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.trips);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      const _PreparationNote(),
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
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 620;

        final Color secondColor =
            Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.4) ??
            colorScheme.tertiary;

        final Widget message = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu próximo viaje, mejor organizado.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Documentos, rutas y gastos en un mismo lugar. '
              'Dedica menos tiempo a organizar y más a disfrutar.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.88),
                height: 1.5,
              ),
            ),
          ],
        );

        final Widget illustration = Container(
          width: compact ? 104 : 136,
          height: compact ? 104 : 136,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.onPrimary.withValues(alpha: 0.12),
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            Icons.travel_explore_rounded,
            size: compact ? 58 : 78,
            color: colorScheme.onPrimary,
          ),
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, secondColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message,
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: illustration,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: message),
                    const SizedBox(width: 28),
                    illustration,
                  ],
                ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 224,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onSecondaryContainer,
                    size: 25,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),

                Row(
                  children: [
                    Text(
                      'Explorar',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: colorScheme.primary,
                      size: 19,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparationNote extends StatelessWidget {
  const _PreparationNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Antes de salir',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _ReminderLine(text: 'Comprueba la vigencia de tus documentos.'),

          const SizedBox(height: 12),

          const _ReminderLine(text: 'Revisa la ruta y los gastos estimados.'),

          const SizedBox(height: 12),

          const _ReminderLine(
            text: 'Mantén tus documentos importantes protegidos.',
          ),
        ],
      ),
    );
  }
}

class _ReminderLine extends StatelessWidget {
  final String text;

  const _ReminderLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
