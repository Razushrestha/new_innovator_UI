import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _ink = Color(0xFF1B1E28);

/// Segmented glass control for picking gender. The selected pill slides
/// between options and fills with ink, matching the primary button.
class GlassGenderSelector extends StatelessWidget {
  const GlassGenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const options = ['Male', 'Female', 'Other'];

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = value == null ? -1 : options.indexOf(value!);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  left: segmentWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2A2F3E).withValues(alpha: .92),
                          const Color(0xFF15181F).withValues(alpha: .88),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: .25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(option);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: option == value
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: option == value
                                  ? Colors.white
                                  : _ink.withValues(alpha: .55),
                            ),
                            child: Text(option),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
