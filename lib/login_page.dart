import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'signup_page.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_orb_logo.dart';
import 'widgets/glass_text_field.dart';
import 'widgets/liquid_button.dart';

const _ink = Color(0xFF1B1E28);

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
  ).animate(
    CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Auth is bypassed for now: any (or no) credentials go straight to the
  // dashboard. Wire a real backend here later.
  void _signIn() {
    final email = _emailController.text.trim();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: DashboardPage(
            email: email.isEmpty ? 'demo@innovator.com' : email,
          ),
        ),
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
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Sign in to continue to Innovator',
                            style: TextStyle(
                              fontSize: 14,
                              color: _ink.withValues(alpha: .5),
                            ),
                          ),
                          const SizedBox(height: 32),
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    _ink.withValues(alpha: .55),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          LiquidButton(
                            label: 'Sign In',
                            onTap: _signIn,
                          ),
                          const SizedBox(height: 26),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: _ink.withValues(alpha: .5),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration:
                                          const Duration(milliseconds: 450),
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
                                      horizontal: 6, vertical: 8),
                                  child: Text(
                                    'Sign up',
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
