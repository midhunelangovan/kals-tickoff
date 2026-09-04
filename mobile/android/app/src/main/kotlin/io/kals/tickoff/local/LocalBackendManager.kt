package io.kals.tickoff.local

import android.content.Context
import android.util.Log
import io.kals.tickoff.local.db.TickoffDatabase
import io.kals.tickoff.local.repository.HabitSqliteRepository
import io.kals.tickoff.local.server.TickoffHttpServer
import io.kals.tickoff.local.service.HabitService
import io.kals.tickoff.local.service.StreakService
import java.util.concurrent.atomic.AtomicBoolean

class LocalBackendManager(private val context: Context) {

    companion object {
        private const val TAG = "LocalBackendManager"
        const val DEFAULT_PORT = 18080
        const val BIND_HOST = "127.0.0.1"

        @Volatile
        private var instance: LocalBackendManager? = null

        fun getInstance(context: Context): LocalBackendManager {
            return instance ?: synchronized(this) {
                instance ?: LocalBackendManager(context.applicationContext).also { instance = it }
            }
        }
    }

    private var database: TickoffDatabase? = null
    private var server: TickoffHttpServer? = null
    private val ready = AtomicBoolean(false)

    @Synchronized
    fun start(port: Int = DEFAULT_PORT) {
        if (ready.get() && server?.isAlive == true) {
            Log.i(TAG, "Local backend server already running on port $port")
            return
        }

        try {
            Log.i(TAG, "Initializing SQLite database...")
            val db = TickoffDatabase(context)
            database = db

            // Force DB creation & migrations
            db.writableDatabase

            val repository = HabitSqliteRepository(db)
            val streakService = StreakService(repository)
            val habitService = HabitService(repository, streakService)

            Log.i(TAG, "Starting NanoHTTPD server on $BIND_HOST:$port...")
            val s = TickoffHttpServer(BIND_HOST, port, habitService)
            s.start()
            server = s
            ready.set(true)
            Log.i(TAG, "Embedded backend ready on $BIND_HOST:$port/tickoff")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start local backend server", e)
            ready.set(false)
            throw e
        }
    }

    @Synchronized
    fun stop() {
        Log.i(TAG, "Stopping local backend server...")
        ready.set(false)
        try {
            server?.stop()
            server = null
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping server", e)
        }

        try {
            database?.close()
            database = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing database", e)
        }
        Log.i(TAG, "Local backend server stopped")
    }

    fun isRunning(): Boolean = server?.isAlive == true

    fun isReady(): Boolean = ready.get() && isRunning()

    fun getPort(): Int = DEFAULT_PORT
}
