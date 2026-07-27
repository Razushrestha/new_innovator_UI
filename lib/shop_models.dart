import 'package:flutter/material.dart';

/// A product sold in the shop. Prices are in Nepali rupees.
class ShopProduct {
  const ShopProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.icon,
    required this.tint,
    required this.images,
    required this.description,
    required this.specifications,
  });

  final String name;
  final String category;
  final double price;
  final double rating;
  final IconData icon;
  final Color tint;

  /// Gallery of relative asset paths (cover is [images.first]).
  final List<String> images;
  final String description;
  final List<ProductSpec> specifications;

  /// Cover image used in grids, cart, and search.
  String get imageAsset => images.first;
}

class ProductSpec {
  const ProductSpec(this.label, this.value);

  final String label;
  final String value;
}

/// The full shop catalog, shared by the shop grid and global search.
const kShopProducts = [
  ShopProduct(
    name: 'Pitch Deck Kit',
    category: 'Templates',
    price: 2400,
    rating: 4.9,
    icon: Icons.slideshow_rounded,
    tint: Color(0xFF2563EB),
    images: [
      'Assets/shop/product_01.jpg',
      'Assets/shop/featured_01.jpg',
      'Assets/shop/product_06.jpg',
      'Assets/shop/featured_03.jpg',
    ],
    description:
        'A complete investor-ready pitch deck system with 24 editable slides, '
        'sample narratives for SaaS and marketplace startups, and speaker notes '
        'so you can present with confidence. Built for founders who need clarity '
        'fast without sacrificing design quality.',
    specifications: [
      ProductSpec('Format', 'PPTX + Keynote + PDF'),
      ProductSpec('Slides', '24 editable layouts'),
      ProductSpec('License', 'Commercial · 1 team'),
      ProductSpec('Updates', 'Lifetime free updates'),
      ProductSpec('Delivery', 'Instant download'),
      ProductSpec('Includes', 'Icons, charts, mockups'),
    ],
  ),
  ShopProduct(
    name: 'UX Research Course',
    category: 'Courses',
    price: 4900,
    rating: 4.8,
    icon: Icons.school_rounded,
    tint: Color(0xFF7C3AED),
    images: [
      'Assets/shop/product_02.jpg',
      'Assets/shop/featured_02.jpg',
      'Assets/shop/product_04.jpg',
      'Assets/shop/product_01.jpg',
    ],
    description:
        'Learn to plan interviews, run usability tests, synthesize insights, '
        'and present findings that actually change the roadmap. Includes '
        'templates for scripts, affinity maps, and research readouts used by '
        'product teams at early-stage startups.',
    specifications: [
      ProductSpec('Lessons', '32 video lessons'),
      ProductSpec('Duration', '6.5 hours'),
      ProductSpec('Level', 'Beginner → Intermediate'),
      ProductSpec('Certificate', 'Yes · Innovator'),
      ProductSpec('Resources', '12 research templates'),
      ProductSpec('Access', 'Lifetime · offline downloads'),
    ],
  ),
  ShopProduct(
    name: 'Startup Playbook',
    category: 'E-books',
    price: 1900,
    rating: 4.7,
    icon: Icons.menu_book_rounded,
    tint: Color(0xFFDC2626),
    images: [
      'Assets/shop/product_03.jpg',
      'Assets/shop/product_08.jpg',
      'Assets/shop/featured_01.jpg',
      'Assets/shop/product_05.jpg',
    ],
    description:
        'A practical field guide covering idea validation, MVP scoping, early '
        'hiring, pricing experiments, and the first fundraising conversations. '
        'Written for Nepal-based founders with local case notes and checklists.',
    specifications: [
      ProductSpec('Pages', '148 pages'),
      ProductSpec('Format', 'PDF + EPUB'),
      ProductSpec('Language', 'English'),
      ProductSpec('Extras', 'Notion checklist pack'),
      ProductSpec('Updates', '1 year of revisions'),
      ProductSpec('Print', 'Printable A4 layout'),
    ],
  ),
  ShopProduct(
    name: 'Brand Identity Pack',
    category: 'Design',
    price: 3200,
    rating: 4.9,
    icon: Icons.palette_rounded,
    tint: Color(0xFFDB2777),
    images: [
      'Assets/shop/product_04.jpg',
      'Assets/shop/featured_03.jpg',
      'Assets/shop/product_02.jpg',
      'Assets/shop/product_07.jpg',
    ],
    description:
        'Logo lockups, color systems, type pairings, social templates, and a '
        'one-page brand guide you can hand to freelancers. Designed to feel '
        'premium on day one while staying easy to customize.',
    specifications: [
      ProductSpec('Files', 'AI · Figma · PNG · SVG'),
      ProductSpec('Logos', 'Primary + 4 variants'),
      ProductSpec('Colors', 'Full palette + tokens'),
      ProductSpec('Templates', '12 social posts'),
      ProductSpec('Guide', '8-page brand PDF'),
      ProductSpec('License', 'Commercial · unlimited'),
    ],
  ),
  ShopProduct(
    name: 'Roadmap Planner',
    category: 'Tools',
    price: 1500,
    rating: 4.6,
    icon: Icons.route_rounded,
    tint: Color(0xFF17A275),
    images: [
      'Assets/shop/product_05.jpg',
      'Assets/shop/product_01.jpg',
      'Assets/shop/featured_02.jpg',
      'Assets/shop/product_08.jpg',
    ],
    description:
        'A lightweight roadmap workspace for quarterly planning: now / next / '
        'later boards, capacity notes, and stakeholder-ready export views. Ideal '
        'for small product teams that want structure without enterprise bloat.',
    specifications: [
      ProductSpec('Platform', 'Notion + Sheets'),
      ProductSpec('Views', 'Timeline · Board · List'),
      ProductSpec('Seats', 'Up to 8 collaborators'),
      ProductSpec('Export', 'PDF · CSV'),
      ProductSpec('Templates', '3 roadmap styles'),
      ProductSpec('Support', 'Email · 7 days'),
    ],
  ),
  ShopProduct(
    name: 'Product Spec Doc',
    category: 'Templates',
    price: 1200,
    rating: 4.8,
    icon: Icons.description_rounded,
    tint: Color(0xFF4F46E5),
    images: [
      'Assets/shop/product_06.jpg',
      'Assets/shop/product_03.jpg',
      'Assets/shop/featured_01.jpg',
      'Assets/shop/product_02.jpg',
    ],
    description:
        'A crisp PRD / product spec template that keeps goals, user stories, '
        'edge cases, and success metrics on one readable canvas. Includes '
        'examples for feature launches and bug-bash scopes.',
    specifications: [
      ProductSpec('Format', 'Doc · Notion · Markdown'),
      ProductSpec('Sections', '11 structured blocks'),
      ProductSpec('Examples', '3 filled samples'),
      ProductSpec('Diagrams', 'Flow + wireframe slots'),
      ProductSpec('Collab', 'Comment-ready layout'),
      ProductSpec('License', 'Team · internal use'),
    ],
  ),
  ShopProduct(
    name: 'Growth Marketing 101',
    category: 'Courses',
    price: 3900,
    rating: 4.7,
    icon: Icons.trending_up_rounded,
    tint: Color(0xFFB45309),
    images: [
      'Assets/shop/product_07.jpg',
      'Assets/shop/featured_02.jpg',
      'Assets/shop/product_05.jpg',
      'Assets/shop/product_04.jpg',
    ],
    description:
        'Acquisition loops, retention experiments, channel scoring, and a '
        'weekly growth ritual you can run with a two-person team. Comes with '
        'spreadsheet models for CAC, LTV, and experiment tracking.',
    specifications: [
      ProductSpec('Lessons', '28 video lessons'),
      ProductSpec('Duration', '5 hours'),
      ProductSpec('Level', 'Intermediate'),
      ProductSpec('Tools', 'Sheets + Looker Studio'),
      ProductSpec('Certificate', 'Yes · Innovator'),
      ProductSpec('Community', 'Private cohort chat'),
    ],
  ),
  ShopProduct(
    name: 'Investor One-Pager',
    category: 'Templates',
    price: 900,
    rating: 4.5,
    icon: Icons.article_rounded,
    tint: Color(0xFF0D9488),
    images: [
      'Assets/shop/product_08.jpg',
      'Assets/shop/product_01.jpg',
      'Assets/shop/featured_03.jpg',
      'Assets/shop/product_06.jpg',
    ],
    description:
        'A single-page teaser that captures problem, solution, traction, and '
        'the ask — designed to survive a 30-second skim in an investor inbox. '
        'Includes warm-intro and cold-outreach variants.',
    specifications: [
      ProductSpec('Format', 'PDF · Figma · Docs'),
      ProductSpec('Pages', '1 page · 2 variants'),
      ProductSpec('Size', 'A4 + US Letter'),
      ProductSpec('Editable', 'Fully customizable'),
      ProductSpec('Extras', 'Email blurb templates'),
      ProductSpec('Delivery', 'Instant download'),
    ],
  ),
];

class CartItem {
  CartItem(this.product, {this.quantity = 1});

  final ShopProduct product;
  int quantity;

  double get total => product.price * quantity;
}

/// App-wide cart. 13% VAT and a flat Rs 200 delivery charge that covers
/// all of Nepal are applied on top of the subtotal.
class Cart extends ChangeNotifier {
  Cart._();

  static final Cart instance = Cart._();

  static const vatRate = .13;
  static const deliveryCharge = 200.0;

  final List<CartItem> items = [];

  bool get isEmpty => items.isEmpty;
  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get vat => subtotal * vatRate;
  double get delivery => items.isEmpty ? 0 : deliveryCharge;
  double get grandTotal => subtotal + vat + delivery;

  void add(ShopProduct product) {
    for (final item in items) {
      if (item.product.name == product.name) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    items.add(CartItem(product));
    notifyListeners();
  }

  void increment(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  /// Dropping below one removes the line from the cart.
  void decrement(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}

/// 12400 -> "12,400"
String groupNum(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write(',');
  }
  return buffer.toString();
}

/// 12400 -> "Rs 12,400"
String formatRs(num value) => 'Rs ${groupNum(value)}';
