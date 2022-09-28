using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawOpaquePass : DrawObjectPass
    {
        FilteringSettings m_FilteringSettings;

        public DrawOpaquePass(RenderPassEvent evt, LayerMask layerMask) : base(evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(DrawOpaquePass));
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DrawOpaqueObjects)))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var drawSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);
                context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
