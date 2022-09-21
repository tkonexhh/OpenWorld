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

        int m_ShadowCasterCascadesCount;
        int m_MainLightShadowmapID;

        int renderTargetWidth, renderTargetHeight;

        Matrix4x4[] m_MainLightShadowMatrices;
        ShadowSliceData[] m_CascadeSlices;
        Vector4[] m_CascadeShadowSplitSpheres;
        Vector4[] m_CascadeDatas;

        internal RTHandle m_MainLightShadowmapTexture;

        FilteringSettings m_FilteringSettings;


        static class ShaderIDs
        {
            public static readonly string MainLightShadowmapTexture = "_MainLightShadowmapTexture";
            public static readonly int WorldToShadow = Shader.PropertyToID("_MainLightWorldToShadow");
            public static readonly int ShadowParams = Shader.PropertyToID("_MainLightShadowParams");
            public static readonly int ShadowmapSize = Shader.PropertyToID("_MainLightShadowmapSize");
            public static readonly int CascadeCount = Shader.PropertyToID("_MainLightCascadeCount");
            public static readonly int CascadeShadowSplitSpheres = Shader.PropertyToID("_CascadeShadowSplitSpheres");
            public static readonly int CascadeDatas = Shader.PropertyToID("_CascadeDatas");
        }


        public MainLightShadowCasterPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(MainLightShadowCasterPass));

            m_MainLightShadowMatrices = new Matrix4x4[k_MaxCascades + 1];
            m_CascadeSlices = new ShadowSliceData[k_MaxCascades];
            m_CascadeShadowSplitSpheres = new Vector4[k_MaxCascades];
            m_CascadeDatas = new Vector4[k_MaxCascades];

            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            m_MainLightShadowmapID = Shader.PropertyToID(ShaderIDs.MainLightShadowmapTexture);
        }

        public bool Setup(ref RenderingData renderingData)
        {
            int shadowLightIndex = renderingData.lightData.mainLightIndex;
            if (shadowLightIndex == -1)
                return false;

            VisibleLight shadowLight = renderingData.cullingResults.visibleLights[shadowLightIndex];
            Light light = shadowLight.light;
            if (light.shadows == LightShadows.None || light.shadowStrength <= 0)
                return false;

            if (shadowLight.lightType != LightType.Directional)
            {
                Debug.LogWarning("Only directional lights are supported as main light.");
                return false;
            }

            Bounds bounds;
            if (!renderingData.cullingResults.GetShadowCasterBounds(shadowLightIndex, out bounds))
                return false;

            m_ShadowCasterCascadesCount = renderingData.shadowData.mainLightShadowCascadesCount;

            renderTargetWidth = renderingData.shadowData.mainLightShadowmapWidth;
            renderTargetHeight = renderingData.shadowData.mainLightShadowmapHeight;
            int shadowResolution = ShadowUtils.GetMaxTileResolutionInAtlas(renderTargetWidth, renderTargetHeight, m_ShadowCasterCascadesCount);

            //找出与灯光方向匹配的视图和投影矩阵，并为提供一个剪辑空间立方体
            for (int cascadeIndex = 0; cascadeIndex < m_ShadowCasterCascadesCount; ++cascadeIndex)
            {
                bool success = ShadowUtils.ExtractDirectionalLightMatrix(ref renderingData.cullingResults, ref renderingData.shadowData, shadowLightIndex, cascadeIndex, renderTargetWidth, renderTargetHeight, shadowResolution, light.shadowNearPlane, out m_CascadeShadowSplitSpheres[cascadeIndex], out m_CascadeSlices[cascadeIndex], out m_CascadeDatas[cascadeIndex]);

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

            var cullResults = renderingData.cullingResults;
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
                    Vector4 shadowBias = renderingData.shadowData.bias[shadowLightIndex];//ShadowUtils.GetShadowBias(ref shadowLight, shadowLightIndex, ref shadowData, m_CascadeSlices[cascadeIndex].projectionMatrix, m_CascadeSlices[cascadeIndex].resolution);
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
            cmd.SetGlobalVectorArray(ShaderIDs.CascadeDatas, m_CascadeDatas);
            cmd.SetGlobalTexture(m_MainLightShadowmapID, m_MainLightShadowmapTexture.nameID);


            var maxShadowDistanceSq = shadowData.maxShadowDistance * shadowData.maxShadowDistance;
            ShadowUtils.GetScaleAndBiasForLinearDistanceFade(maxShadowDistanceSq, shadowData.manLightShadowDistanceFade, out float shadowFadeScale, out float shadowFadeBias);

            bool softShadows = shadowLight.light.shadows == LightShadows.Soft && shadowData.supportsSoftShadows;
            float softShadowsProp = softShadows ? 1.0f : 0.0f;
            softShadowsProp *= 1 + (int)shadowData.softShadowsMode;
            cmd.SetGlobalVector(ShaderIDs.ShadowParams, new Vector4(shadowLight.light.shadowStrength, softShadowsProp, shadowFadeScale, shadowFadeBias));


            // Inside shader soft shadows are controlled through global keyword.
            // If any additional light has soft shadows it will force soft shadows on main light too.
            // As it is not trivial finding out which additional light has soft shadows, we will pass main light properties if soft shadows are supported.
            // This workaround will be removed once we will support soft shadows per light.
            if (shadowData.supportsSoftShadows)
            {
                float invShadowAtlasWidth = 1.0f / renderTargetWidth;
                float invShadowAtlasHeight = 1.0f / renderTargetHeight;

                cmd.SetGlobalVector(ShaderIDs.ShadowmapSize, new Vector4(invShadowAtlasWidth, invShadowAtlasHeight, renderTargetWidth, renderTargetHeight));
            }
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
