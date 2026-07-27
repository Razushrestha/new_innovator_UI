import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'shop_models.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;

/// One row in the global search index: people from the feed and every
/// product from the shop catalog.
class _SearchEntry {
  const _SearchEntry({
    required this.title,
    required this.subtitle,
    required this.kind,
    this.icon,
    this.tint,
  });

  final String title;
  final String subtitle;
  final String kind; // 'Person' | 'Product'
  final IconData? icon; // products only; people get an initial avatar
  final Color? tint;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      subtitle.toLowerCase().contains(query);
}

final _entries = <_SearchEntry>[
  const _SearchEntry(
    title: 'Aarav Sharma',
    subtitle: 'Product Designer',
    kind: 'Person',
  ),
  const _SearchEntry(
    title: 'Maya Chen',
    subtitle: 'Innovation Lead',
    kind: 'Person',
  ),
  const _SearchEntry(
    title: 'Innovator Team',
    subtitle: 'Official',
    kind: 'Person',
  ),
  const _SearchEntry(
    title: 'Rohan Karki',
    subtitle: 'Flutter Developer',
    kind: 'Person',
  ),
  const _SearchEntry(
    title: 'Priya Thapa',
    subtitle: 'Growth Marketer',
    kind: 'Person',
  ),
  for (final product in kShopProducts)
    _SearchEntry(
      title: product.name,
      subtitle: '${product.category} · ${formatRs(product.price)}',
      kind: 'Product',
      icon: product.icon,
      tint: product.tint,
    ),
];

const _trending = ['Design', 'Course', 'Template', 'Aarav', 'Marketing'];

/// In-shell search: the bar starts as a small glass droplet (the search
/// icon that was just tapped) and elastically elongates into a full
/// pill; results well up right beneath it as you type, each landing
/// with its own liquid pop.
class SearchSection extends StatefulWidget {
  const SearchSection({super.key, this.contentPadding = EdgeInsets.zero});

  /// Clearances from the shell so content stays clear of the docked bar.
  final EdgeInsets contentPadding;

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  /// Drives the droplet-to-pill elongation.
  late final AnimationController _stretch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  /// Continuous phase for the liquid resting inside the bar and tiles.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Invite typing once the pill has (mostly) finished stretching.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _stretch.dispose();
    _wave.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value.trim());

  void _useTrending(String term) {
    HapticFeedback.selectionClick();
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focus.requestFocus();
    _setQuery(term);
  }

  void _clear() {
    HapticFeedback.selectionClick();
    _controller.clear();
    _focus.requestFocus();
    _setQuery('');
  }

  List<_SearchEntry> get _results {
    final query = _query.toLowerCase();
    if (query.isEmpty) return const [];
    return _entries.where((entry) => entry.matches(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        padding.top + 10,
        20,
        padding.bottom + 6,
      ),
      children: [
        _buildBar(),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _query.isEmpty
              ? _buildTrending()
              : _results.isEmpty
              ? _buildNoResults()
              : _buildResults(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ bar

  Widget _buildBar() {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([_stretch, _wave, _focus]),
        builder: (context, _) {
          // Overshooting ease: the droplet stretches past full width and
          // snaps back, like liquid finding its shape.
          final t = Curves.easeOutBack.transform(_stretch.value);
          final width = lerpDouble(
            56,
            constraints.maxWidth,
            t.clamp(0, 1.2),
          )!.clamp(56.0, constraints.maxWidth);
          final open = ((_stretch.value - .55) / .35).clamp(0.0, 1.0);
          final focused = _focus.hasFocus;
          final phase = _wave.value * 2 * pi;

          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: width,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: focused ? .72 : .58),
                        Colors.white.withValues(alpha: focused ? .42 : .30),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: focused ? 1 : .85),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: focused ? .14 : .08),
                        blurRadius: focused ? 26 : 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Liquid pooled at the bottom of the pill; it rises
                      // slightly while the field is focused.
                      CustomPaint(
                        painter: WaveFillPainter(
                          phase: phase,
                          fill: focused ? .22 : .12,
                          color: _ink.withValues(alpha: .05),
                          amplitude: 3,
                          frequency: 1.6,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 54,
                            child: Icon(
                              Icons.search_rounded,
                              size: 23,
                              color: _ink,
                            ),
                          ),
                          Expanded(
                            child: Opacity(
                              opacity: open,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                onChanged: _setQuery,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _ink,
                                ),
                                cursorColor: _ink,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Search people, products…',
                                  hintStyle: TextStyle(
                                    fontSize: 14.5,
                                    color: _muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedScale(
                            scale: _query.isEmpty ? 0 : 1,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutBack,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: LiquidPressable(
                                onTap: _clear,
                                borderRadius: BorderRadius.circular(14),
                                rippleColor: Colors.white,
                                intensity: 1.1,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(
                                          0xFF2A2F3E,
                                        ).withValues(alpha: .95),
                                        const Color(
                                          0xFF15181F,
                                        ).withValues(alpha: .9),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: .35,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
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
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------- trending

  Widget _buildTrending() {
    return Column(
      key: const ValueKey('trending'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _wave,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, sin(_wave.value * 2 * pi) * 2.2),
            child: child,
          ),
          child: const Center(
            child: Text(
              'Trending',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _trending.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 480 + i * 90),
                curve: Curves.easeOutBack,
                builder: (context, t, child) => Transform.scale(
                  scale: t.clamp(0, 1.15),
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
                child: LiquidPressable(
                  onTap: () => _useTrending(_trending[i]),
                  borderRadius: BorderRadius.circular(20),
                  rippleColor: _ink,
                  intensity: .6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: .5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: _ink.withValues(alpha: .55),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _trending[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _ink.withValues(alpha: .75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------- results

  Widget _buildResults() {
    final results = _results;
    return Column(
      key: ValueKey('results-$_query'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: .2,
            ),
          ),
        ),
        for (var i = 0; i < results.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + i * 70),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.translate(
              offset: Offset(0, 14 * (1 - t.clamp(0, 1))),
              child: Transform.scale(
                scale: (0.94 + .06 * t).clamp(0, 1.06),
                child: Opacity(opacity: t.clamp(0, 1), child: child),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ResultTile(entry: results[i], query: _query),
            ),
          ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Padding(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          // A near-empty glass droplet: barely any liquid left in it.
          AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .95),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: .1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WaveFillPainter(
                        phase: _wave.value * 2 * pi,
                        fill: .16,
                        color: _ink.withValues(alpha: .1),
                        amplitude: 3,
                        frequency: 1.5,
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 28,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches for “$_query”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try a person, product or category name.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
        ],
      ),
    );
  }
}

/// A frosted result row. The part of the title that matches the query is
/// inked darker, so the match is visible at a glance.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.entry, required this.query});

  final _SearchEntry entry;
  final String query;

  TextSpan _highlighted() {
    const base = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xB31B1E28), // _ink at 70%
    );
    const match = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: _ink,
    );
    final lowerTitle = entry.title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerTitle.indexOf(lowerQuery);
    if (lowerQuery.isEmpty || start < 0) {
      return TextSpan(text: entry.title, style: base);
    }
    final end = start + lowerQuery.length;
    return TextSpan(
      children: [
        TextSpan(text: entry.title.substring(0, start), style: base),
        TextSpan(text: entry.title.substring(start, end), style: match),
        TextSpan(text: entry.title.substring(end), style: base),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPerson = entry.kind == 'Person';
    final tint = entry.tint ?? _ink;

    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(20),
      rippleColor: _ink,
      intensity: .6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Row(
              children: [
                if (isPerson)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BrandColors.secondarySurface,
                          Color(0xFF8A93A8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .8),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        entry.title[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: .22),
                          tint.withValues(alpha: .08),
                        ],
                      ),
                      border: Border.all(color: tint.withValues(alpha: .2)),
                    ),
                    child: Icon(entry.icon, size: 19, color: tint),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: _highlighted(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: (isPerson ? _ink : tint).withValues(alpha: .08),
                    border: Border.all(
                      color: (isPerson ? _ink : tint).withValues(alpha: .15),
                    ),
                  ),
                  child: Text(
                    entry.kind,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3,
                      color: (isPerson ? _ink : tint).withValues(alpha: .75),
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
