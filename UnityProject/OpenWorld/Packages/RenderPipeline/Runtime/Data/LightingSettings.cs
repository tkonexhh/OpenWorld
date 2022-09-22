using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [System.Serializable]
    public class LightingSettings
    {
        public bool enableAdditionalLighting;
        [Range(1, 4)] public int additionalLightsCount;
    }
}
