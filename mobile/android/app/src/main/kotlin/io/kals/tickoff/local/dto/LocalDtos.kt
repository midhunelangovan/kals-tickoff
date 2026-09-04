package io.kals.tickoff.local.dto

import com.google.gson.annotations.SerializedName

data class CreateHabitRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("icon") val icon: String? = "bolt",
    @SerializedName("description") val description: String? = null,
    @SerializedName("color") val color: String? = "#7C3AED"
)

data class UpdateHabitRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("icon") val icon: String? = "bolt",
    @SerializedName("description") val description: String? = null,
    @SerializedName("color") val color: String? = "#7C3AED"
)

data class ReorderHabitsRequest(
    @SerializedName("habitIds") val habitIds: List<String> = emptyList()
)

data class HabitResponse(
    @SerializedName("id") val id: String,
    @SerializedName("habitId") val habitId: String,
    @SerializedName("name") val name: String,
    @SerializedName("icon") val icon: String,
    @SerializedName("description") val description: String? = null,
    @SerializedName("color") val color: String,
    @SerializedName("createdAt") val createdAt: String, // ISO-8601 string yyyy-MM-dd'T'HH:mm:ss
    @SerializedName("archived") val archived: Boolean,
    @SerializedName("sortOrder") val sortOrder: Int = 0,
    @SerializedName("currentStreak") val currentStreak: Int,
    @SerializedName("selectedDate") val selectedDate: String? = null, // yyyy-MM-dd
    @SerializedName("completedOnSelectedDate") val completedOnSelectedDate: Boolean? = null,
    @SerializedName("completedOnDate") val completedOnDate: Boolean? = null,
    @SerializedName("completedToday") val completedToday: Boolean? = null,
    @SerializedName("completions") val completions: List<String> = emptyList(), // list of yyyy-MM-dd
    @SerializedName("hasNote") val hasNote: Boolean = false,
    @SerializedName("noteContent") val noteContent: String? = null
)

data class CompletionResponse(
    @SerializedName("habitId") val habitId: String,
    @SerializedName("completionDate") val completionDate: String, // yyyy-MM-dd
    @SerializedName("completed") val completed: Boolean,
    @SerializedName("currentStreak") val currentStreak: Int,
    @SerializedName("completions") val completions: List<String> = emptyList() // list of yyyy-MM-dd
)

data class HabitScoreResponse(
    @SerializedName("date") val date: String? = null,
    @SerializedName("score") val score: Double,
    @SerializedName("completed") val completed: Long,
    @SerializedName("total") val total: Long = 0,
    @SerializedName("expected") val expected: Long = total
)

data class HabitNoteDto(
    @SerializedName("id") val id: String,
    @SerializedName("habitId") val habitId: String,
    @SerializedName("date") val date: String,
    @SerializedName("content") val content: String,
    @SerializedName("createdAt") val createdAt: String,
    @SerializedName("updatedAt") val updatedAt: String
)

data class SaveNoteRequest(
    @SerializedName("content") val content: String = ""
)

data class BackupHabitItem(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("icon") val icon: String = "bolt",
    @SerializedName("description") val description: String? = null,
    @SerializedName("color") val color: String = "#7C3AED",
    @SerializedName("createdAt") val createdAt: String,
    @SerializedName("archived") val archived: Boolean = false,
    @SerializedName("sortOrder") val sortOrder: Int = 0
)

data class BackupCompletionItem(
    @SerializedName("id") val id: String,
    @SerializedName("habitId") val habitId: String,
    @SerializedName("completionDate") val completionDate: String,
    @SerializedName("createdAt") val createdAt: String
)

data class BackupNoteItem(
    @SerializedName("id") val id: String,
    @SerializedName("habitId") val habitId: String,
    @SerializedName("date") val date: String,
    @SerializedName("content") val content: String,
    @SerializedName("createdAt") val createdAt: String,
    @SerializedName("updatedAt") val updatedAt: String
)

data class BackupPayload(
    @SerializedName("version") val version: Int = 1,
    @SerializedName("app") val app: String = "Habit Tracker",
    @SerializedName("createdAt") val createdAt: String,
    @SerializedName("habits") val habits: List<BackupHabitItem> = emptyList(),
    @SerializedName("completions") val completions: List<BackupCompletionItem> = emptyList(),
    @SerializedName("notes") val notes: List<BackupNoteItem> = emptyList(),
    @SerializedName("settings") val settings: Map<String, Any?> = emptyMap()
)

data class HealthResponse(
    @SerializedName("status") val status: String = "UP"
)

data class ErrorResponse(
    @SerializedName("timestamp") val timestamp: String,
    @SerializedName("status") val status: Int,
    @SerializedName("error") val error: String,
    @SerializedName("message") val message: String,
    @SerializedName("path") val path: String? = null
)
