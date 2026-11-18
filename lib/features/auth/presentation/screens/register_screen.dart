import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';
import 'package:rumboapp/features/auth/application/auth_error_message.dart';

import 'package:rumboapp/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:rumboapp/features/auth/presentation/widgets/social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!pattern.hasMatch(email)) {
      return 'Ingresa un correo válido.';
    }

    return null;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Firebase crea la cuenta antes de enviar el correo.
      // Si falla el envío, mostramos la pantalla de verificación
      // en lugar de intentar registrar nuevamente la misma cuenta.
      final currentUser = ref.read(authRepositoryProvider).currentUser;

      if (currentUser?.email?.toLowerCase() ==
          _emailController.text.trim().toLowerCase()) {
        Navigator.of(context).pop();
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthErrorMessage.from(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthPageLayout(
      title: 'Crea tu cuenta',
      description: 'Registra tu cuenta para comenzar a organizar tus viajes.',

      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.newUsername,
              ],
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                helperText: 'Utiliza al menos 8 caracteres.',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una contraseña.';
                }

                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña.';
                }

                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!isLoading) {
                  _register();
                }
              },
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: isLoading ? null : _register,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),

            const SizedBox(height: 24),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('O regístrate con'),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 18),

            const SocialAuthButtons(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(child: Text('¿Ya tienes una cuenta?')),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
