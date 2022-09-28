using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace OpenWorld.RenderPipelines.Runtime
{
    [System.Serializable]
    public class GeneralSettings
    {
        public bool requireDepthTexture = false;
        [Range(0.1f, 2f)] public float renderScale = 1;
        public bool allowHDR;
        public bool useSRPBatcher = true;
    }
}
