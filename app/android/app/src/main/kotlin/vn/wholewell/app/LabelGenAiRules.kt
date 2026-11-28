package vn.wholewell.app

import com.google.mlkit.genai.common.FeatureStatus

/**
 * Luật thuần cho AI đọc nhãn trên máy (đặc tả label-scan-inventory, Bổ sung 1, mục B1.5).
 * Tách khỏi [LabelGenAiExtractor] để test JVM được.
 */
object LabelGenAiRules {
    /**
     * Chỉ gọi mô hình khi đã có sẵn trên máy. Mọi trạng thái khác (cần tải, đang tải, không hỗ trợ)
     * trả về false để Flutter dùng ngay bộ đọc chữ; app không tự tải mô hình.
     */
    fun shouldRun(status: Int): Boolean = status == FeatureStatus.AVAILABLE
}
