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


        public GBufferPass(RenderPassEvent evt, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonOpaque);
            context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
        }
    }
}
