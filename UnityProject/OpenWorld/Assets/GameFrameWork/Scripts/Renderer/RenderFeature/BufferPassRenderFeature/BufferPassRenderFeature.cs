// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using UnityEngine.Rendering;
// using UnityEngine.Rendering.Universal;

// namespace OpenWorld
// {
//     public class BufferPassRenderFeature : ScriptableRendererFeature
//     {
//         [System.Serializable]
//         public class Settings
//         {
//             public BufferType bufferType = BufferType.Depth;
//             public float arg = 1;
//         }


//         public enum BufferType
//         {
//             Depth,
//             WorldNormal,
//         }

//         public Settings settings = new Settings();

//         private BufferRenderPass m_BufferRenderPass;

//         public override void Create()
//         {
//             var material = new Material(Shader.Find("HMK/RenderFeature/ShowBuffer"));
//             m_BufferRenderPass = new BufferRenderPass(name, material, settings);
//             m_BufferRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
//             m_BufferRenderPass.passIndex = (int)settings.bufferType;
//         }

//         public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
//         {
//             m_BufferRenderPass.Setup(renderer.cameraColorTarget, RenderTargetHandle.CameraTarget);
//             renderer.EnqueuePass(m_BufferRenderPass);
//         }



//         class BufferRenderPass : ScriptableRenderPass
//         {
//             private Material m_BlitMat;
//             public int passIndex;

//             private RenderTargetIdentifier source { get; set; }
//             private RenderTargetHandle dest { get; set; }
//             private string m_ProfilerTag;
//             RenderTargetHandle m_TempTexture;

//             private Settings m_Setting;


//             public BufferRenderPass(string name, Material material, Settings settings)
//             {
//                 m_Setting = settings;
//                 m_BlitMat = material;
//                 m_ProfilerTag = name;
//                 m_TempTexture.Init("_TempTexture");
//             }

//             public void Setup(RenderTargetIdentifier source, RenderTargetHandle dest)
//             {
//                 this.source = source;
//                 this.dest = dest;
//             }

//             public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
//             {
//                 CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);

//                 RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
//                 opaqueDesc.depthBufferBits = 0;
//                 m_BlitMat.SetFloat(ShaderConstants.Args, m_Setting.arg);
//                 cmd.GetTemporaryRT(m_TempTexture.id, opaqueDesc, FilterMode.Bilinear);
//                 cmd.Blit(source, m_TempTexture.Identifier(), m_BlitMat, passIndex);
//                 cmd.Blit(m_TempTexture.Identifier(), source);
//                 context.ExecuteCommandBuffer(cmd);
//                 CommandBufferPool.Release(cmd);
//             }

//             private class ShaderConstants
//             {
//                 public static readonly int Args = Shader.PropertyToID("_Args");
//             }
//         }
//     }
// }

