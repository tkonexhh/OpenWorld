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

        public DrawOpacityPass(RenderPassEvent evt, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DrawOpaqueObjects)))
            {
                var drawSettings = RenderingUtils.CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
