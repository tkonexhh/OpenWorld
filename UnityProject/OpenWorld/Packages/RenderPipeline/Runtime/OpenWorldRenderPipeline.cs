using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

namespace OpenWorld.RenderPipelines.Runtime
{
    public partial class OpenWorldRenderPipeline : RenderPipeline
    {
        ScriptableRenderer m_Renderer;

        ShadowSettings m_ShadowSettings;

        public OpenWorldRenderPipeline(OpenWorldRenderPipelineAsset asset)
        {
            m_Renderer = new ForwardRender();
            m_ShadowSettings = asset.ShadowSettings;

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

        public void DrawGizmos()
        {
            m_Renderer?.DrawGizmos();
        }


        void InitRenderingData(ScriptableRenderContext renderContext, out RenderingData renderingData, Camera camera, ref ScriptableCullingParameters cullingParameters)
        {
            cullingParameters.shadowDistance = Mathf.Min(m_ShadowSettings.maxDistance, camera.farClipPlane);

            var cullingResults = renderContext.Cull(ref cullingParameters);
            renderingData.cullingResults = cullingResults;
            renderingData.supportsDynamicBatching = true;

            //Shadow Data
            var shadowData = new ShadowData();
            shadowData.maxShadowDistance = m_ShadowSettings.maxDistance;
            int shadowResolution = (int)m_ShadowSettings.directional.resolution;
            shadowData.supportsSoftShadows = m_ShadowSettings.softShadow;
            shadowData.softShadowsMode = m_ShadowSettings.filter;
            shadowData.mainLightShadowmapWidth = shadowResolution;
            shadowData.mainLightShadowmapHeight = shadowResolution;
            shadowData.mainLightShadowCascadesCount = m_ShadowSettings.directional.cascadeCount;
            switch (shadowData.mainLightShadowCascadesCount)
            {
                case 1:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(1.0f, 0.0f, 0.0f);
                    break;
                case 2:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(m_ShadowSettings.directional.cascadeRatio1, 1.0f, 0.0f);
                    break;
                case 3:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(m_ShadowSettings.directional.cascadeRatio1, m_ShadowSettings.directional.cascadeRatio2, 0.0f);
                    break;
                default:
                    shadowData.mainLightShadowCascadesSplit = m_ShadowSettings.directional.CascadeRatios;
                    break;
            }
            shadowData.manLightShadowDistanceFade = m_ShadowSettings.distanceFade;
            shadowData.bias = m_ShadowBiasData;// new Vector4(m_ShadowSettings.depthBias, m_ShadowSettings.normalBias, 0, 0);
            renderingData.shadowData = shadowData;


            renderingData.lightData = new LightData();
            renderingData.lightData.mainLightIndex = -1;

            var cameraData = new CameraData();
            cameraData.camera = camera;
            cameraData.worldSpaceCameraPos = camera.transform.position;
            cameraData.cameraType = camera.cameraType;
            cameraData.aspectRatio = camera.aspect;

            Matrix4x4 projectionMatrix = camera.projectionMatrix;
            if (!camera.orthographic)
            {
                // m00 = (cotangent / aspect), therefore m00 * aspect gives us cotangent.
                float cotangent = camera.projectionMatrix.m00 * camera.aspect;

                // Get new m00 by dividing by base camera aspectRatio.
                float newCotangent = cotangent / cameraData.aspectRatio;
                projectionMatrix.m00 = newCotangent;
            }

            cameraData.SetViewAndProjectionMatrix(camera.worldToCameraMatrix, projectionMatrix);
            cameraData.renderer = m_Renderer;
            cameraData.cameraTargetDescriptor = CreateRenderTextureDescriptor(camera, 1, true, 1, false, true);
            renderingData.cameraData = cameraData;

            renderingData.commandBuffer = CommandBufferPool.Get();

            InitializeShadowData(cullingResults.visibleLights);
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

                m_Renderer.FinishRendering(ref renderingData);
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
            RenderingUtils.RenderObjectsWithError(renderContext, ref renderingData.cullingResults, renderingData.cameraData.camera, FilteringSettings.defaultValue, SortingCriteria.CommonOpaque);
        }



        static void InitializeShadowData(NativeArray<VisibleLight> visibleLights)
        {
            m_ShadowBiasData.Clear();
            for (int i = 0; i < visibleLights.Length; ++i)
            {
                ref VisibleLight vl = ref visibleLights.UnsafeElementAtMutable(i);
                Light light = vl.light;
                float shadowBias = light.shadowBias;
                float normalBias = light.shadowNormalBias;
                //URP 使用了一个AdditionalLightData 可以选择是否override设置 决定是否使用管线的bias

                m_ShadowBiasData.Add(new Vector4(shadowBias, normalBias, 0.0f, 0.0f));
            }
        }


        protected override void Dispose(bool disposing)
        {
            m_Renderer?.Dispose();
        }

    }
}
