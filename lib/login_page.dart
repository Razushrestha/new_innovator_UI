import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';

import 'dashboard_page.dart';
import 'models/api_response.dart';
import 'services/auth_api.dart';
import 'services/auth_session.dart';
import 'signup_page.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_orb_logo.dart';
import 'widgets/glass_text_field.dart';
import 'widgets/google_logo.dart';
import 'widgets/liquid_button.dart';

const _ink = BrandColors.ink;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApi();
  bool _busy = false;

  Future<void> _enterDashboard() async {
    final email = AuthSession.instance.email ??
        _emailController.text.trim().ifEmpty('demo@innovator.com');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: DashboardPage(email: email),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Enter email and password');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.login(email: email, password: password);
      await _enterDashboard();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not sign in');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _authApi.loginWithGoogle();
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GlassOrbLogo(size: 52),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5,
                              height: 1.15,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign in to continue to Innovator',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              color: _ink.withValues(alpha: .5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            dense: true,
                          ),
                          const SizedBox(height: 8),
                          GlassTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.key_rounded,
                            obscure: true,
                            dense: true,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _ink.withValues(alpha: .55),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          else ...[
                            LiquidButton(
                              label: 'Sign In',
                              dense: true,
                              onTap: _signIn,
                            ),
                            const SizedBox(height: 8),
                            const _OrDivider(),
                            const SizedBox(height: 8),
                            LiquidButton(
                              label: 'Continue with Google',
                              dark: false,
                              dense: true,
                              leading: const GoogleLogo(),
                              onTap: _signInWithGoogle,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _ink.withValues(alpha: .5),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 450,
                                      ),
                                      pageBuilder: (_, animation, __) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: const SignupPage(),
                                          ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontSize: 13,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or',
            style: TextStyle(fontSize: 12, color: _ink.withValues(alpha: .4)),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _ink.withValues(alpha: .12)),
        ),
      ],
    );
  }
}
