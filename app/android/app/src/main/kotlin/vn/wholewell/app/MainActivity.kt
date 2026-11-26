package vn.wholewell.app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var genAiExtractor: LabelGenAiExtractor? = null
    private var reminderScheduler: ReminderScheduler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DbKeyStore.CHANNEL)
            .setMethodCallHandler(DbKeyStore(applicationContext))
        val extractor = LabelGenAiExtractor()
        genAiExtractor = extractor
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LabelGenAiExtractor.CHANNEL)
            .setMethodCallHandler(extractor)
        val notifChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ReminderScheduler.CHANNEL_NAME)
        val scheduler = ReminderScheduler(applicationContext, this, notifChannel)
        reminderScheduler = scheduler
        notifChannel.setMethodCallHandler(scheduler)
        scheduler.handleLaunchIntent(intent, deliverOverChannel = false)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.wholewell.app/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openAppSettings") {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        reminderScheduler?.handleLaunchIntent(intent, deliverOverChannel = true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (reminderScheduler?.onRequestPermissionsResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        genAiExtractor?.dispose()
        genAiExtractor = null
        reminderScheduler = null
        super.onDestroy()
    }
}
