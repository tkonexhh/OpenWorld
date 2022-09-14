using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public abstract class DrawObjectPass : ScriptableRenderPass
    {
        protected static readonly List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>
                 {
                    new ShaderTagId("UniversalForward"),
                    new ShaderTagId("OpenWorldForward")
                 };

        // protected abstract RenderQueueRange renderQueueRange;
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) { }
    }
}
