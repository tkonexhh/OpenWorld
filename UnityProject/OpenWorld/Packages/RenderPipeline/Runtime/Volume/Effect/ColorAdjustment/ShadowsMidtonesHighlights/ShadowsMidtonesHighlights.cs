using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + ShadowsMidtonesHighlights.title)]
    public class ShadowsMidtonesHighlights : VolumeSetting
    {
        public const string title = "(Shadows Midtones Highlights)";

        public ShadowsMidtonesHighlights()
        {
            this.displayName = title;
        }

        public override bool IsActive()
        {
            var defaultState = new Vector4(1f, 1f, 1f, 0f);
            return shadows != defaultState
                || midtones != defaultState
                || highlights != defaultState;
        }

        [Tooltip("Use this to control and apply a hue to the shadows.")]
        public ColorParameter shadows = new ColorParameter(new Vector4(1f, 1f, 1f, 0f));

        [Tooltip("Use this to control and apply a hue to the midtones.")]
        public ColorParameter midtones = new ColorParameter(new Vector4(1f, 1f, 1f, 0f));

        [Tooltip("Use this to control and apply a hue to the highlights.")]
        public ColorParameter highlights = new ColorParameter(new Vector4(1f, 1f, 1f, 0f));

        [Header("Shadow Limits")]
        [Tooltip("Start point of the transition between shadows and midtones.")]
        public MinFloatParameter shadowsStart = new MinFloatParameter(0f, 0f);

        [Tooltip("End point of the transition between shadows and midtones.")]
        public MinFloatParameter shadowsEnd = new MinFloatParameter(0.3f, 0f);

        [Header("Highlight Limits")]
        [Tooltip("Start point of the transition between midtones and highlights.")]
        public MinFloatParameter highlightsStart = new MinFloatParameter(0.55f, 0f);

        [Tooltip("End point of the transition between midtones and highlights.")]
        public MinFloatParameter highlightsEnd = new MinFloatParameter(1f, 0f);
    }


    public class ShadowsMidtonesHighlightsRenderer : VolumeRenderer<ShadowsMidtonesHighlights>
    {
        public override string PROFILER_TAG => "ShadowsMidtonesHighlights";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustment/ShadowsMidtonesHighlights";

        static class ShaderIDs
        {
            public static readonly int ShadowsID = Shader.PropertyToID("_Shadows");
            public static readonly int MidtonesID = Shader.PropertyToID("_Midtones");
            public static readonly int HighlightsID = Shader.PropertyToID("_Highlights");
            public static readonly int RangeID = Shader.PropertyToID("_Range");
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            blitMaterial.SetVector(ShaderIDs.ShadowsID, settings.shadows.value);
            blitMaterial.SetVector(ShaderIDs.MidtonesID, settings.midtones.value);
            blitMaterial.SetVector(ShaderIDs.HighlightsID, settings.highlights.value);
            blitMaterial.SetVector(ShaderIDs.RangeID, new Vector4(settings.shadowsStart.value, settings.shadowsEnd.value, settings.highlightsStart.value, settings.highlightsEnd.value));
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }
    }
}
