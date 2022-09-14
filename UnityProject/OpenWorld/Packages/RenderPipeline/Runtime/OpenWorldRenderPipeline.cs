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

            GraphicsSettings.useScriptableRenderPipelineBatching = asset.UseSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;
            // Shader.globalRenderPipeline = "UniversalPipeline";
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

        void InitRenderingData(ScriptableRenderContext renderContext, out RenderingData renderingData, Camera camera, ref ScriptableCullingParameters cullingParameters)
        {
            // cullingParameters.shadowDistance = 10;//Mathf.Min(camera.farClipPlane,)

            renderingData.cullResults = renderContext.Cull(ref cullingParameters);
            renderingData.supportsDynamicBatching = true;

            renderingData.shadowData = new ShadowData();
            renderingData.lightData = new LightData();
            renderingData.lightData.mainLightIndex = 0;

            renderingData.cameraData = new CameraData();
            renderingData.cameraData.camera = camera;
            renderingData.cameraData.cameraType = camera.cameraType;
            renderingData.cameraData.SetViewAndProjectionMatrix(camera.cameraToWorldMatrix, camera.projectionMatrix);

            renderingData.commandBuffer = CommandBufferPool.Get();
        }

        void RenderSingleCamera(ScriptableRenderContext renderContext, Camera camera)
        {
            if (!camera.TryGetCullingParameters(out ScriptableCullingParameters cullingParameters))
            {
                return;
            }

            InitRenderingData(renderContext, out var renderingData, camera, ref cullingParameters);

            CommandBuffer cmd = renderingData.commandBuffer;

            CommandBuffer cmdScope = cmd;
            ProfilingSampler sampler = Profiling.TryGetOrAddCameraSampler(camera);
            using (new ProfilingScope(cmdScope, sampler))
            {
                renderContext.SetupCameraProperties(camera);
                CameraClearFlags clearFlags = camera.clearFlags;
                bool clearDepth = camera.clearFlags == CameraClearFlags.Nothing ? false : true;
                bool clearColor = camera.clearFlags == CameraClearFlags.Color;
                cmd.ClearRenderTarget(clearDepth, clearColor, camera.backgroundColor.linear);

                ExecuteCommandBuffer(renderContext, ref renderingData);

                m_Renderer.Setup(renderContext, ref renderingData);
                m_Renderer.Render(renderContext, ref renderingData);

#if UNITY_EDITOR
                // Emit scene view UI
                if (camera.cameraType == CameraType.SceneView)
                    ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
#endif

                DrawUnsupportdShaders(renderContext, ref renderingData);
                DrawGizmos(renderContext, ref renderingData);
            }

            renderContext.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            renderContext.Submit();
        }

        void ExecuteCommandBuffer(ScriptableRenderContext renderContext, ref RenderingData renderingData)
        {
            renderContext.ExecuteCommandBuffer(renderingData.commandBuffer);
            renderingData.commandBuffer.Clear();
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

        void DrawUnsupportdShaders(ScriptableRenderContext renderContext, ref RenderingData renderingData)
        {
            RenderingUtils.RenderObjectsWithError(renderContext, ref renderingData.cullResults, renderingData.cameraData.camera, FilteringSettings.defaultValue, SortingCriteria.CommonOpaque);
        }

    }
}
