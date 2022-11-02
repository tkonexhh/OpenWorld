using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    public enum MeteringMask { None, Vignette, Custom }

    [System.Serializable]
    public sealed class MeteringMaskParameter : VolumeParameter<MeteringMask>
    {
        public MeteringMaskParameter(MeteringMask value, bool overrideState = false) : base(value, overrideState) { }
    }


    [VolumeComponentMenu(VolumeDefine.Environment + AutoExposure.title)]
    public class AutoExposure : VolumeSetting
    {
        public const string title = "自动曝光 (Auto Exposure)";

        public AutoExposure()
        {
            this.displayName = title;
        }


        public override bool IsActive() => metering.value != MeteringMode.None;

        public ComputeShaderParameter autoExposureCS = new ComputeShaderParameter(null);
        public ComputeShaderParameter logHistogramCS = new ComputeShaderParameter(null);

        public MeteringModeParameter metering = new MeteringModeParameter(MeteringMode.None);
        public MeteringMaskParameter meteringMask = new MeteringMaskParameter(MeteringMask.Vignette);
        public ClampedFloatParameter minEV = new ClampedFloatParameter(-10, -10, 10);
        public ClampedFloatParameter maxEV = new ClampedFloatParameter(10, -10, 10);
        public ClampedFloatParameter lowPercent = new ClampedFloatParameter(1, 1, 99);
        public ClampedFloatParameter highPercent = new ClampedFloatParameter(99, 1, 99);
        [Tooltip("曝光补偿")]
        public FloatParameter compensation = new FloatParameter(0);
        public AdaptationModeParameter adaptation = new AdaptationModeParameter(AdaptationMode.Progressive);
        public MinFloatParameter speedUp = new MinFloatParameter(3, 0);
        public MinFloatParameter speedDown = new MinFloatParameter(1, 0);
    }

    public class AutoExposureRenderer : VolumeRenderer<AutoExposure>
    {
        public override string PROFILER_TAG => "AutoExposure";
        public override string ShaderName => "Hidden/PostProcessing/Environment/AutoExposure";


        RTHandle[] m_AutoExposureRT;
        RTHandle m_CurrentAutoExposure;
        int autoExposurePingPong;
        LogHistogram m_LogHistogram;
        // CommandBuffer m_Buffer = new CommandBuffer { name = "Auto Exposure" };
        bool resetHistory;
        ComputeShader cs;

        static class ShaderIDs
        {
            public static readonly int Params1ID = Shader.PropertyToID("_Params1");
            public static readonly int Params2ID = Shader.PropertyToID("_Params2");
            public static readonly int Params3ID = Shader.PropertyToID("_Params3");
        }

        static class ShaderKeywords
        {
            public static readonly string PhysicalBased = "PHYSCIAL_BASED";
        }

        public override void Init()
        {
            base.Init();
            m_AutoExposureRT = new RTHandle[2];

            for (int i = 0; i < m_AutoExposureRT.Length; i++)
            {
                m_AutoExposureRT[i] = RTHandles.Alloc(1, 1, colorFormat: GraphicsFormat.R32_SFloat, enableRandomWrite: true);
            }
        }

        public override void Render(CommandBuffer cmd, RTHandle source, RTHandle target, ref RenderingData renderingData)
        {
            var physcialCameraData = renderingData.cameraData.physcialCameraData;
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;

            cs = settings.autoExposureCS.value;
            if (m_LogHistogram == null)
            {
                m_LogHistogram = new LogHistogram(cmd, settings.logHistogramCS.value);
            }

            switch (settings.meteringMask.value)
            {
                case MeteringMask.None:
                    cmd.SetGlobalInt("_MeteringMask", 0);
                    break;
                case MeteringMask.Vignette:
                    cmd.SetGlobalInt("_MeteringMask", 1);
                    break;
                case MeteringMask.Custom:
                    cmd.SetGlobalInt("_MeteringMask", 2);
                    break;
                default:
                    break;
            }

            m_LogHistogram.GenerateHistorgram(descriptor.width, descriptor.height, source.nameID);

            //make sure filtering values are correct to avoid apocalyptic consequences
            float lowPercent = settings.lowPercent.value;
            float highPercent = settings.highPercent.value;
            const float minDelta = 1e-2f;
            highPercent = Mathf.Clamp(highPercent, 1f + minDelta, 99f);
            lowPercent = Mathf.Clamp(lowPercent, 1f, highPercent - minDelta);
            //clamp min/max adaptation values as well
            float minLum = settings.minEV.value;
            float maxLum = settings.maxEV.value;
            Vector4 exposureParams = new Vector4(lowPercent, highPercent, minLum, maxLum);
            Vector4 adaptationParams = new Vector4(settings.speedDown.value, settings.speedUp.value, settings.compensation.value, Time.deltaTime);
            Vector4 physcialParams = new Vector4(physcialCameraData.fStop, 1f / physcialCameraData.shutterSpeed, physcialCameraData.ISO, ColorUtils.lensImperfectionExposureScale);
            Vector4 scaleOffsetRes = m_LogHistogram.GetHistogramScaleOffsetRes(descriptor.width, descriptor.height);

            bool isFixed = settings.adaptation == AdaptationMode.Fixed ? true : false;
            bool isPhysical = settings.metering == MeteringMode.Physical ? true : false;
            AutoExposureLookUp(cmd, exposureParams, adaptationParams, physcialParams, scaleOffsetRes, m_LogHistogram.data, isFixed, isPhysical);

            Blitter.BlitCameraTexture(cmd, source, target, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, blitMaterial, 0);
        }

        //exposureParams x: lowPercent, y: highPercent, z: minEV, w: maxEV
        void AutoExposureLookUp(CommandBuffer cmd, Vector4 exposureParams, Vector4 adaptationParams, Vector4 physicalParams, Vector4 scaleOffsetRes, ComputeBuffer data, bool isFixed, bool isPhysical)
        {
            bool firstFrame = resetHistory || !Application.isPlaying;
            string adaptation = null;
            if (firstFrame || isFixed)
            {
                adaptation = "AutoExposureAvgLuminance_fixed";
            }
            else
            {
                adaptation = "AutoExposureAvgLuminance_progressive";
            }

            int kernel = cs.FindKernel(adaptation);
            cmd.SetComputeBufferParam(cs, kernel, "_HistogramBuffer", data);
            cmd.SetComputeVectorParam(cs, ShaderIDs.Params1ID, new Vector4(exposureParams.x * 0.01f, exposureParams.y * 0.01f, Mathf.Pow(2, exposureParams.z), Mathf.Pow(2, exposureParams.w)));
            cmd.SetComputeVectorParam(cs, ShaderIDs.Params2ID, adaptationParams);
            cmd.SetComputeVectorParam(cs, ShaderIDs.Params3ID, physicalParams);
            cmd.SetComputeVectorParam(cs, "_ScaleOffsetRes", scaleOffsetRes);

            CoreUtils.SetKeyword(cmd, ShaderKeywords.PhysicalBased, isPhysical);

            if (firstFrame)
            {
                //don't want eye adaptation when not in play mode because the GameView isn't animated, thus making it harder to tweak. Just use the final audo exposure value.
                m_CurrentAutoExposure = m_AutoExposureRT[0];
                cmd.SetComputeTextureParam(cs, kernel, "_DestinationTex", m_CurrentAutoExposure.nameID);
                cmd.DispatchCompute(cs, kernel, 1, 1, 1);
                //copy current exposure to the other pingpong target to avoid adapting from black
                cmd.Blit(m_AutoExposureRT[0], m_AutoExposureRT[1]);
                resetHistory = false;
            }
            else
            {
                int pp = autoExposurePingPong;
                var src = m_AutoExposureRT[++pp % 2];
                var dst = m_AutoExposureRT[++pp % 2];
                cmd.SetComputeTextureParam(cs, kernel, "_SourceTex", src);
                cmd.SetComputeTextureParam(cs, kernel, "_DestinationTex", dst);
                cmd.DispatchCompute(cs, kernel, 1, 1, 1);
                autoExposurePingPong = ++pp % 2;
                m_CurrentAutoExposure = dst;
            }
            cmd.SetGlobalTexture("_AutoExposureLUT", m_CurrentAutoExposure);

        }
    }
}
