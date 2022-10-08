using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Glitch + GlitchAnalogNoise.title)]
    public class GlitchAnalogNoise : VolumeSetting
    {
        public const string title = "模拟噪点故障 (Analog Noise Glitch)";

        public GlitchAnalogNoise()
        {
            this.displayName = title;
        }

        public override bool IsActive() => NoiseFading.value > 0;

        public FloatParameter NoiseFading = new ClampedFloatParameter(0f, 0f, 1f);
        public FloatParameter NoiseSpeed = new ClampedFloatParameter(0.5f, 0f, 1f);
        public FloatParameter LuminanceJitterThreshold = new ClampedFloatParameter(0.8f, 0f, 1f);
    }


    public class GlitchAnalogNoiseRenderer : VolumeRenderer<GlitchAnalogNoise>
    {
        public override string PROFILER_TAG => "GlitchAnalogNoise";
        public override string ShaderName => "Hidden/PostProcessing/Glitch/AnalogNoise";


        private float TimeX = 1.0f;


        static class ShaderIDs
        {
            internal static readonly int Params = Shader.PropertyToID("_Params");
        }


        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            TimeX += Time.deltaTime;
            if (TimeX > 100)
            {
                TimeX = 0;
            }

            blitMaterial.SetVector(ShaderIDs.Params, new Vector4(settings.NoiseSpeed.value, settings.NoiseFading.value, settings.LuminanceJitterThreshold.value, TimeX));

            cmd.Blit(source, target, blitMaterial);
        }


    }

}