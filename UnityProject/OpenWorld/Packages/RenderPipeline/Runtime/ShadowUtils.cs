using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public struct ShadowSliceData
    {
        public Matrix4x4 viewMatrix;
        public Matrix4x4 projectionMatrix;
        public Matrix4x4 shadowTransform;//阴影矩阵 给定世界空间位置的阴影纹理坐标
        public ShadowSplitData splitData; // splitData contains culling information

        // offset in cascade shadow
        public int offsetX;
        public int offsetY;
        public int resolution;//single size in cascade shadow map
    }


    public class ShadowUtils
    {

        /// <summary>
        /// Calculates the maximum tile resolution in an Atlas.
        /// </summary>
        /// <param name="atlasWidth"></param>
        /// <param name="atlasHeight"></param>
        /// <param name="tileCount"></param>
        /// <returns>The maximum tile resolution in an Atlas.</returns>
        public static int GetMaxTileResolutionInAtlas(int atlasWidth, int atlasHeight, int tileCount)
        {
            int resolution = Mathf.Min(atlasWidth, atlasHeight);
            int currentTileCount = atlasWidth / resolution * atlasHeight / resolution;
            while (currentTileCount < tileCount)
            {
                resolution = resolution >> 1;
                currentTileCount = atlasWidth / resolution * atlasHeight / resolution;
            }
            return resolution;
        }

        public static RTHandle AllocShadowRT(int width, int height, int bits, string name)
        {
            var rtd = GetTemporaryShadowTextureDescriptor(width, height, bits);
            return RTHandles.Alloc(rtd, FilterMode.Bilinear, TextureWrapMode.Clamp, isShadowMap: true, name: name);
        }

        private static RenderTextureDescriptor GetTemporaryShadowTextureDescriptor(int width, int height, int bits)
        {
            var format = GraphicsFormatUtility.GetDepthStencilFormat(bits, 0);
            RenderTextureDescriptor rtd = new RenderTextureDescriptor(width, height, GraphicsFormat.None, format);
            rtd.shadowSamplingMode = ShadowSamplingMode.CompareDepths;
            return rtd;
        }

        public static bool ExtractDirectionalLightMatrix(ref CullingResults cullResults, ref ShadowData shadowData, int shadowLightIndex, int cascadeIndex, int shadowmapWidth, int shadowmapHeight, int shadowResolution, float shadowNearPlane, out Vector4 cascadeSplitDistance, out ShadowSliceData shadowSliceData)
        {
            //如果要突破4级 级联阴影的话 就需要自行实现下列API 计算额外的VP
            bool success = cullResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(shadowLightIndex, cascadeIndex, shadowData.mainLightShadowCascadesCount, shadowData.mainLightShadowCascadesSplit,
                               shadowResolution, shadowNearPlane, out shadowSliceData.viewMatrix, out shadowSliceData.projectionMatrix, out shadowSliceData.splitData);

            cascadeSplitDistance = shadowSliceData.splitData.cullingSphere;
            //暂时定为2*2 大小的4级级联阴影
            shadowSliceData.offsetX = (cascadeIndex % 2) * shadowResolution;
            shadowSliceData.offsetY = (cascadeIndex / 2) * shadowResolution;
            shadowSliceData.resolution = shadowResolution;
            shadowSliceData.shadowTransform = GetShadowTransform(shadowSliceData.projectionMatrix, shadowSliceData.viewMatrix);

            // If we have shadow cascades baked into the atlas we bake cascade transform
            // in each shadow matrix to save shader ALU and L/S
            if (shadowData.mainLightShadowCascadesCount > 1)
                ApplySliceTransform(ref shadowSliceData, shadowmapWidth, shadowmapHeight);

            return success;
        }


        static Matrix4x4 GetShadowTransform(Matrix4x4 proj, Matrix4x4 view)
        {
            // Currently CullResults ComputeDirectionalShadowMatricesAndCullingPrimitives doesn't
            // apply z reversal to projection matrix. We need to do it manually here.
            if (SystemInfo.usesReversedZBuffer)
            {
                proj.m20 = -proj.m20;
                proj.m21 = -proj.m21;
                proj.m22 = -proj.m22;
                proj.m23 = -proj.m23;
            }

            Matrix4x4 worldToShadow = proj * view;

            var textureScaleAndBias = Matrix4x4.identity;
            textureScaleAndBias.m00 = 0.5f;
            textureScaleAndBias.m11 = 0.5f;
            textureScaleAndBias.m22 = 0.5f;
            textureScaleAndBias.m03 = 0.5f;
            textureScaleAndBias.m13 = 0.5f;
            textureScaleAndBias.m23 = 0.5f;
            // textureScaleAndBias maps texture space coordinates from [-1,1] to [0,1]

            // Apply texture scale and offset to save a MAD in shader.
            return textureScaleAndBias * worldToShadow;
        }

        /// <summary>
        /// Used for baking bake cascade transforms in each shadow matrix.
        /// </summary>
        static void ApplySliceTransform(ref ShadowSliceData shadowSliceData, int shadowmapWidth, int shadowmapHeight)
        {
            Matrix4x4 sliceTransform = Matrix4x4.identity;
            float scaleWidth = 1.0f / shadowmapWidth;
            float scaleHeight = 1.0f / shadowmapHeight;

            sliceTransform.m00 = shadowSliceData.resolution * scaleWidth;
            sliceTransform.m11 = shadowSliceData.resolution * scaleHeight;
            sliceTransform.m03 = shadowSliceData.offsetX * scaleWidth;
            sliceTransform.m13 = shadowSliceData.offsetY * scaleHeight;

            // Apply shadow slice scale and offset
            shadowSliceData.shadowTransform = sliceTransform * shadowSliceData.shadowTransform;
        }

        public static void RenderShadowSlice(CommandBuffer cmd, ref ScriptableRenderContext context, ref ShadowSliceData shadowSliceData, ref ShadowDrawingSettings settings)
        {
            cmd.SetGlobalDepthBias(1.0f, 2.5f); // these values match HDRP defaults (see https://github.com/Unity-Technologies/Graphics/blob/9544b8ed2f98c62803d285096c91b44e9d8cbc47/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowAtlas.cs#L197 )
            cmd.SetViewport(new Rect(shadowSliceData.offsetX, shadowSliceData.offsetY, shadowSliceData.resolution, shadowSliceData.resolution));
            // cmd.EnableScissorRect(new Rect(4, 4, shadowSliceData.resolution - 8, shadowSliceData.resolution - 8));
            cmd.SetViewProjectionMatrices(shadowSliceData.viewMatrix, shadowSliceData.projectionMatrix);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawShadows(ref settings);
            // cmd.DisableScissorRect();
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            cmd.SetGlobalDepthBias(0.0f, 0.0f); // Restore previous depth bias values
        }


        /// <summary>
        /// Extract scale and bias from a fade distance to achieve a linear fading of the fade distance.
        /// </summary>
        /// <param name="fadeDistance">Distance at which object should be totally fade</param>
        /// <param name="border">Normalized distance of fade</param>
        /// <param name="scale">[OUT] Slope of the fading on the fading part</param>
        /// <param name="bias">[OUT] Ordinate of the fading part at abscissa 0</param>
        internal static void GetScaleAndBiasForLinearDistanceFade(float fadeDistance, float border, out float scale, out float bias)
        {
            // To avoid division from zero
            // This values ensure that fade within cascade will be 0 and outside 1
            if (border < 0.0001f)
            {
                float multiplier = 1000f; // To avoid blending if difference is in fractions
                scale = multiplier;
                bias = -fadeDistance * multiplier;
                return;
            }

            border = 1 - border;
            border *= border;

            // Fade with distance calculation is just a linear fade from 90% of fade distance to fade distance. 90% arbitrarily chosen but should work well enough.
            float distanceFadeNear = border * fadeDistance;
            scale = 1.0f / (fadeDistance - distanceFadeNear);
            bias = -distanceFadeNear / (fadeDistance - distanceFadeNear);
        }


        /// <summary>
        /// Sets up the shadow bias, light direction and position for rendering.
        /// </summary>
        /// <param name="cmd"></param>
        /// <param name="shadowLight"></param>
        /// <param name="shadowBias"></param>
        public static void SetupShadowCasterConstantBuffer(CommandBuffer cmd, ref VisibleLight shadowLight, Vector4 shadowBias)
        {
            cmd.SetGlobalVector(ShaderPropertyId.ShadowBias, shadowBias);

            // Light direction is currently used in shadow caster pass to apply shadow normal offset (normal bias).
            Vector3 lightDirection = -shadowLight.localToWorldMatrix.GetColumn(2);
            cmd.SetGlobalVector(ShaderPropertyId.LightDirection, new Vector4(lightDirection.x, lightDirection.y, lightDirection.z, 0.0f));

            // For punctual lights, computing light direction at each vertex position provides more consistent results (shadow shape does not change when "rotating the point light" for example)
            Vector3 lightPosition = shadowLight.localToWorldMatrix.GetColumn(3);
            cmd.SetGlobalVector(ShaderPropertyId.LightPosition, new Vector4(lightPosition.x, lightPosition.y, lightPosition.z, 1.0f));
        }
    }
}
