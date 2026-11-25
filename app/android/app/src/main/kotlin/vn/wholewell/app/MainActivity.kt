package vn.wholewell.app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var genAiExtractor: LabelGenAiExtractor? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DbKeyStore.CHANNEL)
            .setMethodCallHandler(DbKeyStore(applicationContext))
        val extractor = LabelGenAiExtractor()
        genAiExtractor = extractor
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LabelGenAiExtractor.CHANNEL)
            .setMethodCallHandler(extractor)
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

    override fun onDestroy() {
        genAiExtractor?.dispose()
        genAiExtractor = null
        super.onDestroy()
    }
}
