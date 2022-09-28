using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DepthOnlyPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("DepthOnly");

        FilteringSettings m_FilteringSettings;
        private RTHandle destination { get; set; }

        public DepthOnlyPass(RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask)
        {
            base.profilingSampler = new ProfilingSampler(nameof(DepthOnlyPass));
            m_FilteringSettings = new FilteringSettings(renderQueueRange);
            renderPassEvent = evt;
        }

        public void Setup(RTHandle depthAttachmentHandle)
        {
            this.destination = depthAttachmentHandle;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(destination);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DepthPrepass)))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                // var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonOpaque);
                var sortingSettings = new SortingSettings(renderingData.cameraData.camera);
                var drawSettings = new DrawingSettings(k_ShaderTagId, sortingSettings);
                context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
