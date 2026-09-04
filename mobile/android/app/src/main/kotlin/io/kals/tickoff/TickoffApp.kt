package io.kals.tickoff

import android.util.Log
import io.flutter.app.FlutterApplication
import io.kals.tickoff.local.LocalBackendManager

class TickoffApp : FlutterApplication() {

    companion object {
        private const val TAG = "TickoffApp"
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "TickoffApp starting embedded local backend...")
        try {
            LocalBackendManager.getInstance(this).start()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting embedded backend in TickoffApp.onCreate", e)
        }
    }

    override fun onTerminate() {
        super.onTerminate()
        Log.i(TAG, "TickoffApp terminating...")
        LocalBackendManager.getInstance(this).stop()
    }
}
