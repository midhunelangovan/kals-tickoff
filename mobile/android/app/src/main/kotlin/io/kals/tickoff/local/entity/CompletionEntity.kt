package io.kals.tickoff.local.entity

import java.time.LocalDate
import java.time.LocalDateTime

data class CompletionEntity(
    val id: String,
    val habitId: String,
    val completionDate: LocalDate,
    val createdAt: LocalDateTime
)
