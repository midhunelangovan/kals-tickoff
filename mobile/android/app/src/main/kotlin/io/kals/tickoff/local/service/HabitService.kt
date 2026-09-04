package io.kals.tickoff.local.service

import io.kals.tickoff.local.dto.*
import io.kals.tickoff.local.entity.CompletionEntity
import io.kals.tickoff.local.entity.HabitEntity
import io.kals.tickoff.local.entity.HabitNoteEntity
import io.kals.tickoff.local.repository.HabitSqliteRepository
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

class HabitService(
    private val repository: HabitSqliteRepository,
    private val streakService: StreakService
) {
    companion object {
        private val ISO_DT_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")
        private val DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    }

    fun createHabit(request: CreateHabitRequest): HabitResponse {
        val name = request.name?.trim().orEmpty()
        if (name.isEmpty()) {
            throw IllegalArgumentException("Habit name cannot be blank")
        }

        val effectiveIcon = request.icon?.trim()?.takeIf { it.isNotEmpty() } ?: "bolt"
        val effectiveColor = request.color?.trim()?.takeIf { it.isNotEmpty() } ?: "#7C3AED"
        val now = LocalDateTime.now()

        // Place new habit at the beginning (sort_order = 0)
        val existingHabits = repository.findAllByArchivedFalseOrderByCreatedAtDesc()
        val habit = HabitEntity(
            id = UUID.randomUUID().toString(),
            name = name,
            icon = effectiveIcon,
            description = request.description?.trim()?.takeIf { it.isNotEmpty() },
            color = effectiveColor,
            createdAt = now,
            archived = false,
            sortOrder = 0
        )

        // Increment others if needed or save
        repository.save(habit)

        return HabitResponse(
            id = habit.id,
            habitId = habit.id,
            name = habit.name,
            icon = habit.icon,
            description = habit.description,
            color = habit.color,
            createdAt = habit.createdAt.format(ISO_DT_FORMAT),
            archived = habit.archived,
            sortOrder = habit.sortOrder,
            currentStreak = 0,
            completedToday = false,
            completedOnDate = false,
            completedOnSelectedDate = false,
            completions = emptyList(),
            hasNote = false,
            noteContent = null
        )
    }

    fun listHabits(selectedDate: LocalDate?): List<HabitResponse> {
        val today = LocalDate.now()
        val effectiveSelectedDate = selectedDate ?: today
        val habits = repository.findAllByArchivedFalseOrderByCreatedAtDesc()

        if (habits.isEmpty()) {
            return emptyList()
        }

        val habitIds = habits.map { it.id }
        val allCompletions = repository.findCompletionsByHabitIds(habitIds)
        val notesMap = repository.findNotesMapByHabitIdsAndDate(habitIds, effectiveSelectedDate)

        val completionsByHabit = allCompletions.groupBy(
            keySelector = { it.habitId },
            valueTransform = { it.completionDate }
        )

        return habits.map { habit ->
            val sortedDates = completionsByHabit[habit.id] ?: emptyList()
            val completedDatesSet = sortedDates.toSet()

            val completedOnSelectedDate = completedDatesSet.contains(effectiveSelectedDate)
            val currentStreak = streakService.calculateStreakFromDateSet(completedDatesSet, today)
            val noteContent = notesMap[habit.id]

            HabitResponse(
                id = habit.id,
                habitId = habit.id,
                name = habit.name,
                icon = habit.icon,
                description = habit.description,
                color = habit.color,
                createdAt = habit.createdAt.format(ISO_DT_FORMAT),
                archived = habit.archived,
                sortOrder = habit.sortOrder,
                selectedDate = effectiveSelectedDate.format(DATE_FORMAT),
                currentStreak = currentStreak,
                completedOnDate = completedOnSelectedDate,
                completedOnSelectedDate = completedOnSelectedDate,
                completions = sortedDates.map { it.format(DATE_FORMAT) },
                hasNote = !noteContent.isNullOrBlank(),
                noteContent = noteContent
            )
        }
    }

    fun reorderHabits(request: ReorderHabitsRequest) {
        if (request.habitIds.isNotEmpty()) {
            repository.reorderHabits(request.habitIds)
        }
    }

    fun calculateHabitScore(targetDate: LocalDate?): HabitScoreResponse {
        val today = LocalDate.now()
        val selectedDate = targetDate ?: today

        val activeHabits = repository.findAllByArchivedFalseOrderByCreatedAtDesc()
        if (activeHabits.isEmpty()) {
            return HabitScoreResponse(
                date = selectedDate.format(DATE_FORMAT),
                score = 0.0,
                completed = 0,
                total = 0,
                expected = 0
            )
        }

        val endDate = if (selectedDate.isAfter(today)) today else selectedDate

        var totalEligible = 0L
        var totalCompleted = 0L

        val habitIds = activeHabits.map { it.id }
        val allCompletions = repository.findCompletionsByHabitIds(habitIds)
        val completionsByHabit = allCompletions.groupBy { it.habitId }

        for (habit in activeHabits) {
            val startDate = habit.createdAt.toLocalDate()
            if (endDate.isBefore(startDate)) {
                continue
            }
            val eligibleDays = java.time.temporal.ChronoUnit.DAYS.between(startDate, endDate) + 1
            totalEligible += eligibleDays

            val completions = completionsByHabit[habit.id] ?: emptyList()
            val completedInRange = completions.count {
                !it.completionDate.isBefore(startDate) && !it.completionDate.isAfter(endDate)
            }
            totalCompleted += completedInRange
        }

        val score = if (totalEligible > 0L) {
            val raw = (totalCompleted.toDouble() / totalEligible.toDouble()) * 100.0
            Math.round(raw * 10.0) / 10.0
        } else {
            0.0
        }

        return HabitScoreResponse(
            date = selectedDate.format(DATE_FORMAT),
            score = score,
            completed = totalCompleted,
            total = totalEligible,
            expected = totalEligible
        )
    }

    fun markCompletion(habitId: String, date: LocalDate): CompletionResponse {
        if (!repository.existsById(habitId)) {
            throw NoSuchElementException("Habit not found: $habitId")
        }

        if (!repository.existsCompletionByHabitIdAndDate(habitId, date)) {
            val completion = CompletionEntity(
                id = UUID.randomUUID().toString(),
                habitId = habitId,
                completionDate = date,
                createdAt = LocalDateTime.now()
            )
            repository.saveCompletion(completion)
        }

        val today = LocalDate.now()
        val currentStreak = streakService.calculateCurrentStreak(habitId, today)
        val completions = repository.findCompletionDatesByHabitIdAsc(habitId)

        return CompletionResponse(
            habitId = habitId,
            completionDate = date.format(DATE_FORMAT),
            completed = true,
            currentStreak = currentStreak,
            completions = completions.map { it.format(DATE_FORMAT) }
        )
    }

    fun unmarkCompletion(habitId: String, date: LocalDate): CompletionResponse {
        if (!repository.existsById(habitId)) {
            throw NoSuchElementException("Habit not found: $habitId")
        }

        if (repository.existsCompletionByHabitIdAndDate(habitId, date)) {
            repository.deleteCompletionByHabitIdAndDate(habitId, date)
        }

        val today = LocalDate.now()
        val currentStreak = streakService.calculateCurrentStreak(habitId, today)
        val completions = repository.findCompletionDatesByHabitIdAsc(habitId)

        return CompletionResponse(
            habitId = habitId,
            completionDate = date.format(DATE_FORMAT),
            completed = false,
            currentStreak = currentStreak,
            completions = completions.map { it.format(DATE_FORMAT) }
        )
    }

    fun updateHabit(habitId: String, request: UpdateHabitRequest): HabitResponse {
        val habit = repository.findById(habitId)
            ?: throw NoSuchElementException("Habit not found: $habitId")

        val trimmedName = request.name?.trim().orEmpty()
        if (trimmedName.isEmpty()) {
            throw IllegalArgumentException("Habit name cannot be blank")
        }

        val updated = habit.copy(
            name = trimmedName,
            icon = request.icon?.trim()?.takeIf { it.isNotEmpty() } ?: habit.icon,
            color = request.color?.trim()?.takeIf { it.isNotEmpty() } ?: habit.color,
            description = request.description?.trim()?.takeIf { it.isNotEmpty() } ?: habit.description
        )

        repository.save(updated)

        val today = LocalDate.now()
        val currentStreak = streakService.calculateCurrentStreak(habitId, today)
        val completedToday = repository.existsCompletionByHabitIdAndDate(habitId, today)
        val completions = repository.findCompletionDatesByHabitIdAsc(habitId)
        val note = repository.findNoteByHabitIdAndDate(habitId, today)

        return HabitResponse(
            id = updated.id,
            habitId = updated.id,
            name = updated.name,
            icon = updated.icon,
            description = updated.description,
            color = updated.color,
            createdAt = updated.createdAt.format(ISO_DT_FORMAT),
            archived = updated.archived,
            sortOrder = updated.sortOrder,
            currentStreak = currentStreak,
            completedToday = completedToday,
            completedOnDate = completedToday,
            completedOnSelectedDate = completedToday,
            completions = completions.map { it.format(DATE_FORMAT) },
            hasNote = note != null && note.content.isNotBlank(),
            noteContent = note?.content
        )
    }

    fun deleteHabit(habitId: String) {
        if (!repository.existsById(habitId)) {
            throw NoSuchElementException("Habit not found: $habitId")
        }

        repository.deleteAllCompletionsByHabitId(habitId)
        repository.deleteById(habitId)
    }

    // ─── Daily Notes ─────────────────────────────────────────────────

    fun getNote(habitId: String, date: LocalDate): HabitNoteDto? {
        val note = repository.findNoteByHabitIdAndDate(habitId, date) ?: return null
        return HabitNoteDto(
            id = note.id,
            habitId = note.habitId,
            date = note.noteDate.format(DATE_FORMAT),
            content = note.content,
            createdAt = note.createdAt.format(ISO_DT_FORMAT),
            updatedAt = note.updatedAt.format(ISO_DT_FORMAT)
        )
    }

    fun saveNote(habitId: String, date: LocalDate, content: String): HabitNoteDto {
        if (!repository.existsById(habitId)) {
            throw NoSuchElementException("Habit not found: $habitId")
        }

        val existing = repository.findNoteByHabitIdAndDate(habitId, date)
        val now = LocalDateTime.now()

        val entity = if (existing != null) {
            existing.copy(content = content.trim(), updatedAt = now)
        } else {
            HabitNoteEntity(
                id = UUID.randomUUID().toString(),
                habitId = habitId,
                noteDate = date,
                content = content.trim(),
                createdAt = now,
                updatedAt = now
            )
        }

        repository.saveNote(entity)

        return HabitNoteDto(
            id = entity.id,
            habitId = entity.habitId,
            date = entity.noteDate.format(DATE_FORMAT),
            content = entity.content,
            createdAt = entity.createdAt.format(ISO_DT_FORMAT),
            updatedAt = entity.updatedAt.format(ISO_DT_FORMAT)
        )
    }

    fun deleteNote(habitId: String, date: LocalDate): Boolean {
        return repository.deleteNoteByHabitIdAndDate(habitId, date)
    }

    // ─── Backup & Restore ────────────────────────────────────────────

    fun exportBackup(): BackupPayload {
        val habits = repository.findAll()
        val completions = repository.findAllCompletions()
        val notes = repository.findAllNotes()

        return BackupPayload(
            version = 1,
            app = "Habit Tracker",
            createdAt = LocalDateTime.now().format(ISO_DT_FORMAT),
            habits = habits.map {
                BackupHabitItem(
                    id = it.id,
                    name = it.name,
                    icon = it.icon,
                    description = it.description,
                    color = it.color,
                    createdAt = it.createdAt.format(ISO_DT_FORMAT),
                    archived = it.archived,
                    sortOrder = it.sortOrder
                )
            },
            completions = completions.map {
                BackupCompletionItem(
                    id = it.id,
                    habitId = it.habitId,
                    completionDate = it.completionDate.format(DATE_FORMAT),
                    createdAt = it.createdAt.format(ISO_DT_FORMAT)
                )
            },
            notes = notes.map {
                BackupNoteItem(
                    id = it.id,
                    habitId = it.habitId,
                    date = it.noteDate.format(DATE_FORMAT),
                    content = it.content,
                    createdAt = it.createdAt.format(ISO_DT_FORMAT),
                    updatedAt = it.updatedAt.format(ISO_DT_FORMAT)
                )
            },
            settings = emptyMap()
        )
    }

    fun restoreBackup(payload: BackupPayload) {
        if (payload.version > 1) {
            throw IllegalArgumentException("Unsupported backup version: ${payload.version}. Please update the application first.")
        }
        if (payload.app != "Habit Tracker") {
            throw IllegalArgumentException("This file is not a valid Habit Tracker backup.")
        }

        val habits = payload.habits.map {
            HabitEntity(
                id = it.id,
                name = it.name,
                icon = it.icon,
                description = it.description,
                color = it.color,
                createdAt = parseDateTime(it.createdAt),
                archived = it.archived,
                sortOrder = it.sortOrder
            )
        }

        val completions = payload.completions.map {
            CompletionEntity(
                id = it.id,
                habitId = it.habitId,
                completionDate = LocalDate.parse(it.completionDate, DATE_FORMAT),
                createdAt = parseDateTime(it.createdAt)
            )
        }

        val notes = payload.notes.map {
            HabitNoteEntity(
                id = it.id,
                habitId = it.habitId,
                noteDate = LocalDate.parse(it.date, DATE_FORMAT),
                content = it.content,
                createdAt = parseDateTime(it.createdAt),
                updatedAt = parseDateTime(it.updatedAt)
            )
        }

        repository.atomicRestore(habits, completions, notes)
    }

    private fun parseDateTime(raw: String): LocalDateTime {
        return try {
            LocalDateTime.parse(raw, ISO_DT_FORMAT)
        } catch (_: Exception) {
            try {
                LocalDateTime.parse(raw)
            } catch (_: Exception) {
                LocalDateTime.now()
            }
        }
    }
}
