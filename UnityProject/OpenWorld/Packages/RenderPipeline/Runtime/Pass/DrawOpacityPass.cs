using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawOpacityPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("UniversalForward");

        FilteringSettings m_FilteringSettings;

        public DrawOpacityPass(RenderPassEvent evt, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            Debug.LogError("[DrawOpacityPass][Execute]");
            var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonOpaque);
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
        }
    }
}
