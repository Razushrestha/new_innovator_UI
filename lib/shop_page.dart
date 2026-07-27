import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'shop_models.dart';
import 'widgets/fast_glass.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;

class _FeaturedItem {
  const _FeaturedItem({
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

const _featured = [
  _FeaturedItem(
    name: 'Innovator Pro Bundle',
    subtitle: 'All templates, courses & tools in one pack',
    price: 'Rs 12,900',
    badge: 'Save 40%',
    icon: Icons.auto_awesome_rounded,
    colors: [BrandColors.secondarySurface, BrandColors.secondarySurface],
    imageAsset: 'Assets/shop/featured_01.jpg',
  ),
  _FeaturedItem(
    name: 'Design System Masterclass',
    subtitle: '6 hours · 24 lessons · certificate',
    price: 'Rs 5,900',
    badge: 'Bestseller',
    icon: Icons.play_circle_fill_rounded,
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    imageAsset: 'Assets/shop/featured_02.jpg',
  ),
  _FeaturedItem(
    name: "Founder's Toolkit",
    subtitle: 'Pitch, plan and launch faster',
    price: 'Rs 4,500',
    badge: 'New',
    icon: Icons.rocket_launch_rounded,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    imageAsset: 'Assets/shop/featured_03.jpg',
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
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  int _featuredIndex = 0;
  String _category = 'All';
  String _query = '';
  Timer? _autoScroll;
  bool _userDragging = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
    // Wait until the PageView is laid out before starting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _userDragging) return;
      if (!_pageController.hasClients) return;
      final next = (_featuredIndex + 1) % _featured.length;
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

  @override
  void dispose() {
    _autoScroll?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _entrance.dispose();
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

  List<ShopProduct> get _visibleProducts {
    final q = _query.toLowerCase();
    return kShopProducts.where((p) {
      if (_category != 'All' && p.category != _category) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  void _addToCart(ShopProduct product) {
    HapticFeedback.mediumImpact();
    Cart.instance.add(product);
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;
    final products = _visibleProducts;
    return Stack(
      children: [
        CustomScrollView(
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
                  _stagger(index: 1, child: const _TrustBar()),
                  const SizedBox(height: 16),
                  _stagger(index: 1, child: _buildSearchBar()),
                  const SizedBox(height: 18),
                  _stagger(index: 2, child: const _FloatingTitle('Categories')),
                  const SizedBox(height: 12),
                  _stagger(index: 2, child: _buildCategories()),
                  const SizedBox(height: 22),
                  _stagger(
                    index: 3,
                    child: _FloatingTitle(
                      products.isEmpty
                          ? 'No products found'
                          : _query.isEmpty
                          ? 'Products'
                          : '${products.length} result${products.length == 1 ? '' : 's'}',
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (products.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 6),
                sliver: SliverToBoxAdapter(child: _buildEmptySearch()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, padding.bottom + 6),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .74,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        onAdd: () => _addToCart(product),
                      );
                    },
                    childCount: products.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    addSemanticIndexes: false,
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 18,
          bottom: max(24, padding.bottom - 18),
          child: ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) => _FloatingCart(
              count: Cart.instance.count,
              onTap: widget.onCartTap,
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
          child: Listener(
            onPointerDown: (_) => _pauseAutoScroll(),
            onPointerUp: (_) => _resumeAutoScroll(),
            onPointerCancel: (_) => _resumeAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _featured.length,
              onPageChanged: (index) {
                setState(() => _featuredIndex = index);
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _FeaturedCard(item: _featured[index]),
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

  // --------------------------------------------------------------- search

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FastGlass(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: _ink.withValues(alpha: .45)),
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
                  hintText: 'Search products, categories…',
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
            'No matches for “$_query”',
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

// ---------------------------------------------------------------- widgets

/// Floating glass cart orb — static (no blur / bob) so scroll stays light.
class _FloatingCart extends StatelessWidget {
  const _FloatingCart({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Cart',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FastTap(
            onTap: onTap,
            borderRadius: BorderRadius.circular(29),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .78),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .95),
                  width: 1.4,
                ),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 24,
                color: _ink,
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
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
                  '',
                  style: const TextStyle(
                    fontSize: 11,
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
}

/// Centered section title.
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

/// Slim frosted strip of trust markers under the featured carousel.
class _TrustBar extends StatelessWidget {
  const _TrustBar();

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

/// Simple category chip — no per-frame wave paint.
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final _FeaturedItem item;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.colors,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: FastAssetImage(
                  asset: item.imageAsset,
                  fit: BoxFit.cover,
                  width: 420,
                  height: 200,
                  errorColor: item.colors.first,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
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
    required this.onAdd,
  });

  final ShopProduct product;
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

  void _openDetails() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _ink.withValues(alpha: .28),
      builder: (ctx) {
        return Stack(
          children: [
            // Tap outside the card to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ),
            DraggableScrollableSheet(
              expand: false,
              initialChildSize: .92,
              minChildSize: .2,
              maxChildSize: .92,
              shouldCloseOnMinExtent: true,
              builder: (context, scrollController) {
                return GestureDetector(
                  // Keep taps on the card from hitting the dismiss scrim.
                  onTap: () {},
                  child: _ProductDetailSheet(
                    product: widget.product,
                    onAdd: widget.onAdd,
                    scrollController: scrollController,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return FastTap(
      onTap: _openDetails,
      borderRadius: BorderRadius.circular(24),
      child: FastGlass(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        FastAssetImage(
                          asset: product.imageAsset,
                          fit: BoxFit.cover,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          errorColor: product.tint.withValues(alpha: .2),
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
                              color: Colors.white.withValues(alpha: .9),
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
                    );
                  },
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
                FastTap(
                  onTap: _handleAdd,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
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
                const Spacer(),
                _AddButton(added: _added, onTap: _handleAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add-to-cart button that floods with green liquid and surfaces a check
/// mark for a moment after each add.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.added, required this.onTap});

  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: added
              ? const Color(0xFF17A275)
              : BrandColors.secondarySurface,
          border: Border.all(color: Colors.white.withValues(alpha: .3)),
        ),
        child: Icon(
          added ? Icons.check_rounded : Icons.add_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Product detail sheet: swipeable gallery, description, and specs.
/// Drag down from anywhere (via [scrollController]) or tap outside to close.
class _ProductDetailSheet extends StatefulWidget {
  const _ProductDetailSheet({
    required this.product,
    required this.onAdd,
    this.scrollController,
  });

  final ShopProduct product;
  final VoidCallback onAdd;
  final ScrollController? scrollController;

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  final _pageController = PageController();
  int _imageIndex = 0;
  bool _added = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _add() {
    HapticFeedback.mediumImpact();
    widget.onAdd();
    setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final width = MediaQuery.sizeOf(context).width;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: FastGlass(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          opacity: .94,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _ink.withValues(alpha: .18),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // ---- Image gallery ----
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: product.images.length,
                              onPageChanged: (i) =>
                                  setState(() => _imageIndex = i),
                              itemBuilder: (context, index) {
                                return FastAssetImage(
                                  asset: product.images[index],
                                  fit: BoxFit.cover,
                                  width: width,
                                  height: width / 1.15,
                                  errorColor:
                                      product.tint.withValues(alpha: .2),
                                );
                              },
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withValues(alpha: .92),
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
                                      product.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0;
                                      i < product.images.length;
                                      i++)
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: i == _imageIndex ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.white.withValues(
                                          alpha: i == _imageIndex ? .95 : .45,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Thumbnail strip
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final selected = index == _imageIndex;
                          return FastTap(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? BrandColors.accent
                                      : Colors.white.withValues(alpha: .7),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FastAssetImage(
                                asset: product.images[index],
                                fit: BoxFit.cover,
                                width: 58,
                                height: 58,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: product.tint.withValues(alpha: .12),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.tint,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatRs(product.price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: _ink.withValues(alpha: .72),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Specifications',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final spec in product.specifications) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                spec.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _ink.withValues(alpha: .5),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                spec.value,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: _ink.withValues(alpha: .08),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FastTap(
                      onTap: _add,
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: _added
                              ? const Color(0xFF17A275)
                              : BrandColors.secondarySurface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _added
                                  ? Icons.check_rounded
                                  : Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _added ? 'Added to cart' : 'Add to cart',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
