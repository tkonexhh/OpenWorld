using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ForwardRender : ScriptableRenderer
    {
        MainLightShadowCasterPass m_MainLightShadowCasterPass;
        DepthOnlyPass m_DepthOnlyPass;
        DrawOpacityPass m_OpacityPass;
        DrawSkyboxPass m_SkyboxPass;
        DrawTransparentPass m_TransparentPass;

        ForwardLights m_ForwardLights;
        PostProcessPasses m_PostProcessPasses;

        internal PostProcessPass finalPostProcessPass { get => m_PostProcessPasses.finalPostProcessPass; }

        RTHandle m_OpaqueColor;

        public ForwardRender()
        {
            m_MainLightShadowCasterPass = new MainLightShadowCasterPass(RenderPassEvent.BeforeRenderingShadows);
            m_DepthOnlyPass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, -1);
            m_OpacityPass = new DrawOpacityPass(RenderPassEvent.BeforeRenderingOpaques, -1);
            m_SkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
            m_TransparentPass = new DrawTransparentPass(RenderPassEvent.BeforeRenderingTransparents, -1);

            m_ForwardLights = new ForwardLights();

            m_PostProcessPasses = new PostProcessPasses(true);
        }

        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            m_ForwardLights.Setup(ref renderingData);


            var cmd = renderingData.commandBuffer;
            var camera = renderingData.cameraData.camera;
            var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

            if (m_OpaqueColor == null)
            {
                m_OpaqueColor = RTHandles.Alloc(cameraTargetDescriptor.width, cameraTargetDescriptor.height, name: ShaderTextureId.OpacityTexture);
            }

            ConfigureCameraColorTarget(m_OpaqueColor);
            m_PostProcessPasses.Setup(m_OpaqueColor);


            bool drawSkyBox = renderingData.cameraData.camera.clearFlags == CameraClearFlags.Skybox ? true : false;
            bool mainLightShadows = m_MainLightShadowCasterPass.Setup(ref renderingData);
            bool enablePostprocessing = renderingData.cameraData.postProcessEnabled;

            if (mainLightShadows) EnqueuePass(m_MainLightShadowCasterPass);


            EnqueuePass(m_DepthOnlyPass);
            EnqueuePass(m_OpacityPass);

            if (drawSkyBox) EnqueuePass(m_SkyboxPass);

            EnqueuePass(m_TransparentPass);

            if (enablePostprocessing) EnqueuePass(finalPostProcessPass);
        }

        public override void DrawGizmos()
        {
            m_MainLightShadowCasterPass?.DrawGizmos();
        }

        protected override void Dispose(bool disposing)
        {
            m_MainLightShadowCasterPass?.Dispose();
            m_OpaqueColor?.Release();
        }

    }
}
