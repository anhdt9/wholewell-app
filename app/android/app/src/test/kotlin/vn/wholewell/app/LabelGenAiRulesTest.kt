package vn.wholewell.app

import com.google.mlkit.genai.common.FeatureStatus
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LabelGenAiRulesTest {
    @Test
    fun chiChayKhiMoHinhCoSan() {
        assertTrue(LabelGenAiRules.shouldRun(FeatureStatus.AVAILABLE))
    }

    @Test
    fun khongTaiMoHinhGiuaLuongQuet() {
        assertFalse(LabelGenAiRules.shouldRun(FeatureStatus.DOWNLOADABLE))
        assertFalse(LabelGenAiRules.shouldRun(FeatureStatus.DOWNLOADING))
        assertFalse(LabelGenAiRules.shouldRun(FeatureStatus.UNAVAILABLE))
    }
}
