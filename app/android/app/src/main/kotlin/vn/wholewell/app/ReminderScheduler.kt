package vn.wholewell.app

import android.app.Activity
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ReminderScheduler(
    private val context: Context,
    private val activity: Activity?,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "vn.wholewell.app/notifications"
        const val NOTIF_CHANNEL_ID = "wholewell_dose_reminders"
        const val NOTIF_ALERT_CHANNEL_ID = "wholewell_ul_alerts"
        const val PREFS_NAME = "wholewell_reminders_meta"
        const val KEY_SLOTS = "slots_json"
        const val REQUEST_CODE_PERMISSION = 4201
        const val UL_ALERT_NOTIF_ID = 9001

        const val EXTRA_ACTION_KIND = "wholewell_action_kind"
        const val EXTRA_TIME_OF_DAY = "wholewell_time_of_day"
        const val EXTRA_SCHEDULE_IDS = "wholewell_schedule_ids"

        fun notificationIdForTime(minutesOfDay: Int): Int = 1000 + (minutesOfDay and 0x7FFF)

        fun ensureChannels(ctx: Context) {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(NOTIF_CHANNEL_ID) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(
                        NOTIF_CHANNEL_ID,
                        "Nhắc giờ uống bổ sung",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Thông báo chung khi tới giờ uống theo lịch"
                    },
                )
            }
            if (nm.getNotificationChannel(NOTIF_ALERT_CHANNEL_ID) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(
                        NOTIF_ALERT_CHANNEL_ID,
                        "Thông báo cảnh báo giới hạn",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Thông báo chung khi có thông tin mới cần xem"
                    },
                )
            }
        }

        fun canScheduleExact(am: AlarmManager): Boolean =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) am.canScheduleExactAlarms() else true

        fun scheduleSingleAlarm(ctx: Context, slot: ReminderSlotMeta, minDelayFromNow: Boolean = false) {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val now = System.currentTimeMillis() + if (minDelayFromNow) 61_000L else 0L
            val triggerAt = ReminderLogic.nextTriggerAtMillis(slot.timeOfDayMinutes, now)
            val intent = Intent(ctx, ReminderReceiver::class.java).apply {
                action = ReminderReceiver.ACTION_TRIGGER
                putExtra(EXTRA_TIME_OF_DAY, slot.timeOfDayMinutes)
                putExtra("itemCount", slot.itemCount)
                putExtra(EXTRA_SCHEDULE_IDS, slot.scheduleIds.toIntArray())
            }
            val pi = PendingIntent.getBroadcast(
                ctx,
                slot.timeOfDayMinutes,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            try {
                if (canScheduleExact(am)) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } catch (_: SecurityException) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }

        fun cancelAlarmAndNotification(ctx: Context, timeOfDayMinutes: Int) {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(ctx, ReminderReceiver::class.java).apply {
                action = ReminderReceiver.ACTION_TRIGGER
            }
            val pi = PendingIntent.getBroadcast(
                ctx,
                timeOfDayMinutes,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pi != null) {
                am.cancel(pi)
                pi.cancel()
            }
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(notificationIdForTime(timeOfDayMinutes))
        }

        fun showDoseNotification(ctx: Context, slot: ReminderSlotMeta) {
            ensureChannels(ctx)
            val idsArray = slot.scheduleIds.toIntArray()

            val openAppIntent = Intent(ctx, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ACTION_KIND, "openTodayDoses")
                putExtra(EXTRA_TIME_OF_DAY, slot.timeOfDayMinutes)
                putExtra(EXTRA_SCHEDULE_IDS, idsArray)
            }
            val openAppPi = PendingIntent.getActivity(
                ctx,
                slot.timeOfDayMinutes * 2 + 1,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val markTakenIntent = Intent(ctx, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ACTION_KIND, "markTaken")
                putExtra(EXTRA_TIME_OF_DAY, slot.timeOfDayMinutes)
                putExtra(EXTRA_SCHEDULE_IDS, idsArray)
            }
            val markTakenPi = PendingIntent.getActivity(
                ctx,
                slot.timeOfDayMinutes * 2 + 2,
                markTakenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val notif = Notification.Builder(ctx, NOTIF_CHANNEL_ID)
                .setSmallIcon(ctx.applicationInfo.icon)
                .setContentTitle(ReminderLogic.formatNotificationTitle(slot.timeOfDayMinutes))
                .setContentText(ReminderLogic.formatNotificationBody(slot.itemCount))
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setTimeoutAfter(ReminderLogic.TIMEOUT_MILLIS)
                .setContentIntent(openAppPi)
                .addAction(
                    Notification.Action.Builder(null, "Đã uống", markTakenPi).build(),
                )
                .addAction(
                    Notification.Action.Builder(null, "Mở app", openAppPi).build(),
                )
                .build()

            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(notificationIdForTime(slot.timeOfDayMinutes), notif)
        }
    }

    private var pendingPermResult: MethodChannel.Result? = null
    private var pendingAction: Map<String, Any?>? = null

    fun handleLaunchIntent(intent: Intent?, deliverOverChannel: Boolean) {
        if (intent == null) return
        val kind = intent.getStringExtra(EXTRA_ACTION_KIND) ?: return
        val timeOfDay = if (intent.hasExtra(EXTRA_TIME_OF_DAY)) {
            intent.getIntExtra(EXTRA_TIME_OF_DAY, -1).takeIf { it >= 0 }
        } else {
            null
        }
        val ids = intent.getIntArrayExtra(EXTRA_SCHEDULE_IDS)?.toList() ?: emptyList()
        intent.removeExtra(EXTRA_ACTION_KIND)

        if (timeOfDay != null && (kind == "markTaken" || kind == "openTodayDoses")) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(notificationIdForTime(timeOfDay))
        }

        val payload = hashMapOf<String, Any?>(
            "kind" to kind,
            "timeOfDayMinutes" to timeOfDay,
            "scheduleIds" to ids,
        )
        pendingAction = payload
        if (deliverOverChannel) {
            channel.invokeMethod("onNotificationAction", payload)
            pendingAction = null
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE_PERMISSION) return false
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermResult?.success(granted)
        pendingPermResult = null
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> {
                val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                        PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }
                result.success(granted)
            }

            "requestPermission" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    result.success(true)
                    return
                }
                val already = context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED
                if (already) {
                    result.success(true)
                    return
                }
                val act = activity
                if (act == null) {
                    result.success(false)
                    return
                }
                pendingPermResult = result
                act.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE_PERMISSION)
            }

            "canScheduleExactAlarms" -> {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                result.success(canScheduleExact(am))
            }

            "openNotificationSettings" -> {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                try {
                    context.startActivity(intent)
                } catch (_: Exception) {
                    val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(fallback)
                }
                result.success(null)
            }

            "syncSchedules" -> {
                val rawList = (call.arguments as? List<*>) ?: emptyList<Any>()
                val newSlots = rawList.mapNotNull { item ->
                    val m = item as? Map<*, *> ?: return@mapNotNull null
                    val tod = (m["timeOfDayMinutes"] as? Number)?.toInt() ?: return@mapNotNull null
                    val count = (m["itemCount"] as? Number)?.toInt() ?: 1
                    val ids = ((m["scheduleIds"] as? List<*>) ?: emptyList<Any>())
                        .mapNotNull { (it as? Number)?.toInt() }
                    ReminderSlotMeta(tod, count, ids)
                }
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val oldSlots = ReminderLogic.decodeSlots(prefs.getString(KEY_SLOTS, null))
                val newTimes = newSlots.map { it.timeOfDayMinutes }.toSet()
                for (old in oldSlots) {
                    if (old.timeOfDayMinutes !in newTimes) {
                        cancelAlarmAndNotification(context, old.timeOfDayMinutes)
                    }
                }
                prefs.edit().putString(KEY_SLOTS, ReminderLogic.encodeSlots(newSlots)).apply()
                for (slot in newSlots) {
                    scheduleSingleAlarm(context, slot)
                }
                result.success(null)
            }

            "cancelWindow" -> {
                val tod = call.argument<Int>("timeOfDayMinutes")
                if (tod != null) {
                    val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    nm.cancel(notificationIdForTime(tod))
                }
                result.success(null)
            }

            "showUlAlertNotice" -> {
                ensureChannels(context)
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(EXTRA_ACTION_KIND, "openUlAlerts")
                }
                val pi = PendingIntent.getActivity(
                    context,
                    UL_ALERT_NOTIF_ID,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                val notif = Notification.Builder(context, NOTIF_ALERT_CHANNEL_ID)
                    .setSmallIcon(context.applicationInfo.icon)
                    .setContentTitle("WholeWell")
                    .setContentText("Có thông tin mới cần xem trong WholeWell")
                    .setVisibility(Notification.VISIBILITY_PUBLIC)
                    .setAutoCancel(true)
                    .setContentIntent(pi)
                    .build()
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(UL_ALERT_NOTIF_ID, notif)
                result.success(null)
            }

            "takePendingAction" -> {
                result.success(pendingAction)
                pendingAction = null
            }

            else -> result.notImplemented()
        }
    }
}
