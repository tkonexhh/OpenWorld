using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class MainLightShadowCasterPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("ShadowCaster");
        const int k_MaxCascades = 4;
        const int k_ShadowmapBufferBits = 32;

        float m_MaxShadowDistanceSq;
        int m_ShadowCasterCascadesCount;
        int m_MainLightShadowmapID;

        int renderTargetWidth;
        int renderTargetHeight;

        Matrix4x4[] m_MainLightShadowMatrices;
        ShadowSliceData[] m_CascadeSlices;
        Vector4[] m_CascadeShadowSplitSpheres;

        internal RTHandle m_MainLightShadowmapTexture;

        FilteringSettings m_FilteringSettings;


        static class ShaderIDs
        {
            public static readonly int WorldToShadow = Shader.PropertyToID("_MainLightWorldToShadow");
            public static readonly int ShadowParams = Shader.PropertyToID("_MainLightShadowParams");
            public static readonly int CascadeCount = Shader.PropertyToID("_MainLightCascadeCount");
            public static readonly int CascadeShadowSplitSpheres = Shader.PropertyToID("_CascadeShadowSplitSpheres");
            public static readonly string MainLightShadowmapTexture = "_MainLightShadowmapTexture";
        }


        public MainLightShadowCasterPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(MainLightShadowCasterPass));

            m_MainLightShadowMatrices = new Matrix4x4[k_MaxCascades + 1];
            m_CascadeSlices = new ShadowSliceData[k_MaxCascades];
            m_CascadeShadowSplitSpheres = new Vector4[k_MaxCascades];

            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            m_MainLightShadowmapID = Shader.PropertyToID(ShaderIDs.MainLightShadowmapTexture);
        }

        public bool Setup(ref RenderingData renderingData)
        {
            int shadowLightIndex = renderingData.lightData.mainLightIndex;
            if (shadowLightIndex == -1)
                return false;

            VisibleLight shadowLight = renderingData.cullResults.visibleLights[shadowLightIndex];
            Light light = shadowLight.light;
            if (light.shadows == LightShadows.None || light.shadowStrength <= 0)
                return false;

            if (shadowLight.lightType != LightType.Directional)
            {
                Debug.LogWarning("Only directional lights are supported as main light.");
                return false;
            }

            Bounds bounds;
            if (!renderingData.cullResults.GetShadowCasterBounds(shadowLightIndex, out bounds))
                return false;

            m_ShadowCasterCascadesCount = renderingData.shadowData.mainLightShadowCascadesCount;
            m_MaxShadowDistanceSq = renderingData.shadowData.maxShadowDistance * renderingData.shadowData.maxShadowDistance;
            renderTargetWidth = renderingData.shadowData.mainLightShadowmapWidth;
            renderTargetHeight = renderingData.shadowData.mainLightShadowmapHeight;
            int shadowResolution = ShadowUtils.GetMaxTileResolutionInAtlas(renderTargetWidth, renderTargetHeight, m_ShadowCasterCascadesCount);

            //找出与灯光方向匹配的视图和投影矩阵，并为提供一个剪辑空间立方体
            for (int cascadeIndex = 0; cascadeIndex < m_ShadowCasterCascadesCount; ++cascadeIndex)
            {
                bool success = ShadowUtils.ExtractDirectionalLightMatrix(ref renderingData.cullResults, ref renderingData.shadowData, shadowLightIndex, cascadeIndex, renderTargetWidth, renderTargetHeight, shadowResolution, light.shadowNearPlane, out m_CascadeShadowSplitSpheres[cascadeIndex], out m_CascadeSlices[cascadeIndex]);

                if (!success)
                    return false;
            }

            if (m_MainLightShadowmapTexture == null)
            {
                m_MainLightShadowmapTexture = ShadowUtils.AllocShadowRT(renderTargetWidth, renderTargetHeight, k_ShadowmapBufferBits, ShaderIDs.MainLightShadowmapTexture);
            }

            return true;
        }

        public override void Configure(CommandBuffer cmd)
        {
            ConfigureTarget(m_MainLightShadowmapTexture);
            ConfigureColorStoreAction(RenderBufferStoreAction.Store);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;

            var cullResults = renderingData.cullResults;
            var lightData = renderingData.lightData;
            var shadowData = renderingData.shadowData;

            int shadowLightIndex = lightData.mainLightIndex;
            if (shadowLightIndex == -1)
                return;

            VisibleLight shadowLight = cullResults.visibleLights[shadowLightIndex];
            if (shadowLight.light.shadowStrength <= 0)
                return;

            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.MainLightShadow)))
            {
                var shadowSettings = new ShadowDrawingSettings(cullResults, shadowLightIndex, BatchCullingProjectionType.Orthographic);

                for (int cascadeIndex = 0; cascadeIndex < m_ShadowCasterCascadesCount; ++cascadeIndex)
                {
                    shadowSettings.splitData = m_CascadeSlices[cascadeIndex].splitData;
                    Vector4 shadowBias = renderingData.shadowData.bias;//ShadowUtils.GetShadowBias(ref shadowLight, shadowLightIndex, ref shadowData, m_CascadeSlices[cascadeIndex].projectionMatrix, m_CascadeSlices[cascadeIndex].resolution);
                    ShadowUtils.SetupShadowCasterConstantBuffer(cmd, ref shadowLight, shadowBias);
                    ShadowUtils.RenderShadowSlice(cmd, ref context, ref m_CascadeSlices[cascadeIndex], ref shadowSettings);
                }

                SetupMainLightShadowReceiverConstants(cmd, ref shadowLight, ref shadowData);

                cmd.SetViewProjectionMatrices(renderingData.cameraData.GetViewMatrix(), renderingData.cameraData.GetProjectionMatrix());
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }

        }

        void SetupMainLightShadowReceiverConstants(CommandBuffer cmd, ref VisibleLight shadowLight, ref ShadowData shadowData)
        {
            int cascadeCount = m_ShadowCasterCascadesCount;
            for (int i = 0; i < cascadeCount; ++i)
                m_MainLightShadowMatrices[i] = m_CascadeSlices[i].shadowTransform;

            // We setup and additional a no-op WorldToShadow matrix in the last index
            // because the ComputeCascadeIndex function in Shadows.hlsl can return an index
            // out of bounds. (position not inside any cascade) and we want to avoid branching
            Matrix4x4 noOpShadowMatrix = Matrix4x4.zero;
            noOpShadowMatrix.m22 = (SystemInfo.usesReversedZBuffer) ? 1.0f : 0.0f;
            for (int i = cascadeCount; i <= k_MaxCascades; ++i)
                m_MainLightShadowMatrices[i] = noOpShadowMatrix;

            cmd.SetGlobalMatrixArray(ShaderIDs.WorldToShadow, m_MainLightShadowMatrices);
            cmd.SetGlobalInt(ShaderIDs.CascadeCount, m_ShadowCasterCascadesCount);
            cmd.SetGlobalVectorArray(ShaderIDs.CascadeShadowSplitSpheres, m_CascadeShadowSplitSpheres);
            cmd.SetGlobalTexture(m_MainLightShadowmapID, m_MainLightShadowmapTexture.nameID);

            ShadowUtils.GetScaleAndBiasForLinearDistanceFade(m_MaxShadowDistanceSq, shadowData.manLightShadowDistanceFade, out float shadowFadeScale, out float shadowFadeBias);

            bool softShadows = shadowLight.light.shadows == LightShadows.Soft && shadowData.supportsSoftShadows;
            float softShadowsProp = softShadows ? 1.0f : 0.0f;
            cmd.SetGlobalVector(ShaderIDs.ShadowParams, new Vector4(shadowLight.light.shadowStrength, softShadowsProp, shadowFadeScale, shadowFadeBias));
        }

        public override void DrawGizmos()
        {
            // Gizmos.color = Color.white;
            // for (int i = 0; i < m_ShadowCasterCascadesCount; i++)
            // {
            //     Vector4 spere = m_CascadeShadowSplitSpheres[i];
            //     Gizmos.DrawWireSphere(spere, spere.w);
            // }
        }

        public void Dispose()
        {
            m_MainLightShadowmapTexture?.Release();
        }
    }
}
