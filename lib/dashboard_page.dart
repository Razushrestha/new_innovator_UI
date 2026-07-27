import 'package:flutter/material.dart';
import 'theme/brand_colors.dart';
import 'package:flutter/services.dart';

import 'cart_page.dart';
import 'chat_page.dart';
import 'elearning_page.dart';
import 'login_page.dart';
import 'post_page.dart';
import 'profile_page.dart';
import 'search_section.dart';
import 'shop_page.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_drawer.dart';
import 'widgets/liquid_nav_bar.dart';
import 'widgets/news_feed_section.dart';

const _ink = BrandColors.ink;

/// Post-login dashboard: the news feed, a glass drawer, and a dockable
/// liquid nav bar. Drag the bar (it melts into the logo orb) toward any
/// edge — the target edge glows while you drag — and drop to dock it
/// there; it springs back into shape on arrival.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.email});

  final String email;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Bar layout: Chat, E-learning, Search · [logo] · Post, Shop, Menu.
  static const _navLeading = [
    LiquidNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    LiquidNavItem(icon: Icons.school_outlined, label: 'E-learning'),
    LiquidNavItem(icon: Icons.search_rounded, label: 'Search'),
  ];
  static const _navTrailing = [
    LiquidNavItem(icon: Icons.post_add_rounded, label: 'Post'),
    LiquidNavItem(icon: Icons.storefront_outlined, label: 'Shop'),
    LiquidNavItem(icon: Icons.menu_rounded, label: 'Menu', pinBottom: true),
  ];
  static const _navItems = [..._navLeading, ..._navTrailing];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scroll = ScrollController();

  NavDock _dock = NavDock.bottom;
  int _selected = -1;
  bool _showCart = false;
  bool _showProfile = false;
  bool _dragging = false;
  Offset _dragPos = Offset.zero;
  NavDock? _previewDock;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: const LoginPage()),
      ),
    );
  }

  void _onNavSelect(int index) {
    final item = _navItems[index];
    if (item.label == 'Menu') {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    setState(() {
      _selected = index;
      _showCart = false;
      _showProfile = false;
    });
  }

  int get _shopIndex => _navItems.indexWhere((i) => i.label == 'Shop');
  int get _postIndex => _navItems.indexWhere((i) => i.label == 'Post');
  int get _searchIndex => _navItems.indexWhere((i) => i.label == 'Search');
  int get _learnIndex => _navItems.indexWhere((i) => i.label == 'E-learning');
  int get _chatIndex => _navItems.indexWhere((i) => i.label == 'Chat');

  /// Logo tap: back to the feed, scrolled to the top.
  void _goToFeed() {
    setState(() {
      _selected = -1;
      _showCart = false;
      _showProfile = false;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ------------------------------------------------------ drag to dock

  NavDock _nearestDock(Offset position) {
    final size = MediaQuery.of(context).size;
    final distances = <NavDock, double>{
      NavDock.left: position.dx,
      NavDock.right: size.width - position.dx,
      NavDock.top: position.dy,
      NavDock.bottom: size.height - position.dy,
    };
    return distances.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  void _onDragStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = true;
      _dragPos = details.globalPosition;
      _previewDock = _nearestDock(details.globalPosition);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final preview = _nearestDock(details.globalPosition);
    if (preview != _previewDock) HapticFeedback.selectionClick();
    setState(() {
      _dragPos = details.globalPosition;
      _previewDock = preview;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _dock = _previewDock ?? _nearestDock(_dragPos);
      _dragging = false;
      _previewDock = null;
    });
  }

  EdgeInsets get _feedPadding => switch (_dock) {
    NavDock.bottom => const EdgeInsets.fromLTRB(20, 18, 20, 118),
    NavDock.top => const EdgeInsets.fromLTRB(20, 120, 20, 28),
    _ => const EdgeInsets.fromLTRB(20, 18, 20, 28),
  };

  EdgeInsets get _contentMargin => switch (_dock) {
    NavDock.left => const EdgeInsets.only(left: 78),
    NavDock.right => const EdgeInsets.only(right: 78),
    _ => EdgeInsets.zero,
  };

  String get _displayName {
    final rawName = widget.email.split('@').first;
    return rawName.isEmpty
        ? 'Innovator'
        : rawName[0].toUpperCase() + rawName.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: _ink.withValues(alpha: .06),
      drawer: GlassDrawer(
        name: _displayName,
        title: 'Premium Member',
        onLogout: _logout,
        onProfile: () => setState(() {
          _showProfile = true;
          _showCart = false;
          _selected = -1;
        }),
        onShop: () => setState(() {
          _selected = _shopIndex;
          _showCart = false;
          _showProfile = false;
        }),
        onELearning: () => setState(() {
          _selected = _learnIndex;
          _showCart = false;
          _showProfile = false;
        }),
      ),
      // Keys keep every layer's element stable when the glow/ghost layers
      // appear mid-drag — otherwise the nav bar's gesture detector would
      // be rebuilt and the active drag gesture lost.
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(
            key: ValueKey('background'),
            animate: false,
          ),
          SafeArea(
            key: const ValueKey('content'),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: _contentMargin,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  // Sections swap in place under the persistent nav bar,
                  // melting into each other like liquid.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _showProfile
                        ? ProfileSection(
                            key: const ValueKey('profile'),
                            name: _displayName,
                            contentPadding: _feedPadding,
                          )
                        : _showCart
                        ? CartSection(
                            key: const ValueKey('cart'),
                            contentPadding: _feedPadding,
                            onShop: () => setState(() => _showCart = false),
                          )
                        : _selected == _shopIndex
                        ? ShopSection(
                            key: const ValueKey('shop'),
                            contentPadding: _feedPadding,
                            onCartTap: () => setState(() => _showCart = true),
                          )
                        : _selected == _searchIndex
                        ? SearchSection(
                            key: const ValueKey('search'),
                            contentPadding: _feedPadding,
                          )
                        : _selected == _learnIndex
                        ? ELearningSection(
                            key: const ValueKey('elearning'),
                            contentPadding: _feedPadding,
                          )
                        : _selected == _chatIndex
                        ? ChatSection(
                            key: const ValueKey('chat'),
                            contentPadding: _feedPadding,
                          )
                        : _selected == _postIndex
                        ? PostSection(
                            key: const ValueKey('post'),
                            authorName: _displayName,
                            contentPadding: _feedPadding,
                            onPosted: () => setState(() => _selected = -1),
                          )
                        : NewsFeedSection(
                            key: const ValueKey('feed'),
                            controller: _scroll,
                            padding: _feedPadding,
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (_dragging && _previewDock != null)
            _EdgeGlow(key: const ValueKey('edge-glow'), dock: _previewDock!),
          _buildNav(context),
          // The bar melts into just the logo orb under the finger. Drawn
          // as a separate overlay so the bar's gesture detector stays
          // mounted and keeps receiving the drag events.
          if (_dragging)
            Positioned(
              key: const ValueKey('drag-ghost'),
              left: _dragPos.dx - 30,
              top: _dragPos.dy - 30,
              child: const IgnorePointer(child: _DragGhost()),
            ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bar = GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onPanCancel: () => setState(() {
        _dragging = false;
        _previewDock = null;
      }),
      // Hidden (not removed) while dragging so the gesture survives;
      // springs into shape whenever it lands on a new edge.
      child: Opacity(
        opacity: _dragging ? 0 : 1,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_dock),
          tween: Tween(begin: .75, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Transform.scale(
            scale: t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
          child: LiquidNavBar(
            dock: _dock,
            leading: _navLeading,
            trailing: _navTrailing,
            selectedIndex: _selected,
            onSelect: _onNavSelect,
            onLogoTap: _goToFeed,
          ),
        ),
      ),
    );

    // The same key across all docks keeps the gesture detector's element
    // alive when the bar re-docks or the overlay layers appear.
    const navKey = ValueKey('nav-bar');
    return switch (_dock) {
      // Scaffold shrinks for the keyboard; offset the bar back down so it
      // stays pinned to the screen edge instead of riding up with Post /
      // Attachment. It sits under the keyboard while typing.
      NavDock.bottom => Positioned(
        key: navKey,
        left: 14,
        right: 14,
        bottom: 8 - keyboard,
        child: SafeArea(bottom: keyboard == 0, child: bar),
      ),
      NavDock.top => Positioned(
        key: navKey,
        left: 14,
        right: 14,
        top: 8,
        child: SafeArea(child: bar),
      ),
      NavDock.left => Positioned(
        key: navKey,
        left: 10,
        top: 0,
        bottom: 0,
        child: SafeArea(child: Center(child: bar)),
      ),
      NavDock.right => Positioned(
        key: navKey,
        left: null,
        right: 10,
        top: 0,
        bottom: 0,
        child: SafeArea(child: Center(child: bar)),
      ),
    };
  }
}

/// The logo orb pulsing gently while it's being dragged.
class _DragGhost extends StatelessWidget {
  const _DragGhost();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .85, end: 1.05),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: const Opacity(opacity: .92, child: NavLogoOrb(size: 60)),
    );
  }
}

/// Soft glow along the edge the nav bar would dock to if dropped now.
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow({super.key, required this.dock});

  final NavDock dock;

  @override
  Widget build(BuildContext context) {
    const thickness = 14.0;
    final gradient = switch (dock) {
      NavDock.left => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_ink.withValues(alpha: .30), _ink.withValues(alpha: 0)],
      ),
      NavDock.right => LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [_ink.withValues(alpha: .30), _ink.withValues(alpha: 0)],
      ),
      NavDock.top => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_ink.withValues(alpha: .30), _ink.withValues(alpha: 0)],
      ),
      NavDock.bottom => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_ink.withValues(alpha: .30), _ink.withValues(alpha: 0)],
      ),
    };

    final glow = IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(dock),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      ),
    );

    return switch (dock) {
      NavDock.left => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: thickness,
        child: glow,
      ),
      NavDock.right => Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: thickness,
        child: glow,
      ),
      NavDock.top => Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: thickness,
        child: glow,
      ),
      NavDock.bottom => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: thickness,
        child: glow,
      ),
    };
  }
}
