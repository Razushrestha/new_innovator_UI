import 'dart:math';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = Color(0xFF1B1E28);
const _muted = Color(0xFF7A8194);

class _TitleBadge {
  const _TitleBadge({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
}

const _titles = [
  _TitleBadge(
    label: 'Innovator',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _TitleBadge(
    label: 'Creator',
    icon: Icons.palette_rounded,
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _TitleBadge(
    label: 'Developer',
    icon: Icons.code_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _TitleBadge(
    label: 'Programmer',
    icon: Icons.terminal_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
];

class _Innovation {
  const _Innovation({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

const _innovations = [
  _Innovation(
    title: 'Liquid Glass Nav',
    subtitle: 'Dockable bar with spring physics',
    icon: Icons.water_drop_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _Innovation(
    title: 'Khalti Checkout',
    subtitle: 'Nepal-ready liquid payments',
    icon: Icons.account_balance_wallet_rounded,
    colors: [Color(0xFF5C2D91), Color(0xFF7C3AED)],
  ),
  _Innovation(
    title: 'Wave Fill System',
    subtitle: 'Shared liquid surfaces everywhere',
    icon: Icons.waves_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
  _Innovation(
    title: 'Bouncy Chat Drop',
    subtitle: 'Messages that fly like water',
    icon: Icons.chat_bubble_rounded,
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _Innovation(
    title: 'E-learning Rails',
    subtitle: 'Featured & top-selling courses',
    icon: Icons.school_rounded,
    colors: [Color(0xFF92400E), Color(0xFFB45309)],
  ),
  _Innovation(
    title: 'Search Pill',
    subtitle: 'Icon that elongates into a field',
    icon: Icons.search_rounded,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
  ),
];

/// Profile as an in-shell section: avatar with camera, name + titled badge,
/// Collaborators / Collaborating / Innovation stats, then an innovations grid.
class ProfileSection extends StatefulWidget {
  const ProfileSection({
    super.key,
    required this.name,
    this.contentPadding = EdgeInsets.zero,
  });

  final String name;
  final EdgeInsets contentPadding;

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection>
    with TickerProviderStateMixin {
  int _titleIndex = 0;
  Uint8List? _avatarBytes;

  static const _collaborators = 128;
  static const _collaborating = 64;
  static const _innovationCount = 6;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .1).clamp(0.0, .6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _changePhoto() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes != null && mounted) {
        setState(() => _avatarBytes = bytes);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open the photo picker'),
        ),
      );
    }
  }

  void _cycleTitle() {
    HapticFeedback.selectionClick();
    setState(() => _titleIndex = (_titleIndex + 1) % _titles.length);
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    final title = _titles[_titleIndex];

    return ListView(
      padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
      children: [
        _stagger(
          index: 0,
          child: _AvatarBlock(
            name: widget.name,
            bytes: _avatarBytes,
            wave: _wave,
            accent: title.colors,
            onCamera: _changePhoto,
          ),
        ),
        const SizedBox(height: 16),
        _stagger(
          index: 1,
          child: Column(
            children: [
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 10),
              _TitleBadgeChip(badge: title, wave: _wave, onTap: _cycleTitle),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _stagger(
          index: 2,
          child: _StatsRow(
            wave: _wave,
            collaborators: _collaborators,
            collaborating: _collaborating,
            innovations: _innovationCount,
          ),
        ),
        const SizedBox(height: 24),
        _stagger(
          index: 3,
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, sin(_wave.value * 2 * pi) * 2.4),
              child: child,
            ),
            child: const Center(
              child: Text(
                'Innovations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _stagger(index: 4, child: _InnovationsGrid(wave: _wave)),
      ],
    );
  }
}

// ----------------------------------------------------------------- avatar

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.name,
    required this.bytes,
    required this.wave,
    required this.accent,
    required this.onCamera,
  });

  final String name;
  final Uint8List? bytes;
  final AnimationController wave;
  final List<Color> accent;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Soft breathing ring around the avatar.
            AnimatedBuilder(
              animation: wave,
              builder: (context, _) {
                final pulse = 1 + .03 * sin(wave.value * 2 * pi);
                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: accent,
                      ),
                    ),
                    padding: const EdgeInsets.all(3.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .92),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: bytes != null
                              ? Image.memory(bytes!, fit: BoxFit.cover)
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            accent.first.withValues(alpha: .85),
                                            accent.last.withValues(alpha: .95),
                                          ],
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: WaveFillPainter(
                                        phase: wave.value * 2 * pi,
                                        fill: .3,
                                        color: Colors.white.withValues(
                                          alpha: .12,
                                        ),
                                        amplitude: 4,
                                        frequency: 1.3,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        name.isEmpty
                                            ? '?'
                                            : name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Camera droplet — liquid press to change the photo.
            Positioned(
              right: 2,
              bottom: 2,
              child: LiquidPressable(
                onTap: onCamera,
                borderRadius: BorderRadius.circular(18),
                rippleColor: Colors.white,
                intensity: 1.2,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A2F3E), Color(0xFF15181F)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: .25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- badge

class _TitleBadgeChip extends StatelessWidget {
  const _TitleBadgeChip({
    required this.badge,
    required this.wave,
    required this.onTap,
  });

  final _TitleBadge badge;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      rippleColor: Colors.white,
      intensity: 1.1,
      child: AnimatedBuilder(
        animation: wave,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: badge.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.colors.last.withValues(alpha: .35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi,
                        fill: .28,
                        color: Colors.white.withValues(alpha: .12),
                        amplitude: 2.5,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badge.icon, size: 15, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(
                        badge.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ stats

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.wave,
    required this.collaborators,
    required this.collaborating,
    required this.innovations,
  });

  final AnimationController wave;
  final int collaborators;
  final int collaborating;
  final int innovations;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .55),
                Colors.white.withValues(alpha: .28),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCell(
                  value: collaborators,
                  label: 'Collaborators',
                  wave: wave,
                  phaseShift: 0,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: _ink.withValues(alpha: .08),
              ),
              Expanded(
                child: _StatCell(
                  value: collaborating,
                  label: 'Collaborating',
                  wave: wave,
                  phaseShift: .8,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: _ink.withValues(alpha: .08),
              ),
              Expanded(
                child: _StatCell(
                  value: innovations,
                  label: 'Innovation',
                  wave: wave,
                  phaseShift: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.wave,
    required this.phaseShift,
  });

  final int value;
  final String label;
  final AnimationController wave;
  final double phaseShift;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(16),
      rippleColor: _ink,
      intensity: .7,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: wave,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, sin(wave.value * 2 * pi + phaseShift) * 1.8),
                child: child,
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ innovations

class _InnovationsGrid extends StatelessWidget {
  const _InnovationsGrid({required this.wave});

  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _innovations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .92,
      ),
      itemBuilder: (context, index) {
        final item = _innovations[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 420 + index * 70),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(0, 16 * (1 - t.clamp(0, 1))),
            child: Transform.scale(
              scale: (.9 + .1 * t).clamp(0, 1.05),
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
          ),
          child: _InnovationCard(item: item, wave: wave, index: index),
        );
      },
    );
  }
}

class _InnovationCard extends StatelessWidget {
  const _InnovationCard({
    required this.item,
    required this.wave,
    required this.index,
  });

  final _Innovation item;
  final AnimationController wave;
  final int index;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(22),
      rippleColor: Colors.white,
      intensity: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .55),
                  Colors.white.withValues(alpha: .28),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .85)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: item.colors,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: wave,
                        builder: (context, _) => CustomPaint(
                          painter: WaveFillPainter(
                            phase: wave.value * 2 * pi + index,
                            fill: .3,
                            color: Colors.white.withValues(alpha: .12),
                            amplitude: 4,
                            frequency: 1.3,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          item.icon,
                          size: 36,
                          color: Colors.white.withValues(alpha: .92),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: _muted),
                      ),
                    ],
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
