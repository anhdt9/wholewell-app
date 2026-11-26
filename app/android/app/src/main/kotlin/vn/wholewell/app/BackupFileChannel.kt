package vn.wholewell.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Kênh mở/lưu tệp qua Android Storage Access Framework (ACTION_CREATE_DOCUMENT / ACTION_OPEN_DOCUMENT).
 * Không yêu cầu quyền READ_EXTERNAL_STORAGE hay WRITE_EXTERNAL_STORAGE.
 */
class BackupFileChannel(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "vn.wholewell.app/backup_files"
        private const val REQ_SAVE = 7101
        private const val REQ_PICK = 7102
    }

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var pendingSaveName: String = "wholewell-backup.wwbackup"

    private var pendingPickResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveFile" -> {
                if (pendingSaveResult != null || pendingPickResult != null) {
                    result.error("BUSY", "Đang có hộp thoại chọn tệp khác.", null)
                    return
                }
                val suggestedName = call.argument<String>("suggestedName") ?: "wholewell-backup.wwbackup"
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("INVALID_ARGS", "Thiếu dữ liệu tệp.", null)
                    return
                }
                pendingSaveResult = result
                pendingSaveBytes = bytes
                pendingSaveName = suggestedName

                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = mimeType
                    putExtra(Intent.EXTRA_TITLE, suggestedName)
                }
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQ_SAVE)
            }

            "pickFile" -> {
                if (pendingSaveResult != null || pendingPickResult != null) {
                    result.error("BUSY", "Đang có hộp thoại chọn tệp khác.", null)
                    return
                }
                pendingPickResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                }
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQ_PICK)
            }

            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQ_SAVE -> {
                val res = pendingSaveResult
                val bytes = pendingSaveBytes
                val fallbackName = pendingSaveName
                pendingSaveResult = null
                pendingSaveBytes = null
                if (res == null) return true

                val uri = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
                    res.success(null)
                    return true
                }

                ioExecutor.execute {
                    try {
                        activity.contentResolver.openOutputStream(uri)?.use { stream ->
                            stream.write(bytes)
                            stream.flush()
                        } ?: throw IllegalStateException("Không mở được luồng ghi tệp.")
                        val name = queryDisplayName(uri) ?: fallbackName
                        mainHandler.post { res.success(name) }
                    } catch (e: Exception) {
                        mainHandler.post { res.error("WRITE_FAILED", e.message, null) }
                    }
                }
                true
            }

            REQ_PICK -> {
                val res = pendingPickResult
                pendingPickResult = null
                if (res == null) return true

                val uri = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    res.success(null)
                    return true
                }

                ioExecutor.execute {
                    try {
                        val bytes = activity.contentResolver.openInputStream(uri)?.use { stream ->
                            stream.readBytes()
                        } ?: throw IllegalStateException("Không đọc được tệp.")
                        val name = queryDisplayName(uri) ?: "backup.wwbackup"
                        mainHandler.post {
                            res.success(
                                mapOf(
                                    "name" to name,
                                    "bytes" to bytes,
                                ),
                            )
                        }
                    } catch (e: Exception) {
                        mainHandler.post { res.error("READ_FAILED", e.message, null) }
                    }
                }
                true
            }

            else -> false
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (idx >= 0) cursor.getString(idx) else null
                    } else {
                        null
                    }
                } ?: uri.lastPathSegment
        } catch (_: Exception) {
            uri.lastPathSegment
        }
    }

    fun dispose() {
        ioExecutor.shutdownNow()
        pendingSaveResult = null
        pendingSaveBytes = null
        pendingPickResult = null
    }
}
