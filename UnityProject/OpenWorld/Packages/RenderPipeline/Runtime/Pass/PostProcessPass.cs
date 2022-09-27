using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using OpenWorld.RenderPipelines.Runtime.PostProcessing;

namespace OpenWorld.RenderPipelines.Runtime
{
    public abstract class AbstractPostProcessPass : ScriptableRenderPass
    {
        protected abstract string RenderPostProcessingTag { get; }
        List<AbstractVolumeRenderer> m_PostProcessingRenderers = new List<AbstractVolumeRenderer>();

        static RTHandle m_TempRT;
        RTHandle m_Source;

        public AbstractPostProcessPass(RenderPassEvent evt)
        {
            base.renderPassEvent = evt;
            base.profilingSampler = new ProfilingSampler(RenderPostProcessingTag);

        }

        public void Setup(RTHandle handle)
        {
            m_Source = handle;
        }

        protected void AddEffect(AbstractVolumeRenderer renderer)
        {
            m_PostProcessingRenderers.Add(renderer);
            renderer.Init();
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_TempRT == null)
            {
                m_TempRT = RTHandles.Alloc(renderingData.cameraData.cameraTargetDescriptor);
            }
            // 初始化临时RT
            RTHandle buff0 = m_TempRT;
            RTHandle GetSource() => m_Source;
            RTHandle GetTarget() => buff0;

            void Swap() => CoreUtils.Swap<RTHandle>(ref m_Source, ref buff0);

            var cmd = renderingData.commandBuffer;
            int count = 0;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.PostProcessing)))
            {
                foreach (var renderer in m_PostProcessingRenderers)
                {
                    if (renderer.IsActive(ref renderingData))
                    {
                        cmd.BeginSample(renderer.PROFILER_TAG);
                        renderer.Render(cmd, GetSource(), GetTarget(), ref renderingData);
                        Swap();
                        count++;
                        cmd.EndSample(renderer.PROFILER_TAG);
                    }
                }
            }

            if (count > 0 && count % 2 != 0)
            {
                Blit(cmd, GetSource(), GetTarget());
            }


            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }

    }


    public class PostProcessPass : AbstractPostProcessPass
    {
        protected override string RenderPostProcessingTag => "Final PostProcessPass";

        public PostProcessPass(RenderPassEvent evt) : base(evt)
        {
            AddEffect(new BloomRenderer());
        }
    }
}
