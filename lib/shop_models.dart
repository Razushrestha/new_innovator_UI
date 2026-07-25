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
  });

  final String name;
  final String category;
  final double price;
  final double rating;
  final IconData icon;
  final Color tint;
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
  ),
  ShopProduct(
    name: 'UX Research Course',
    category: 'Courses',
    price: 4900,
    rating: 4.8,
    icon: Icons.school_rounded,
    tint: Color(0xFF7C3AED),
  ),
  ShopProduct(
    name: 'Startup Playbook',
    category: 'E-books',
    price: 1900,
    rating: 4.7,
    icon: Icons.menu_book_rounded,
    tint: Color(0xFFDC2626),
  ),
  ShopProduct(
    name: 'Brand Identity Pack',
    category: 'Design',
    price: 3200,
    rating: 4.9,
    icon: Icons.palette_rounded,
    tint: Color(0xFFDB2777),
  ),
  ShopProduct(
    name: 'Roadmap Planner',
    category: 'Tools',
    price: 1500,
    rating: 4.6,
    icon: Icons.route_rounded,
    tint: Color(0xFF17A275),
  ),
  ShopProduct(
    name: 'Product Spec Doc',
    category: 'Templates',
    price: 1200,
    rating: 4.8,
    icon: Icons.description_rounded,
    tint: Color(0xFF4F46E5),
  ),
  ShopProduct(
    name: 'Growth Marketing 101',
    category: 'Courses',
    price: 3900,
    rating: 4.7,
    icon: Icons.trending_up_rounded,
    tint: Color(0xFFB45309),
  ),
  ShopProduct(
    name: 'Investor One-Pager',
    category: 'Templates',
    price: 900,
    rating: 4.5,
    icon: Icons.article_rounded,
    tint: Color(0xFF0D9488),
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
