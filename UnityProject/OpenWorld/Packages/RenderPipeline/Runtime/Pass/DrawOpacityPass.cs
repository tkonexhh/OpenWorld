using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawOpacityPass : DrawObjectPass
    {
        FilteringSettings m_FilteringSettings;

        public DrawOpacityPass(RenderPassEvent evt, LayerMask layerMask) : base()
        {
            base.profilingSampler = new ProfilingSampler(nameof(DrawOpacityPass));
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            renderPassEvent = evt;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DrawOpaqueObjects)))
            {
                // ConfigureTarget(renderingData.cameraData.renderer.cameraColorTargetHandle);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var drawSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);
                context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
