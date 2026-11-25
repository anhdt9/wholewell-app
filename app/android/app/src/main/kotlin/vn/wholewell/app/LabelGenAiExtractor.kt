package vn.wholewell.app

import android.util.Log
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Trích xuất thành phần nhãn thực phẩm bổ sung trên máy bằng Gemini Nano (Android AICore).
 * Trả về `null` nếu máy không hỗ trợ hoặc lỗi để Flutter fallback về parser OCR.
 */
class LabelGenAiExtractor : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "vn.wholewell.app/genai_label"
        private const val TAG = "LabelGenAi"
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "extractLabelJson") {
            result.notImplemented()
            return
        }
        val ocrText = call.argument<String>("ocrText")?.trim().orEmpty()
        if (ocrText.isEmpty()) {
            result.success(null)
            return
        }
        scope.launch {
            val json = extract(ocrText)
            result.success(json)
        }
    }

    private suspend fun extract(ocrText: String): String? {
        var client: GenerativeModel? = null
        return try {
            client = Generation.getClient()
            val status = client.checkStatus()
            val ready = when (status) {
                FeatureStatus.AVAILABLE -> true
                FeatureStatus.DOWNLOADABLE -> {
                    withTimeoutOrNull(25_000L) {
                        var done = false
                        client.download().collect { ds ->
                            if (ds is DownloadStatus.DownloadCompleted) done = true
                        }
                        done
                    } ?: false
                }
                else -> false
            }
            if (!ready) return null

            val prompt = """
Extract supplement label fields from the OCR text below. Return ONLY valid JSON (no markdown, no extra text):
{"productName": string or null, "boxCount": number or null, "servings": number or null, "unit": "tablet"|"capsule"|"softgel"|"sachet"|"drop"|"ml"|"g"|null, "ingredients": [{"name": string, "amount": number, "unit": "mg"|"ug"|"iu"|"g"|"ug_dfe"|"ug_rae"|"mg_ne", "form": string or null, "elemental": boolean}]}

Rules:
- Convert mcg/µg to "ug", mcg DFE to "ug_dfe", mcg RAE to "ug_rae", mg NE to "mg_ne", IU to "iu".
- Ignore % Daily Value numbers.
- If label says elemental or "pure elemental", set elemental=true.

OCR text:
$ocrText
""".trimIndent()

            val response = withTimeoutOrNull(20_000L) {
                client.generateContent(prompt)
            } ?: return null

            val raw = response.candidates.firstOrNull()?.text ?: return null
            val start = raw.indexOf('{')
            val end = raw.lastIndexOf('}')
            if (start < 0 || end <= start) return null
            raw.substring(start, end + 1)
        } catch (e: Throwable) {
            Log.d(TAG, "Gemini Nano unavailable or failed: ${e.message}")
            null
        } finally {
            try {
                client?.close()
            } catch (_: Throwable) {
            }
        }
    }

    fun dispose() {
        scope.cancel()
    }
}
