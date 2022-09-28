using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawTransparentPass : DrawObjectPass
    {
        FilteringSettings m_FilteringSettings;

        public DrawTransparentPass(RenderPassEvent evt, LayerMask layerMask) : base(evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(DrawTransparentPass));
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.transparent);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DrawTransparentObjects)))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var drawSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, SortingCriteria.CommonTransparent);
                context.DrawRenderers(renderingData.cullingResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
