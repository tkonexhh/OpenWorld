using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public struct RenderingData
    {
        public CameraData cameraData;
        public ShadowData shadowData;
        public LightData lightData;

        // /// <summary>
        // /// Holds per-object data that are requested when drawing
        // /// <see cref="PerObjectData"/>
        // /// </summary>
        // public PerObjectData perObjectData;

        /// <summary>
        /// True if the pipeline supports dynamic batching.
        /// This settings doesn't apply when drawing shadow casters. Dynamic batching is always disabled when drawing shadow casters.
        /// </summary>
        public bool supportsDynamicBatching;


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
        // public Matrix4x4 GetGPUProjectionMatrix()
        // {
        //     return GL.GetGPUProjectionMatrix(GetProjectionMatrix(), IsCameraProjectionMatrixFlipped());
        // }

        internal Matrix4x4 GetGPUProjectionMatrix(bool renderIntoTexture)
        {
            return GL.GetGPUProjectionMatrix(GetProjectionMatrix(), renderIntoTexture);
        }

        /// <summary>
        /// The camera component.
        /// </summary>
        public Camera camera;


        /// <summary>
        /// Returns the current renderer used by this camera.
        /// <see cref="ScriptableRenderer"/>
        /// </summary>
        // public ScriptableRenderer renderer;
    }

    public struct ShadowData
    {
    }

    /// <summary>
    /// Struct that holds settings related to lights.
    /// </summary>
    public struct LightData
    {
        /// <summary>
        /// Holds the main light index from the <c>VisibleLight</c> list returned by culling. If there's no main light in the scene, <c>mainLightIndex</c> is set to -1.
        /// The main light is the directional light assigned as Sun source in light settings or the brightest directional light.
        /// <seealso cref="CullingResults"/>
        /// </summary>
        public int mainLightIndex;
    }
}
