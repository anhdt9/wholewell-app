package vn.wholewell.app

import android.app.KeyguardManager
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
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
 * Phân loại khi đọc: không có bản khóa → absent; có bản khóa mà alias không còn hoặc
 * KeyPermanentlyInvalidatedException → lost; mọi lỗi khác → unavailable.
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

    private val wrappedFile: File get() = File(context.noBackupFilesDir, FILE_NAME)

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "read" -> result.success(read())
            "create" -> {
                val key = call.argument<ByteArray>("key")
                if (key == null || key.size != 32) {
                    result.error("bad_key", null, null)
                } else if (wrappedFile.exists()) {
                    // Không bao giờ ghi đè khóa đang có.
                    result.error("exists", null, null)
                } else {
                    try {
                        create(key)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("create_failed", null, null)
                    }
                }
            }
            "delete" -> {
                try {
                    delete()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("delete_failed", null, null)
                }
            }
            "isDeviceUnlocked" -> {
                val km = context.getSystemService(KeyguardManager::class.java)
                result.success(km != null && !km.isDeviceLocked)
            }
            else -> result.notImplemented()
        }
    }

    private fun read(): Map<String, Any> {
        val f = wrappedFile
        if (!f.exists()) return mapOf("status" to "absent")
        return try {
            val secret = keyStore().getKey(ALIAS, null) as SecretKey?
                ?: return mapOf("status" to "lost")
            val bytes = f.readBytes()
            val ivLen = bytes[0].toInt()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, secret, GCMParameterSpec(TAG_BITS, bytes, 1, ivLen))
            val plain = cipher.doFinal(bytes, 1 + ivLen, bytes.size - 1 - ivLen)
            mapOf("status" to "present", "key" to plain)
        } catch (e: KeyPermanentlyInvalidatedException) {
            mapOf("status" to "lost")
        } catch (e: Exception) {
            mapOf("status" to "unavailable")
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
        val iv = cipher.iv
        val ct = cipher.doFinal(key)
        val out = byteArrayOf(iv.size.toByte()) + iv + ct
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
