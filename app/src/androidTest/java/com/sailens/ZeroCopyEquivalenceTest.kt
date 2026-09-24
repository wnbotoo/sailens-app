package com.sailens

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.ai.edge.litert.Accelerator
import com.google.ai.edge.litert.TensorBuffer
import com.sailens.core.frame.ImageFrame
import com.sailens.core.frame.ImagePixelFormat
import com.sailens.core.log.LogService
import com.sailens.guidance.config.AnalysisConfig
import com.sailens.guidance.kernel.NavigationScorePostprocessor
import com.sailens.guidance.semantics.CityscapesNavigationSemantics
import com.sailens.runtime.CatalogModelSourceResolver
import com.sailens.runtime.ImageTensorLayout
import com.sailens.runtime.ModelAcceleratorBackend
import com.sailens.runtime.ModelAcceleratorSelectionMode
import com.sailens.runtime.ModelType
import com.sailens.runtime.session.AcceleratorSelection
import com.sailens.runtime.session.LiteRtSession
import com.sailens.runtime.session.LiteRtSessionFactory
import com.sailens.vision.detection.DetectionLayout
import com.sailens.vision.detection.DetectionPostProcessor
import com.sailens.vision.semantic.SemanticContentRegion
import com.sailens.vision.semantic.SemanticScoreSpec
import com.sailens.vision.semantic.SemanticScores
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.random.Random

/**
 * The zero-copy output path against the copying path, on the packaged models and the GPU.
 *
 * The zero-copy kernels unwrap the Kotlin TensorBuffer handle by the LiteRT C++ wrapper's layout
 * (sailens-runtime litert_zero_copy.h, note 3) -- a known ABI dependency, so it has to be proven on
 * a real device with the real runtime. One inference, then the same output buffer read both ways:
 * locked in place through the handle, and copied out through readFloat(). Every class id,
 * statistic and detection must match.
 *
 * Lives in this distribution because it needs weights; Sailens Android ships none.
 */
@RunWith(AndroidJUnit4::class)
class ZeroCopyEquivalenceTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun semanticZeroCopyMatchesTheCopyingPath() = withSession(ModelType.SEMANTIC_SEGMENTATION) { session ->
        val postprocessor = NavigationScorePostprocessor(AnalysisConfig(), CityscapesNavigationSemantics, SilentLog)
        val spec = SemanticScoreSpec(
            width = 640,
            height = 640,
            channels = 19,
            layout = ImageTensorLayout.NHWC,
            content = SemanticContentRegion(140, 0, 360, 640),
        )
        val output = session.outputBuffers.single()

        val viaHandle = postprocessor.postprocessScores(
            SemanticScores.FloatHandle(handleOf(output)), spec, IntArray(spec.content.pixelCount),
        )
        val viaCopy = postprocessor.postprocessScores(
            SemanticScores.FloatValues(output.readFloat()), spec, IntArray(spec.content.pixelCount),
        )

        assertNotNull("the zero-copy path declined on this device", viaHandle)
        assertNotNull(viaCopy)
        assertTrue("the input should produce more than one class", viaCopy!!.value.mask.classMap.distinct().size > 1)
        assertEquals(viaCopy.value.mask, viaHandle!!.value.mask)
        assertEquals(viaCopy.value.stats, viaHandle.value.stats)
    }

    @Test
    fun detectionZeroCopyMatchesTheCopyingPath() = withSession(ModelType.OBSTACLE_DETECTION) { session ->
        val output = session.outputBuffers.single()
        val decoder = DetectionPostProcessor(
            inputSize = 640,
            classCount = 80,
            detectionLayout = DetectionLayout.RAW_TRANSPOSED,
            confidenceThreshold = 0.01f,
            maxDetections = 50,
        )
        val frame = ImageFrame(
            width = 1280,
            height = 720,
            pixelBytes = ByteArray(0),
            pixelFormat = ImagePixelFormat.RGBA_8888,
            rotationDegrees = 90,
            timestamp = 0,
            sequenceNumber = 0,
        )

        val copied = output.readFloat()
        val viaHandle = decoder.postProcessFloatFromHandle(frame, handleOf(output), rawElementCount = copied.size)
        val viaCopy = decoder.postProcessWithBackend(frame, copied)

        assertNotNull("the zero-copy path declined on this device", viaHandle)
        assertEquals("native_bbox_nms_float_handle", viaHandle!!.backend)
        assertEquals(viaCopy.detections, viaHandle.detections)
    }

    private fun withSession(type: ModelType, block: (LiteRtSession) -> Unit) {
        val session = LiteRtSessionFactory.create(
            context = context,
            sourceResolver = { accelerator -> CatalogModelSourceResolver.source(type, accelerator) },
            selection = AcceleratorSelection(
                mode = ModelAcceleratorSelectionMode.EXPLICIT,
                preferredBackend = ModelAcceleratorBackend.GPU,
                fallbackOrder = listOf(Accelerator.GPU),
            ),
            logTag = "ZeroCopyEquivalenceTest",
            modelLabel = type.name,
        )
        try {
            val input = session.inputBuffers.single()
            // Per-pixel noise: synthetic smooth images come out as a single class ("building") on
            // this model, and a one-class mask would let a broken read path match by accident.
            val random = Random(42)
            val values = FloatArray(640 * 640 * 3) { random.nextFloat() }
            input.writeFloat(values)
            session.run()
            block(session)
        } finally {
            session.close()
        }
    }

    private fun handleOf(buffer: TensorBuffer): Long {
        val method = Class.forName("com.google.ai.edge.litert.JniHandle")
            .getDeclaredMethod("getHandle\$third_party_odml_litert_litert_kotlin_litert_kotlin_api")
        method.isAccessible = true
        return method.invoke(buffer) as Long
    }

    private object SilentLog : LogService {
        override fun debug(tag: String, message: String, data: Map<String, Any>?) = Unit
        override fun info(tag: String, message: String, data: Map<String, Any>?) = Unit
        override fun warning(tag: String, message: String, data: Map<String, Any>?, throwable: Throwable?) = Unit
        override fun error(tag: String, message: String, throwable: Throwable?) = Unit
    }
}
