using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System;

namespace OpenWorld.RenderPipelines.Runtime
{


    public sealed partial class OpenWorldRenderPipeline
    {
        static List<Vector4> m_ShadowBiasData = new List<Vector4>();


        public static bool IsGameCamera(Camera camera)
        {
            if (camera == null)
                throw new ArgumentNullException("camera");

            return camera.cameraType == CameraType.Game || camera.cameraType == CameraType.VR;
        }

        /// <summary>
        /// Returns the current render pipeline asset for the current quality setting.
        /// If no render pipeline asset is assigned in QualitySettings, then returns the one assigned in GraphicsSettings.
        /// </summary>
        public static OpenWorldRenderPipelineAsset asset => GraphicsSettings.currentRenderPipeline as OpenWorldRenderPipelineAsset;


        // internal static GraphicsFormat MakeRenderTextureGraphicsFormat(bool isHdrEnabled, HDRColorBufferPrecision requestHDRColorBufferPrecision, bool needsAlpha)
        // {
        //     if (isHdrEnabled)
        //     {
        //         // TODO: we need a proper format scoring system. Score formats, sort, pick first or pick first supported (if not in score).
        //         if (!needsAlpha && requestHDRColorBufferPrecision != HDRColorBufferPrecision._64Bits && RenderingUtils.SupportsGraphicsFormat(GraphicsFormat.B10G11R11_UFloatPack32, FormatUsage.Linear | FormatUsage.Render))
        //             return GraphicsFormat.B10G11R11_UFloatPack32;
        //         if (RenderingUtils.SupportsGraphicsFormat(GraphicsFormat.R16G16B16A16_SFloat, FormatUsage.Linear | FormatUsage.Render))
        //             return GraphicsFormat.R16G16B16A16_SFloat;
        //         return SystemInfo.GetGraphicsFormat(DefaultFormat.HDR); // This might actually be a LDR format on old devices.
        //     }

        //     return SystemInfo.GetGraphicsFormat(DefaultFormat.LDR);
        // }

        static RenderTextureDescriptor CreateRenderTextureDescriptor(Camera camera, float renderScale, bool isHdrEnabled, int msaaSamples, bool needsAlpha, bool requiresOpaqueTexture)
        {
            int scaledWidth = (int)((float)camera.pixelWidth * renderScale);
            int scaledHeight = (int)((float)camera.pixelHeight * renderScale);

            RenderTextureDescriptor desc;

            if (camera.targetTexture == null)
            {
                desc = new RenderTextureDescriptor(camera.pixelWidth, camera.pixelHeight);
                desc.width = scaledWidth;
                desc.height = scaledHeight;
                desc.graphicsFormat = isHdrEnabled ? SystemInfo.GetGraphicsFormat(DefaultFormat.HDR) : SystemInfo.GetGraphicsFormat(DefaultFormat.LDR);// MakeRenderTextureGraphicsFormat(isHdrEnabled, requestHDRColorBufferPrecision, needsAlpha);
                desc.depthBufferBits = 32;
                desc.msaaSamples = msaaSamples;
                desc.sRGB = (QualitySettings.activeColorSpace == ColorSpace.Linear);
            }
            else
            {
                desc = camera.targetTexture.descriptor;
                desc.width = scaledWidth;
                desc.height = scaledHeight;

                if (camera.cameraType == CameraType.SceneView && !isHdrEnabled)
                {
                    desc.graphicsFormat = SystemInfo.GetGraphicsFormat(DefaultFormat.LDR);
                }
                // SystemInfo.SupportsRenderTextureFormat(camera.targetTexture.descriptor.colorFormat)
                // will assert on R8_SINT since it isn't a valid value of RenderTextureFormat.
                // If this is fixed then we can implement debug statement to the user explaining why some
                // RenderTextureFormats available resolves in a black render texture when no warning or error
                // is given.
            }

            // Make sure dimension is non zero
            desc.width = Mathf.Max(1, desc.width);
            desc.height = Mathf.Max(1, desc.height);

            desc.enableRandomWrite = false;
            desc.bindMS = false;
            desc.useDynamicScale = camera.allowDynamicResolution;

            // The way RenderTextures handle MSAA fallback when an unsupported sample count of 2 is requested (falling back to numSamples = 1), differs fom the way
            // the fallback is handled when setting up the Vulkan swapchain (rounding up numSamples to 4, if supported). This caused an issue on Mali GPUs which don't support
            // 2x MSAA.
            // The following code makes sure that on Vulkan the MSAA unsupported fallback behaviour is consistent between RenderTextures and Swapchain.
            // TODO: we should review how all backends handle MSAA fallbacks and move these implementation details in engine code.
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Vulkan)
            {
                // if the requested number of samples is 2, and the supported value is 1x, it means that 2x is unsupported on this GPU.
                // Then we bump up the requested value to 4.
                if (desc.msaaSamples == 2 && SystemInfo.GetRenderTextureSupportedMSAASampleCount(desc) == 1)
                    desc.msaaSamples = 4;
            }

            // check that the requested MSAA samples count is supported by the current platform. If it's not supported,
            // replace the requested desc.msaaSamples value with the actual value the engine falls back to
            desc.msaaSamples = SystemInfo.GetRenderTextureSupportedMSAASampleCount(desc);

            // if the target platform doesn't support storing multisampled RTs and we are doing a separate opaque pass, using a Load load action on the subsequent passes
            // will result in loading Resolved data, which on some platforms is discarded, resulting in losing the results of the previous passes.
            // As a workaround we disable MSAA to make sure that the results of previous passes are stored. (fix for Case 1247423).
            if (!SystemInfo.supportsStoreAndResolveAction && requiresOpaqueTexture)
                desc.msaaSamples = 1;

            return desc;
        }
    }

}
