import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../domain/habit_note.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NoteRepository(dio);
});

class NoteRepository {
  final Dio _dio;

  NoteRepository(this._dio);

  Future<HabitNote?> getNote(String habitId, String date) async {
    try {
      final response = await _dio.get(
        '/habits/$habitId/notes',
        queryParameters: {'date': date},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final note = HabitNote.fromJson(response.data as Map<String, dynamic>);
        return note.content.isNotEmpty ? note : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<HabitNote> saveNote(String habitId, String date, String content) async {
    final response = await _dio.put(
      '/habits/$habitId/notes/$date',
      data: {'content': content.trim()},
    );
    return HabitNote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String habitId, String date) async {
    await _dio.delete('/habits/$habitId/notes/$date');
  }
}
