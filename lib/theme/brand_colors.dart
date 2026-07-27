import 'package:flutter/material.dart';

/// Innovator brand palette.
abstract final class BrandColors {
  /// Dark navy used for solid surfaces, orbs, and filled liquid ink.
  static const secondarySurface = Color(0xFF071323);

  /// Primary text/icons on dark surfaces.
  static const text = Color(0xFFFFFFFF);

  /// Gold brand accent — selection, badges, highlights.
  static const accent = Color(0xFFF4B400);

  /// Readable body text on light glass (secondary surface at full opacity).
  static const ink = secondarySurface;

  /// Soft muted label on light glass.
  static const muted = Color(0xFF6B7280);

  /// Scaffold / clean backdrop behind glass.
  static const canvas = Color(0xFFF4F5F8);
}
