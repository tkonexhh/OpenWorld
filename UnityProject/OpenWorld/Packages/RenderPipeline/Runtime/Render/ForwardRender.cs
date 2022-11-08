using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ForwardRender : ScriptableRenderer
    {
        MainLightShadowCasterPass m_MainLightShadowCasterPass;
        DepthOnlyPass m_DepthPrepass;
        DrawOpaquePass m_OpaquePass;
        DrawSkyboxPass m_SkyboxPass;
        DrawTransparentPass m_TransparentPass;

        ForwardLights m_ForwardLights;
        PostProcessPasses m_PostProcessPasses;

        internal PostProcessPass finalPostProcessPass { get => m_PostProcessPasses.finalPostProcessPass; }
        FinalBlitPass m_FinalBlitPass;

        RTHandle m_OpaqueColor;
        RTHandle m_DepthTexture;

        Material m_BlitMaterial = null;

        public ForwardRender(OpenWorldRenderPipelineAsset asset)
        {
            m_BlitMaterial = CoreUtils.CreateEngineMaterial(asset.resources.shaders.coreBlitPS);


            m_MainLightShadowCasterPass = new MainLightShadowCasterPass(RenderPassEvent.BeforeRenderingShadows);
            m_DepthPrepass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, -1);
            m_OpaquePass = new DrawOpaquePass(RenderPassEvent.BeforeRenderingOpaques, -1);
            m_SkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
            m_TransparentPass = new DrawTransparentPass(RenderPassEvent.BeforeRenderingTransparents, -1);
            m_FinalBlitPass = new FinalBlitPass(RenderPassEvent.AfterRendering + 1, m_BlitMaterial);

            m_ForwardLights = new ForwardLights();

            m_PostProcessPasses = new PostProcessPasses(true);
        }

        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            m_ForwardLights.Setup(ref renderingData);


            var cmd = renderingData.commandBuffer;
            var camera = renderingData.cameraData.camera;
            var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

            var colorDescriptor = cameraTargetDescriptor;
            colorDescriptor.useMipMap = false;
            colorDescriptor.autoGenerateMips = false;
            colorDescriptor.depthBufferBits = (int)DepthBits.None;
            RenderingUtils.ReAllocateIfNeeded(ref m_OpaqueColor, colorDescriptor, name: ShaderTextureId.OpacityTexture);

            bool isPreviewCamera = renderingData.cameraData.isPreviewCamera;
            bool isSceneViewCamera = renderingData.cameraData.isSceneViewCamera;
            bool requiresDepthTexture = renderingData.cameraData.requiresDepthTexture;
            bool requiresDepthPrepass = requiresDepthTexture;
            requiresDepthPrepass |= isSceneViewCamera;
            requiresDepthPrepass |= isPreviewCamera;

            bool createDepthTexture = requiresDepthPrepass;

            if (createDepthTexture)
            {
                var depthDescriptor = cameraTargetDescriptor;
                depthDescriptor.graphicsFormat = GraphicsFormat.None;
                depthDescriptor.depthStencilFormat = GraphicsFormat.D32_SFloat_S8_UInt;
                depthDescriptor.depthBufferBits = (int)DepthBits.Depth32;
                depthDescriptor.msaaSamples = 1;// Depth-Only pass don't use MSAA
                RenderingUtils.ReAllocateIfNeeded(ref m_DepthTexture, depthDescriptor, name: ShaderTextureId.CameraDepthTexture);
            }

            cmd.SetGlobalTexture(m_DepthTexture.name, m_DepthTexture.nameID);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            // Assign camera targets (color and depth)
            ConfigureCameraTarget(m_OpaqueColor, m_DepthTexture);
            m_PostProcessPasses.Setup(m_OpaqueColor);

            bool drawSkyBox = renderingData.cameraData.camera.clearFlags == CameraClearFlags.Skybox ? true : false;
            bool mainLightShadows = m_MainLightShadowCasterPass.Setup(ref renderingData);
            bool enablePostprocessing = renderingData.cameraData.postProcessEnabled;

            if (mainLightShadows) EnqueuePass(m_MainLightShadowCasterPass);

            m_DepthPrepass.Setup(m_DepthTexture);
            if (requiresDepthPrepass) EnqueuePass(m_DepthPrepass);

            m_OpaquePass.ConfigureClear(ClearFlag.All, Color.black);
            m_OpaquePass.ConfigureColorStoreAction(RenderBufferStoreAction.StoreAndResolve);
            m_OpaquePass.ConfigureDepthStoreAction(RenderBufferStoreAction.StoreAndResolve);
            EnqueuePass(m_OpaquePass);

            if (drawSkyBox) EnqueuePass(m_SkyboxPass);

            EnqueuePass(m_TransparentPass);

            if (enablePostprocessing) EnqueuePass(finalPostProcessPass);

            m_FinalBlitPass.Setup(m_OpaqueColor);
            EnqueuePass(m_FinalBlitPass);
        }

        public override void OnDrawGizmos()
        {
            m_MainLightShadowCasterPass?.OnDrawGizmos();
        }

        protected override void Dispose(bool disposing)
        {
            m_MainLightShadowCasterPass?.Dispose();
            m_FinalBlitPass?.Dispose();
            m_OpaqueColor?.Release();
            m_DepthTexture?.Release();
            m_PostProcessPasses.Dispose();

            CoreUtils.Destroy(m_BlitMaterial);

            Blitter.Cleanup();
        }

    }
}
