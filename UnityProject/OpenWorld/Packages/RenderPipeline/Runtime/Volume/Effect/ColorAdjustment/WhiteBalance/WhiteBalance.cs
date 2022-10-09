using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + WhiteBalance.title)]
    public class WhiteBalance : VolumeSetting
    {
        public const string title = "白平衡 (WhiteBalance)";

        public WhiteBalance()
        {
            this.displayName = title;
        }


        public override bool IsActive() => temperature.value != 0f || tint.value != 0f;
        public ClampedFloatParameter temperature = new ClampedFloatParameter(0f, -100, 100f);
        public ClampedFloatParameter tint = new ClampedFloatParameter(0f, -100, 100f);
    }

    public class WhiteBalanceRenderer : VolumeRenderer<WhiteBalance>
    {
        public override string PROFILER_TAG => "WhiteBalance";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustment/WhiteBalance";

        static class ShaderIDs
        {
            public static readonly int ParamsID = Shader.PropertyToID("_WhiteBalance");
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            blitMaterial.SetVector(ShaderIDs.ParamsID, ColorUtils.ColorBalanceToLMSCoeffs(settings.temperature.value, settings.tint.value));
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }
    }
}
