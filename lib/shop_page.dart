import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shop_models.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = Color(0xFF1B1E28);
const _muted = Color(0xFF7A8194);

class _FeaturedItem {
  const _FeaturedItem({
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

const _featured = [
  _FeaturedItem(
    name: 'Innovator Pro Bundle',
    subtitle: 'All templates, courses & tools in one pack',
    price: 'Rs 12,900',
    badge: 'Save 40%',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF2A2F3E), Color(0xFF15181F)],
  ),
  _FeaturedItem(
    name: 'Design System Masterclass',
    subtitle: '6 hours · 24 lessons · certificate',
    price: 'Rs 5,900',
    badge: 'Bestseller',
    icon: Icons.play_circle_fill_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _FeaturedItem(
    name: "Founder's Toolkit",
    subtitle: 'Pitch, plan and launch faster',
    price: 'Rs 4,500',
    badge: 'New',
    icon: Icons.rocket_launch_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
];

class _Category {
  const _Category(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _categories = [
  _Category('All', Icons.grid_view_rounded),
  _Category('Templates', Icons.dashboard_customize_rounded),
  _Category('Courses', Icons.school_rounded),
  _Category('E-books', Icons.menu_book_rounded),
  _Category('Design', Icons.palette_rounded),
  _Category('Tools', Icons.handyman_rounded),
];

/// The shop as an in-shell section: rendered inside the dashboard so the
/// dockable liquid nav bar stays present. A parallax featured carousel
/// with liquid surfaces, ink-flooding category chips, springy product
/// cards, and a floating glass cart orb bobbing on the wave.
class ShopSection extends StatefulWidget {
  const ShopSection({
    super.key,
    required this.onCartTap,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Opens the cart section in the shell.
  final VoidCallback onCartTap;

  /// Vertical clearances from the shell (kept clear of the docked nav
  /// bar). Horizontal insets are managed internally so the carousel can
  /// bleed to the edges.
  final EdgeInsets contentPadding;

  @override
  State<ShopSection> createState() => _ShopSectionState();
}

class _ShopSectionState extends State<ShopSection>
    with TickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: .9);
  int _featuredIndex = 0;
  String _category = 'All';

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Continuous phase shared by every liquid surface in the shop.
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
    final start = (index * .11).clamp(0.0, .6);
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

  List<ShopProduct> get _visibleProducts => _category == 'All'
      ? kShopProducts
      : kShopProducts.where((p) => p.category == _category).toList();

  void _addToCart(ShopProduct product) {
    HapticFeedback.mediumImpact();
    Cart.instance.add(product);
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(
            top: padding.top,
            bottom: padding.bottom + 6,
          ),
          children: [
            _stagger(index: 0, child: _buildFeatured()),
            const SizedBox(height: 16),
            _stagger(index: 1, child: const _TrustBar()),
            const SizedBox(height: 20),
            _stagger(
              index: 2,
              child: _FloatingTitle('Categories', wave: _wave),
            ),
            const SizedBox(height: 12),
            _stagger(index: 2, child: _buildCategories()),
            const SizedBox(height: 22),
            _stagger(
              index: 3,
              child: _FloatingTitle(
                'Products',
                wave: _wave,
                phaseShift: pi * .7,
              ),
            ),
            const SizedBox(height: 12),
            _stagger(index: 3, child: _buildGrid()),
          ],
        ),
        // Floating cart orb, bobbing on the liquid and clear of the bar.
        Positioned(
          right: 18,
          bottom: max(24, padding.bottom - 18),
          child: _stagger(
            index: 1,
            child: ListenableBuilder(
              listenable: Cart.instance,
              builder: (context, _) => _FloatingCart(
                count: Cart.instance.count,
                wave: _wave,
                onTap: widget.onCartTap,
              ),
            ),
          ),
        ),
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
            itemCount: _featured.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _featuredIndex = index);
            },
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                // Parallax: neighbours sink and shrink slightly, so
                // swiping feels like cards floating through liquid.
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
                child: _FeaturedCard(
                  item: _featured[index],
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
            for (var i = 0; i < _featured.length; i++)
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

  // ----------------------------------------------------------- categories

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category.label == _category;
          return _LiquidChip(
            label: category.label,
            icon: category.icon,
            selected: selected,
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
    final products = _visibleProducts;
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
            childAspectRatio: .74,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            // Springy staggered entrance whenever the category changes.
            final product = products[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey('$_category-${product.name}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(
                milliseconds: 380 + (index * 70).clamp(0, 350),
              ),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: .82 + .18 * t,
                child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
              ),
              child: _ProductCard(
                product: product,
                wave: _wave,
                onAdd: () => _addToCart(product),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- widgets

/// Floating glass cart orb: bobs on the wave, squashes like liquid on
/// press, and pulses whenever an item lands in it.
class _FloatingCart extends StatelessWidget {
  const _FloatingCart({
    required this.count,
    required this.wave,
    required this.onTap,
  });

  final int count;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wave,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(wave.value * 2 * pi) * 3.2),
        child: child,
      ),
      child: Tooltip(
        message: 'Cart',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Pulse the whole orb every time the count changes.
            TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: count == 0 ? 1 : .8, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: LiquidPressable(
                onTap: onTap,
                borderRadius: BorderRadius.circular(29),
                rippleColor: _ink,
                intensity: .7,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: .85),
                            Colors.white.withValues(alpha: .45),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .95),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: .22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: _ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(count),
                    tween: Tween(begin: .4, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, t, child) =>
                        Transform.scale(scale: t, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE0245E),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

/// Centered section title bobbing gently, as if floating on liquid.
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

/// Slim frosted strip of trust markers under the featured carousel.
class _TrustBar extends StatelessWidget {
  const _TrustBar();

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
                    icon: Icons.verified_user_rounded,
                    label: 'Secure checkout',
                  ),
                ),
                Expanded(
                  child: _TrustItem(
                    icon: Icons.download_rounded,
                    label: 'Instant access',
                  ),
                ),
                Expanded(
                  child: _TrustItem(
                    icon: Icons.replay_rounded,
                    label: '30-day refund',
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

/// Category chip that floods with liquid ink when selected: the ink
/// rises with a moving wave surface, and the label surfaces to white.
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.item,
    required this.index,
    required this.wave,
    required this.sheen,
  });

  final _FeaturedItem item;
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
              // A body of liquid resting at the bottom of the card, its
              // surface always in motion.
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
              // Light band drifting across the glass.
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
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.wave,
    required this.onAdd,
  });

  final ShopProduct product;
  final AnimationController wave;
  final VoidCallback onAdd;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _added = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleAdd() {
    widget.onAdd();
    setState(() => _added = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return LiquidPressable(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(24),
      rippleColor: product.tint,
      intensity: .3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .62),
                  Colors.white.withValues(alpha: .32),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product art: tinted glass block with the product icon.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          product.tint.withValues(alpha: .20),
                          product.tint.withValues(alpha: .07),
                        ],
                      ),
                      border: Border.all(
                        color: product.tint.withValues(alpha: .18),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            product.icon,
                            size: 44,
                            color: product.tint,
                          ),
                        ),
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: .85),
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
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // The price is liquid too: it squashes when pressed
                    // (and adds to the cart), and pops with a green flash
                    // whenever an item lands in the cart.
                    LiquidPressable(
                      onTap: _handleAdd,
                      borderRadius: BorderRadius.circular(10),
                      rippleColor: const Color(0xFF17A275),
                      intensity: .8,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_added),
                        tween: Tween(begin: _added ? .55 : 1, end: 1),
                        duration: const Duration(milliseconds: 620),
                        curve: Curves.elasticOut,
                        builder: (context, t, child) =>
                            Transform.scale(scale: t, child: child),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 280),
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: _added ? const Color(0xFF17A275) : _ink,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(formatRs(product.price)),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _AddButton(
                      added: _added,
                      wave: widget.wave,
                      onTap: _handleAdd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add-to-cart button that floods with green liquid and surfaces a check
/// mark for a moment after each add.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.added,
    required this.wave,
    required this.onTap,
  });

  final bool added;
  final AnimationController wave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      rippleColor: Colors.white,
      intensity: 1.2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: added ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => AnimatedBuilder(
          animation: wave,
          builder: (context, _) => Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2A2F3E).withValues(alpha: .95),
                  const Color(0xFF15181F).withValues(alpha: .9),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: wave.value * 2 * pi,
                      fill: t * 1.1,
                      color: const Color(0xFF17A275),
                      amplitude: 2.5,
                      frequency: 1.4,
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        added ? Icons.check_rounded : Icons.add_rounded,
                        key: ValueKey(added),
                        size: 18,
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
  }
}
