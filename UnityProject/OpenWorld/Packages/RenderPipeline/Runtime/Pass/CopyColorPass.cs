using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class CopyColorPass : ScriptableRenderPass
    {
        public CopyColorPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(CopyColorPass));
            base.renderPassEvent = evt;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
        }
    }
}
