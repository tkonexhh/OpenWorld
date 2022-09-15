using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using Unity.Collections;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class ForwardLights
    {
        static class ShaderIDs
        {
            public static readonly int MainLightPosition = Shader.PropertyToID("_MainLightPosition");
            public static readonly int MainLightColor = Shader.PropertyToID("_MainLightColor");
            public static readonly int AdditionalLightCount = Shader.PropertyToID("_AdditionalLightsCount");
            public static readonly int AdditionalLightsPosition = Shader.PropertyToID("_AdditionalLightsPosition");
            public static readonly int AdditionalLightsColor = Shader.PropertyToID("_AdditionalLightsColor");
        }

        Vector4[] m_AdditionalLightPositions;
        Vector4[] m_AdditionalLightColors;

        const int MAX_ADDITIONAL_LIGHT_COUNT = 16;//must math input.hlsl  MAX_VISIBLE_LIGHTS

        public void Setup(ref RenderingData renderingData)
        {
            var visibleLights = renderingData.cullResults.visibleLights;
            renderingData.lightData.mainLightIndex = GetMainLightIndex(visibleLights);
            SetupMainLight(renderingData.commandBuffer, ref renderingData.lightData);

            m_AdditionalLightPositions = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];
            m_AdditionalLightColors = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];
        }

        void SetupMainLight(CommandBuffer cmd, ref LightData lightData)
        {

            Light mainLight = RenderSettings.sun;
            cmd.SetGlobalVector(ShaderIDs.MainLightPosition, -mainLight.transform.forward);
            cmd.SetGlobalColor(ShaderIDs.MainLightColor, mainLight.color.linear * mainLight.intensity);
        }

        int GetMainLightIndex(NativeArray<VisibleLight> visibleLights)
        {
            return 0;
        }
    }
}
