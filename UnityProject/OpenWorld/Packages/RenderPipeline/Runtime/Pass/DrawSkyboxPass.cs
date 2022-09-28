using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    public class DrawSkyboxPass : ScriptableRenderPass
    {

        public DrawSkyboxPass(RenderPassEvent evt)
        {
            base.profilingSampler = new ProfilingSampler(nameof(DrawSkyboxPass));
            base.renderPassEvent = evt;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;
            using (new ProfilingScope(cmd, ProfilingSampler.Get(ProfileId.DrawSkybox)))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                ref CameraData cameraData = ref renderingData.cameraData;
                Camera camera = cameraData.camera;
                context.DrawSkybox(camera);
            }
        }
    }
}
