import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../domain/habit.dart';
import '../../domain/habit_color_palette.dart';
import '../habit_controller.dart';
import 'color_picker.dart';
import 'icon_picker.dart';

class EditHabitBottomSheet extends ConsumerStatefulWidget {
  final Habit habit;

  const EditHabitBottomSheet({
    super.key,
    required this.habit,
  });

  static Future<void> show(BuildContext context, Habit habit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditHabitBottomSheet(habit: habit),
    );
  }

  @override
  ConsumerState<EditHabitBottomSheet> createState() =>
      _EditHabitBottomSheetState();
}

class _EditHabitBottomSheetState extends ConsumerState<EditHabitBottomSheet> {
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  late String _selectedIconId;
  late String _selectedHex;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.habit.name);
    _selectedIconId = widget.habit.icon;
    _selectedHex = widget.habit.color ?? '#7C3AED';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return 'Habit not found.';
      } else if (statusCode == 400) {
        return 'Please enter a valid habit name.';
      } else if (statusCode == 500) {
        return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final habitName = _textController.text.trim();
    if (habitName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(habitControllerProvider.notifier).editHabit(
            widget.habit.id,
            name: habitName,
            icon: _selectedIconId,
            color: _selectedHex,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeColor = parseHexColor(_selectedHex);
    final themeShades = ref.watch(appThemeShadesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit habit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Habit Icon Selector Grid
              HabitIconPicker(
                selectedIconId: _selectedIconId,
                activeColor: activeColor,
                onIconSelected: (iconId) {
                  setState(() {
                    _selectedIconId = iconId;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 2. Habit Name Input
              const Text(
                'Habit name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'e.g. Morning Jog, Read 10 pages',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: activeColor,
                      width: 2,
                    ),
                  ),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 16),

              // 3. Habit Color Selector Palette
              HabitColorPicker(
                selectedHex: _selectedHex,
                onColorSelected: (hex) {
                  setState(() {
                    _selectedHex = hex;
                  });
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Action Buttons: [ Cancel ] [ Save changes ]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeShades.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
