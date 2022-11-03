using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [Serializable]
    public sealed class ShaderResources
    {
        [Reload("Shaders/Utils/CoreBlit.shader"), SerializeField]
        internal Shader coreBlitPS;
        [Reload("Shaders/Utils/CoreBlitColorAndDepth.shader"), SerializeField]
        internal Shader coreBlitColorAndDepthPS;

        // Post-processing
        public ComputeShader exposureCS;

    }
}
