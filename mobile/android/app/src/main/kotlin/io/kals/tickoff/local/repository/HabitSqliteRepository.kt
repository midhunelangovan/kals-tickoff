package io.kals.tickoff.local.repository

import android.content.ContentValues
import android.database.Cursor
import io.kals.tickoff.local.db.TickoffDatabase
import io.kals.tickoff.local.entity.CompletionEntity
import io.kals.tickoff.local.entity.HabitEntity
import io.kals.tickoff.local.entity.HabitNoteEntity
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class HabitSqliteRepository(private val database: TickoffDatabase) {

    companion object {
        private val DT_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        private val DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    }

    // ─── Habit Operations ────────────────────────────────────────────

    fun findAllByArchivedFalseOrderByCreatedAtDesc(): List<HabitEntity> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, name, icon, category_id, description, color, created_at, archived, sort_order FROM habits WHERE archived = 0 ORDER BY sort_order ASC, created_at DESC",
            null
        )
        return cursor.use { readHabits(it) }
    }

    fun findAll(): List<HabitEntity> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, name, icon, category_id, description, color, created_at, archived, sort_order FROM habits ORDER BY sort_order ASC, created_at DESC",
            null
        )
        return cursor.use { readHabits(it) }
    }

    fun findById(id: String): HabitEntity? {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, name, icon, category_id, description, color, created_at, archived, sort_order FROM habits WHERE id = ?",
            arrayOf(id)
        )
        return cursor.use { if (it.moveToFirst()) readHabit(it) else null }
    }

    fun existsById(id: String): Boolean {
        val db = database.readableDatabase
        val cursor = db.rawQuery("SELECT 1 FROM habits WHERE id = ?", arrayOf(id))
        return cursor.use { it.moveToFirst() }
    }

    fun save(habit: HabitEntity): HabitEntity {
        val db = database.writableDatabase
        val values = ContentValues().apply {
            put("id", habit.id)
            put("name", habit.name)
            put("icon", habit.icon)
            put("category_id", habit.categoryId)
            put("description", habit.description)
            put("color", habit.color)
            put("created_at", habit.createdAt.format(DT_FORMAT))
            put("archived", if (habit.archived) 1 else 0)
            put("sort_order", habit.sortOrder)
        }

        // Try update first, insert if no rows affected
        val rowsUpdated = db.update("habits", values, "id = ?", arrayOf(habit.id))
        if (rowsUpdated == 0) {
            db.insertWithOnConflict("habits", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
        }
        return habit
    }

    fun reorderHabits(habitIds: List<String>) {
        val db = database.writableDatabase
        db.beginTransaction()
        try {
            habitIds.forEachIndexed { index, id ->
                val values = ContentValues().apply {
                    put("sort_order", index)
                }
                db.update("habits", values, "id = ?", arrayOf(id))
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun deleteById(id: String) {
        val db = database.writableDatabase
        db.delete("habits", "id = ?", arrayOf(id))
    }

    // ─── Completion Operations ───────────────────────────────────────

    fun findAllCompletions(): List<CompletionEntity> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, habit_id, completion_date, created_at FROM habit_completions ORDER BY completion_date ASC",
            null
        )
        return cursor.use { readCompletions(it) }
    }

    fun findCompletionsByHabitIds(habitIds: List<String>): List<CompletionEntity> {
        if (habitIds.isEmpty()) return emptyList()

        val db = database.readableDatabase
        val placeholders = habitIds.joinToString(",") { "?" }
        val cursor = db.rawQuery(
            "SELECT id, habit_id, completion_date, created_at FROM habit_completions WHERE habit_id IN ($placeholders) ORDER BY completion_date ASC",
            habitIds.toTypedArray()
        )
        return cursor.use { readCompletions(it) }
    }

    fun countCompletionsByHabitIdsAndDate(habitIds: List<String>, date: LocalDate): Long {
        if (habitIds.isEmpty()) return 0L
        val db = database.readableDatabase
        val placeholders = habitIds.joinToString(",") { "?" }
        val args = habitIds.toMutableList().apply { add(date.format(DATE_FORMAT)) }
        val cursor = db.rawQuery(
            "SELECT COUNT(*) FROM habit_completions WHERE habit_id IN ($placeholders) AND completion_date = ?",
            args.toTypedArray()
        )
        return cursor.use {
            if (it.moveToFirst()) it.getLong(0) else 0L
        }
    }

    fun existsCompletionByHabitIdAndDate(habitId: String, date: LocalDate): Boolean {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT 1 FROM habit_completions WHERE habit_id = ? AND completion_date = ?",
            arrayOf(habitId, date.format(DATE_FORMAT))
        )
        return cursor.use { it.moveToFirst() }
    }

    fun saveCompletion(completion: CompletionEntity) {
        val db = database.writableDatabase
        val values = ContentValues().apply {
            put("id", completion.id)
            put("habit_id", completion.habitId)
            put("completion_date", completion.completionDate.format(DATE_FORMAT))
            put("created_at", completion.createdAt.format(DT_FORMAT))
        }
        db.insertWithOnConflict(
            "habit_completions", null, values,
            android.database.sqlite.SQLiteDatabase.CONFLICT_IGNORE
        )
    }

    fun deleteCompletionByHabitIdAndDate(habitId: String, date: LocalDate) {
        val db = database.writableDatabase
        db.delete(
            "habit_completions",
            "habit_id = ? AND completion_date = ?",
            arrayOf(habitId, date.format(DATE_FORMAT))
        )
    }

    fun deleteAllCompletionsByHabitId(habitId: String) {
        val db = database.writableDatabase
        db.delete("habit_completions", "habit_id = ?", arrayOf(habitId))
    }

    fun findCompletionDatesByHabitIdAndDateLessThanEqual(
        habitId: String, date: LocalDate
    ): List<LocalDate> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT completion_date FROM habit_completions WHERE habit_id = ? AND completion_date <= ? ORDER BY completion_date DESC",
            arrayOf(habitId, date.format(DATE_FORMAT))
        )
        return cursor.use { readDates(it) }
    }

    fun findCompletionDatesByHabitIdAsc(habitId: String): List<LocalDate> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT completion_date FROM habit_completions WHERE habit_id = ? ORDER BY completion_date ASC",
            arrayOf(habitId)
        )
        return cursor.use { readDates(it) }
    }

    // ─── Daily Notes Operations ──────────────────────────────────────

    fun findNoteByHabitIdAndDate(habitId: String, date: LocalDate): HabitNoteEntity? {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, habit_id, note_date, content, created_at, updated_at FROM habit_notes WHERE habit_id = ? AND note_date = ?",
            arrayOf(habitId, date.format(DATE_FORMAT))
        )
        return cursor.use {
            if (it.moveToFirst()) readNote(it) else null
        }
    }

    fun findNotesMapByHabitIdsAndDate(habitIds: List<String>, date: LocalDate): Map<String, String> {
        if (habitIds.isEmpty()) return emptyMap()
        val db = database.readableDatabase
        val placeholders = habitIds.joinToString(",") { "?" }
        val args = habitIds.toMutableList().apply { add(date.format(DATE_FORMAT)) }
        val cursor = db.rawQuery(
            "SELECT habit_id, content FROM habit_notes WHERE habit_id IN ($placeholders) AND note_date = ?",
            args.toTypedArray()
        )
        val result = mutableMapOf<String, String>()
        cursor.use {
            while (it.moveToNext()) {
                result[it.getString(0)] = it.getString(1)
            }
        }
        return result
    }

    fun findAllNotes(): List<HabitNoteEntity> {
        val db = database.readableDatabase
        val cursor = db.rawQuery(
            "SELECT id, habit_id, note_date, content, created_at, updated_at FROM habit_notes ORDER BY note_date DESC",
            null
        )
        return cursor.use { readNotes(it) }
    }

    fun saveNote(note: HabitNoteEntity): HabitNoteEntity {
        val db = database.writableDatabase
        val values = ContentValues().apply {
            put("id", note.id)
            put("habit_id", note.habitId)
            put("note_date", note.noteDate.format(DATE_FORMAT))
            put("content", note.content)
            put("created_at", note.createdAt.format(DT_FORMAT))
            put("updated_at", note.updatedAt.format(DT_FORMAT))
        }
        db.insertWithOnConflict(
            "habit_notes", null, values,
            android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE
        )
        return note
    }

    fun deleteNoteByHabitIdAndDate(habitId: String, date: LocalDate): Boolean {
        val db = database.writableDatabase
        val rows = db.delete(
            "habit_notes",
            "habit_id = ? AND note_date = ?",
            arrayOf(habitId, date.format(DATE_FORMAT))
        )
        return rows > 0
    }

    // ─── Atomic Backup & Restore ─────────────────────────────────────

    fun atomicRestore(
        habits: List<HabitEntity>,
        completions: List<CompletionEntity>,
        notes: List<HabitNoteEntity>
    ) {
        val db = database.writableDatabase
        db.beginTransaction()
        try {
            // 1. Clear existing user data
            db.delete("habit_notes", null, null)
            db.delete("habit_completions", null, null)
            db.delete("habits", null, null)

            // 2. Insert habits
            for (habit in habits) {
                val values = ContentValues().apply {
                    put("id", habit.id)
                    put("name", habit.name)
                    put("icon", habit.icon)
                    put("category_id", habit.categoryId)
                    put("description", habit.description)
                    put("color", habit.color)
                    put("created_at", habit.createdAt.format(DT_FORMAT))
                    put("archived", if (habit.archived) 1 else 0)
                    put("sort_order", habit.sortOrder)
                }
                db.insertWithOnConflict("habits", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
            }

            // 3. Insert completions
            for (comp in completions) {
                val values = ContentValues().apply {
                    put("id", comp.id)
                    put("habit_id", comp.habitId)
                    put("completion_date", comp.completionDate.format(DATE_FORMAT))
                    put("created_at", comp.createdAt.format(DT_FORMAT))
                }
                db.insertWithOnConflict("habit_completions", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
            }

            // 4. Insert notes
            for (note in notes) {
                val values = ContentValues().apply {
                    put("id", note.id)
                    put("habit_id", note.habitId)
                    put("note_date", note.noteDate.format(DATE_FORMAT))
                    put("content", note.content)
                    put("created_at", note.createdAt.format(DT_FORMAT))
                    put("updated_at", note.updatedAt.format(DT_FORMAT))
                }
                db.insertWithOnConflict("habit_notes", null, values, android.database.sqlite.SQLiteDatabase.CONFLICT_REPLACE)
            }

            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    // ─── Cursor Helpers ──────────────────────────────────────────────

    private fun readHabits(cursor: Cursor): List<HabitEntity> {
        val list = mutableListOf<HabitEntity>()
        while (cursor.moveToNext()) {
            list.add(readHabit(cursor))
        }
        return list
    }

    private fun readHabit(cursor: Cursor): HabitEntity {
        val sortOrder = if (cursor.columnCount > 8) cursor.getInt(8) else 0
        return HabitEntity(
            id = cursor.getString(0),
            name = cursor.getString(1),
            icon = cursor.getString(2) ?: "bolt",
            categoryId = cursor.getString(3),
            description = cursor.getString(4),
            color = cursor.getString(5) ?: "#7C3AED",
            createdAt = parseDateTime(cursor.getString(6)),
            archived = cursor.getInt(7) != 0,
            sortOrder = sortOrder
        )
    }

    private fun readCompletions(cursor: Cursor): List<CompletionEntity> {
        val list = mutableListOf<CompletionEntity>()
        while (cursor.moveToNext()) {
            list.add(
                CompletionEntity(
                    id = cursor.getString(0),
                    habitId = cursor.getString(1),
                    completionDate = LocalDate.parse(cursor.getString(2), DATE_FORMAT),
                    createdAt = parseDateTime(cursor.getString(3))
                )
            )
        }
        return list
    }

    private fun readNotes(cursor: Cursor): List<HabitNoteEntity> {
        val list = mutableListOf<HabitNoteEntity>()
        while (cursor.moveToNext()) {
            list.add(readNote(cursor))
        }
        return list
    }

    private fun readNote(cursor: Cursor): HabitNoteEntity {
        return HabitNoteEntity(
            id = cursor.getString(0),
            habitId = cursor.getString(1),
            noteDate = LocalDate.parse(cursor.getString(2), DATE_FORMAT),
            content = cursor.getString(3),
            createdAt = parseDateTime(cursor.getString(4)),
            updatedAt = parseDateTime(cursor.getString(5))
        )
    }

    private fun readDates(cursor: Cursor): List<LocalDate> {
        val list = mutableListOf<LocalDate>()
        while (cursor.moveToNext()) {
            list.add(LocalDate.parse(cursor.getString(0), DATE_FORMAT))
        }
        return list
    }

    private fun parseDateTime(raw: String): LocalDateTime {
        val trimmed = raw.trim()
        try {
            return LocalDateTime.parse(trimmed, DT_FORMAT)
        } catch (_: Exception) {}
        try {
            return LocalDateTime.parse(trimmed)
        } catch (_: Exception) {}
        try {
            if (trimmed.length >= 10) {
                val datePart = trimmed.substring(0, 10)
                return LocalDate.parse(datePart, DATE_FORMAT).atStartOfDay()
            }
        } catch (_: Exception) {}
        return LocalDateTime.now()
    }
}
