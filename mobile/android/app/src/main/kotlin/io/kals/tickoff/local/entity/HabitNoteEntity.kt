package io.kals.tickoff.local.entity

import java.time.LocalDate
import java.time.LocalDateTime

data class HabitNoteEntity(
    val id: String,
    val habitId: String,
    val noteDate: LocalDate,
    val content: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)
