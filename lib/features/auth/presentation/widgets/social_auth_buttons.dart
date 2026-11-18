import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';
import 'package:rumboapp/features/auth/application/auth_error_message.dart';

class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthErrorMessage.from(error))));
    }
  }

  Future<void> _signInWithGitHub(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGitHub();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _signInWithGoogle(context, ref),
          icon: const Text(
            'G',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _signInWithGitHub(context, ref),
          icon: const Icon(Icons.code_rounded),
          label: const Text('Continuar con GitHub'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}
