using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{

    public class Profiling
    {
        private static Dictionary<int, ProfilingSampler> s_HashSamplerCache = new Dictionary<int, ProfilingSampler>();

        public static ProfilingSampler TryGetOrAddCameraSampler(Camera camera)
        {

            ProfilingSampler ps = null;
            int cameraId = camera.GetHashCode();
            bool exists = s_HashSamplerCache.TryGetValue(cameraId, out ps);
            if (!exists)
            {
                // NOTE: camera.name allocates!
                ps = new ProfilingSampler($"{camera.name}");
                // ps = new ProfilingSampler($"{nameof(OpenWorldRenderPipeline)}: {camera.name}");
                s_HashSamplerCache.Add(cameraId, ps);
            }
            return ps;

        }
    }
}
