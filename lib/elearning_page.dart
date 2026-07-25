import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shop_models.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = Color(0xFF1B1E28);
const _muted = Color(0xFF7A8194);

class _FeaturedCourse {
  const _FeaturedCourse({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.icon,
    required this.colors,
  });

  final String name;
  final String subtitle;
  final String price;
  final String badge;
  final IconData icon;
  final List<Color> colors;
}

const _featuredCourses = [
  _FeaturedCourse(
    name: 'Flutter Masterclass',
    subtitle: '48 lessons · 12 hours · certificate',
    price: 'Rs 6,900',
    badge: 'Featured',
    icon: Icons.flutter_dash_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _FeaturedCourse(
    name: 'UX Design Bootcamp',
    subtitle: 'Portfolio-ready in 8 weeks',
    price: 'Rs 8,900',
    badge: 'Bestseller',
    icon: Icons.design_services_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _FeaturedCourse(
    name: 'AI for Innovators',
    subtitle: 'Ship AI features without a PhD',
    price: 'Rs 7,400',
    badge: 'New',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  ),
];

class _Course {
  const _Course({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.lessons,
    required this.students,
    required this.icon,
    required this.colors,
  });

  final String name;
  final String category;
  final double price;
  final double rating;
  final int lessons;
  final String students;
  final IconData icon;
  final List<Color> colors;
}

const _courses = [
  _Course(
    name: 'Liquid UI Design',
    category: 'Design',
    price: 4900,
    rating: 4.9,
    lessons: 24,
    students: '3.2k',
    icon: Icons.water_drop_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _Course(
    name: 'Flutter From Zero',
    category: 'Development',
    price: 5900,
    rating: 4.8,
    lessons: 42,
    students: '5.6k',
    icon: Icons.flutter_dash_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _Course(
    name: 'Design Systems Pro',
    category: 'Design',
    price: 3900,
    rating: 4.9,
    lessons: 18,
    students: '2.4k',
    icon: Icons.grid_view_rounded,
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
  ),
  _Course(
    name: 'API Mastery',
    category: 'Development',
    price: 4400,
    rating: 4.8,
    lessons: 30,
    students: '1.9k',
    icon: Icons.cable_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
  ),
  _Course(
    name: 'Startup Finance',
    category: 'Business',
    price: 2900,
    rating: 4.6,
    lessons: 16,
    students: '1.4k',
    icon: Icons.pie_chart_rounded,
    colors: [Color(0xFF92400E), Color(0xFFB45309)],
  ),
  _Course(
    name: 'Pitch Like a Pro',
    category: 'Business',
    price: 1900,
    rating: 4.5,
    lessons: 12,
    students: '980',
    icon: Icons.co_present_rounded,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
  ),
  _Course(
    name: 'Brand Storytelling',
    category: 'Marketing',
    price: 2400,
    rating: 4.7,
    lessons: 14,
    students: '1.7k',
    icon: Icons.campaign_rounded,
    colors: [Color(0xFF9F1239), Color(0xFFE11D48)],
  ),
  _Course(
    name: 'SEO Fundamentals',
    category: 'Marketing',
    price: 1500,
    rating: 4.6,
    lessons: 10,
    students: '1.1k',
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF166534), Color(0xFF16A34A)],
  ),
];

class _CourseCategory {
  const _CourseCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _courseCategories = [
  _CourseCategory('All', Icons.grid_view_rounded),
  _CourseCategory('Design', Icons.palette_rounded),
  _CourseCategory('Development', Icons.code_rounded),
  _CourseCategory('Business', Icons.work_rounded),
  _CourseCategory('Marketing', Icons.campaign_rounded),
];

/// E-learning as an in-shell section: featured course carousel with
/// parallax and liquid surfaces, a ranked top-selling rail, ink-flooding
/// category chips, and course cards whose enroll buttons fill with
/// liquid when tapped.
class ELearningSection extends StatefulWidget {
  const ELearningSection({super.key, this.contentPadding = EdgeInsets.zero});

  /// Vertical clearances from the shell (kept clear of the docked nav
  /// bar). Horizontal insets are managed internally so rails can bleed.
  final EdgeInsets contentPadding;

  @override
  State<ELearningSection> createState() => _ELearningSectionState();
}

class _ELearningSectionState extends State<ELearningSection>
    with TickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: .9);
  int _featuredIndex = 0;
  String _category = 'All';

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Continuous phase shared by every liquid surface in the section.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  /// Light band drifting across the featured glass cards.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    _sheen.dispose();
    _pageController.dispose();
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

  List<_Course> get _visibleCourses => _category == 'All'
      ? _courses
      : _courses.where((c) => c.category == _category).toList();

  /// Ranked by student count (parsed loosely from the display string).
  List<_Course> get _topSelling {
    double learners(_Course c) {
      final raw = c.students.replaceAll('k', '');
      final value = double.tryParse(raw) ?? 0;
      return c.students.endsWith('k') ? value * 1000 : value;
    }

    final sorted = [..._courses]
      ..sort((a, b) => learners(b).compareTo(learners(a)));
    return sorted.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return ListView(
      padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom + 6),
      children: [
        _stagger(index: 0, child: _buildFeatured()),
        const SizedBox(height: 16),
        _stagger(index: 1, child: const _LearnTrustBar()),
        const SizedBox(height: 22),
        _stagger(index: 2, child: _FloatingTitle('Top selling', wave: _wave)),
        const SizedBox(height: 12),
        _stagger(index: 2, child: _buildTopSelling()),
        const SizedBox(height: 22),
        _stagger(
          index: 3,
          child: _FloatingTitle('Categories', wave: _wave, phaseShift: pi * .5),
        ),
        const SizedBox(height: 12),
        _stagger(index: 3, child: _buildCategories()),
        const SizedBox(height: 22),
        _stagger(
          index: 4,
          child: _FloatingTitle('Courses', wave: _wave, phaseShift: pi * .9),
        ),
        const SizedBox(height: 12),
        _stagger(index: 4, child: _buildGrid()),
      ],
    );
  }

  // ------------------------------------------------------------- featured

  Widget _buildFeatured() {
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredCourses.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _featuredIndex = index);
            },
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                var delta = 0.0;
                if (_pageController.hasClients &&
                    _pageController.position.haveDimensions) {
                  delta = (_pageController.page ?? 0) - index;
                }
                final scale = (1 - delta.abs() * .07).clamp(.85, 1.0);
                return Transform.translate(
                  offset: Offset(0, 12 * delta.abs()),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _FeaturedCourseCard(
                  item: _featuredCourses[index],
                  index: index,
                  wave: _wave,
                  sheen: _sheen,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _featuredCourses.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: i == _featuredIndex ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _ink.withValues(
                    alpha: i == _featuredIndex ? .85 : .22,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------- top selling

  Widget _buildTopSelling() {
    final top = _topSelling;
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: top.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _TopCourseCard(course: top[index], rank: index + 1, wave: _wave),
      ),
    );
  }

  // ----------------------------------------------------------- categories

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _courseCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = _courseCategories[index];
          return _LiquidChip(
            label: category.label,
            icon: category.icon,
            selected: category.label == _category,
            wave: _wave,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = category.label);
            },
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- grid

  Widget _buildGrid() {
    final courses = _visibleCourses;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        child: GridView.builder(
          key: ValueKey(_category),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Taller cards so View courses + Enroll now sit side by side.
            childAspectRatio: .62,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey('$_category-${course.name}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 420 + index * 60),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - t.clamp(0, 1))),
                child: Transform.scale(
                  scale: (0.9 + .1 * t).clamp(0, 1.05),
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
              ),
              child: _CourseCard(course: course, wave: _wave),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ title

class _FloatingTitle extends StatelessWidget {
  const _FloatingTitle(this.title, {required this.wave, this.phaseShift = 0});

  final String title;
  final AnimationController wave;
  final double phaseShift;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wave,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(wave.value * 2 * pi + phaseShift) * 2.6),
        child: child,
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -.2,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- trust bar

class _LearnTrustBar extends StatelessWidget {
  const _LearnTrustBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: .48),
              border: Border.all(color: Colors.white.withValues(alpha: .85)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _TrustItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Certificates',
                  ),
                ),
                Expanded(
                  child: _TrustItem(
                    icon: Icons.groups_rounded,
                    label: 'Expert mentors',
                  ),
                ),
                Expanded(
                  child: _TrustItem(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Lifetime access',
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

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _ink.withValues(alpha: .6)),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- liquid chip

class _LiquidChip extends StatelessWidget {
  const _LiquidChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.wave,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      rippleColor: selected ? Colors.white : _ink,
      intensity: .55,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            final labelColor = Color.lerp(
              _ink,
              Colors.white,
              ((t - .3) / .45).clamp(0, 1),
            )!;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: .9),
                    Colors.white.withValues(alpha: .35),
                    t,
                  )!,
                ),
                boxShadow: t > .85
                    ? [
                        BoxShadow(
                          color: _ink.withValues(alpha: .25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WaveFillPainter(
                          phase: wave.value * 2 * pi,
                          fill: t * 1.08,
                          color: const Color(0xFF15181F).withValues(alpha: .92),
                          amplitude: 3,
                          frequency: 1.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: selected ? labelColor : _muted,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- featured card

class _FeaturedCourseCard extends StatelessWidget {
  const _FeaturedCourseCard({
    required this.item,
    required this.index,
    required this.wave,
    required this.sheen,
  });

  final _FeaturedCourse item;
  final int index;
  final AnimationController wave;
  final AnimationController sheen;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(28),
      rippleColor: Colors.white,
      intensity: .35,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.colors,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
          boxShadow: [
            BoxShadow(
              color: item.colors.last.withValues(alpha: .35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Liquid resting at the bottom of the card, always moving.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: wave,
                  builder: (context, _) {
                    final phase = wave.value * 2 * pi + index * 1.7;
                    return CustomPaint(
                      painter: WaveFillPainter(
                        phase: phase,
                        fill: .20,
                        color: Colors.white.withValues(alpha: .08),
                        amplitude: 7,
                        frequency: 1.15,
                      ),
                      foregroundPainter: WaveFillPainter(
                        phase: phase + 2.2,
                        fill: .15,
                        color: Colors.white.withValues(alpha: .10),
                        amplitude: 5,
                        frequency: 1.5,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: sheen,
                    builder: (context, _) {
                      final t = (sheen.value + index * .33) % 1;
                      return Align(
                        alignment: Alignment(-1.8 + 3.6 * t, 0),
                        child: Transform.rotate(
                          angle: -.55,
                          child: Container(
                            width: 70,
                            height: 320,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: .16),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(
                  item.icon,
                  size: 130,
                  color: Colors.white.withValues(alpha: .14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: .18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .4),
                        ),
                      ),
                      child: Text(
                        item.badge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          item.price,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: .92),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Enroll',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: _ink,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- top selling card

class _TopCourseCard extends StatelessWidget {
  const _TopCourseCard({
    required this.course,
    required this.rank,
    required this.wave,
  });

  final _Course course;
  final int rank;
  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: LiquidPressable(
        onTap: () => HapticFeedback.selectionClick(),
        borderRadius: BorderRadius.circular(24),
        rippleColor: _ink,
        intensity: .5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .58),
                    Colors.white.withValues(alpha: .30),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .85)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course art with a moving liquid surface and rank badge.
                  SizedBox(
                    height: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: course.colors,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: wave,
                          builder: (context, _) => CustomPaint(
                            painter: WaveFillPainter(
                              phase: wave.value * 2 * pi + rank,
                              fill: .3,
                              color: Colors.white.withValues(alpha: .12),
                              amplitude: 5,
                              frequency: 1.3,
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            course.icon,
                            size: 34,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: .9),
                            ),
                            child: Text(
                              '#$rank bestseller',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${course.students} learners · ${course.lessons} lessons',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _muted,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    formatRs(course.price),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _EnrollButton(wave: wave, compact: true),
                            ],
                          ),
                        ],
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
  }
}

// ------------------------------------------------------------ course card

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.wave});

  final _Course course;
  final AnimationController wave;

  void _openDetails(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (_) => _CourseDetailSheet(course: course, wave: wave),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(24),
      rippleColor: _ink,
      intensity: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedBuilder(
            animation: wave,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .58),
                    Colors.white.withValues(alpha: .30),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .85)),
                boxShadow: [
                  BoxShadow(
                    color: course.colors.last.withValues(alpha: .12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Soft liquid resting across the frosted card body.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: wave.value * 2 * pi + course.lessons * .2,
                        fill: .12,
                        color: _ink.withValues(alpha: .04),
                        amplitude: 3,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course image: gradient art with liquid pooled at its base.
                SizedBox(
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: course.colors,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: wave,
                        builder: (context, _) => CustomPaint(
                          painter: WaveFillPainter(
                            phase: wave.value * 2 * pi + course.lessons,
                            fill: .28,
                            color: Colors.white.withValues(alpha: .12),
                            amplitude: 5,
                            frequency: 1.3,
                          ),
                          foregroundPainter: WaveFillPainter(
                            phase: wave.value * 2 * pi + course.lessons + 1.8,
                            fill: .18,
                            color: Colors.white.withValues(alpha: .08),
                            amplitude: 3.5,
                            frequency: 1.6,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          course.icon,
                          size: 34,
                          color: Colors.white.withValues(alpha: .92),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: .9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                course.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.lessons} lessons · ${course.students} learners',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: _muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatRs(course.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _ViewCoursesButton(
                                wave: wave,
                                onTap: () => _openDetails(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: _EnrollButton(wave: wave)),
                          ],
                        ),
                      ],
                    ),
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

/// Glass "View courses" control — liquid press + a soft ink wash on tap.
class _ViewCoursesButton extends StatelessWidget {
  const _ViewCoursesButton({required this.wave, required this.onTap});

  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      rippleColor: _ink,
      intensity: 1.15,
      child: AnimatedBuilder(
        animation: wave,
        builder: (context, _) => Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: .55),
            border: Border.all(color: Colors.white.withValues(alpha: .95)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: WaveFillPainter(
                      phase: wave.value * 2 * pi + .8,
                      fill: .18,
                      color: _ink.withValues(alpha: .07),
                      amplitude: 2.5,
                      frequency: 1.5,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 13, color: _ink),
                        SizedBox(width: 4),
                        Text(
                          'View courses',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .1,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
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

/// Liquid glass sheet that wells up when a course card (or View) is tapped.
class _CourseDetailSheet extends StatelessWidget {
  const _CourseDetailSheet({required this.course, required this.wave});

  final _Course course;
  final AnimationController wave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .86),
                  Colors.white.withValues(alpha: .62),
                ],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .95)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _ink.withValues(alpha: .18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: course.colors,
                                ),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: wave,
                              builder: (context, _) => CustomPaint(
                                painter: WaveFillPainter(
                                  phase: wave.value * 2 * pi,
                                  fill: .3,
                                  color: Colors.white.withValues(alpha: .12),
                                  amplitude: 6,
                                  frequency: 1.25,
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                course.icon,
                                size: 48,
                                color: Colors.white.withValues(alpha: .92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${course.category} · ${course.lessons} lessons · '
                      '${course.students} learners · ★ ${course.rating}',
                      style: const TextStyle(fontSize: 12.5, color: _muted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatRs(course.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A premium liquid-designed course with practical lessons, '
                      'mentor feedback and a certificate when you finish.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _ink.withValues(alpha: .7),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: LiquidPressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(14),
                            rippleColor: _ink,
                            intensity: 1.1,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: .55),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .95),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _EnrollButton(wave: wave)),
                      ],
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
}

// ---------------------------------------------------------- enroll button

/// "Enroll now" floods with dark liquid when tapped — the wave rises
/// through the button — then settles as an enrolled state with a check.
class _EnrollButton extends StatefulWidget {
  const _EnrollButton({required this.wave, this.compact = false});

  final AnimationController wave;
  final bool compact;

  @override
  State<_EnrollButton> createState() => _EnrollButtonState();
}

class _EnrollButtonState extends State<_EnrollButton>
    with SingleTickerProviderStateMixin {
  bool _enrolled = false;

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _enroll() {
    if (_enrolled) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _enrolled = true);
    _fill.forward();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return LiquidPressable(
      onTap: _enroll,
      borderRadius: BorderRadius.circular(14),
      rippleColor: _enrolled ? Colors.white : _ink,
      intensity: 1.2,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.wave, _fill]),
        builder: (context, _) {
          final level = Curves.easeOutCubic.transform(_fill.value);
          final labelColor = Color.lerp(
            _ink,
            Colors.white,
            ((level - .3) / .45).clamp(0, 1),
          )!;
          return Container(
            height: compact ? 30 : 36,
            width: compact ? null : double.infinity,
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 11)
                : const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: .55),
              border: Border.all(
                color: Color.lerp(
                  Colors.white.withValues(alpha: .95),
                  Colors.white.withValues(alpha: .35),
                  level,
                )!,
              ),
              boxShadow: level > .8
                  ? [
                      BoxShadow(
                        color: _ink.withValues(alpha: .3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WaveFillPainter(
                        phase: widget.wave.value * 2 * pi,
                        fill: level * 1.1,
                        color: const Color(0xFF15181F).withValues(alpha: .93),
                        amplitude: 3,
                        frequency: 1.4,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _enrolled
                                ? Icons.check_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(_enrolled),
                            size: compact ? 13 : 14,
                            color: labelColor,
                          ),
                        ),
                        SizedBox(width: compact ? 4 : 4),
                        Text(
                          _enrolled
                              ? 'Enrolled'
                              : compact
                              ? 'Enroll'
                              : 'Enroll now',
                          style: TextStyle(
                            fontSize: compact ? 11 : 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .1,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
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
