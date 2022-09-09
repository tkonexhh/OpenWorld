using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [CreateAssetMenu(menuName = "Rendering/OpenWorld Render Pipeline")]
    public class OpenWorldRenderPipelineAsset : RenderPipelineAsset
    {
        /// <summary>
        /// The elements in this enum define how Unity renders shadows.
        /// </summary>
        public enum ShadowQuality
        {
            /// <summary>
            /// Disables the shadows.
            /// </summary>
            Disabled,
            /// <summary>
            /// Shadows have hard edges.
            /// </summary>
            HardShadows,
            /// <summary>
            /// Filtering is applied when sampling shadows. Shadows have smooth edges.
            /// </summary>
            SoftShadows,
        }

        /// <summary>
        /// This controls the size of the shadow map texture.
        /// </summary>
        public enum ShadowResolution
        {
            /// <summary>
            /// Use this for 256x256 shadow resolution.
            /// </summary>
            _256 = 256,

            /// <summary>
            /// Use this for 512x512 shadow resolution.
            /// </summary>
            _512 = 512,

            /// <summary>
            /// Use this for 1024x1024 shadow resolution.
            /// </summary>
            _1024 = 1024,

            /// <summary>
            /// Use this for 2048x2048 shadow resolution.
            /// </summary>
            _2048 = 2048,

            /// <summary>
            /// Use this for 4096x4096 shadow resolution.
            /// </summary>
            _4096 = 4096
        }

        [SerializeField] ShadowResolution m_MainLightShadowmapResolution = ShadowResolution._2048;



        public int mainLightShadowmapResolution
        {
            get { return (int)m_MainLightShadowmapResolution; }
            internal set { m_MainLightShadowmapResolution = (ShadowResolution)value; }
        }

        protected override RenderPipeline CreatePipeline()
        {
            return new OpenWorldRenderPipeline(this);
        }
    }
}
