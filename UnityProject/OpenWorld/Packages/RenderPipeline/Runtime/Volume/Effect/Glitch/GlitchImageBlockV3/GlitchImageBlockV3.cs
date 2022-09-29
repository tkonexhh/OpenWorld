using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Glitch + title)]
    public class GlitchImageBlockV3 : VolumeSetting
    {
        public const string title = "错位图块故障V3 (Image Block GlitchV3)";

        public GlitchImageBlockV3()
        {
            this.displayName = title;
        }

        public override bool IsActive() => Speed.value > 0;

        public FloatParameter Speed = new ClampedFloatParameter(0f, 0f, 50f);
        public FloatParameter BlockSize = new ClampedFloatParameter(8f, 0f, 50f);
    }

    public class GlitchImageBlockV3Renderer : VolumeRenderer<GlitchImageBlockV3>
    {
        public override string PROFILER_TAG => "GlitchImageBlockV3";
        public override string ShaderName => "Hidden/PostProcessing/Glitch/ImageBlockV3";


        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
        }


        public override void Render(CommandBuffer cmd, RTHandle source, RenderTargetIdentifier target, ref RenderingData renderingData)
        {
            blitMaterial.SetVector(ShaderIDs.Params, new Vector2(settings.Speed.value, settings.BlockSize.value));

            cmd.Blit(source, target, blitMaterial);
        }
    }

}