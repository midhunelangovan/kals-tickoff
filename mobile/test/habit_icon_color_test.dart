import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/app/theme.dart';
import 'package:habit_tracker_mobile/app/theme_controller.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_color_palette.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_icons_catalog.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/widgets/color_picker.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/widgets/habit_card.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/widgets/icon_picker.dart';
import 'package:habit_tracker_mobile/features/settings/presentation/theme_settings_sheet.dart';

void main() {
  group('HabitIcon & HabitColor Domain Tests', () {
    test('getHabitIcon returns correct Material Icon', () {
      expect(getHabitIcon('code'), Icons.code_rounded);
      expect(getHabitIcon('directions_run'), Icons.directions_run_rounded);
      expect(getHabitIcon('fitness_center'), Icons.fitness_center_rounded);
      expect(getHabitIcon('reading'), Icons.menu_book_rounded);
      expect(getHabitIcon('unknown_id'), Icons.bolt_rounded);
      expect(habitIconsCatalog.length, greaterThanOrEqualTo(100));
    });

    test('parseHexColor parses 6-digit and 8-digit hex colors accurately', () {
      expect(parseHexColor('#10B981'), const Color(0xFF10B981));
      expect(parseHexColor('2563EB'), const Color(0xFF2563EB));
      expect(parseHexColor(null), const Color(0xFF7C3AED));
      expect(parseHexColor('invalid'), const Color(0xFF7C3AED));
    });

    test('colorToHex serializes color to hex string', () {
      expect(colorToHex(const Color(0xFF10B981)), '#10B981');
    });

    test('HabitColorShades derives all habit visual states from base color', () {
      const base = Color(0xFF2563EB);
      final shades = HabitColorShades.fromColor(base);

      expect(shades.base, base);
      expect(shades.primary, base);
      expect(shades.completed, base);
      expect(shades.selected, base);
      expect(shades.text, base);
      expect(shades.hover, base.withValues(alpha: 0.28));
      expect(shades.pressed, base.withValues(alpha: 0.45));
      expect(shades.lightBackground, base.withValues(alpha: 0.12));
      expect(shades.border, base.withValues(alpha: 0.35));
    });

    test('AppThemeShades derives centralized application-level visual states', () {
      const base = Color(0xFF7C3AED);
      final shades = AppThemeShades.fromColor(base);

      expect(shades.primary, base);
      expect(shades.selected, base);
      expect(shades.hover, base.withValues(alpha: 0.12));
      expect(shades.pressed, base.withValues(alpha: 0.25));
      expect(shades.backgroundTint, base.withValues(alpha: 0.10));
      expect(shades.border, base.withValues(alpha: 0.35));
      expect(shades.primaryLight, isNotNull);
      expect(shades.primaryDark, isNotNull);
    });
  });

  group('Widget Tests for Color and Icon Pickers', () {
    testWidgets('HabitIconPicker allows selecting an icon from 100+ icon grid', (tester) async {
      String selected = 'bolt';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitIconPicker(
              selectedIconId: selected,
              onIconSelected: (id) => selected = id,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Icon'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.pumpAndSettle();

      expect(selected, 'star');
    });

    testWidgets('HabitColorPicker allows selecting a color swatch', (tester) async {
      String selected = '#7C3AED';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitColorPicker(
              selectedHex: selected,
              onColorSelected: (hex) => selected = hex,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
      final inkWells = find.descendant(
        of: find.byType(HabitColorPicker),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsWidgets);

      // Tap the second color swatch
      await tester.tap(inkWells.at(1));
      await tester.pumpAndSettle();

      expect(selected, predefinedHabitColors[1].hex);
    });

    testWidgets('ThemeSettingsSheet allows changing global application theme', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ThemeSettingsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Theme & Appearance'), findsOneWidget);

      final gridSwatches = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(gridSwatches, findsWidgets);

      // Tap on the second theme swatch
      await tester.tap(gridSwatches.at(1));
      await tester.pumpAndSettle();

      final currentTheme = container.read(appThemeColorProvider);
      expect(currentTheme, predefinedHabitColors[1].color);
    });

    testWidgets('HabitCard applies custom habit color to UI components', (tester) async {
      final habit = Habit(
        id: 'h-custom',
        name: 'Coding Sprint',
        icon: 'code',
        color: '#10B981', // Emerald green
        createdAt: DateTime.now(),
        completed: true,
        currentStreak: 4,
        selectedDate: DateTime.now(),
        completedDates: {formatDateKey(DateTime.now())},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitCard(
              habit: habit,
              selectedDate: DateTime.now(),
              onToggle: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Coding Sprint'), findsOneWidget);
      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
