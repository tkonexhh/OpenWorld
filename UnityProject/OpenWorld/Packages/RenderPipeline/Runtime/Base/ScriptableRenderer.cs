using System;
using System.Diagnostics;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Experimental.Rendering.RenderGraphModule;
using UnityEngine.Profiling;

namespace OpenWorld.RenderPipelines.Runtime
{
    public abstract class ScriptableRenderer : IDisposable
    {
        List<ScriptableRenderPass> m_ActiveRenderPassQueue = new List<ScriptableRenderPass>(32);
        List<ScriptableRendererFeature> m_RendererFeatures = new List<ScriptableRendererFeature>(10);

        bool m_IsPipelineExecuting = false;

        RTHandle m_CameraColorTexture;


        public RTHandle cameraColorTargetHandle
        {
            get
            {
                if (!m_IsPipelineExecuting)
                {
                    UnityEngine.Debug.LogError("You can only call cameraColorTarget inside the scope of a ScriptableRenderPass. Otherwise the pipeline camera target texture might have not been created or might have already been disposed.");
                    return null;
                }

                return m_CameraColorTexture;
            }
        }


        /// <summary>
        /// Enqueues a render pass for execution.
        /// </summary>
        /// <param name="pass">Render pass to be enqueued.</param>
        public void EnqueuePass(ScriptableRenderPass pass)
        {
            m_ActiveRenderPassQueue.Add(pass);
        }

        public abstract void Setup(ScriptableRenderContext context, ref RenderingData renderingData);

        public void Render(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            m_IsPipelineExecuting = true;

            var cmd = renderingData.commandBuffer;
            foreach (var pass in m_ActiveRenderPassQueue)
                pass.Configure(cmd);

            foreach (var pass in m_ActiveRenderPassQueue)
            {
                using (new ProfilingScope(cmd, pass.profilingSampler))
                {
                    if (pass.colorAttachmentHandle != null)
                        CoreUtils.SetRenderTarget(cmd, pass.colorAttachmentHandle, RenderBufferLoadAction.DontCare, pass.colorStoreAction);
                    CoreUtils.ClearRenderTarget(cmd, pass.clearFlag, pass.clearColor);
                    pass.Execute(context, ref renderingData);
                }
            }

            m_ActiveRenderPassQueue.Clear();
        }


        internal void ConfigureCameraColorTarget(RTHandle colorTarget)
        {
            m_CameraColorTexture = colorTarget;
        }


        public void Dispose()
        {
            // Dispose all renderer features...
            for (int i = 0; i < m_RendererFeatures.Count; ++i)
            {
                if (m_RendererFeatures[i] == null)
                    continue;

                m_RendererFeatures[i].Dispose();
            }

            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
        }
    }
}
