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
                RenderSingleCamera(renderContext, cameras[i]);
            }
        }

        void InitRenderingData(ScriptableRenderContext renderContext, out RenderingData renderingData, Camera camera, ScriptableCullingParameters cullingParameters)
        {
            cullingParameters.shadowDistance = 10;//Mathf.Min(camera.farClipPlane,)

            renderingData.cullResults = renderContext.Cull(ref cullingParameters);
            renderingData.supportsDynamicBatching = true;

            renderingData.shadowData = new ShadowData();
            renderingData.lightData = new LightData();
            renderingData.lightData.mainLightIndex = 0;

            renderingData.cameraData = new CameraData();
            renderingData.cameraData.camera = camera;
            renderingData.cameraData.SetViewAndProjectionMatrix(camera.cameraToWorldMatrix, camera.projectionMatrix);

            renderingData.cmd = new CommandBuffer()
            {
                name = camera.name
            };
        }

        void RenderSingleCamera(ScriptableRenderContext renderContext, Camera camera)
        {
            ScriptableCullingParameters cullingParameters;
            if (!camera.TryGetCullingParameters(out cullingParameters))
            {
                return;
            }

            InitRenderingData(renderContext, out var renderingData, camera, cullingParameters);

            CommandBuffer cmd = renderingData.cmd;
            renderContext.SetupCameraProperties(camera);
            cmd.ClearRenderTarget(true, false, Color.clear);
            // cmd.BeginSample(camera.name);
            renderContext.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            m_Renderer.Setup(renderContext, ref renderingData);
            m_Renderer.Render(renderContext, ref renderingData);

            // cmd.EndSample(camera.name);
            cmd.Release();

            DrawGizmos(renderContext, ref renderingData);

            renderContext.Submit();
        }



        void DrawGizmos(ScriptableRenderContext renderContext, ref RenderingData renderingData)
        {
#if UNITY_EDITOR
            if (UnityEditor.Handles.ShouldRenderGizmos())
            {
                renderContext.DrawGizmos(renderingData.cameraData.camera, GizmoSubset.PreImageEffects);
                renderContext.DrawGizmos(renderingData.cameraData.camera, GizmoSubset.PostImageEffects);
            }
#endif
        }
    }
}
