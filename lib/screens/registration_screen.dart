import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../enums/app_enums.dart';
import '../models/user_model.dart';
import '../validators/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Screen 1 — collects new-user details with full real-time validation.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  Gender? _gender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Tracks whether the form currently passes every validation rule,
  /// so the submit button can be enabled/disabled in real time.
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the form whenever any field changes.
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _password,
      _confirmPassword,
    ]) {
      c.addListener(_revalidate);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _password,
      _confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Recomputes [_isFormValid] without showing error text — that is
  /// handled per-field by [AutovalidateMode.onUserInteraction].
  void _revalidate() {
    final valid = Validators.validateName(_firstName.text,
                fieldName: 'First name') ==
            null &&
        Validators.validateName(_lastName.text, fieldName: 'Last name') ==
            null &&
        Validators.validateEmail(_email.text) == null &&
        Validators.validatePassword(_password.text) == null &&
        Validators.validateConfirmPassword(
              _confirmPassword.text,
              _password.text,
            ) ==
            null &&
        Validators.validateSelection(_gender, fieldName: 'gender') == null;

    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _gender == null) return;

    final auth = context.read<AuthController>();
    final result = await auth.register(
      UserModel(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        gender: _gender!,
        password: _password.text,
      ),
    );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message ?? ''),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (result.isSuccess) {
      NavigationController.toLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isBusy = auth.state == AuthState.authenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _firstName,
                  label: 'First Name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'First name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _lastName,
                  label: 'Last Name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.validateName(v, fieldName: 'Last name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _email,
                  label: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                _GenderDropdown(
                  value: _gender,
                  onChanged: (g) {
                    setState(() => _gender = g);
                    _revalidate();
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Password must be at least 6 characters and include '
                  '1 uppercase letter and 1 special character.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPassword,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.validateConfirmPassword(
                      v, _password.text),
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Register',
                  enabled: _isFormValid,
                  isLoading: isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () =>
                          NavigationController.toLogin(context),
                      child: const Text('Log in'),
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

/// Gender dropdown wired to the [Gender] enum.
class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final Gender? value;
  final ValueChanged<Gender?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Gender>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.wc_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (v) =>
          Validators.validateSelection(v, fieldName: 'gender'),
      items: Gender.values
          .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
