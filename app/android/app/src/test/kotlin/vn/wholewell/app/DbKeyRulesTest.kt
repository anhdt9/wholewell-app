package vn.wholewell.app

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DbKeyRulesTest {
    @Test
    fun phanLoaiBonTrangThai() {
        assertEquals("absent", DbKeyRules.classify(false, false, null))
        assertEquals("absent", DbKeyRules.classify(false, true, null))
        assertEquals("lost", DbKeyRules.classify(true, false, null))
        assertEquals("lost", DbKeyRules.classify(true, true, DbKeyRules.Failure.PERMANENTLY_INVALIDATED))
        assertEquals("unavailable", DbKeyRules.classify(true, true, DbKeyRules.Failure.OTHER))
        assertEquals("present", DbKeyRules.classify(true, true, null))
    }

    @Test
    fun dongGoiVaMoGoiBanKhoa() {
        val iv = ByteArray(12) { it.toByte() }
        val ct = ByteArray(48) { (100 + it).toByte() }
        val (iv2, ct2) = DbKeyRules.unpack(DbKeyRules.pack(iv, ct))!!
        assertArrayEquals(iv, iv2)
        assertArrayEquals(ct, ct2)
    }

    @Test
    fun tepHongCauTrucTraNull() {
        assertNull(DbKeyRules.unpack(ByteArray(0)))
        assertNull(DbKeyRules.unpack(byteArrayOf(0, 1, 2)))
        assertNull(DbKeyRules.unpack(byteArrayOf(12, 1, 2, 3)))
        // Độ dài IV đọc như số không dấu (byte 0xF0 = 240), không ném lỗi chỉ số.
        assertNull(DbKeyRules.unpack(byteArrayOf(0xF0.toByte(), 1)))
    }
}
