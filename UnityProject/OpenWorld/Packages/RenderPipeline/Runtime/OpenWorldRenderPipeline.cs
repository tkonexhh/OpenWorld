using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Diagnostics;
using UnityEngine.Rendering;
using Unity.Collections;

namespace OpenWorld.RenderPipelines.Runtime
{
    public partial class OpenWorldRenderPipeline : RenderPipeline
    {
        ScriptableRenderer m_Renderer;

        OpenWorldRenderPipelineAsset m_Asset;

        public OpenWorldRenderPipeline(OpenWorldRenderPipelineAsset asset)
        {
            //初始化blit相关shader
            Blitter.Initialize(asset.resources.shaders.coreBlitPS, asset.resources.shaders.coreBlitColorAndDepthPS);
            m_Asset = asset;
            m_Renderer = new ForwardRender(asset);

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

        public void OnDrawGizmos()
        {
            m_Renderer?.OnDrawGizmos();
        }


        void InitRenderingData(ScriptableRenderContext renderContext, out RenderingData renderingData, Camera camera, ref ScriptableCullingParameters cullingParameters)
        {
            var generalSettings = m_Asset.GeneralSettings;
            var shadowSettings = m_Asset.ShadowSettings;
            var lightingSettings = m_Asset.LightingSettings;
            var physicalCameraSettings = m_Asset.PhyscialCameraSettings;

            cullingParameters.shadowDistance = Mathf.Min(shadowSettings.maxDistance, camera.farClipPlane);

            bool isHdrEnabled = generalSettings.allowHDR && camera.allowHDR;

            var cullingResults = renderContext.Cull(ref cullingParameters);
            renderingData.cullingResults = cullingResults;
            renderingData.supportsDynamicBatching = true;
            renderingData.perObjectData = GetPerObjectLightFlags(lightingSettings.additionalLightsCount, false);

            //Shadow Data
            var shadowData = new ShadowData();
            shadowData.maxShadowDistance = shadowSettings.maxDistance;
            int shadowResolution = (int)shadowSettings.directional.resolution;
            shadowData.supportsSoftShadows = shadowSettings.softShadow;
            shadowData.softShadowsMode = shadowSettings.filter;
            shadowData.mainLightShadowmapWidth = shadowResolution;
            shadowData.mainLightShadowmapHeight = shadowResolution;
            shadowData.mainLightShadowCascadesCount = shadowSettings.directional.cascadeCount;
            switch (shadowData.mainLightShadowCascadesCount)
            {
                case 1:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(1.0f, 0.0f, 0.0f);
                    break;
                case 2:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(shadowSettings.directional.cascadeRatio1, 1.0f, 0.0f);
                    break;
                case 3:
                    shadowData.mainLightShadowCascadesSplit = new Vector3(shadowSettings.directional.cascadeRatio1, shadowSettings.directional.cascadeRatio2, 0.0f);
                    break;
                default:
                    shadowData.mainLightShadowCascadesSplit = shadowSettings.directional.CascadeRatios;
                    break;
            }
            shadowData.manLightShadowDistanceFade = shadowSettings.distanceFade;
            shadowData.bias = m_ShadowBiasData;// new Vector4(m_ShadowSettings.depthBias, m_ShadowSettings.normalBias, 0, 0);
            renderingData.shadowData = shadowData;

            LightData lightData = new LightData();
            lightData.mainLightIndex = -1;
            lightData.visibleLights = cullingResults.visibleLights;
            lightData.supportsAdditionalLights = lightingSettings.enableAdditionalLighting;
            lightData.maxPerObjectAdditionalLightsCount = lightingSettings.additionalLightsCount;
            renderingData.lightData = lightData;

            var cameraData = new CameraData();
            cameraData.camera = camera;
            cameraData.worldSpaceCameraPos = camera.transform.position;
            cameraData.cameraType = camera.cameraType;
            cameraData.aspectRatio = camera.aspect;
            cameraData.postProcessEnabled = CoreUtils.ArePostProcessesEnabled(camera);
            cameraData.requiresDepthTexture = true;
            cameraData.pixelRect = camera.pixelRect;

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
            cameraData.cameraTargetDescriptor = CreateRenderTextureDescriptor(camera, generalSettings.renderScale, isHdrEnabled, 1, false, false);

            PhyscialCameraData physcialCameraData = new PhyscialCameraData();
            physcialCameraData.fStop = physicalCameraSettings.fStop;
            physcialCameraData.shutterSpeed = physicalCameraSettings.shutterSpeed;
            physcialCameraData.ISO = physicalCameraSettings.ISO;
            cameraData.physcialCameraData = physcialCameraData;

            renderingData.cameraData = cameraData;

            renderingData.isHdrEnabled = isHdrEnabled;
            renderingData.commandBuffer = CommandBufferPool.Get();

            var postProcessingData = new PostProcessingData();
            postProcessingData.lutSize = (int)m_Asset.PostProcessingSettings.resolution;
            renderingData.postProcessingData = postProcessingData;

            InitializeShadowData(cullingResults.visibleLights);
        }

        void RenderSingleCamera(ScriptableRenderContext renderContext, Camera camera)
        {
            if (!camera.TryGetCullingParameters(out ScriptableCullingParameters cullingParameters))
            {
                return;
            }

            UpdateVolumeFramework(camera);
            InitRenderingData(renderContext, out var renderingData, camera, ref cullingParameters);

            CommandBuffer cmd = renderingData.commandBuffer;

            CommandBuffer cmdScope = cmd;
            ProfilingSampler sampler = Profiling.TryGetOrAddCameraSampler(camera);
            using (new ProfilingScope(cmdScope, sampler))
            {
                renderContext.SetupCameraProperties(camera);

                m_Renderer.Setup(renderContext, ref renderingData);
                m_Renderer.Render(renderContext, ref renderingData);

#if UNITY_EDITOR
                // Emit scene view UI
                if (camera.cameraType == CameraType.SceneView)
                    ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
#endif

                DrawUnsupportdShaders(renderContext, ref renderingData);
                DrawWireOverlay(renderContext, camera);
                m_Renderer.FinishRendering(ref renderingData);
            }

            renderContext.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            renderContext.Submit();
        }

        static void UpdateVolumeFramework(Camera camera)
        {
            VolumeManager.instance.Update(camera.transform, 1);
        }

        //为了 Shaded Wireframe
        [Conditional("UNITY_EDITOR")]
        void DrawWireOverlay(ScriptableRenderContext context, Camera camera)
        {
            context.DrawWireOverlay(camera);
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

        static PerObjectData GetPerObjectLightFlags(int additionalLightsCount, bool clustering)
        {
            var configuration = PerObjectData.ReflectionProbes | PerObjectData.Lightmaps | PerObjectData.LightProbe | PerObjectData.LightData | PerObjectData.OcclusionProbe | PerObjectData.ShadowMask;

            if (additionalLightsCount > 0 && !clustering)//使用逐对象灯光分配
            {
                configuration |= PerObjectData.LightData;
                configuration |= PerObjectData.LightIndices;
            }

            return configuration;
        }


        protected override void Dispose(bool disposing)
        {
            m_Renderer?.Dispose();
        }

    }
}
