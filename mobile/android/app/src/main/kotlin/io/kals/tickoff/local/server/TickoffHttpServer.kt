package io.kals.tickoff.local.server

import android.util.Log
import com.google.gson.Gson
import fi.iki.elonen.NanoHTTPD
import io.kals.tickoff.local.dto.*
import io.kals.tickoff.local.service.HabitService
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class TickoffHttpServer(
    hostname: String = "127.0.0.1",
    port: Int = 18080,
    private val habitService: HabitService
) : NanoHTTPD(hostname, port) {

    companion object {
        private const val TAG = "TickoffHttpServer"
        private val ISO_DT_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")
        private val DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    }

    private val gson = Gson()

    override fun serve(session: IHTTPSession): Response {
        val uri = session.uri.removePrefix("/tickoff")
        val method = session.method

        Log.d(TAG, "Request: $method ${session.uri}")

        return try {
            when {
                // GET /internal/health
                method == Method.GET && (uri == "/internal/health" || uri == "/internal/health/") -> {
                    jsonResponse(Response.Status.OK, HealthResponse("UP"))
                }

                // PUT /habits/reorder
                method == Method.PUT && (uri == "/habits/reorder" || uri == "/habits/reorder/") -> {
                    val body = readBody(session)
                    val request = gson.fromJson(body, ReorderHabitsRequest::class.java)
                    habitService.reorderHabits(request)
                    newFixedLengthResponse(Response.Status.NO_CONTENT, "application/json", "")
                }

                // POST /habits
                method == Method.POST && (uri == "/habits" || uri == "/habits/") -> {
                    val body = readBody(session)
                    val request = try {
                        gson.fromJson(body, CreateHabitRequest::class.java)
                    } catch (e: Exception) {
                        throw IllegalArgumentException("JSON parse error on raw body: [$body], error: ${e.message}")
                    }
                    val response = habitService.createHabit(request)
                    jsonResponse(Response.Status.CREATED, response)
                }

                // GET /habits/score
                method == Method.GET && (uri == "/habits/score" || uri == "/habits/score/") -> {
                    val dateParam = session.parameters["date"]?.firstOrNull()
                    val targetDate = dateParam?.let { LocalDate.parse(it, DATE_FORMAT) }
                    val response = habitService.calculateHabitScore(targetDate)
                    jsonResponse(Response.Status.OK, response)
                }

                // GET /habits
                method == Method.GET && (uri == "/habits" || uri == "/habits/") -> {
                    val dateParam = session.parameters["date"]?.firstOrNull()
                    val targetDate = dateParam?.let { LocalDate.parse(it, DATE_FORMAT) }
                    val response = habitService.listHabits(targetDate)
                    jsonResponse(Response.Status.OK, response)
                }

                // PUT /habits/{habitId}/completions/{date}
                method == Method.PUT && uri.matches(Regex("/habits/[^/]+/completions/[^/]+")) -> {
                    val parts = uri.split("/")
                    val habitId = parts[2]
                    val date = LocalDate.parse(parts[4], DATE_FORMAT)
                    val response = habitService.markCompletion(habitId, date)
                    jsonResponse(Response.Status.OK, response)
                }

                // DELETE /habits/{habitId}/completions/{date}
                method == Method.DELETE && uri.matches(Regex("/habits/[^/]+/completions/[^/]+")) -> {
                    val parts = uri.split("/")
                    val habitId = parts[2]
                    val date = LocalDate.parse(parts[4], DATE_FORMAT)
                    val response = habitService.unmarkCompletion(habitId, date)
                    jsonResponse(Response.Status.OK, response)
                }

                // GET /habits/{habitId}/notes
                method == Method.GET && uri.matches(Regex("/habits/[^/]+/notes")) -> {
                    val habitId = uri.split("/")[2]
                    val dateParam = session.parameters["date"]?.firstOrNull() ?: LocalDate.now().format(DATE_FORMAT)
                    val date = LocalDate.parse(dateParam, DATE_FORMAT)
                    val note = habitService.getNote(habitId, date)
                    if (note != null) {
                        jsonResponse(Response.Status.OK, note)
                    } else {
                        jsonResponse(Response.Status.OK, mapOf("habitId" to habitId, "date" to dateParam, "content" to ""))
                    }
                }

                // PUT /habits/{habitId}/notes/{date}
                method == Method.PUT && uri.matches(Regex("/habits/[^/]+/notes/[^/]+")) -> {
                    val parts = uri.split("/")
                    val habitId = parts[2]
                    val date = LocalDate.parse(parts[4], DATE_FORMAT)
                    val body = readBody(session)
                    val request = gson.fromJson(body, SaveNoteRequest::class.java)
                    val response = habitService.saveNote(habitId, date, request.content)
                    jsonResponse(Response.Status.OK, response)
                }

                // DELETE /habits/{habitId}/notes/{date}
                method == Method.DELETE && uri.matches(Regex("/habits/[^/]+/notes/[^/]+")) -> {
                    val parts = uri.split("/")
                    val habitId = parts[2]
                    val date = LocalDate.parse(parts[4], DATE_FORMAT)
                    habitService.deleteNote(habitId, date)
                    newFixedLengthResponse(Response.Status.NO_CONTENT, "application/json", "")
                }

                // PUT /habits/{habitId}
                method == Method.PUT && uri.matches(Regex("/habits/[^/]+")) -> {
                    val habitId = uri.removePrefix("/habits/").removeSuffix("/")
                    val body = readBody(session)
                    val request = try {
                        gson.fromJson(body, UpdateHabitRequest::class.java)
                    } catch (e: Exception) {
                        throw IllegalArgumentException("JSON parse error on raw body: [$body], error: ${e.message}")
                    }
                    val response = habitService.updateHabit(habitId, request)
                    jsonResponse(Response.Status.OK, response)
                }

                // DELETE /habits/{habitId}
                method == Method.DELETE && uri.matches(Regex("/habits/[^/]+")) -> {
                    val habitId = uri.removePrefix("/habits/").removeSuffix("/")
                    habitService.deleteHabit(habitId)
                    newFixedLengthResponse(Response.Status.NO_CONTENT, "application/json", "")
                }

                // GET /backup/export
                method == Method.GET && (uri == "/backup/export" || uri == "/backup/export/") -> {
                    val backup = habitService.exportBackup()
                    jsonResponse(Response.Status.OK, backup)
                }

                // POST /backup/restore
                method == Method.POST && (uri == "/backup/restore" || uri == "/backup/restore/") -> {
                    val body = readBody(session)
                    val backup = gson.fromJson(body, BackupPayload::class.java)
                    habitService.restoreBackup(backup)
                    jsonResponse(Response.Status.OK, mapOf("status" to "RESTORED"))
                }

                else -> {
                    errorResponse(Response.Status.NOT_FOUND, "Not found: ${session.method} ${session.uri}", session.uri)
                }
            }
        } catch (e: NoSuchElementException) {
            errorResponse(Response.Status.NOT_FOUND, e.message ?: "Resource not found", session.uri)
        } catch (e: IllegalArgumentException) {
            errorResponse(Response.Status.BAD_REQUEST, e.message ?: "Bad request", session.uri)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling request", e)
            errorResponse(Response.Status.INTERNAL_ERROR, "Internal server error: ${e.message}", session.uri)
        }
    }

    private fun readBody(session: IHTTPSession): String {
        val files = HashMap<String, String>()
        session.parseBody(files)
        Log.d(TAG, "parseBody files keys: ${files.keys}")

        for (key in listOf("content", "postData")) {
            val value = files[key] ?: continue
            val file = java.io.File(value)
            if (file.exists() && file.isFile) {
                val text = file.readText(Charsets.UTF_8).trim()
                if (text.isNotEmpty()) return text
            } else if (value.startsWith("{") || value.startsWith("[")) {
                return value
            }
        }

        val contentLength = session.headers["content-length"]?.toIntOrNull() ?: 0
        if (contentLength > 0) {
            val buffer = ByteArray(contentLength)
            var totalRead = 0
            while (totalRead < contentLength) {
                val read = session.inputStream.read(buffer, totalRead, contentLength - totalRead)
                if (read == -1) break
                totalRead += read
            }
            if (totalRead > 0) {
                return String(buffer, 0, totalRead, Charsets.UTF_8)
            }
        }
        return ""
    }

    private fun jsonResponse(status: Response.IStatus, obj: Any): Response {
        val json = gson.toJson(obj)
        val response = newFixedLengthResponse(status, "application/json", json)
        response.addHeader("Access-Control-Allow-Origin", "*")
        return response
    }

    private fun errorResponse(status: Response.IStatus, message: String, path: String): Response {
        val error = ErrorResponse(
            timestamp = LocalDateTime.now().format(ISO_DT_FORMAT),
            status = status.requestStatus,
            error = status.description,
            message = message,
            path = path
        )
        val json = gson.toJson(error)
        return newFixedLengthResponse(status, "application/json", json)
    }
}
