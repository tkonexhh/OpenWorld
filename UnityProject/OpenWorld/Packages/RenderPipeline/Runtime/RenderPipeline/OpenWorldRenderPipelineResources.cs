using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class OpenWorldRenderPipelineResources : RenderPipelineResources
    {
        protected override string packagePath => PipelineUtils.GetRenderPipelinePath();
    }
}
