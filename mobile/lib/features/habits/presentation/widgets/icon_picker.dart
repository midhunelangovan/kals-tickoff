import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../domain/habit_icons_catalog.dart';

class HabitIconPicker extends StatelessWidget {
  final String selectedIconId;
  final ValueChanged<String> onIconSelected;
  final Color activeColor;

  const HabitIconPicker({
    super.key,
    required this.selectedIconId,
    required this.onIconSelected,
    this.activeColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 136,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: habitIconsCatalog.length,
            itemBuilder: (context, index) {
              final item = habitIconsCatalog[index];
              final isSelected = item.id.toLowerCase() == selectedIconId.toLowerCase();

              return InkWell(
                onTap: () => onIconSelected(item.id),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
