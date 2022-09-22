using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace OpenWorld.RenderPipelines.Runtime
{
    public struct PostProcessPasses : IDisposable
    {
        PostProcessPass m_FinalPostProcessPass;


        public PostProcessPass finalPostProcessPass { get => m_FinalPostProcessPass; }

        public PostProcessPasses(bool s)
        {
            m_FinalPostProcessPass = new PostProcessPass(RenderPassEvent.AfterRenderingPostProcessing);
        }

        public void Dispose()
        {
        }
    }
}
