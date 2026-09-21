package com.sailens

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Pins the identity of the official Sailens Android distribution.
 *
 * The host stays intentionally close to Sailens Android's reference host, so identity is tested
 * explicitly: the shipping product owns the plain com.sailens applicationId, remains AGPL-3.0
 * under the current bundled-model choices, and must point users at this distribution's complete
 * corresponding source rather than at the Apache-2.0 platform repository.
 */
@RunWith(AndroidJUnit4::class)
class DistributionIdentityTest {

    @Test
    fun packageIsTheOfficialSailensProduct() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.sailens", appContext.packageName)
    }

    @Test
    fun licenceShownInTheAppIsAgpl() {
        assertEquals("AGPL-3.0", BuildConfig.APP_LICENSE)
    }

    @Test
    fun sourceLinkPointsAtTheOfficialDistribution() {
        assertEquals("https://github.com/wnbotoo/sailens-app", BuildConfig.APP_SOURCE_URL)
    }
}
