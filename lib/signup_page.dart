import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';

import 'dashboard_page.dart';
import 'models/api_response.dart';
import 'services/auth_api.dart';
import 'services/auth_session.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_gender_selector.dart';
import 'widgets/glass_orb_logo.dart';
import 'widgets/glass_text_field.dart';
import 'widgets/google_logo.dart';
import 'widgets/liquid_button.dart';

const _ink = BrandColors.ink;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, .8, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApi();
  String? _gender;
  bool _busy = false;

  String _usernameFromName(String name) {
    final cleaned = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (cleaned.length >= 3) return cleaned;
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'user_$stamp';
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _toast('Fill name, email, and password');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.register(
        username: _usernameFromName(name),
        email: email,
        password: password,
      );
      if (!mounted) return;
      await _enterDashboard();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not create account');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _authApi.loginWithGoogle();
      if (!mounted) return;
      await _enterDashboard();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('canceled')) return;
      _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not sign in with Google');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterDashboard() async {
    final resolved = AuthSession.instance.email ??
        _emailController.text.trim().ifEmpty('demo@innovator.com');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: DashboardPage(email: resolved),
        ),
      ),
      (_) => false,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GlassOrbLogo(),
                          const SizedBox(height: 22),
                          const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Join Innovator in a few seconds',
                            style: TextStyle(
                              fontSize: 14,
                              color: _ink.withValues(alpha: .5),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GlassTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          GlassTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.key_rounded,
                            obscure: true,
                          ),
                          const SizedBox(height: 14),
                          GlassGenderSelector(
                            value: _gender,
                            onChanged: (gender) =>
                                setState(() => _gender = gender),
                          ),
                          const SizedBox(height: 24),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          else ...[
                            LiquidButton(label: 'Sign Up', onTap: _signUp),
                            const SizedBox(height: 18),
                            const _OrDivider(),
                            const SizedBox(height: 18),
                            LiquidButton(
                              label: 'Continue with Google',
                              dark: false,
                              leading: const GoogleLogo(),
                              onTap: _signInWithGoogle,
                            ),
                          ],
                          const SizedBox(height: 26),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: _ink.withValues(alpha: .5),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: _ink.withValues(alpha: .12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(fontSize: 12.5, color: _ink.withValues(alpha: .4)),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _ink.withValues(alpha: .12)),
        ),
      ],
    );
  }
}
