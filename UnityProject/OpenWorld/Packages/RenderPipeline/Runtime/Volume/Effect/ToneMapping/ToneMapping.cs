using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    public enum ToneMappingType
    {
        None = -1,
        Reinhard = 0,
        Neutral,
        ACES,
    }

    [System.Serializable]
    public sealed class ToneMappingTypeParameter : VolumeParameter<ToneMappingType> { public ToneMappingTypeParameter(ToneMappingType value, bool overrideState = false) : base(value, overrideState) { } }

    [VolumeComponentMenu(VolumeDefine.VOLUMEROOT + ToneMapping.title)]
    public class ToneMapping : VolumeSetting
    {
        public const string title = "色调映射 (Tonemapping)";

        public ToneMapping()
        {
            this.displayName = title;
        }

        public override bool IsActive() => Type.value != ToneMappingType.None;

        public ToneMappingTypeParameter Type = new ToneMappingTypeParameter(ToneMappingType.None);
    }


    public class ToneMappingRenderer : VolumeRenderer<ToneMapping>
    {
        public override string PROFILER_TAG => "ToneMapping";
        public override string ShaderName => "Hidden/PostProcessing/Tonemapping";

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            ToneMappingType type = settings.Type.value;
            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)type);
        }
    }
}
