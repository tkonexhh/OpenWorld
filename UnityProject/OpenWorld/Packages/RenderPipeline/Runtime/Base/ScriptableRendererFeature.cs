using System;
using UnityEngine;

namespace OpenWorld.RenderPipelines.Runtime
{
    [ExcludeFromPreset]
    public class ScriptableRendererFeature : ScriptableObject, IDisposable
    {

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
        }
    }
}
