package io.kals.tickoff.local.entity

import java.time.LocalDateTime

data class HabitEntity(
    val id: String,
    val name: String,
    val icon: String = "bolt",
    val categoryId: String? = null,
    val description: String? = null,
    val color: String = "#7C3AED",
    val createdAt: LocalDateTime,
    val archived: Boolean = false,
    val sortOrder: Int = 0
)
