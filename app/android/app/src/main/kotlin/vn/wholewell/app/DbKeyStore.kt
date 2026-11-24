package vn.wholewell.app

import android.app.KeyguardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Giữ khóa CSDL (docs/specs/encrypted-db.md, mục Khóa).
 *
 * Khóa CSDL (32 byte, tạo ở Dart) được mã hóa bằng một khóa AES-256-GCM trong Android
 * Keystore tạo với setUnlockedDeviceRequired(true): chỉ giải mã được khi máy đã mở khóa.
 * Bản đã mã hóa nằm trong noBackupFilesDir. Không ghi khóa ra log.
 *
 * Thao tác Keystore chạy trên một luồng nền (tuần tự); kết quả trả về trên luồng chính.
 */
class DbKeyStore(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "vn.wholewell.app/db_key"
        private const val ALIAS = "wholewell_db_wrap_v1"
        private const val FILE_NAME = "wholewell_db_key.bin"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val TAG_BITS = 128
    }

    private sealed class Reply {
        class Ok(val value: Any?) : Reply()
        class Err(val code: String) : Reply()
        object NotImplemented : Reply()
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private val wrappedFile: File get() = File(context.noBackupFilesDir, FILE_NAME)

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val method = call.method
        val keyArg = if (method == "create") call.argument<ByteArray>("key") else null
        worker.execute {
            val reply = try {
                handle(method, keyArg)
            } catch (e: Exception) {
                Reply.Err("${method}_failed")
            }
            main.post {
                when (reply) {
                    is Reply.Ok -> result.success(reply.value)
                    is Reply.Err -> result.error(reply.code, null, null)
                    Reply.NotImplemented -> result.notImplemented()
                }
            }
        }
    }

    private fun handle(method: String, key: ByteArray?): Reply = when (method) {
        "read" -> Reply.Ok(read())
        "create" -> when {
            key == null || key.size != 32 -> Reply.Err("bad_key")
            // Không bao giờ ghi đè khóa đang có.
            wrappedFile.exists() -> Reply.Err("exists")
            else -> {
                create(key)
                Reply.Ok(null)
            }
        }
        "delete" -> {
            delete()
            Reply.Ok(null)
        }
        "isDeviceUnlocked" -> {
            val km = context.getSystemService(KeyguardManager::class.java)
            Reply.Ok(km != null && !km.isDeviceLocked)
        }
        else -> Reply.NotImplemented
    }

    private fun status(s: String): Map<String, Any> = mapOf("status" to s)

    private fun read(): Map<String, Any> {
        val f = wrappedFile
        if (!f.exists()) return status(DbKeyRules.classify(false, false, null))
        return try {
            val ks = keyStore()
            if (!ks.containsAlias(ALIAS)) return status(DbKeyRules.classify(true, false, null))
            val secret = ks.getKey(ALIAS, null) as SecretKey
            val parts = DbKeyRules.unpack(f.readBytes())
                ?: return status(DbKeyRules.classify(true, true, DbKeyRules.Failure.OTHER))
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, secret, GCMParameterSpec(TAG_BITS, parts.first))
            val plain = cipher.doFinal(parts.second)
            mapOf("status" to DbKeyRules.classify(true, true, null), "key" to plain)
        } catch (e: KeyPermanentlyInvalidatedException) {
            status(DbKeyRules.classify(true, true, DbKeyRules.Failure.PERMANENTLY_INVALIDATED))
        } catch (e: Exception) {
            status(DbKeyRules.classify(true, true, DbKeyRules.Failure.OTHER))
        }
    }

    private fun create(key: ByteArray) {
        val ks = keyStore()
        // Alias còn sót mà không có bản khóa: không còn dữ liệu nào dùng nó.
        if (ks.containsAlias(ALIAS)) ks.deleteEntry(ALIAS)
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        gen.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setUnlockedDeviceRequired(true)
                .build(),
        )
        val secret = gen.generateKey()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secret)
        val out = DbKeyRules.pack(cipher.iv, cipher.doFinal(key))
        val tmp = File(context.noBackupFilesDir, "$FILE_NAME.tmp")
        FileOutputStream(tmp).use {
            it.write(out)
            it.fd.sync()
        }
        if (!tmp.renameTo(wrappedFile)) {
            tmp.delete()
            throw IllegalStateException("rename")
        }
    }

    private fun delete() {
        // Xóa bản khóa trước: dữ liệu không đọc được ngay cả khi xóa alias lỗi.
        val f = wrappedFile
        if (f.exists() && !f.delete()) throw IllegalStateException("delete")
        val ks = keyStore()
        if (ks.containsAlias(ALIAS)) ks.deleteEntry(ALIAS)
    }
}
