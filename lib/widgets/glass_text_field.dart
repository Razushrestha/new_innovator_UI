import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';

const _ink = BrandColors.ink;

/// Translucent input that brightens and gains a soft glow when focused,
/// as if the glass under your finger lights up.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.dense = false,
  });

  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;

  /// Slightly shorter field for compact auth layouts.
  final bool dense;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  late bool _obscured = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _focused
            ? Colors.white.withValues(alpha: .85)
            : Colors.white.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _focused
              ? BrandColors.accent.withValues(alpha: .65)
              : BrandColors.text.withValues(alpha: .9),
          width: 1.2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: BrandColors.accent.withValues(alpha: .18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        cursorColor: BrandColors.accent,
        style: const TextStyle(fontSize: 15, letterSpacing: .2, color: _ink),
        decoration: InputDecoration(
          isDense: widget.dense,
          hintText: widget.hint,
          hintStyle: TextStyle(color: _ink.withValues(alpha: .35)),
          prefixIcon: Icon(
            widget.icon,
            size: widget.dense ? 18 : 20,
            color: _ink.withValues(alpha: _focused ? .75 : .4),
          ),
          suffixIcon: widget.obscure
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  visualDensity: widget.dense
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: widget.dense ? 18 : 19,
                    color: _ink.withValues(alpha: .4),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: widget.dense ? 12 : 16.5,
          ),
        ),
      ),
    );
  }
}
