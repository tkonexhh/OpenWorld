using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + SplitToning.title)]
    public class SplitToning : VolumeSetting
    {
        public const string title = "分离色调 (SplitToning)";

        public SplitToning()
        {
            this.displayName = title;
        }

        public override bool IsActive() => shadows != Color.grey || highlights != Color.grey;

        [Tooltip("The color to use for shadows.")]
        public ColorParameter shadows = new ColorParameter(Color.grey, false, false, true);

        /// <summary>
        /// The color to use for highlights.
        /// </summary>
        [Tooltip("The color to use for highlights.")]
        public ColorParameter highlights = new ColorParameter(Color.grey, false, false, true);

        /// <summary>
        /// Balance between the colors in the highlights and shadows.
        /// </summary>
        [Tooltip("Balance between the colors in the highlights and shadows.")]
        public ClampedFloatParameter balance = new ClampedFloatParameter(0f, -100f, 100f);
    }

    public class SplitToningRenderer : VolumeRenderer<SplitToning>
    {
        public override string PROFILER_TAG => "SplitToning";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustment/SplitToning";

        static class ShaderIDs
        {
            public static readonly int SplitToningShadowsID = Shader.PropertyToID("_SplitToningShadows");
            public static readonly int SplitToningHighlightsID = Shader.PropertyToID("_SplitToningHighlights");
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            Color splitColor = settings.shadows.value;
            splitColor.a = settings.balance.value * 0.01f;
            blitMaterial.SetColor(ShaderIDs.SplitToningShadowsID, splitColor);
            blitMaterial.SetColor(ShaderIDs.SplitToningHighlightsID, settings.highlights.value);
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }
    }
}
