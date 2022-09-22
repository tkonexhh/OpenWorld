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
            public static readonly int AdditionalLightsSpotDir = Shader.PropertyToID("_AdditionalLightsSpotDir");
            public static readonly int AdditionalLightsAttenuation = Shader.PropertyToID("_AdditionalLightsAttenuation");
        }

        Vector4[] m_AdditionalLightPositions;
        Vector4[] m_AdditionalLightColors;
        Vector4[] m_AdditionalLightAttenuations;
        Vector4[] m_AdditionalLightSpotDirections;

        bool m_UseStructuredBuffer;//是否使用SSBO来传输灯光信息
        const int MAX_ADDITIONAL_LIGHT_COUNT = 16;//must math input.hlsl  MAX_VISIBLE_LIGHTS

        static Vector4 k_DefaultLightPosition = new Vector4(0.0f, 0.0f, 1.0f, 0.0f);
        static Vector4 k_DefaultLightColor = Color.black;
        static Vector4 k_DefaultLightAttenuation = new Vector4(0.0f, 1.0f, 0.0f, 1.0f);
        static Vector4 k_DefaultLightSpotDirection = new Vector4(0.0f, 0.0f, 1.0f, 0.0f);

        public void Setup(ref RenderingData renderingData)
        {
            m_AdditionalLightPositions = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];
            m_AdditionalLightColors = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];
            m_AdditionalLightAttenuations = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];
            m_AdditionalLightSpotDirections = new Vector4[MAX_ADDITIONAL_LIGHT_COUNT];

            var visibleLights = renderingData.lightData.visibleLights;
            renderingData.lightData.mainLightIndex = GetMainLightIndex(visibleLights);

            SetupShaderLightConstants(renderingData.commandBuffer, ref renderingData);
        }

        int GetMainLightIndex(NativeArray<VisibleLight> visibleLights)
        {
            float brightestLightIntensity = 0.0f;
            int brightestDirectionalLightIndex = -1;
            for (int i = 0; i < visibleLights.Length; i++)
            {
                VisibleLight currMainLight = visibleLights[i];
                Light currLight = currMainLight.light;

                if (currLight.type != LightType.Directional)
                    continue;

                if (currLight == null)
                    break;
                //sun is main light for sure
                if (currLight == RenderSettings.sun)
                {
                    return i;
                }
                //In case no sun light is present we will return the brightest directional light
                if (currLight.intensity > brightestLightIntensity)
                {
                    brightestLightIntensity = currLight.intensity;
                    brightestDirectionalLightIndex = i;
                }
            }
            return brightestDirectionalLightIndex;
        }

        void SetupShaderLightConstants(CommandBuffer cmd, ref RenderingData renderingData)
        {
            SetupMainLightConstants(cmd, ref renderingData.lightData);
            SetupAdditionalLightConstants(cmd, ref renderingData);
        }

        void SetupMainLightConstants(CommandBuffer cmd, ref LightData lightData)
        {
            if (lightData.mainLightIndex == -1)
            {
                cmd.SetGlobalColor(ShaderIDs.MainLightColor, Color.black);
                return;
            }
            var mainLight = lightData.visibleLights[lightData.mainLightIndex];
            var light = mainLight.light;

            cmd.SetGlobalVector(ShaderIDs.MainLightPosition, -light.transform.forward);
            cmd.SetGlobalColor(ShaderIDs.MainLightColor, light.color.linear * light.intensity);
        }

        void SetupAdditionalLightConstants(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var lights = renderingData.lightData.visibleLights;
            int additionalLightCount = SetupPerObjectLightIndices(renderingData.cullingResults, ref renderingData.lightData);
            int maxAdditionalLightCount = MAX_ADDITIONAL_LIGHT_COUNT;
            if (additionalLightCount > 0)
            {
                int lightIter = 0;
                for (int i = 0; i < lights.Length; i++)
                {
                    if (i == renderingData.lightData.mainLightIndex)
                        continue;

                    var visibleLight = lights[i];
                    if (lightIter >= maxAdditionalLightCount)
                        break;

                    InitAdditionalLightConstants(lightIter++, ref visibleLight);
                }
            }

            cmd.SetGlobalVector(ShaderIDs.AdditionalLightCount, new Vector4(additionalLightCount, 0, 0, 0));
            cmd.SetGlobalVectorArray(ShaderIDs.AdditionalLightsPosition, m_AdditionalLightPositions);
            cmd.SetGlobalVectorArray(ShaderIDs.AdditionalLightsColor, m_AdditionalLightColors);
            cmd.SetGlobalVectorArray(ShaderIDs.AdditionalLightsAttenuation, m_AdditionalLightAttenuations);
            cmd.SetGlobalVectorArray(ShaderIDs.AdditionalLightsSpotDir, m_AdditionalLightSpotDirections);
        }

        //返回分配到额外光源数量
        int SetupPerObjectLightIndices(CullingResults cullResults, ref LightData lightData)
        {
            if (!lightData.supportsAdditionalLights)
                return 0;

            var perObjectLightIndexMap = cullResults.GetLightIndexMap(Allocator.Temp);

            int globalDirectionalLightsCount = 0;
            int additionalLightsCount = 0;
            int maxVisibleAdditionalLightsCount = MAX_ADDITIONAL_LIGHT_COUNT;
            int len = lightData.visibleLights.Length;

            // Disable all directional lights from the perobject light indices
            // Pipeline handles main light globally and there's no support for additional directional lights atm.
            for (int i = 0; i < len; ++i)
            {
                if (additionalLightsCount >= maxVisibleAdditionalLightsCount)
                    break;

                if (i == lightData.mainLightIndex)
                {
                    perObjectLightIndexMap[i] = -1;
                    ++globalDirectionalLightsCount;
                }
                else
                {
                    perObjectLightIndexMap[i] -= globalDirectionalLightsCount;
                    ++additionalLightsCount;
                }
            }

            // Disable all remaining lights we cannot fit into the global light buffer.
            for (int i = globalDirectionalLightsCount + additionalLightsCount; i < perObjectLightIndexMap.Length; ++i)
                perObjectLightIndexMap[i] = -1;

            cullResults.SetLightIndexMap(perObjectLightIndexMap);

            perObjectLightIndexMap.Dispose();

            return additionalLightsCount;
        }


        internal static void GetPunctualLightDistanceAttenuation(float lightRange, ref Vector4 lightAttenuation)
        {
            // Light attenuation in universal matches the unity vanilla one (HINT_NICE_QUALITY).
            // attenuation = 1.0 / distanceToLightSqr
            // The smoothing factor makes sure that the light intensity is zero at the light range limit.
            // (We used to offer two different smoothing factors.)

            // The current smoothing factor matches the one used in the Unity lightmapper.
            // smoothFactor = (1.0 - saturate((distanceSqr * 1.0 / lightRangeSqr)^2))^2
            float lightRangeSqr = lightRange * lightRange;
            float fadeStartDistanceSqr = 0.8f * 0.8f * lightRangeSqr;
            float fadeRangeSqr = (fadeStartDistanceSqr - lightRangeSqr);
            float lightRangeSqrOverFadeRangeSqr = -lightRangeSqr / fadeRangeSqr;
            float oneOverLightRangeSqr = 1.0f / Mathf.Max(0.0001f, lightRangeSqr);

            // On all devices: Use the smoothing factor that matches the GI.
            lightAttenuation.x = oneOverLightRangeSqr;
            lightAttenuation.y = lightRangeSqrOverFadeRangeSqr;
        }

        internal static void GetSpotAngleAttenuation(float spotAngle, float innerSpotAngle, ref Vector4 lightAttenuation)
        {
            // Spot Attenuation with a linear falloff can be defined as
            // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
            // This can be rewritten as
            // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
            // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
            // If we precompute the terms in a MAD instruction
            float cosOuterAngle = Mathf.Cos(Mathf.Deg2Rad * spotAngle * 0.5f);
            // We need to do a null check for particle lights
            // This should be changed in the future
            // Particle lights will use an inline function
            float cosInnerAngle = Mathf.Cos(innerSpotAngle * Mathf.Deg2Rad * 0.5f);
            // if (innerSpotAngle.HasValue)
            //     cosInnerAngle = Mathf.Cos(innerSpotAngle.Value * Mathf.Deg2Rad * 0.5f);
            // else
            //     cosInnerAngle = Mathf.Cos((2.0f * Mathf.Atan(Mathf.Tan(spotAngle * 0.5f * Mathf.Deg2Rad) * (64.0f - 18.0f) / 64.0f)) * 0.5f);
            float smoothAngleRange = Mathf.Max(0.001f, cosInnerAngle - cosOuterAngle);
            float invAngleRange = 1.0f / smoothAngleRange;
            float add = -cosOuterAngle * invAngleRange;

            lightAttenuation.z = invAngleRange;
            lightAttenuation.w = add;
        }

        internal static void GetSpotDirection(ref Matrix4x4 lightLocalToWorldMatrix, out Vector4 lightSpotDir)
        {
            Vector4 dir = lightLocalToWorldMatrix.GetColumn(2);
            lightSpotDir = new Vector4(-dir.x, -dir.y, -dir.z, 0.0f);
        }

        void InitAdditionalLightConstants(int lightIndex, ref VisibleLight visibleLight)
        {
            Vector4 lightPos = k_DefaultLightPosition;
            Vector4 lightColor = k_DefaultLightColor;
            Vector4 lightAttenuation = k_DefaultLightAttenuation;
            Vector4 lightSpotDir = k_DefaultLightSpotDirection;

            var light = visibleLight.light;
            var lightLocalToWorld = visibleLight.localToWorldMatrix;
            var lightType = visibleLight.lightType;
            if (lightType == LightType.Directional)
            {
                Vector4 dir = -lightLocalToWorld.GetColumn(2);
                lightPos = new Vector4(dir.x, dir.y, dir.z, 0.0f);
            }
            else
            {
                Vector4 pos = lightLocalToWorld.GetColumn(3);
                lightPos = new Vector4(pos.x, pos.y, pos.z, 1.0f);

                GetPunctualLightDistanceAttenuation(visibleLight.range, ref lightAttenuation);

                if (lightType == LightType.Spot)
                {
                    GetSpotAngleAttenuation(visibleLight.spotAngle, light.innerSpotAngle, ref lightAttenuation);
                    GetSpotDirection(ref lightLocalToWorld, out lightSpotDir);
                }
            }
            lightColor = visibleLight.finalColor;

            m_AdditionalLightPositions[lightIndex] = lightPos;
            m_AdditionalLightColors[lightIndex] = lightColor;
            m_AdditionalLightAttenuations[lightIndex] = lightAttenuation;
            m_AdditionalLightSpotDirections[lightIndex] = lightSpotDir;
        }


    }
}
