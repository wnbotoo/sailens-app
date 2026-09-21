package com.sailens

import org.junit.Assert.assertEquals
import org.junit.Test

class BuildContractTest {

    @Test
    fun `official distribution build identity stays pinned`() {
        assertEquals("com.sailens", BuildConfig.APPLICATION_ID)
        assertEquals("AGPL-3.0", BuildConfig.APP_LICENSE)
        assertEquals("https://github.com/wnbotoo/sailens-app", BuildConfig.APP_SOURCE_URL)
    }
}
