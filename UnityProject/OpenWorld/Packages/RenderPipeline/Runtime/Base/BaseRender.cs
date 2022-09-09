using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public abstract class BaseRender
    {
        List<ScriptableRenderPass> m_ActiveRenderPassQueue = new List<ScriptableRenderPass>(32);

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
            for (int i = 0; i < m_ActiveRenderPassQueue.Count; i++)
            {
                m_ActiveRenderPassQueue[i].Execute(context, ref renderingData);
            }

            m_ActiveRenderPassQueue.Clear();
        }


    }
}
