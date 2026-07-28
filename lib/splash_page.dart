import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';
import 'dashboard_page.dart';
import 'services/auth_session.dart';
import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/wave_fill_painter.dart';

const _logoAsset = 'Assets/logss-removebg-preview.png';

/// Opening splash: liquid-glass orb with the Innovator mark, a rising wave,
/// and a soft exit into login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final Animation<double> _orbScale = Tween<double>(begin: .72, end: 1)
      .animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0, .75, curve: Curves.easeOutBack),
        ),
      );

  late final Animation<double> _orbFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, .45, curve: Curves.easeOut),
  );

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(.45, 1, curve: Curves.easeOut),
  );

  late final Animation<Offset> _titleSlide =
      Tween<Offset>(begin: const Offset(0, .35), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(.45, 1, curve: Curves.easeOutCubic),
        ),
      );

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _fill.forward();
    });
    _navTimer = Timer(const Duration(milliseconds: 2600), _goLogin);
  }

  Future<void> _goLogin() async {
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    final signedIn = AuthSession.instance.isSignedIn;
    final email = AuthSession.instance.email ?? 'demo@innovator.com';
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: signedIn ? DashboardPage(email: email) : const LoginPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entrance.dispose();
    _wave.dispose();
    _fill.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: BrandColors.canvas,
        body: AnimatedBuilder(
          animation: _exit,
          builder: (context, child) {
            final leave = Curves.easeInCubic.transform(_exit.value);
            return Opacity(
              opacity: (1 - leave).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 - leave * .06,
                child: child,
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AnimatedBlobBackground(animate: true),
              // Soft gold mist behind the orb.
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_wave, _fill]),
                  builder: (context, _) {
                    final pulse =
                        1 + .04 * sin(_wave.value * 2 * pi);
                    return Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              BrandColors.accent.withValues(
                                alpha: .22 * _fill.value,
                              ),
                              BrandColors.accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _entrance,
                    builder: (context, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _orbFade,
                            child: ScaleTransition(
                              scale: _orbScale,
                              child: const _LiquidLogoOrb(),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Column(
                                children: [
                                  const Text(
                                    'INNOVATOR',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: BrandColors.ink,
                                      letterSpacing: -.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'where every innovations get capture',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                      color: BrandColors.ink.withValues(
                                        alpha: .45,
                                      ),
                                      letterSpacing: .2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AnimatedBuilder(
                                    animation: _fill,
                                    builder: (context, _) {
                                      return Container(
                                        width: 36 * _fill.value,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          color: BrandColors.accent,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidLogoOrb extends StatefulWidget {
  const _LiquidLogoOrb();

  @override
  State<_LiquidLogoOrb> createState() => _LiquidLogoOrbState();
}

class _LiquidLogoOrbState extends State<_LiquidLogoOrb>
    with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_wave, _fill, _sheen]),
      builder: (context, _) {
        final level = Curves.easeOutCubic.transform(_fill.value);
        final phase = _wave.value * 2 * pi;

        return Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BrandColors.secondarySurface.withValues(alpha: .18),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: BrandColors.accent.withValues(alpha: .28 * level),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BrandColors.secondarySurface.withValues(alpha: .92),
                          const Color(0xFF0C1A2C),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .55),
                        width: 1.6,
                      ),
                    ),
                  ),
                  // Rising liquid gold wash inside the dark glass.
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: phase,
                      fill: level * 1.05,
                      color: BrandColors.accent.withValues(alpha: .22),
                      amplitude: 5,
                      frequency: 1.35,
                    ),
                  ),
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: phase + 1.3,
                      fill: level * .55,
                      color: Colors.white.withValues(alpha: .1),
                      amplitude: 3.5,
                      frequency: 1.8,
                    ),
                  ),
                  // Drifting glass sheen.
                  Align(
                    alignment: Alignment(-1.6 + 3.2 * _sheen.value, -.2),
                    child: Transform.rotate(
                      angle: -.55,
                      child: Container(
                        width: 42,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: .28),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Logo sits on the liquid glass.
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Image.asset(
                      _logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  // Frosted gold rim.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BrandColors.accent.withValues(
                            alpha: .45 + .35 * level,
                          ),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
