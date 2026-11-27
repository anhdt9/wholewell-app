package vn.wholewell.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReminderLogicTest {
    @Test
    fun thongBaoKhongLoTenChatVaDungSoLoai() {
        assertEquals("WholeWell · 08:00", ReminderLogic.formatNotificationTitle(480))
        assertEquals("WholeWell · 20:05", ReminderLogic.formatNotificationTitle(20 * 60 + 5))
        assertEquals("Đến giờ uống", ReminderLogic.formatNotificationBody(1))
        assertEquals("Đến giờ uống, 2 loại", ReminderLogic.formatNotificationBody(2))
        assertEquals(
            "Đến giờ uống: Vitamin C 500 mg",
            ReminderLogic.formatNotificationBody(1, "Vitamin C 500 mg"),
        )
        assertEquals(
            "Đến giờ uống: Canxi D3, Vitamin C 500 mg",
            ReminderLogic.formatNotificationBody(2, "Canxi D3, Vitamin C 500 mg"),
        )
        assertEquals("Đến giờ uống, 2 loại", ReminderLogic.formatNotificationBody(2, "   "))
        assertEquals(2L * 60L * 60L * 1000L, ReminderLogic.TIMEOUT_MILLIS)
    }

    @Test
    fun tinhGioNhacTiepTheoCungNgayVaQuaNgayMoi() {
        val tz = TimeZone.getTimeZone("Asia/Ho_Chi_Minh")
        val now = Calendar.getInstance(tz).apply {
            set(2026, Calendar.NOVEMBER, 26, 9, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        // 20:00 hôm nay > 09:00 -> 20:00 hôm nay.
        val evening = ReminderLogic.nextTriggerAtMillis(20 * 60, now, tz)
        val calEve = Calendar.getInstance(tz).apply { timeInMillis = evening }
        assertEquals(26, calEve.get(Calendar.DAY_OF_MONTH))
        assertEquals(20, calEve.get(Calendar.HOUR_OF_DAY))

        // 08:00 <= 09:00 -> sang 08:00 ngày mai (27/11).
        val morning = ReminderLogic.nextTriggerAtMillis(8 * 60, now, tz)
        val calMorn = Calendar.getInstance(tz).apply { timeInMillis = morning }
        assertEquals(27, calMorn.get(Calendar.DAY_OF_MONTH))
        assertEquals(8, calMorn.get(Calendar.HOUR_OF_DAY))
    }

    @Test
    fun encodeDecodeSlotsChiChuaMaVaGio() {
        val slots = listOf(
            ReminderSlotMeta(timeOfDayMinutes = 480, itemCount = 2, scheduleIds = listOf(1, 3)),
            ReminderSlotMeta(timeOfDayMinutes = 1200, itemCount = 1, scheduleIds = listOf(2)),
        )
        val json = ReminderLogic.encodeSlots(slots)
        assertTrue(!json.contains("Canxi") && !json.contains("Vitamin"))
        assertEquals(slots, ReminderLogic.decodeSlots(json))
    }

    @Test
    fun encodeDecodeSlotsVoiTenHienThiCoDauPhayVaXoaSachKhiTat() {
        val slots = listOf(
            ReminderSlotMeta(
                timeOfDayMinutes = 480,
                itemCount = 2,
                scheduleIds = listOf(1, 3),
                detailText = "Canxi D3, Vitamin C 500 mg",
            ),
            ReminderSlotMeta(timeOfDayMinutes = 1200, itemCount = 1, scheduleIds = listOf(2)),
        )
        val encoded = ReminderLogic.encodeSlots(slots)
        assertEquals(slots, ReminderLogic.decodeSlots(encoded))

        val cleared = slots.map { it.copy(detailText = null) }
        val encodedCleared = ReminderLogic.encodeSlots(cleared)
        assertTrue(!encodedCleared.contains("Canxi") && !encodedCleared.contains("Vitamin"))
        assertEquals(cleared, ReminderLogic.decodeSlots(encodedCleared))
    }
}
