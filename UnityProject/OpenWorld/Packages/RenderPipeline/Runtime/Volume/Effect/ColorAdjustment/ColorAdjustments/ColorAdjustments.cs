using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + ColorAdjustments.title)]
    public class ColorAdjustments : VolumeSetting
    {
        public const string title = "调色 (ColorAdjustments)";

        public ColorAdjustments()
        {
            this.displayName = title;
        }

        public override bool IsActive()
        {
            return postExposure.value != 0f
                || contrast.value != 0f
                || colorFilter != Color.white
                || hueShift != 0f
                || saturation != 0f;
        }

        [Tooltip("Adjusts the overall exposure of the scene in EV100. This is applied after HDR effect and right before tonemapping so it won't affect previous effects in the chain.")]
        public FloatParameter postExposure = new FloatParameter(0f);

        [Tooltip("Expands or shrinks the overall range of tonal values.")]
        public ClampedFloatParameter contrast = new ClampedFloatParameter(0f, -100f, 100f);

        [Tooltip("Tint the render by multiplying a color.")]
        public ColorParameter colorFilter = new ColorParameter(Color.white, true, false, true);

        [Tooltip("Shift the hue of all colors.")]
        public ClampedFloatParameter hueShift = new ClampedFloatParameter(0f, -180f, 180f);

        [Tooltip("Pushes the intensity of all colors.")]
        public ClampedFloatParameter saturation = new ClampedFloatParameter(0f, -100f, 100f);

    }


    public class ColorAdjustmentsRenderer : VolumeRenderer<ColorAdjustments>
    {
        public override string PROFILER_TAG => "ColorAdjustments";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustments";

        static class ShaderIDs
        {
            public static readonly int ParamsID = Shader.PropertyToID("_Params");
            public static readonly int ColorFilterID = Shader.PropertyToID("_ColorFilter");
            public static readonly int WhiteBalanceID = Shader.PropertyToID("_WhiteBalance");
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            float postExposureLinear = Mathf.Pow(2f, settings.postExposure.value);
            float contrast = settings.contrast.value * 0.01f + 1f;
            float hueShift = settings.hueShift.value * (1f / 360f);
            float saturation = settings.saturation.value * 0.01f + 1f;
            blitMaterial.SetVector(ShaderIDs.ParamsID, new Vector4(postExposureLinear, contrast, hueShift, saturation));
            blitMaterial.SetColor(ShaderIDs.ColorFilterID, settings.colorFilter.value);
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }
    }
}
