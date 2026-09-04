import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import 'habit_dto.dart';
import 'habit_score_dto.dart';

final habitApiServiceProvider = Provider<HabitApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return HabitApiService(dio);
});

class HabitApiService {
  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  HabitApiService(this._dio);

  String _formatDate(DateTime date) => _dateFormat.format(date);

  Future<List<HabitDto>> getHabits({DateTime? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = _formatDate(date);
    }

    final response = await _dio.get<List<dynamic>>(
      '/habits',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data ?? [];
    return data
        .map((item) => HabitDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HabitScoreDto> getHabitScore(DateTime date) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/habits/score',
      queryParameters: {'date': _formatDate(date)},
    );

    return HabitScoreDto.fromJson(response.data!);
  }

  Future<HabitDto> createHabit(
    String name, {
    String icon = 'bolt',
    String? description,
    String? color,
  }) async {
    final requestDto = CreateHabitRequestDto(
      name: name,
      icon: icon,
      description: description,
      color: color,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      '/habits',
      data: requestDto.toJson(),
    );

    return HabitDto.fromJson(response.data!);
  }

  Future<HabitDto> updateHabit(
    String habitId, {
    required String name,
    required String icon,
    String? color,
    String? description,
  }) async {
    final requestDto = UpdateHabitRequestDto(
      name: name,
      icon: icon,
      color: color,
      description: description,
    );
    final response = await _dio.put<Map<String, dynamic>>(
      '/habits/$habitId',
      data: requestDto.toJson(),
    );

    return HabitDto.fromJson(response.data!);
  }

  Future<void> deleteHabit(String habitId) async {
    await _dio.delete('/habits/$habitId');
  }

  Future<CompletionResponseDto> markCompleted(String habitId, DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await _dio.put<Map<String, dynamic>>(
      '/habits/$habitId/completions/$dateStr',
    );

    return CompletionResponseDto.fromJson(response.data!);
  }

  Future<CompletionResponseDto> unmarkCompleted(String habitId, DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await _dio.delete<Map<String, dynamic>>(
      '/habits/$habitId/completions/$dateStr',
    );

    return CompletionResponseDto.fromJson(response.data!);
  }

  Future<void> reorderHabits(List<String> habitIds) async {
    await _dio.put(
      '/habits/reorder',
      data: {'habitIds': habitIds},
    );
  }
}
