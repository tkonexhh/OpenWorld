using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class OpenWorldRenderPipeline : RenderPipeline
    {
        BaseRender m_Renderer;

        public OpenWorldRenderPipeline(OpenWorldRenderPipelineAsset asset)
        {
            m_Renderer = new ForwardRender();
        }


        protected override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
        {
            Render(renderContext, new List<Camera>(cameras));
        }

        protected override void Render(ScriptableRenderContext renderContext, List<Camera> cameras)
        {
            for (int i = 0; i < cameras.Count; ++i)
            {
                InitRenderingData(out var renderingData, cameras[i]);
                m_Renderer.Setup(renderContext, ref renderingData);
                m_Renderer.Render(renderContext, ref renderingData);
            }

            renderContext.Submit();
        }

        void InitRenderingData(out RenderingData renderingData, Camera camera)
        {
            renderingData.supportsDynamicBatching = true;

            renderingData.shadowData = new ShadowData();
            renderingData.lightData = new LightData();
            renderingData.lightData.mainLightIndex = 0;

            renderingData.cameraData = new CameraData();
            renderingData.cameraData.camera = camera;
            renderingData.cameraData.SetViewAndProjectionMatrix(camera.cameraToWorldMatrix, camera.projectionMatrix);
        }


    }
}
