package com.sailens

import com.sailens.app.appModule
import com.sailens.core.frame.PipelineTimingConfig
import com.sailens.guidance.config.GuidanceOptimizationConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test
import org.koin.dsl.koinApplication

class BuildContractTest {

    @Test
    fun `official distribution build identity stays pinned`() {
        assertEquals("com.sailens", BuildConfig.APPLICATION_ID)
        assertEquals("AGPL-3.0", BuildConfig.APP_LICENSE)
        assertEquals("https://github.com/wnbotoo/sailens-app", BuildConfig.APP_SOURCE_URL)
    }

    @Test
    fun `det-first launch combination stays off`() {
        assertFalse(BuildConfig.DET_FIRST_LAUNCH)
    }

    @Test
    fun `application graph has unique bindings and Release enables the optimizations`() {
        val application = koinApplication(createEagerInstances = false) {
            allowOverride(false)
            modules(appModule)
        }
        try {
            if (BuildConfig.BUILD_TYPE == "release") {
                assertFalse(BuildConfig.DEBUG)
                assertEquals(
                    GuidanceOptimizationConfig(
                        preferSemanticPreprocess = true,
                        useNeonArgmax = true,
                        directFloatNchw = true,
                        precomputeNearestIndices = true,
                        usePairedNeonArgmax = true,
                    ),
                    application.koin.get<GuidanceOptimizationConfig>(),
                )
                assertNull(application.koin.getOrNull<PipelineTimingConfig>())
            }
        } finally {
            application.close()
        }
    }
}
