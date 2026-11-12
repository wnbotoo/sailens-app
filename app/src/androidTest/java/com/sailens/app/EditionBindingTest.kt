package com.sailens.app

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.sailens.shell.app.SailensAppSpec
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.GlobalContext

/**
 * The spec `App.kt` injects is the one this edition binds (`editionModule`), resolved in the running app with
 * its real Android context: it promises navigation assistance and checks the detector too, since this build
 * packages both models.
 */
@RunWith(AndroidJUnit4::class)
class EditionBindingTest {

    @Test
    fun theRunningAppResolvesThisEditionsSpec() {
        val koin = GlobalContext.get()
        val spec = koin.get<SailensAppSpec>()

        assertSame("one spec for the process", spec, koin.get<SailensAppSpec>())
        assertTrue(spec.expectations.guidanceRequired)
        assertFalse(spec.expectations.describeRequired)
        assertNotNull("the packaged detector is checked statically", spec.guidance?.verifyObstacleModel)
    }
}
