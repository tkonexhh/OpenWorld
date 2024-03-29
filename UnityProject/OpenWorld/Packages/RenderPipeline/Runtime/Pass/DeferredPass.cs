using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DeferredPass : ScriptableRenderPass
    {
        public DeferredPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(DeferredPass));
            base.renderPassEvent = evt;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
        }
    }
}
