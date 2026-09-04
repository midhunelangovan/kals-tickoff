import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../domain/habit_color_palette.dart';

class HabitColorPicker extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onColorSelected;

  const HabitColorPicker({
    super.key,
    required this.selectedHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: predefinedHabitColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = predefinedHabitColors[index];
              final isSelected = item.hex.toUpperCase() == selectedHex.toUpperCase();

              return InkWell(
                onTap: () => onColorSelected(item.hex),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
