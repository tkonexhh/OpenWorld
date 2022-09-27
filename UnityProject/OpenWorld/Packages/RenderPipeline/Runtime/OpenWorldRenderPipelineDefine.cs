using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace OpenWorld.RenderPipelines.Runtime
{
    internal enum ProfileId
    {
        DepthPrepass,
        MainLightShadow,
        DrawOpaqueObjects,
        DrawSkybox,
        DrawTransparentObjects,
        PostProcessing,
    }


    public static class ShaderKeywordStrings
    {
        public static readonly string MainLightShadows = "_MAIN_LIGHT_SHADOWS";
    }

    internal static class ShaderPropertyId
    {
        public static readonly int projectionParams = Shader.PropertyToID("_ProjectionParams");
        public static readonly int zBufferParams = Shader.PropertyToID("_ZBufferParams");
        public static readonly int worldSpaceCameraPos = Shader.PropertyToID("_WorldSpaceCameraPos");
        public static readonly int cameraProjectionMatrix = Shader.PropertyToID("unity_CameraProjection");
        public static readonly int inverseCameraProjectionMatrix = Shader.PropertyToID("unity_CameraInvProjection");
        public static readonly int worldToCameraMatrix = Shader.PropertyToID("unity_WorldToCamera");
        public static readonly int cameraToWorldMatrix = Shader.PropertyToID("unity_CameraToWorld");

        public static readonly int ShadowBias = Shader.PropertyToID("_ShadowBias");// x: depth bias, y: normal bias
        public static readonly int LightDirection = Shader.PropertyToID("_LightDirection");
        public static readonly int LightPosition = Shader.PropertyToID("_LightPosition");
    }

    internal static class ShaderTextureId
    {
        public static readonly string OpacityTexture = "_CameraOpaqueTexture";
        public static readonly string CamearColorTexture = "_CameraColorTexture";
        public static readonly string CameraDepthTexture = "_CameraDepthTexture";

    }
}
