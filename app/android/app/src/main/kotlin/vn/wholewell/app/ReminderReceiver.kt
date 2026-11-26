package vn.wholewell.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TRIGGER = "vn.wholewell.app.ACTION_REMINDER_TRIGGER"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(ReminderScheduler.PREFS_NAME, Context.MODE_PRIVATE)
        val slots = ReminderLogic.decodeSlots(prefs.getString(ReminderScheduler.KEY_SLOTS, null))
        when (intent.action) {
            ACTION_TRIGGER -> {
                val tod = intent.getIntExtra(ReminderScheduler.EXTRA_TIME_OF_DAY, -1)
                if (tod < 0) return
                val slot = slots.firstOrNull { it.timeOfDayMinutes == tod } ?: return
                ReminderScheduler.showDoseNotification(context, slot)
                // Đặt lại cho ngày hôm sau.
                ReminderScheduler.scheduleSingleAlarm(context, slot, minDelayFromNow = true)
            }

            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            -> {
                for (slot in slots) {
                    ReminderScheduler.scheduleSingleAlarm(context, slot)
                }
            }
        }
    }
}
