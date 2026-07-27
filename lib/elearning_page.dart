import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'shop_models.dart';
import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/fast_glass.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;

class _FeaturedCourse {
  const _FeaturedCourse({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.icon,
    required this.colors,
    required this.imageAsset,
  });

  final String name;
  final String subtitle;
  final String price;
  final String badge;
  final IconData icon;
  final List<Color> colors;
  final String imageAsset;
}

const _featuredCourses = [
  _FeaturedCourse(
    name: 'Flutter Masterclass',
    subtitle: '48 lessons · 12 hours · certificate',
    price: 'Rs 6,900',
    badge: 'Featured',
    icon: Icons.flutter_dash_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    imageAsset: 'Assets/courses/featured_01.jpg',
  ),
  _FeaturedCourse(
    name: 'UX Design Bootcamp',
    subtitle: 'Portfolio-ready in 8 weeks',
    price: 'Rs 8,900',
    badge: 'Bestseller',
    icon: Icons.design_services_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    imageAsset: 'Assets/courses/featured_02.jpg',
  ),
  _FeaturedCourse(
    name: 'AI for Innovators',
    subtitle: 'Ship AI features without a PhD',
    price: 'Rs 7,400',
    badge: 'New',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    imageAsset: 'Assets/courses/featured_03.jpg',
  ),
];

class _Course {
  const _Course({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.lessons,
    required this.chapters,
    required this.students,
    required this.description,
    required this.videoUrl,
    required this.icon,
    required this.colors,
    required this.imageAsset,
  });

  final String name;
  final String category;
  final double price;
  final double rating;
  final int lessons;
  final int chapters;
  final String students;
  final String description;
  final String videoUrl;
  final IconData icon;
  final List<Color> colors;
  final String imageAsset;
}

/// Short public sample clips used as course cover videos.
const _vBee =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
const _vButterfly =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
const _vBlazes =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
const _vEscapes =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4';
const _vJoyrides =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4';
const _vMeltdowns =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4';
const _vSubaru =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4';
const _vElephants =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';

const _courses = [
  _Course(
    name: 'Liquid UI Design',
    category: 'Design',
    price: 4900,
    rating: 4.9,
    lessons: 24,
    chapters: 8,
    students: '3.2k',
    description:
        'Master soft glass surfaces, spring motion, and liquid layouts. Build '
        'portfolio-ready interfaces with depth, blur, and wave-filled controls.',
    videoUrl: _vBee,
    icon: Icons.water_drop_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    imageAsset: 'Assets/courses/course_01.jpg',
  ),
  _Course(
    name: 'Flutter From Zero',
    category: 'Development',
    price: 5900,
    rating: 4.8,
    lessons: 42,
    chapters: 12,
    students: '5.6k',
    description:
        'Go from blank project to a polished app. Widgets, state, navigation, '
        'networking, and shipping patterns used in real products.',
    videoUrl: _vButterfly,
    icon: Icons.flutter_dash_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    imageAsset: 'Assets/courses/course_02.jpg',
  ),
  _Course(
    name: 'Design Systems Pro',
    category: 'Design',
    price: 3900,
    rating: 4.9,
    lessons: 18,
    chapters: 6,
    students: '2.4k',
    description:
        'Create tokens, components, and documentation that scale. Learn how '
        'teams keep product UI consistent without slowing delivery.',
    videoUrl: _vBlazes,
    icon: Icons.grid_view_rounded,
    colors: [Color(0xFF9D174D), Color(0xFFDB2777)],
    imageAsset: 'Assets/courses/course_03.jpg',
  ),
  _Course(
    name: 'API Mastery',
    category: 'Development',
    price: 4400,
    rating: 4.8,
    lessons: 30,
    chapters: 9,
    students: '1.9k',
    description:
        'Design, consume, and secure REST APIs. Auth flows, pagination, '
        'caching, and error handling for production mobile clients.',
    videoUrl: _vEscapes,
    icon: Icons.cable_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
    imageAsset: 'Assets/courses/course_04.jpg',
  ),
  _Course(
    name: 'Startup Finance',
    category: 'Business',
    price: 2900,
    rating: 4.6,
    lessons: 16,
    chapters: 5,
    students: '1.4k',
    description:
        'Runway, pricing, unit economics, and fundraising basics. Practical '
        'spreadsheets and frameworks founders actually use.',
    videoUrl: _vJoyrides,
    icon: Icons.pie_chart_rounded,
    colors: [Color(0xFF92400E), Color(0xFFB45309)],
    imageAsset: 'Assets/courses/course_05.jpg',
  ),
  _Course(
    name: 'Pitch Like a Pro',
    category: 'Business',
    price: 1900,
    rating: 4.5,
    lessons: 12,
    chapters: 4,
    students: '980',
    description:
        'Structure a story investors remember. Slide craft, delivery drills, '
        'and objection handling for demo days and board rooms.',
    videoUrl: _vMeltdowns,
    icon: Icons.co_present_rounded,
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
    imageAsset: 'Assets/courses/course_06.jpg',
  ),
  _Course(
    name: 'Brand Storytelling',
    category: 'Marketing',
    price: 2400,
    rating: 4.7,
    lessons: 14,
    chapters: 5,
    students: '1.7k',
    description:
        'Find your brand voice and turn it into campaigns. Narrative arcs, '
        'visual language, and content that builds loyal audiences.',
    videoUrl: _vSubaru,
    icon: Icons.campaign_rounded,
    colors: [Color(0xFF9F1239), Color(0xFFE11D48)],
    imageAsset: 'Assets/courses/course_07.jpg',
  ),
  _Course(
    name: 'SEO Fundamentals',
    category: 'Marketing',
    price: 1500,
    rating: 4.6,
    lessons: 10,
    chapters: 4,
    students: '1.1k',
    description:
        'Keyword research, on-page structure, and technical basics that help '
        'your product pages rank and convert organic traffic.',
    videoUrl: _vElephants,
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF166534), Color(0xFF16A34A)],
    imageAsset: 'Assets/courses/course_08.jpg',
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
  final _topScroll = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  int _featuredIndex = 0;
  int _topIndex = 0;
  String _category = 'All';
  String _query = '';
  Timer? _autoScroll;
  Timer? _topAutoScroll;
  bool _userDragging = false;
  bool _topUserDragging = false;

  static const _topCardExtent = 208.0; // 196 width + 12 gap

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Lightweight ticker kept only for one-shot entrance / enroll fills.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAutoScroll();
      _startTopAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _userDragging) return;
      if (!_pageController.hasClients) return;
      final next = (_featuredIndex + 1) % _featuredCourses.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoScroll() {
    _userDragging = true;
    _autoScroll?.cancel();
  }

  void _resumeAutoScroll() {
    _userDragging = false;
    _startAutoScroll();
  }

  void _startTopAutoScroll() {
    _topAutoScroll?.cancel();
    _topAutoScroll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _topUserDragging) return;
      if (!_topScroll.hasClients) return;
      final count = _topSelling.length;
      if (count == 0) return;
      _topIndex = (_topIndex + 1) % count;
      final target = (_topIndex * _topCardExtent).clamp(
        0.0,
        _topScroll.position.maxScrollExtent,
      );
      _topScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseTopAutoScroll() {
    _topUserDragging = true;
    _topAutoScroll?.cancel();
  }

  void _resumeTopAutoScroll() {
    _topUserDragging = false;
    _startTopAutoScroll();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _topAutoScroll?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _entrance.dispose();
    _wave.dispose();
    _pageController.dispose();
    _topScroll.dispose();
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

  List<_Course> get _visibleCourses {
    final q = _query.toLowerCase();
    return _courses.where((c) {
      if (_category != 'All' && c.category != _category) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
    }).toList();
  }

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
    final courses = _visibleCourses;
    return CustomScrollView(
      cacheExtent: 280,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: padding.top),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _stagger(index: 0, child: _buildFeatured()),
              const SizedBox(height: 16),
              _stagger(index: 1, child: const _LearnTrustBar()),
              const SizedBox(height: 16),
              _stagger(index: 1, child: _buildSearchBar()),
              const SizedBox(height: 18),
              _stagger(index: 2, child: const _FloatingTitle('Top selling')),
              const SizedBox(height: 12),
              _stagger(index: 2, child: _buildTopSelling()),
              const SizedBox(height: 22),
              _stagger(index: 3, child: const _FloatingTitle('Categories')),
              const SizedBox(height: 12),
              _stagger(index: 3, child: _buildCategories()),
              const SizedBox(height: 22),
              _stagger(
                index: 4,
                child: _FloatingTitle(
                  courses.isEmpty
                      ? 'No courses found'
                      : _query.isEmpty
                      ? 'Courses'
                      : '${courses.length} result${courses.length == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        if (courses.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 6),
            sliver: SliverToBoxAdapter(child: _buildEmptySearch()),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, padding.bottom + 6),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = courses[index];
                  return _CourseCard(
                    course: course,
                    wave: _wave,
                  );
                },
                childCount: courses.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                addSemanticIndexes: false,
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- search

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FastGlass(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: _ink.withValues(alpha: .45),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                cursorColor: BrandColors.accent,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Search courses, categories…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _ink.withValues(alpha: .38),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              FastTap(
                onTap: () {
                  _searchController.clear();
                  _searchFocus.unfocus();
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _ink.withValues(alpha: .45),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return FastGlass(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: _ink.withValues(alpha: .35),
          ),
          const SizedBox(height: 12),
          Text(
            'No courses for “$_query”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another keyword or clear filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _ink.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 16),
          FastTap(
            onTap: () {
              _searchController.clear();
              setState(() => _category = 'All');
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: BrandColors.secondarySurface,
              ),
              child: const Text(
                'Clear search',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- featured

  Widget _buildFeatured() {
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: Listener(
            onPointerDown: (_) => _pauseAutoScroll(),
            onPointerUp: (_) => _resumeAutoScroll(),
            onPointerCancel: (_) => _resumeAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _featuredCourses.length,
              onPageChanged: (index) {
                setState(() => _featuredIndex = index);
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _FeaturedCourseCard(item: _featuredCourses[index]),
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
      child: Listener(
        onPointerDown: (_) => _pauseTopAutoScroll(),
        onPointerUp: (_) => _resumeTopAutoScroll(),
        onPointerCancel: (_) => _resumeTopAutoScroll(),
        child: ListView.separated(
          controller: _topScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: top.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) =>
              _TopCourseCard(course: top[index], rank: index + 1, wave: _wave),
        ),
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
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = category.label);
            },
          );
        },
      ),
    );
  }

}

// ------------------------------------------------------------------ title

class _FloatingTitle extends StatelessWidget {
  const _FloatingTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
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
      child: FastGlass(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(vertical: 11),
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
                icon: Icons.replay_rounded,
                label: '7 days refund',
              ),
            ),
          ],
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _ink;
    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? BrandColors.secondarySurface
              : Colors.white.withValues(alpha: .55),
          border: Border.all(
            color: selected
                ? BrandColors.secondarySurface
                : Colors.white.withValues(alpha: .9),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? fg : _muted),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? fg : _ink.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- featured card

class _FeaturedCourseCard extends StatelessWidget {
  const _FeaturedCourseCard({required this.item});

  final _FeaturedCourse item;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FastAssetImage(
              asset: item.imageAsset,
              fit: BoxFit.cover,
              width: 420,
              height: 200,
              errorColor: item.colors.first,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.colors.first.withValues(alpha: .72),
                    item.colors.last.withValues(alpha: .55),
                  ],
                ),
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
                              'View',
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

  void _openDetails(BuildContext context) {
    _openCourseDetails(context, course);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: FastTap(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(24),
        child: FastGlass(
          borderRadius: BorderRadius.circular(24),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course art with rank badge.
                  SizedBox(
                    height: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FastAssetImage(
                          asset: course.imageAsset,
                          fit: BoxFit.cover,
                          width: 196,
                          height: 84,
                          errorColor: course.colors.first,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: .15),
                                course.colors.last.withValues(alpha: .45),
                              ],
                            ),
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
    );
  }
}

// ------------------------------------------------------------ course card

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.wave});

  final _Course course;
  final AnimationController wave;

  void _openDetails(BuildContext context) {
    _openCourseDetails(context, course);
  }

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(22),
      child: FastGlass(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image — rounded top only.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: AspectRatio(
                aspectRatio: 1.45,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FastAssetImage(
                      asset: course.imageAsset,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 140,
                      errorColor: course.colors.first,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .05),
                            course.colors.last.withValues(alpha: .35),
                          ],
                        ),
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
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: .94),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: .35),
                        ),
                        child: Text(
                          course.category,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${course.lessons} lessons · ${course.students} learners',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: _muted),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatRs(course.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                        _CardIconButton(
                          icon: Icons.visibility_rounded,
                          onTap: () => _openDetails(context),
                        ),
                        const SizedBox(width: 6),
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
    );
  }
}

void _openCourseDetails(BuildContext context, _Course course) {
  HapticFeedback.mediumImpact();
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: _CourseDetailPage(course: course),
        ),
      ),
    ),
  );
}

/// Compact square icon control used on course cards.
class _CardIconButton extends StatelessWidget {
  const _CardIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: .7),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
        ),
        child: Icon(icon, size: 15, color: _ink.withValues(alpha: .8)),
      ),
    );
  }
}

/// Full-page course detail: cover video, name, description, chapters /
/// episodes, and enroll actions.
class _CourseDetailPage extends StatefulWidget {
  const _CourseDetailPage({required this.course});

  final _Course course;

  @override
  State<_CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<_CourseDetailPage>
    with TickerProviderStateMixin {
  late final VideoPlayerController _video;
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  bool _ready = false;
  bool _failed = false;
  bool _showControls = true;

  _Course get course => widget.course;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.networkUrl(Uri.parse(course.videoUrl))
      ..setLooping(true)
      ..setVolume(1);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      _video.addListener(_onVideoTick);
      setState(() {
        _ready = true;
        _showControls = false;
      });
      await _video.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video.removeListener(_onVideoTick);
    _video.dispose();
    _wave.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    if (!_ready) return;
    setState(() {
      if (_video.value.isPlaying) {
        _video.pause();
        _showControls = true;
      } else {
        _video.play();
        _showControls = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(animate: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                  child: Row(
                    children: [
                      FastTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .95),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _ink.withValues(alpha: .85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          course.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _ink.withValues(alpha: .55),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: .7),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .95),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      _buildCoverVideo(),
                      const SizedBox(height: 20),
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: _ink.withValues(alpha: .75),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ChapterRow(
                        chapters: course.chapters,
                        lessons: course.lessons,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${course.category} · ${course.students} learners · '
                        '★ ${course.rating} · ${formatRs(course.price)}',
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Curriculum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink.withValues(alpha: .9),
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CourseCurriculum(course: course),
                      const SizedBox(height: 12),
                      const _DetailPerk(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Completion certificate',
                        subtitle: 'Shareable proof when you finish',
                      ),
                      SizedBox(height: 88 + bottomSafe),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomSafe),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BrandColors.canvas.withValues(alpha: 0),
                    BrandColors.canvas.withValues(alpha: .92),
                    BrandColors.canvas,
                  ],
                  stops: const [0, .35, 1],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: LiquidPressable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      rippleColor: _ink,
                      intensity: 1.1,
                      child: FastGlass(
                        borderRadius: BorderRadius.circular(16),
                        opacity: .78,
                        child: const SizedBox(
                          height: 48,
                          child: Center(
                            child: Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _EnrollButton(wave: _wave)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverVideo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FastAssetImage(
              asset: course.imageAsset,
              fit: BoxFit.cover,
              width: 720,
              height: 404,
              errorColor: course.colors.first,
            ),
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _video.value.size.width,
                  height: _video.value.size.height,
                  child: VideoPlayer(_video),
                ),
              ),
            if (!_ready && !_failed)
              ColoredBox(
                color: Colors.black.withValues(alpha: .35),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (_failed)
              ColoredBox(
                color: Colors.black.withValues(alpha: .4),
                child: const Center(
                  child: Text(
                    'Video unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: (!_ready ||
                          _failed ||
                          _showControls ||
                          !_video.value.isPlaying)
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: .38),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                      child: Icon(
                        _ready && _video.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
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

class _DetailPerk extends StatelessWidget {
  const _DetailPerk({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      opacity: .72,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.accent.withValues(alpha: .18),
            ),
            child: Icon(icon, size: 20, color: BrandColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _ink.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterOutline {
  const _ChapterOutline({
    required this.title,
    required this.episodes,
  });

  final String title;
  final List<String> episodes;
}

List<_ChapterOutline> _curriculumFor(_Course course) {
  final chapterCount = course.chapters.clamp(1, 50);
  final lessonCount = course.lessons.clamp(chapterCount, 200);
  final base = lessonCount ~/ chapterCount;
  var rem = lessonCount % chapterCount;
  final chapters = <_ChapterOutline>[];
  var episodeNo = 1;

  for (var i = 0; i < chapterCount; i++) {
    final count = base + (rem > 0 ? 1 : 0);
    if (rem > 0) rem--;
    final episodes = [
      for (var j = 0; j < count; j++)
        'Episode ${episodeNo++}: Lesson focus ${j + 1}',
    ];
    chapters.add(
      _ChapterOutline(
        title: 'Chapter ${i + 1}',
        episodes: episodes,
      ),
    );
  }
  return chapters;
}

/// Chapters with their episodes listed just underneath each chapter.
class _CourseCurriculum extends StatefulWidget {
  const _CourseCurriculum({required this.course});

  final _Course course;

  @override
  State<_CourseCurriculum> createState() => _CourseCurriculumState();
}

class _CourseCurriculumState extends State<_CourseCurriculum> {
  late final List<_ChapterOutline> _chapters = _curriculumFor(widget.course);
  late final Set<int> _open = {0};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _chapters.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ChapterBlock(
            index: i,
            chapter: _chapters[i],
            expanded: _open.contains(i),
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (_open.contains(i)) {
                  _open.remove(i);
                } else {
                  _open.add(i);
                }
              });
            },
          ),
        ],
      ],
    );
  }
}

class _ChapterBlock extends StatelessWidget {
  const _ChapterBlock({
    required this.index,
    required this.chapter,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final _ChapterOutline chapter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(18),
      opacity: .78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FastTap(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.accent.withValues(alpha: .18),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: BrandColors.accent,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${chapter.episodes.length} episodes',
                          style: TextStyle(
                            fontSize: 12,
                            color: _ink.withValues(alpha: .48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: _ink.withValues(alpha: .4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: _ink.withValues(alpha: .08)),
                for (var e = 0; e < chapter.episodes.length; e++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      e == 0 ? 10 : 6,
                      14,
                      e == chapter.episodes.length - 1 ? 12 : 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 18,
                          color: BrandColors.accent.withValues(alpha: .9),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            chapter.episodes[e],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ink.withValues(alpha: .78),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapters, required this.lessons});

  final int chapters;
  final int lessons;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      opacity: .78,
      child: Row(
        children: [
          Expanded(
            child: _MetaChip(
              icon: Icons.menu_book_rounded,
              label: '$chapters chapters',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: _ink.withValues(alpha: .1),
          ),
          Expanded(
            child: _MetaChip(
              icon: Icons.play_circle_outline_rounded,
              label: '$lessons episodes',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: BrandColors.accent),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
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
        animation: _fill,
        builder: (context, _) {
          final level = Curves.easeOutCubic.transform(_fill.value);
          final labelColor = Color.lerp(
            _ink,
            Colors.white,
            ((level - .3) / .45).clamp(0, 1),
          )!;
          return Container(
            height: compact ? 30 : 48,
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
                        phase: level * 4,
                        fill: level * 1.1,
                        color: BrandColors.secondarySurface.withValues(
                          alpha: .93,
                        ),
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
