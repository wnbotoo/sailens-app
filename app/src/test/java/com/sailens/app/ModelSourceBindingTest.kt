package com.sailens.app

import com.google.ai.edge.litert.Accelerator
import com.sailens.runtime.CatalogModelSourceResolver
import com.sailens.runtime.ModelAcceleratorBackend
import com.sailens.runtime.ModelSource
import com.sailens.runtime.ModelSourceResolver
import com.sailens.runtime.ModelType
import com.sailens.vision.detection.DetectionModelConfig
import com.sailens.vision.semantic.SemanticModelConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test
import org.koin.dsl.koinApplication

class ModelSourceBindingTest {

    @Test
    fun `this build binds the resolver its runners use`() {
        // Eager instances need an Android context; the binding itself does not.
        val koin = koinApplication(createEagerInstances = false) { modules(appModule) }.koin

        assertSame(CatalogModelSourceResolver, koin.get<ModelSourceResolver>())
    }

    @Test
    fun `both static checks read what the resolver gives for each configured accelerator`() {
        val asked = mutableListOf<Pair<ModelType, Accelerator>>()
        val elsewhere = ModelSource.Asset("elsewhere.tflite")
        val resolver = object : ModelSourceResolver {
            override fun source(type: ModelType, accelerator: Accelerator): ModelSource {
                asked += type to accelerator
                return elsewhere
            }
        }

        assertSame(elsewhere, semanticPreflightSource(resolver, SemanticModelConfig(acceleratorBackend = ModelAcceleratorBackend.CPU)))
        assertSame(elsewhere, obstaclePreflightSource(resolver, DetectionModelConfig(acceleratorBackend = ModelAcceleratorBackend.CPU)))
        assertEquals(
            listOf(ModelType.SEMANTIC_SEGMENTATION to Accelerator.CPU, ModelType.OBSTACLE_DETECTION to Accelerator.CPU),
            asked,
        )
    }
}
