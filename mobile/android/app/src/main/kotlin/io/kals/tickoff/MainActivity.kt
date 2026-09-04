package io.kals.tickoff

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.kals.tickoff.local.LocalBackendManager
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "io.kals.tickoff/backend"
        private const val REQUEST_PICK_BACKUP = 9001
    }

    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val manager = LocalBackendManager.getInstance(this)
            when (call.method) {
                "startBackend" -> {
                    try {
                        manager.start()
                        result.success(manager.getPort())
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "stopBackend" -> {
                    manager.stop()
                    result.success(true)
                }
                "isReady" -> {
                    result.success(manager.isReady())
                }
                "getPort" -> {
                    result.success(manager.getPort())
                }
                "shareBackup" -> {
                    val fileName = call.argument<String>("fileName") ?: "habit_tracker_backup.json"
                    val content = call.argument<String>("content") ?: "{}"
                    try {
                        val backupDir = File(cacheDir, "backups").apply { mkdirs() }
                        val file = File(backupDir, fileName)
                        file.writeText(content, Charsets.UTF_8)

                        val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/json"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_SUBJECT, "Habit Tracker Backup")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(sendIntent, "Save or Share Backup")
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_FAILED", e.message, null)
                    }
                }
                "pickBackupFile" -> {
                    pendingPickResult = result
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "*/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(Intent.createChooser(intent, "Select Habit Tracker Backup"), REQUEST_PICK_BACKUP)
                    } catch (e: Exception) {
                        pendingPickResult = null
                        result.error("PICK_FAILED", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_PICK_BACKUP) {
            val result = pendingPickResult ?: return
            pendingPickResult = null

            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri: Uri = data.data!!
                    val content = contentResolver.openInputStream(uri)?.use { stream ->
                        stream.reader(Charsets.UTF_8).readText()
                    }
                    result.success(content)
                } catch (e: Exception) {
                    result.error("READ_FAILED", "Failed to read selected file: ${e.message}", null)
                }
            } else {
                result.success(null) // Cancelled
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isFinishing) {
            LocalBackendManager.getInstance(this).stop()
        }
    }
}
