using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.ColorAdjustment + ChannelMixer.title)]
    public class ChannelMixer : VolumeSetting
    {
        public const string title = "通道混合 (Channel Mixer)";

        public ChannelMixer()
        {
            this.displayName = title;
        }

        public override bool IsActive()
        {
            return redOutRedIn.value != 100f
                || redOutGreenIn.value != 0f
                || redOutBlueIn.value != 0f
                || greenOutRedIn.value != 0f
                || greenOutGreenIn.value != 100f
                || greenOutBlueIn.value != 0f
                || blueOutRedIn.value != 0f
                || blueOutGreenIn.value != 0f
                || blueOutBlueIn.value != 100f;
        }

        [Tooltip("Modify influence of the red channel in the overall mix.")]
        public ClampedFloatParameter redOutRedIn = new ClampedFloatParameter(100f, -200f, 200f);

        /// <summary>
        /// Modify influence of the green channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the green channel in the overall mix.")]
        public ClampedFloatParameter redOutGreenIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the blue channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the blue channel in the overall mix.")]
        public ClampedFloatParameter redOutBlueIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the red channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the red channel in the overall mix.")]
        public ClampedFloatParameter greenOutRedIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the green channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the green channel in the overall mix.")]
        public ClampedFloatParameter greenOutGreenIn = new ClampedFloatParameter(100f, -200f, 200f);

        /// <summary>
        /// Modify influence of the blue channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the blue channel in the overall mix.")]
        public ClampedFloatParameter greenOutBlueIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the red channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the red channel in the overall mix.")]
        public ClampedFloatParameter blueOutRedIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the green channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the green channel in the overall mix.")]
        public ClampedFloatParameter blueOutGreenIn = new ClampedFloatParameter(0f, -200f, 200f);

        /// <summary>
        /// Modify influence of the blue channel in the overall mix.
        /// </summary>
        [Tooltip("Modify influence of the blue channel in the overall mix.")]
        public ClampedFloatParameter blueOutBlueIn = new ClampedFloatParameter(100f, -200f, 200f);
    }

    public class ChannelMixerRenderer : VolumeRenderer<ChannelMixer>
    {
        public override string PROFILER_TAG => "ChannelMixer";
        public override string ShaderName => "Hidden/PostProcessing/ColorAdjustment/ChannelMixer";

        static class ShaderIDs
        {
            public static readonly int ChannelMixerRedID = Shader.PropertyToID("_ChannelMixerRed");
            public static readonly int ChannelMixerGreenID = Shader.PropertyToID("_ChannelMixerGreen");
            public static readonly int ChannelMixerBlueID = Shader.PropertyToID("_ChannelMixerBlue");
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            blitMaterial.SetVector(ShaderIDs.ChannelMixerRedID, new Vector4(settings.redOutRedIn.value / 100.0f, settings.redOutGreenIn.value / 100.0f, settings.redOutBlueIn.value / 100.0f, 1));
            blitMaterial.SetVector(ShaderIDs.ChannelMixerGreenID, new Vector4(settings.greenOutRedIn.value / 100.0f, settings.greenOutGreenIn.value / 100.0f, settings.greenOutBlueIn.value / 100.0f, 1));
            blitMaterial.SetVector(ShaderIDs.ChannelMixerBlueID, new Vector4(settings.blueOutRedIn.value / 100.0f, settings.blueOutGreenIn.value / 100.0f, settings.blueOutRedIn.value / 100.0f, 1));
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }
    }
}
