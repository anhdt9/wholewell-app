package vn.wholewell.app

import android.util.Log
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
 * Trả về `null` nếu máy chưa có sẵn mô hình, không hỗ trợ hoặc lỗi để Flutter dùng bộ đọc chữ.
 * Không tải mô hình giữa luồng quét (xem [LabelGenAiRules.shouldRun]).
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
            if (!LabelGenAiRules.shouldRun(client.checkStatus())) return null

            val prompt = """
Extract supplement label fields from the OCR text below. Return ONLY valid JSON (no markdown, no extra text):
{"productName": string or null, "boxCount": number or null, "servings": number or null, "unit": "tablet"|"capsule"|"softgel"|"sachet"|"drop"|"ml"|"g"|null, "ingredients": [{"name": string, "amount": number, "unit": "mg"|"ug"|"iu"|"g"|"ug_dfe"|"ug_rae"|"mg_ne"|null, "form": string or null, "elemental": boolean}]}

Rules:
- Copy every amount exactly as printed on the label. Never convert amounts between units.
- Write mcg/µg as "ug", mcg DFE as "ug_dfe", mcg RAE as "ug_rae", mg NE as "mg_ne", IU as "iu".
- If the unit is not printed or is not in the list above, set "unit" to null.
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
