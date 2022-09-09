using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ForwardRender : BaseRender
    {
        DrawSkyboxPass m_SkyboxPass;

        public ForwardRender()
        {
            m_SkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);

        }

        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            EnqueuePass(m_SkyboxPass);
        }

    }
}
