using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ColorGradingLutPass : ScriptableRenderPass
    {

        RTHandle m_InternalLut;

        public ColorGradingLutPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(ColorGradingLutPass));
            base.renderPassEvent = evt;
        }

        public void Setup(in RTHandle internalLut)
        {
            m_InternalLut = internalLut;
        }

        public void ConfigureDescriptor(in PostProcessingData postProcessingData, out RenderTextureDescriptor descriptor, out FilterMode filterMode)
        {
            // bool hdr = postProcessingData.gradingMode == ColorGradingMode.HighDynamicRange;
            int lutHeight = postProcessingData.lutSize;
            int lutWidth = lutHeight * lutHeight;
            var format = GraphicsFormat.R16G16B16A16_SFloat;//hdr ? m_HdrLutFormat : m_LdrLutFormat;
            descriptor = new RenderTextureDescriptor(lutWidth, lutHeight, format, 0);
            descriptor.vrUsage = VRTextureUsage.None; // We only need one for both eyes in VR

            filterMode = FilterMode.Bilinear;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.ColorGradingLUT)))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();


                // Render the lut
                // Blitter.BlitCameraTexture(cmd, m_InternalLut, m_InternalLut, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, material, 0);
            }
        }
    }
}
