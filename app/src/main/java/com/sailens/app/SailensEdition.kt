package com.sailens.app

import android.content.Context
import com.google.ai.edge.litert.Accelerator
import com.sailens.guidance.semantics.CityscapesNavigationSemantics
import com.sailens.guidance.semantics.NavigationSemanticsBinding
import com.sailens.runtime.CatalogModelSourceResolver
import com.sailens.runtime.ModelType
import com.sailens.shell.app.CapabilityExpectations
import com.sailens.shell.app.DescribeSpec
import com.sailens.shell.app.GuidanceSpec
import com.sailens.shell.app.SailensAppSpec
import com.sailens.vision.taxonomy.CityscapesTaxonomy
import com.sailens.vlm.SceneDescriber

/**
 * What the YOLO Edition offers.
 *
 * Unlike Core Edition, this repository **packages its own weights**, so it promises navigation
 * assistance and declares it required (architecture.md §5.1, §5.2). If the model is missing or
 * its class definition does not match, that is a fatal configuration state rather than a quiet
 * fallback -- a build that cannot guide anyone must say so, out loud, on a channel the user can
 * perceive.
 *
 * Every check here is cheap on purpose (§5.2): it resolves a model source and closes the stream,
 * and asks the semantics whether they were written for the taxonomy. Nothing is compiled and no
 * accelerator is touched.
 */
fun sailensEditionSpec(
    context: Context,
    sceneDescriber: SceneDescriber,
): SailensAppSpec = SailensAppSpec(
    guidance = GuidanceSpec(
        semanticModelPresent = {
            CatalogModelSourceResolver
                .source(ModelType.SEMANTIC_SEGMENTATION, Accelerator.GPU)
                .exists(context)
        },
        taxonomyCompatible = {
            NavigationSemanticsBinding.validate(
                taxonomy = CityscapesTaxonomy,
                semantics = CityscapesNavigationSemantics,
            ) == NavigationSemanticsBinding.Result.Compatible
        },
    ),
    describe = DescribeSpec(
        engineAvailable = { sceneDescriber.isAvailable },
    ),
    // The YOLO Edition packages its own weights, so it promises navigation assistance. A missing
    // or mismatched model here is a configuration failure, not a shrug: shipping a build that
    // silently cannot guide anyone is the outcome the capability model exists to prevent.
    expectations = CapabilityExpectations(
        guidanceRequired = true,
        describeRequired = false,
    ),
)
