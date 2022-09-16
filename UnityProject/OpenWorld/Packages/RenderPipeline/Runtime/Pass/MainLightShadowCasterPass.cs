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

        int renderTargetWidth;
        int renderTargetHeight;

        Vector4[] m_CascadeSplitDistances;
        ShadowSliceData[] m_CascadeSlices;

        internal RTHandle m_MainLightShadowmapTexture;

        FilteringSettings m_FilteringSettings;


        public MainLightShadowCasterPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(MainLightShadowCasterPass));

            m_CascadeSlices = new ShadowSliceData[k_MaxCascades];
            m_CascadeSplitDistances = new Vector4[k_MaxCascades];

            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            m_MainLightShadowmapID = Shader.PropertyToID("_MainLightShadowmapTexture");
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

            renderTargetWidth = renderingData.shadowData.mainLightShadowmapWidth;
            renderTargetHeight = renderingData.shadowData.mainLightShadowmapHeight;
            int shadowResolution = ShadowUtils.GetMaxTileResolutionInAtlas(renderTargetWidth, renderTargetHeight, m_ShadowCasterCascadesCount);

            //找出与灯光方向匹配的视图和投影矩阵，并为提供一个剪辑空间立方体
            for (int cascadeIndex = 0; cascadeIndex < m_ShadowCasterCascadesCount; ++cascadeIndex)
            {
                bool success = ShadowUtils.ExtractDirectionalLightMatrix(ref renderingData.cullResults, ref renderingData.shadowData, shadowLightIndex, cascadeIndex, renderTargetWidth, renderTargetHeight, shadowResolution, light.shadowNearPlane, out m_CascadeSlices[cascadeIndex]);

                if (!success)
                    return false;
            }

            if (m_MainLightShadowmapTexture == null)
            {
                m_MainLightShadowmapTexture = ShadowUtils.AllocShadowRT(renderTargetWidth, renderTargetHeight, k_ShadowmapBufferBits, "_MainLightShadowmapTexture");
                Debug.LogError("Create New Shadowmap");
            }

            return true;
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

            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.MainLightShadow)))
            {
                CoreUtils.SetRenderTarget(cmd, m_MainLightShadowmapTexture, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                cmd.ClearRenderTarget(true, false, Color.clear);

                var shadowSettings = new ShadowDrawingSettings(cullResults, shadowLightIndex, BatchCullingProjectionType.Orthographic);

                for (int cascadeIndex = 0; cascadeIndex < m_ShadowCasterCascadesCount; ++cascadeIndex)
                // int cascadeIndex = 2;
                {
                    shadowSettings.splitData = m_CascadeSlices[cascadeIndex].splitData;
                    ShadowUtils.RenderShadowSlice(cmd, ref context, ref m_CascadeSlices[cascadeIndex], ref shadowSettings);
                }
            }

        }

        public void Dispose()
        {
            m_MainLightShadowmapTexture?.Release();
        }
    }
}
