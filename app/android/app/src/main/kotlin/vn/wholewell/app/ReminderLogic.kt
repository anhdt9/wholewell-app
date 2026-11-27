package vn.wholewell.app

import java.util.Calendar
import java.util.TimeZone

data class ReminderSlotMeta(
    val timeOfDayMinutes: Int,
    val itemCount: Int,
    val scheduleIds: List<Int>,
    val detailText: String? = null,
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

    /** Mặc định không kèm tên chất hay liều lượng; chỉ kèm chuỗi tên hiển thị khi bật tùy chọn. */
    fun formatNotificationBody(itemCount: Int, detailText: String? = null): String {
        val clean = detailText?.trim().orEmpty()
        if (clean.isNotEmpty()) return "Đến giờ uống: $clean"
        return if (itemCount > 1) "Đến giờ uống, $itemCount loại" else "Đến giờ uống"
    }

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

    private fun escapeField(raw: String): String {
        val sb = StringBuilder(raw.length)
        for (ch in raw) {
            when (ch) {
                '\\' -> sb.append("\\\\")
                ',' -> sb.append("\\,")
                '\n' -> sb.append("\\n")
                '\r' -> sb.append("\\r")
                else -> sb.append(ch)
            }
        }
        return sb.toString()
    }

    private fun splitEscapedComma(line: String): List<String> {
        val out = ArrayList<String>()
        val cur = StringBuilder()
        var i = 0
        while (i < line.length) {
            val ch = line[i]
            if (ch == '\\' && i + 1 < line.length) {
                when (line[i + 1]) {
                    '\\' -> cur.append('\\')
                    ',' -> cur.append(',')
                    'n' -> cur.append('\n')
                    'r' -> cur.append('\r')
                    else -> cur.append(line[i + 1])
                }
                i += 2
            } else if (ch == ',') {
                out.add(cur.toString())
                cur.setLength(0)
                i += 1
            } else {
                cur.append(ch)
                i += 1
            }
        }
        out.add(cur.toString())
        return out
    }

    fun encodeSlots(slots: List<ReminderSlotMeta>): String =
        slots.joinToString("\n") { s ->
            val detail = s.detailText?.trim()?.takeIf { it.isNotEmpty() }
            val base = "${s.timeOfDayMinutes},${s.itemCount},${s.scheduleIds.joinToString(";")}"
            if (detail == null) base else "$base,${escapeField(detail)}"
        }

    fun decodeSlots(raw: String?): List<ReminderSlotMeta> {
        if (raw.isNullOrBlank()) return emptyList()
        val out = ArrayList<ReminderSlotMeta>()
        for (line in raw.split('\n')) {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) continue
            val parts = splitEscapedComma(trimmed)
            if (parts.size < 2) continue
            val tod = parts[0].toIntOrNull() ?: continue
            val count = parts[1].toIntOrNull() ?: 1
            val ids = if (parts.size >= 3 && parts[2].isNotEmpty()) {
                parts[2].split(';').mapNotNull { it.toIntOrNull() }
            } else {
                emptyList()
            }
            val detail = if (parts.size >= 4) {
                parts[3].trim().takeIf { it.isNotEmpty() }
            } else {
                null
            }
            out.add(ReminderSlotMeta(tod, count, ids, detail))
        }
        return out
    }
}
