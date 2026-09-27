import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  bool _register = false, _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chitwan Care')),
      body: SafeArea(
        child: PageShell(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 30),
                const Eyebrow('BHARATPUR · CHITWAN'),
                const SizedBox(height: 16),
                Text(
                  _register ? 'Create your account' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Report waste and follow the progress of a cleaner destination.',
                ),
                const SizedBox(height: 28),
                if (_register)
                  TextFormField(
                    controller: _name,
                    enabled: !auth.busy,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter your name.' : null,
                  ),
                TextFormField(
                  controller: _email,
                  enabled: !auth.busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v.trim())
                      ? 'Enter a valid email.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _password,
                  enabled: !auth.busy,
                  obscureText: _obscure,
                  autofillHints: [
                    _register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: _register
                        ? 'At least 8 characters; at most 72 UTF-8 bytes.'
                        : null,
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null ||
                          v.isEmpty ||
                          (_register && v.length < 8) ||
                          utf8.encode(v).length > 72
                      ? 'Enter a valid password.'
                      : null,
                ),
                const SizedBox(height: 20),
                if (auth.error != null) Notice(auth.error!, warning: true),
                if (auth.busy) const LinearProgressIndicator(),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: auth.busy
                      ? null
                      : () {
                          if (_form.currentState!.validate()) {
                            ref
                                .read(authProvider.notifier)
                                .authenticate(
                                  register: _register,
                                  email: _email.text,
                                  password: _password.text,
                                  name: _name.text,
                                );
                          }
                        },
                  child: Text(_register ? 'Register' : 'Log in'),
                ),
                TextButton(
                  onPressed: auth.busy
                      ? null
                      : () => setState(() {
                          _register = !_register;
                          _password.clear();
                          _form.currentState?.reset();
                        }),
                  child: Text(
                    _register
                        ? 'Already registered? Log in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
