using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{

    public class OpenWorldRenderPipelineRuntimeResources : OpenWorldRenderPipelineResources
    {
        [SerializeField] ShaderResources shaderResources;

        public ShaderResources shaders => shaderResources;
    }
}
