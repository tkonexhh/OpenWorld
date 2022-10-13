using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class GBufferPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("GBuffer");
        FilteringSettings m_FilteringSettings;

        RTHandle[] m_GbufferAttachments;
        RTHandle m_DepthAttachments;
        const int GBufferSliceCount = 4;


        public GBufferPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(GBufferPass));
            base.renderPassEvent = evt;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);

            //init GBuffer
            int gbufferSliceCount = GBufferSliceCount;
            m_GbufferAttachments = new RTHandle[gbufferSliceCount];

            if (m_GbufferAttachments == null || m_GbufferAttachments.Length != gbufferSliceCount)
            {
                for (int i = 0; i < gbufferSliceCount; ++i)
                {
                    m_GbufferAttachments[i] = RTHandles.Alloc(ShaderTextureId.GBufferNames[i], name: ShaderTextureId.GBufferNames[i]);
                }
            }
        }

        public void Setup(RTHandle depthAttachmentHandle)
        {
            m_DepthAttachments = depthAttachmentHandle;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(m_GbufferAttachments, m_DepthAttachments);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonOpaque);
            context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
        }
    }
}
