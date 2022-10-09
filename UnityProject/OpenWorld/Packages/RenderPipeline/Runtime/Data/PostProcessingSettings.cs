using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [System.Serializable]
    public class PostProcessingSettings
    {
        public ColorLURResolution resolution = ColorLURResolution._32;

        public enum ColorLURResolution
        {
            _16 = 16,
            _32 = 32,
            _64 = 64
        }
    }
}
