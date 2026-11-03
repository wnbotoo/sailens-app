package com.sailens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class BuildContractTest {

    @Test
    fun `official distribution build identity stays pinned`() {
        assertEquals("com.sailens", BuildConfig.APPLICATION_ID)
        assertEquals("AGPL-3.0", BuildConfig.APP_LICENSE)
        assertEquals("https://github.com/wnbotoo/sailens-app", BuildConfig.APP_SOURCE_URL)
    }

    // Unit tests run against debug; scripts/verify-distribution.py holds every build type's value.
    @Test
    fun `det-first launch combination stays off`() {
        assertFalse(BuildConfig.DET_FIRST_LAUNCH)
    }
}
