import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../domain/auth_repository.dart';
import '../domain/customer_profile.dart';

const _teal = Color(0xFF007F78);
const _ink = Color(0xFF142B36);
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
String? _validateEmail(String? value) =>
    _emailPattern.hasMatch(value?.trim() ?? '')
    ? null
    : 'Enter a valid email address';
String _errorMessage(Object error) => error is AuthFailure
    ? error.message
    : 'Something went wrong. Please try again.';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signup = false, _busy = false, _obscure = true;
  String? _error, _notice;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _authenticate(
    Future<AppUser> Function(AuthRepository) action,
  ) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final auth = ref.read(authRepositoryProvider);
    final profiles = ref.read(customerProfileRepositoryProvider);
    final flow = ref.read(authFlowBusyProvider.notifier);
    final signupName = _signup ? _name.text.trim() : '';
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    flow.setBusy(true);
    try {
      final user = await action(auth);
      final existing = await profiles.get(user.id);
      final name = signupName.isNotEmpty ? signupName : user.displayName;
      if (existing == null && name.isNotEmpty && user.email.isNotEmpty) {
        await profiles.save(
          CustomerProfile(
            userId: user.id,
            fullName: name,
            email: user.email,
            phone: user.phone,
          ),
        );
      }
      if (mounted) ref.invalidate(customerProfileProvider);
    } on AuthCancelled {
      // Cancelling an account picker simply returns to the sign-in form.
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
      flow.setBusy(false);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    await _authenticate(
      (auth) => _signup
          ? auth.signUpWithEmail(name, email, password)
          : auth.signInWithEmail(email, password),
    );
  }

  Future<void> _resetPassword() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (_validateEmail(email) != null) {
      setState(
        () => _error = 'Enter your email address above to reset your password.',
      );
      return;
    }
    final auth = ref.read(authRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await auth.resetPassword(email);
      if (mounted) {
        setState(
          () => _notice =
              'If an account exists for this email, a password reset link has been sent.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.videocam_outlined, size: 60, color: _teal),
                    const SizedBox(height: 20),
                    Text(
                      _signup ? 'Create your account' : 'Welcome to CameraCare',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('Service support for your security cameras.'),
                    if (ref.watch(demoModeProvider)) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Demo mode · accounts are stored only for this session.',
                        style: TextStyle(color: _teal),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (_signup) ...[
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v?.trim().length ?? 0) >= 2
                            ? null
                            : 'Enter your name',
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        _signup
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => (v ?? '').isEmpty
                          ? 'Enter your password'
                          : _signup && v!.length < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirm,
                        enabled: !_busy,
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v == _password.text
                            ? null
                            : 'Passwords do not match',
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_notice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _notice!,
                          style: const TextStyle(color: _teal),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          _busy
                              ? 'Please wait…'
                              : _signup
                              ? 'Create account'
                              : 'Sign in',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _authenticate(
                              (auth) => auth.signInWithGoogle(),
                            ),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () =>
                                _authenticate((auth) => auth.signInWithApple()),
                      icon: const Icon(Icons.apple),
                      label: const Text('Continue with Apple'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _signup = !_signup;
                              _error = null;
                              _notice = null;
                              _confirm.clear();
                            }),
                      child: Text(
                        _signup
                            ? 'Already registered? Sign in'
                            : 'New customer? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key, required this.user});
  final AppUser user;
  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _email;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    final profiles = ref.read(customerProfileRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await profiles.save(
        CustomerProfile(
          userId: widget.user.id,
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          phone: widget.user.phone,
        ),
      );
      if (mounted) ref.invalidate(customerProfileProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your profile. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 56, color: _teal),
                  const SizedBox(height: 20),
                  Text(
                    'Complete your profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Add your contact details to continue.'),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) =>
                        (v?.trim().length ?? 0) >= 2 ? null : 'Enter your name',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    readOnly: widget.user.email.isNotEmpty,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: _validateEmail,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? 'Saving…' : 'Save and continue'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
