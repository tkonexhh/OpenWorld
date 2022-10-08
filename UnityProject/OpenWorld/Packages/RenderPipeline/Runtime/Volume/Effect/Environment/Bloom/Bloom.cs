using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    public enum BloomQuailtyType
    {
        Low,
        High,
    }

    [System.Serializable]
    public sealed class BloomQuailtyParameter : VolumeParameter<BloomQuailtyType> { public BloomQuailtyParameter(BloomQuailtyType value, bool overrideState = false) : base(value, overrideState) { } }

    [VolumeComponentMenu(VolumeDefine.Environment + Bloom.title)]
    public class Bloom : VolumeSetting
    {
        public const string title = "泛光 (Bloom)";

        public Bloom()
        {
            this.displayName = title;
        }

        public override bool IsActive() => Intensity.value > 0;
        public BloomQuailtyParameter BloomQuailty = new BloomQuailtyParameter(BloomQuailtyType.High);
        public MinFloatParameter Intensity = new MinFloatParameter(0f, 0f);
        [Tooltip("Set the radius of the bloom effect.")]
        public ClampedFloatParameter Scatter = new ClampedFloatParameter(0.7f, 0f, 1f);
        public ClampedFloatParameter Threshold = new ClampedFloatParameter(0.2f, 0f, 10f);
        public ClampedIntParameter MaxIterations = new ClampedIntParameter(6, 2, 8);
    }

    public class BloomRenderer : VolumeRenderer<Bloom>
    {
        public override string PROFILER_TAG => "Bloom";
        public override string ShaderName => "Hidden/PostProcessing/Environment/Bloom";

        const int MaxIterations = 10;

        RTHandle[] m_BloomMipUp;
        RTHandle[] m_BloomMipDown;


        static class ShaderIDs
        {
            public static readonly int BloomTex = Shader.PropertyToID("_Bloom_Texture");
            public static readonly int ParamsID = Shader.PropertyToID("_Params");
            public static readonly int SourceTexLowMip = Shader.PropertyToID("_SourceTexLowMip");

            public static int[] _BloomMipUp;
            public static int[] _BloomMipDown;
        }

        static class ShaderKeywords
        {
            public static readonly string BloomLQ = "_BLOOM_LQ";
            public static readonly string BloomHQ = "_BLOOM_HQ";
        }

        enum Pass
        {
            Prefilter = 0,
            BlurH = 1,
            BlurV = 2,
            Upsample = 3,
            Combine = 4,
        }

        public override void Init()
        {
            base.Init();


            ShaderIDs._BloomMipUp = new int[MaxIterations];
            ShaderIDs._BloomMipDown = new int[MaxIterations];
            m_BloomMipUp = new RTHandle[MaxIterations];
            m_BloomMipDown = new RTHandle[MaxIterations];

            for (int i = 0; i < MaxIterations; i++)
            {
                ShaderIDs._BloomMipUp[i] = Shader.PropertyToID("_BloomMipUp" + i);
                ShaderIDs._BloomMipDown[i] = Shader.PropertyToID("_BloomMipDown" + i);
                // Get name, will get Allocated with descriptor later
                m_BloomMipUp[i] = RTHandles.Alloc(ShaderIDs._BloomMipUp[i], name: "_BloomMipUp" + i);
                m_BloomMipDown[i] = RTHandles.Alloc(ShaderIDs._BloomMipDown[i], name: "_BloomMipDown" + i);
            }
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            // Material setup
            float threshold = Mathf.GammaToLinearSpace(settings.Threshold.value);
            float thresholdKnee = threshold * 0.5f; // Hardcoded soft knee
            var param = new Vector4(threshold, thresholdKnee, settings.Scatter.value, settings.Intensity.value);
            blitMaterial.SetVector(ShaderIDs.ParamsID, param);
            CoreUtils.SetKeyword(blitMaterial, ShaderKeywords.BloomHQ, settings.BloomQuailty.value == BloomQuailtyType.High);

            var sourceTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

            int RTWidth = sourceTargetDescriptor.width >> 1;
            int RTHeight = sourceTargetDescriptor.height >> 1;

            int maxSize = Mathf.Max(RTWidth, RTHeight);
            int iterations = Mathf.FloorToInt(Mathf.Log(maxSize, 2f) - 1);
            int mipCount = Mathf.Clamp(iterations, 1, settings.MaxIterations.value);

            // Prefilter
            var desc = sourceTargetDescriptor;
            desc.depthBufferBits = (int)DepthBits.None;
            desc.width = RTWidth;
            desc.height = RTHeight;
            desc.graphicsFormat = GraphicsFormat.B10G11R11_UFloatPack32;
            for (int i = 0; i < mipCount; i++)
            {
                RenderingUtils.ReAllocateIfNeeded(ref m_BloomMipUp[i], desc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: m_BloomMipUp[i].name);
                RenderingUtils.ReAllocateIfNeeded(ref m_BloomMipDown[i], desc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: m_BloomMipDown[i].name);
                desc.width = Mathf.Max(1, desc.width >> 1);
                desc.height = Mathf.Max(1, desc.height >> 1);
            }

            //提取高亮范围
            Blitter.BlitCameraTexture(cmd, source, m_BloomMipDown[0], RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)Pass.Prefilter);


            //降采样
            var lastDown = m_BloomMipDown[0];
            for (int i = 0; i < mipCount; i++)
            {
                // Classic two pass gaussian blur - use mipUp as a temporary target
                //   First pass does 2x downsampling + 9-tap gaussian
                //   Second pass does 9-tap gaussian using a 5-tap filter + bilinear filtering
                Blitter.BlitCameraTexture(cmd, lastDown, m_BloomMipUp[i], RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)Pass.BlurH);
                Blitter.BlitCameraTexture(cmd, m_BloomMipUp[i], m_BloomMipDown[i], RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)Pass.BlurV);

                lastDown = m_BloomMipDown[i];
            }

            //升采样
            for (int i = mipCount - 2; i >= 0; i--)
            {
                var lowMip = (i == mipCount - 2) ? m_BloomMipDown[i + 1] : m_BloomMipUp[i + 1];
                var highMip = m_BloomMipDown[i];
                var dst = m_BloomMipUp[i];

                cmd.SetGlobalTexture(ShaderIDs.SourceTexLowMip, lowMip);
                Blitter.BlitCameraTexture(cmd, highMip, dst, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)Pass.Upsample);
                lastDown = dst;
            }

            cmd.SetGlobalTexture(ShaderIDs.BloomTex, lastDown);

            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, (int)Pass.Combine);
        }

        public override void Cleanup()
        {
            foreach (var handle in m_BloomMipDown)
                handle?.Release();
            foreach (var handle in m_BloomMipUp)
                handle?.Release();
        }
    }
}
