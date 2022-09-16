using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [System.Serializable]
    public class ShadowSettings
    {
        [Min(0.001f)] public float maxDistance = 100f;

        public Directional directional = new Directional
        {
            resolution = ShadowResolution._2048,
            filter = FilterMode.PCF2x2,
            cascadeCount = 4,
            cascadeRatio1 = 0.1f,
            cascadeRatio2 = 0.25f,
            cascadeRatio3 = 0.5f,
        };


        [System.Serializable]
        public struct Directional
        {
            public ShadowResolution resolution;
            public FilterMode filter;
            [Range(1, 4)] public int cascadeCount;
            [Range(0f, 1f)]
            public float cascadeRatio1, cascadeRatio2, cascadeRatio3;


            public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);
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

        public enum FilterMode
        {
            PCF2x2,
            PCF3x3,
            PCF5x5,
            PCF7x7,
        }
    }
}
