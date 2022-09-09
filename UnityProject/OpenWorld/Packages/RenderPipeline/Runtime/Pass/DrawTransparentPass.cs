using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawTransparentPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("ForwardLit");

        FilteringSettings m_FilteringSettings;


        public DrawTransparentPass(RenderPassEvent evt, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.transparent);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            Debug.LogError("[DrawTransparentPass][Execute]");
            var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, SortingCriteria.CommonTransparent);
            context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
        }
    }
}
