package vn.wholewell.app

import java.util.Calendar
import java.util.TimeZone

data class ReminderSlotMeta(
    val timeOfDayMinutes: Int,
    val itemCount: Int,
    val scheduleIds: List<Int>,
)

/** Quy tắc thuần Kotlin cho nhắc giờ (tách khỏi Android SDK để test JVM). */
object ReminderLogic {
    const val TIMEOUT_MILLIS: Long = 120L * 60L * 1000L

    fun formatHhMm(minutesOfDay: Int): String {
        val m = ((minutesOfDay % 1440) + 1440) % 1440
        val h = m / 60
        val min = m % 60
        return "%02d:%02d".format(h, min)
    }

    fun formatNotificationTitle(minutesOfDay: Int): String =
        "WholeWell · ${formatHhMm(minutesOfDay)}"

    /** Không bao giờ chứa tên chất, tên sản phẩm hay liều lượng. */
    fun formatNotificationBody(itemCount: Int): String =
        if (itemCount > 1) "Đến giờ uống, $itemCount loại" else "Đến giờ uống"

    fun nextTriggerAtMillis(
        minutesOfDay: Int,
        nowMillis: Long,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long {
        val m = ((minutesOfDay % 1440) + 1440) % 1440
        val cal = Calendar.getInstance(timeZone).apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, m / 60)
            set(Calendar.MINUTE, m % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= nowMillis) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }

    fun encodeSlots(slots: List<ReminderSlotMeta>): String =
        slots.joinToString("\n") { s ->
            "${s.timeOfDayMinutes},${s.itemCount},${s.scheduleIds.joinToString(";")}"
        }

    fun decodeSlots(raw: String?): List<ReminderSlotMeta> {
        if (raw.isNullOrBlank()) return emptyList()
        val out = ArrayList<ReminderSlotMeta>()
        for (line in raw.split('\n')) {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) continue
            val parts = trimmed.split(',')
            if (parts.size < 2) continue
            val tod = parts[0].toIntOrNull() ?: continue
            val count = parts[1].toIntOrNull() ?: 1
            val ids = if (parts.size >= 3 && parts[2].isNotEmpty()) {
                parts[2].split(';').mapNotNull { it.toIntOrNull() }
            } else {
                emptyList()
            }
            out.add(ReminderSlotMeta(tod, count, ids))
        }
        return out
    }
}
