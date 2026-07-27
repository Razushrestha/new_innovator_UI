import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';

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
  String? _gender;

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
                          LiquidButton(label: 'Sign Up', onTap: () {}),
                          const SizedBox(height: 18),
                          const _OrDivider(),
                          const SizedBox(height: 18),
                          LiquidButton(
                            label: 'Continue with Google',
                            dark: false,
                            leading: const GoogleLogo(),
                            onTap: () {},
                          ),
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
