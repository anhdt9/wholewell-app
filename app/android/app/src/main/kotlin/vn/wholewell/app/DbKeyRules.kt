package vn.wholewell.app

/**
 * Quy tắc thuần của kho khóa CSDL, không phụ thuộc Android, để test trên JVM
 * (app/android/app/src/test).
 */
object DbKeyRules {
    /** Lỗi khi giải mã bản khóa. */
    enum class Failure { PERMANENTLY_INVALIDATED, OTHER }

    /**
     * Phân loại kết quả đọc (docs/specs/encrypted-db.md, mục Khóa):
     * không có bản khóa → absent; có bản khóa mà alias không còn, hoặc
     * KeyPermanentlyInvalidatedException → lost; mọi lỗi khác → unavailable.
     */
    fun classify(wrappedExists: Boolean, aliasExists: Boolean, failure: Failure?): String = when {
        !wrappedExists -> "absent"
        !aliasExists -> "lost"
        failure == Failure.PERMANENTLY_INVALIDATED -> "lost"
        failure != null -> "unavailable"
        else -> "present"
    }

    /** Bố cục tệp bản khóa: [độ dài IV, 1 byte][IV][bản mã kèm tag]. */
    fun pack(iv: ByteArray, ciphertext: ByteArray): ByteArray {
        require(iv.size in 1..255) { "iv" }
        return byteArrayOf(iv.size.toByte()) + iv + ciphertext
    }

    /** IV và bản mã; null khi tệp hỏng cấu trúc. */
    fun unpack(bytes: ByteArray): Pair<ByteArray, ByteArray>? {
        if (bytes.isEmpty()) return null
        val ivLen = bytes[0].toInt() and 0xFF
        if (ivLen == 0 || bytes.size <= 1 + ivLen) return null
        return bytes.copyOfRange(1, 1 + ivLen) to bytes.copyOfRange(1 + ivLen, bytes.size)
    }
}
