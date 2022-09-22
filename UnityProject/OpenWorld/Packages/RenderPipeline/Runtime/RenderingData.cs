using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

namespace OpenWorld.RenderPipelines.Runtime
{
    public struct RenderingData
    {
        public CullingResults cullingResults;
        public CameraData cameraData;
        public ShadowData shadowData;
        public LightData lightData;


        public PerObjectData perObjectData;

        /// <summary>
        /// True if the pipeline supports dynamic batching.
        /// This settings doesn't apply when drawing shadow casters. Dynamic batching is always disabled when drawing shadow casters.
        /// </summary>
        public bool supportsDynamicBatching;


        public CommandBuffer commandBuffer;


    }

    public struct CameraData
    {
        Matrix4x4 m_ViewMatrix;
        Matrix4x4 m_ProjectionMatrix;

        internal void SetViewAndProjectionMatrix(Matrix4x4 viewMatrix, Matrix4x4 projectionMatrix)
        {
            m_ViewMatrix = viewMatrix;
            m_ProjectionMatrix = projectionMatrix;
        }

        /// <summary>
        /// Returns the camera view matrix.
        /// </summary>
        /// <param name="viewIndex"> View index in case of stereo rendering. By default <c>viewIndex</c> is set to 0. </param>
        /// <returns> The camera view matrix. </returns>
        public Matrix4x4 GetViewMatrix()
        {
            return m_ViewMatrix;
        }

        /// <summary>
        /// Returns the camera projection matrix.
        /// </summary>
        /// <param name="viewIndex"> View index in case of stereo rendering. By default <c>viewIndex</c> is set to 0. </param>
        /// <returns> The camera projection matrix. </returns>
        public Matrix4x4 GetProjectionMatrix()
        {
            return m_ProjectionMatrix;
        }

        /// <summary>
        /// Returns the camera GPU projection matrix. This contains platform specific changes to handle y-flip and reverse z.
        /// Similar to <c>GL.GetGPUProjectionMatrix</c> but queries URP internal state to know if the pipeline is rendering to render texture.
        /// For more info on platform differences regarding camera projection check: https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
        /// </summary>
        /// <param name="viewIndex"> View index in case of stereo rendering. By default <c>viewIndex</c> is set to 0. </param>
        /// <seealso cref="GL.GetGPUProjectionMatrix(Matrix4x4, bool)"/>
        /// <returns></returns>
        public Matrix4x4 GetGPUProjectionMatrix()
        {
            return GL.GetGPUProjectionMatrix(GetProjectionMatrix(), false);
        }

        internal Matrix4x4 GetGPUProjectionMatrix(bool renderIntoTexture)
        {
            return GL.GetGPUProjectionMatrix(GetProjectionMatrix(), renderIntoTexture);
        }

        /// <summary>
        /// The camera component.
        /// </summary>
        public Camera camera;
        public CameraType cameraType;
        public ScriptableRenderer renderer;
        public RenderTextureDescriptor cameraTargetDescriptor;
        public float aspectRatio;
        public Vector3 worldSpaceCameraPos;
        public bool postProcessEnabled;


    }

    public struct ShadowData
    {
        public float maxShadowDistance;
        public int mainLightShadowmapWidth;
        public int mainLightShadowmapHeight;
        public int mainLightShadowCascadesCount;
        public Vector3 mainLightShadowCascadesSplit;
        public float manLightShadowDistanceFade;
        public bool supportsSoftShadows;
        public ShadowSettings.FilterMode softShadowsMode;
        // public Vector4 bias;
        public List<Vector4> bias;
    }

    /// <summary>
    /// Struct that holds settings related to lights.
    /// </summary>
    public struct LightData
    {

        public int mainLightIndex;
        public NativeArray<VisibleLight> visibleLights;
        public bool supportsAdditionalLights;
        public int maxPerObjectAdditionalLightsCount;
    }
}
