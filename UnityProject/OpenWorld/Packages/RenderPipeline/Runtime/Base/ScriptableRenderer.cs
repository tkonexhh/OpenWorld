using System;
using System.Diagnostics;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
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
            // SetPerCameraShaderVariables(cmd, ref renderingData.cameraData, true);
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


        }

        public void FinishRendering(ref RenderingData renderingData)
        {
            m_ActiveRenderPassQueue.Clear();
        }


        internal void ConfigureCameraColorTarget(RTHandle colorTarget)
        {
            m_CameraColorTexture = colorTarget;
        }

        void SetPerCameraShaderVariables(CommandBuffer cmd, ref CameraData cameraData, bool isTargetFlipped)
        {
            Camera camera = cameraData.camera;

            float scaledCameraWidth = (float)cameraData.cameraTargetDescriptor.width;
            float scaledCameraHeight = (float)cameraData.cameraTargetDescriptor.height;
            float cameraWidth = (float)camera.pixelWidth;
            float cameraHeight = (float)camera.pixelHeight;


            // Camera and Screen variables as described in https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
            cmd.SetGlobalVector(ShaderPropertyId.worldSpaceCameraPos, cameraData.worldSpaceCameraPos);

            //Set per camera matrices.
            SetCameraMatrices(cmd, ref cameraData, true, isTargetFlipped);
        }

        internal static void SetCameraMatrices(CommandBuffer cmd, ref CameraData cameraData, bool setInverseMatrices, bool isTargetFlipped)
        {
            Matrix4x4 viewMatrix = cameraData.GetViewMatrix();
            Matrix4x4 projectionMatrix = cameraData.GetProjectionMatrix();

            // TODO: Investigate why SetViewAndProjectionMatrices is causing y-flip / winding order issue
            // for now using cmd.SetViewProjecionMatrices
            //SetViewAndProjectionMatrices(cmd, viewMatrix, cameraData.GetDeviceProjectionMatrix(), setInverseMatrices);
            cmd.SetViewProjectionMatrices(viewMatrix, projectionMatrix);

            if (setInverseMatrices)
            {
                Matrix4x4 gpuProjectionMatrix = cameraData.GetGPUProjectionMatrix(isTargetFlipped);
                Matrix4x4 viewAndProjectionMatrix = gpuProjectionMatrix * viewMatrix;
                Matrix4x4 inverseViewMatrix = Matrix4x4.Inverse(viewMatrix);
                Matrix4x4 inverseProjectionMatrix = Matrix4x4.Inverse(gpuProjectionMatrix);
                Matrix4x4 inverseViewProjection = inverseViewMatrix * inverseProjectionMatrix;

                // There's an inconsistency in handedness between unity_matrixV and unity_WorldToCamera
                // Unity changes the handedness of unity_WorldToCamera (see Camera::CalculateMatrixShaderProps)
                // we will also change it here to avoid breaking existing shaders. (case 1257518)
                Matrix4x4 worldToCameraMatrix = Matrix4x4.Scale(new Vector3(1.0f, 1.0f, -1.0f)) * viewMatrix;
                Matrix4x4 cameraToWorldMatrix = worldToCameraMatrix.inverse;
                cmd.SetGlobalMatrix(ShaderPropertyId.worldToCameraMatrix, worldToCameraMatrix);
                cmd.SetGlobalMatrix(ShaderPropertyId.cameraToWorldMatrix, cameraToWorldMatrix);

                // cmd.SetGlobalMatrix(ShaderPropertyId.inverseViewMatrix, inverseViewMatrix);
                // cmd.SetGlobalMatrix(ShaderPropertyId.inverseProjectionMatrix, inverseProjectionMatrix);
                // cmd.SetGlobalMatrix(ShaderPropertyId.inverseViewAndProjectionMatrix, inverseViewProjection);
            }

            // TODO: Add SetPerCameraClippingPlaneProperties here once we are sure it correctly behaves in overlay camera for some time
        }

        public virtual void DrawGizmos() { }


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
