package com.sailens.app

import android.content.Context
import com.google.ai.edge.litert.Accelerator
import com.sailens.guidance.semantics.CityscapesNavigationSemantics
import com.sailens.guidance.semantics.DetectionModelPreflight
import com.sailens.guidance.semantics.SemanticModelPreflight
import com.sailens.runtime.CatalogModelSourceResolver
import com.sailens.runtime.ModelType
import com.sailens.shell.app.CapabilityExpectations
import com.sailens.shell.app.DescribeSpec
import com.sailens.shell.app.GuidanceSpec
import com.sailens.shell.app.SailensAppSpec
import com.sailens.shell.app.StaticUnavailableReason
import com.sailens.vision.detection.DetectionModelConfig
import com.sailens.vision.taxonomy.CityscapesTaxonomy
import com.sailens.vlm.SceneDescriber

/**
 * What the official Sailens distribution offers.
 *
 * Unlike the Sailens Android reference host, this repository **packages its own weights**, so it
 * promises navigation assistance and declares it required (architecture.md §5.1, §5.2). If the model is missing or
 * its class definition does not match, that is a fatal configuration state rather than a quiet
 * fallback -- a build that cannot guide anyone must say so, out loud, on a channel the user can
 * perceive.
 *
 * The Guidance check reads the packaged model's TFLite metadata tables and compares its output
 * class count against the declared taxonomy. That is still cheap (§5.2): a memory-mapped read of a
 * few hundred bytes, no compiled model, no accelerator, no inference. It matters more here than in
 * the reference host, because this build ships the weights: a packaging mistake is caught before the
 * user presses start rather than after they have begun walking. What it cannot check is channel
 * *order* -- the models carry no labels, so which channel is `person` remains a manual release
 * gate (§6.2, docs/models.md).
 */
fun sailensEditionSpec(
    context: Context,
    sceneDescriber: SceneDescriber,
): SailensAppSpec = SailensAppSpec(
    guidance = GuidanceSpec(
        verifySemanticModel = { verifySemanticModel(context) },
        // This build packages the detector too, and the default profile needs it: a missing or
        // unreadable det.tflite must stop at the configuration screen, not fail after start.
        verifyObstacleModel = { verifyObstacleModel(context) },
    ),
    describe = DescribeSpec(
        verifyEngine = {
            if (sceneDescriber.isAvailable) null else StaticUnavailableReason.EngineUnavailable
        },
    ),
    // The official distribution packages its own weights, so it promises navigation assistance.
    // A missing or mismatched model here is a configuration failure, not a shrug: shipping a build that
    // silently cannot guide anyone is the outcome the capability model exists to prevent.
    expectations = CapabilityExpectations(
        guidanceRequired = true,
        describeRequired = false,
    ),
)

/**
 * Translates the Guidance pipeline's own verdict into the shell's vocabulary.
 *
 * The shell owns the reasons it can present and speak; what makes a semantic model usable is a
 * Guidance question, answered by Guidance (§6.11).
 */
private fun verifySemanticModel(context: Context): StaticUnavailableReason? {
    val result = SemanticModelPreflight.check(
        context = context,
        source = CatalogModelSourceResolver.source(ModelType.SEMANTIC_SEGMENTATION, Accelerator.GPU),
        taxonomy = CityscapesTaxonomy,
        semantics = CityscapesNavigationSemantics,
    )
    return when (result) {
        SemanticModelPreflight.Result.Compatible -> null
        SemanticModelPreflight.Result.ModelSourceMissing -> StaticUnavailableReason.ModelSourceMissing
        is SemanticModelPreflight.Result.SemanticsMismatch -> StaticUnavailableReason.TaxonomyIncompatible
        is SemanticModelPreflight.Result.OutputUnreadable ->
            StaticUnavailableReason.ModelOutputUnreadable(result.detail)

        is SemanticModelPreflight.Result.ClassCountMismatch ->
            StaticUnavailableReason.ModelClassCountMismatch(
                declared = result.declared,
                found = result.candidates,
            )
    }
}

/** The detector's static check, in the same vocabulary as the semantic one. */
private fun verifyObstacleModel(context: Context): StaticUnavailableReason? {
    val result = DetectionModelPreflight.check(
        context = context,
        source = CatalogModelSourceResolver.source(ModelType.OBSTACLE_DETECTION, Accelerator.GPU),
        classCount = DetectionModelConfig().classCount,
    )
    return when (result) {
        DetectionModelPreflight.Result.Compatible -> null
        DetectionModelPreflight.Result.ModelSourceMissing -> StaticUnavailableReason.ModelSourceMissing
        is DetectionModelPreflight.Result.OutputUnreadable ->
            StaticUnavailableReason.ModelOutputUnreadable(result.detail)
    }
}
