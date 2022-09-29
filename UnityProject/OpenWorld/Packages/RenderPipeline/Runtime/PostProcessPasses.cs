using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public struct PostProcessPasses : IDisposable
    {
        // PostProcessPass m_BeforeTransparentPostProcessPass;
        PostProcessPass m_FinalPostProcessPass;

        public PostProcessPass finalPostProcessPass { get => m_FinalPostProcessPass; }

        public PostProcessPasses(bool s)
        {
            // m_BeforeTransparentPostProcessPass = new PostProcessPass(RenderPassEvent.AfterRenderingOpaques);
            m_FinalPostProcessPass = new PostProcessPass(RenderPassEvent.AfterRendering);
        }

        public void Setup(RTHandle handle)
        {
            finalPostProcessPass.Setup(handle);
        }

        public void Dispose()
        {
            m_FinalPostProcessPass?.Dispose();
        }
    }
}
