import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';
import 'package:rumboapp/features/auth/application/auth_error_message.dart';

import 'package:rumboapp/features/auth/presentation/widgets/auth_page_layout.dart';

class EmailVerificationScreen extends ConsumerWidget {
  final User user;

  const EmailVerificationScreen({super.key, required this.user});

  Future<void> _resendEmail(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Correo de verificación enviado. Revisa tu bandeja de entrada.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthErrorMessage.from(error))));
    }
  }

  Future<void> _checkVerification(BuildContext context, WidgetRef ref) async {
    try {
      final bool verified = await ref
          .read(authControllerProvider.notifier)
          .refreshVerificationStatus();

      if (!context.mounted) {
        return;
      }

      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Todavía no se detecta la verificación. '
              'Revisa tu correo e intenta nuevamente.',
            ),
          ),
        );
      }

      // Si está verificado, userChanges actualiza AuthGate
      // y la pantalla principal aparece automáticamente.
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthErrorMessage.from(error))));
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthErrorMessage.from(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    final email = user.email ?? 'tu dirección de correo';

    return AuthPageLayout(
      title: 'Verifica tu correo',
      description:
          'Antes de utilizar Rumbo necesitamos confirmar '
          'que tienes acceso a tu dirección de correo electrónico.',

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Dirección asociada a tu cuenta:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 6),

          SelectableText(
            email,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 18),

          const Text(
            'Comprueba tu bandeja de entrada y abre el enlace '
            'de verificación. Si no recibiste el mensaje, '
            'puedes solicitar que se envíe nuevamente.',
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: isLoading
                ? null
                : () => _checkVerification(context, ref),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Ya verifiqué mi correo'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: isLoading ? null : () => _resendEmail(context, ref),
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Reenviar correo'),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: isLoading ? null : () => _signOut(context, ref),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
