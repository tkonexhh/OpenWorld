using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class FinalBlitPass : ScriptableRenderPass
    {
        RTHandle m_Source;
        static Material m_BlitMaterial;
        RTHandle m_CameraTargetHandle;

        public FinalBlitPass(RenderPassEvent evt, Material blitMaterial)
        {
            base.profilingSampler = new ProfilingSampler(nameof(FinalBlitPass));
            base.useNativeRenderPass = false;

            m_BlitMaterial = blitMaterial;
            renderPassEvent = evt;
        }

        public void Setup(RTHandle colorHandle)
        {
            m_Source = colorHandle;
        }

        public void Dispose()
        {
            m_CameraTargetHandle?.Release();
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_BlitMaterial == null)
            {
                Debug.LogErrorFormat("Missing {0}. {1} render pass will not execute. Check for missing reference in the renderer resources.", m_BlitMaterial, GetType().Name);
                return;
            }

            // Note: We need to get the cameraData.targetTexture as this will get the targetTexture of the camera stack.
            // Overlay cameras need to output to the target described in the base camera while doing camera stack.
            ref CameraData cameraData = ref renderingData.cameraData;

            RenderTargetIdentifier cameraTarget = BuiltinRenderTextureType.CameraTarget;
            if (m_CameraTargetHandle != cameraTarget)
            {
                m_CameraTargetHandle?.Release();
                m_CameraTargetHandle = RTHandles.Alloc(cameraTarget);
            }

            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.FinalBlit)))
            {
                var loadAction = RenderBufferLoadAction.DontCare;
                RenderingUtils.FinalBlit(cmd, ref cameraData, m_Source, m_CameraTargetHandle, loadAction, RenderBufferStoreAction.Store, m_BlitMaterial, m_Source.rt?.filterMode == FilterMode.Bilinear ? 1 : 0);
            }
        }
    }
}
