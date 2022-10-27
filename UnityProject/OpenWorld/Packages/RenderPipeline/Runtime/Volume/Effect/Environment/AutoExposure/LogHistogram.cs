using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    //直方图
    public class LogHistogram
    {
        //EV range [2^-10, 2^10]
        public const int rangeMin = -10;
        public const int rangeMax = 10;
        const int bins = 256;
        CommandBuffer buffer;
        public ComputeShader cs;
        public ComputeBuffer data;

        int kernel_EyeHistogramClear;
        int kernel_EyeHistogram;

        public LogHistogram(CommandBuffer buffer, ComputeShader cs)
        {
            this.buffer = buffer;
            this.cs = cs;

            kernel_EyeHistogramClear = cs.FindKernel("EyeHistogramClear");
            kernel_EyeHistogram = cs.FindKernel("EyeHistogram");
        }

        public void Release()
        {
            if (data != null)
            {
                data.Release();
                data = null;
            }
        }

        static class ShaderIDs
        {
            public static readonly int HistogramBufferID = Shader.PropertyToID("_HistogramBuffer");
            public static readonly int ScaleOffsetResID = Shader.PropertyToID("_ScaleOffsetRes");
            public static readonly int SourceTexID = Shader.PropertyToID("_SourceTex");
        }

        public Vector4 GetHistogramScaleOffsetRes(int width, int height)
        {
            float diff = rangeMax - rangeMin;
            float scale = 1f / diff;
            float offset = -rangeMin * scale;
            return new Vector4(scale, offset, width, height);
        }

        public void GenerateHistorgram(int witdh, int height, RenderTargetIdentifier source)
        {
            if (data == null)
            {
                data = new ComputeBuffer(bins, sizeof(uint));
            }
            uint threadX, threadY, threadZ;
            var scaleOffsetRes = GetHistogramScaleOffsetRes(witdh, height);
            //clear the buffer on every frame as we use it to accumulate luminance values on each frame

            buffer.SetComputeBufferParam(cs, kernel_EyeHistogramClear, ShaderIDs.HistogramBufferID, data);
            cs.GetKernelThreadGroupSizes(kernel_EyeHistogramClear, out threadX, out threadY, out threadZ);
            buffer.DispatchCompute(cs, kernel_EyeHistogramClear, Mathf.CeilToInt(bins / (float)threadX), 1, 1);
            //get a log histogram

            buffer.SetComputeBufferParam(cs, kernel_EyeHistogram, ShaderIDs.HistogramBufferID, data);
            buffer.SetComputeTextureParam(cs, kernel_EyeHistogram, ShaderIDs.SourceTexID, source);
            buffer.SetComputeVectorParam(cs, ShaderIDs.ScaleOffsetResID, scaleOffsetRes);
            cs.GetKernelThreadGroupSizes(kernel_EyeHistogram, out threadX, out threadY, out threadZ);
            //half resolution
            buffer.DispatchCompute(cs, kernel_EyeHistogram, Mathf.CeilToInt(scaleOffsetRes.z / 2f / threadX), Mathf.CeilToInt(scaleOffsetRes.w / 2f / threadY), 1);
        }
    }
}
