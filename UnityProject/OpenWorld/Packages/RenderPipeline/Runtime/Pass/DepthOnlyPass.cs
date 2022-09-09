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

        public DepthOnlyPass(RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(renderQueueRange);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            Debug.LogError("[DepthOnlyPass][Execute]");
            var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonOpaque);
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
        }
    }
}
