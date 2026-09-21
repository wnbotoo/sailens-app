package com.sailens

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The three values that make this build the YOLO Edition rather than a copy of Core Edition.
 *
 * They are the easiest thing in the repository to lose by accident: `app/` is kept close to Core
 * Edition's host, and syncing it copies Core Edition's identity along with its wiring. That has
 * already happened once — the fresh-root host shipped as `com.sailens`, Apache-2.0, pointing at
 * sailens-android, and this test had been copied with it, so it asserted the wrong package and
 * passed. An AGPL-3.0 build that tells its users it is Apache-2.0 and points them at the wrong
 * corresponding source is a licence problem, not a cosmetic one.
 */
@RunWith(AndroidJUnit4::class)
class EditionIdentityTest {

    @Test
    fun packageIsTheEditionsOwn() {
        // Distinct from Core Edition's com.sailens, so both can be installed side by side and the
        // Play identity stays free for Core Edition.
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.sailens.yolo", appContext.packageName)
    }

    @Test
    fun licenceShownInTheAppIsAgpl() {
        assertEquals("AGPL-3.0", BuildConfig.APP_LICENSE)
    }

    @Test
    fun sourceLinkPointsAtThisRepository() {
        assertEquals("https://github.com/wnbotoo/sailens-yolo", BuildConfig.APP_SOURCE_URL)
    }
}
