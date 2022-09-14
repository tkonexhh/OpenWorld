using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ForwardRender : BaseRender
    {
        DepthOnlyPass m_DepthOnlyPass;
        DrawOpacityPass m_OpacityPass;
        DrawSkyboxPass m_SkyboxPass;
        DrawTransparentPass m_TransparentPass;

        ForwardLights m_ForwardLights;

        public ForwardRender()
        {
            m_DepthOnlyPass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, -1);
            m_OpacityPass = new DrawOpacityPass(RenderPassEvent.BeforeRenderingOpaques, -1);
            m_SkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
            m_TransparentPass = new DrawTransparentPass(RenderPassEvent.BeforeRenderingTransparents, -1);

            m_ForwardLights = new ForwardLights();
        }

        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            bool drawSkyBox = renderingData.cameraData.camera.clearFlags == CameraClearFlags.Skybox ? true : false;

            m_ForwardLights.Setup(ref renderingData);

            EnqueuePass(m_DepthOnlyPass);
            EnqueuePass(m_OpacityPass);

            if (drawSkyBox) EnqueuePass(m_SkyboxPass);

            EnqueuePass(m_TransparentPass);
        }

    }
}
