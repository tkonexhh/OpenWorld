using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DeferredRender : ScriptableRenderer
    {
        MainLightShadowCasterPass m_MainLightShadowCasterPass;
        GBufferPass m_GBufferPass;
        DeferredPass m_DeferredPass;
        DrawSkyboxPass m_SkyboxPass;

        ForwardLights m_ForwardLights;

        public DeferredRender()
        {
            m_MainLightShadowCasterPass = new MainLightShadowCasterPass(RenderPassEvent.BeforeRenderingShadows);
            m_GBufferPass = new GBufferPass(RenderPassEvent.BeforeRenderingGbuffer);
            m_DeferredPass = new DeferredPass(RenderPassEvent.BeforeRenderingDeferredLights);
            m_SkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
            m_ForwardLights = new ForwardLights();
        }
        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            m_ForwardLights.Setup(ref renderingData);

            var cmd = renderingData.commandBuffer;
            var camera = renderingData.cameraData.camera;
            var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

            bool drawSkyBox = renderingData.cameraData.camera.clearFlags == CameraClearFlags.Skybox ? true : false;
            bool mainLightShadows = m_MainLightShadowCasterPass.Setup(ref renderingData);

            if (mainLightShadows) EnqueuePass(m_MainLightShadowCasterPass);
            EnqueuePass(m_GBufferPass);
            EnqueuePass(m_DeferredPass);
            if (drawSkyBox) EnqueuePass(m_SkyboxPass);
        }

        protected override void Dispose(bool disposing)
        {
            m_MainLightShadowCasterPass?.Dispose();
        }
    }
}
