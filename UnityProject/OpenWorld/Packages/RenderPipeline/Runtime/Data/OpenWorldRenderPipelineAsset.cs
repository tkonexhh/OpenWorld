using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{

    public class OpenWorldRenderPipelineAsset : RenderPipelineAsset
    {
        [SerializeField] GeneralSettings generalSettings = default;
        [SerializeField] PhyscialCameraSettings physcialCameraSettings = default;
        // [SerializeField] QualitySetting qualitySetting = default;
        [SerializeField] ShadowSettings shadowSettings = default;
        [SerializeField] LightingSettings lightingSettings = default;
        [SerializeField] PostProcessingSettings postProcessingSettings = default;
        [SerializeField] OpenWorldRenderPipelineRuntimeResources runtimeResources;

        public GeneralSettings GeneralSettings => generalSettings;
        public PhyscialCameraSettings PhyscialCameraSettings => physcialCameraSettings;
        public ShadowSettings ShadowSettings => shadowSettings;
        public LightingSettings LightingSettings => lightingSettings;
        public PostProcessingSettings PostProcessingSettings => postProcessingSettings;
        public OpenWorldRenderPipelineRuntimeResources resources => runtimeResources;

        public bool UseSRPBatcher => generalSettings.useSRPBatcher;

        protected override RenderPipeline CreatePipeline()
        {
            return new OpenWorldRenderPipeline(this);
        }
    }
}
