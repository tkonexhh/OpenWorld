using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [CreateAssetMenu(menuName = "Rendering/OpenWorld Render Pipeline")]
    public class OpenWorldRenderPipelineAsset : RenderPipelineAsset
    {
        [SerializeField] GeneralSettings generalSettings = default;
        [SerializeField] ShadowSettings shadowSettings = default;
        [SerializeField] LightingSettings lightingSettings = default;
        [SerializeField] PostProcessingSettings postProcessingSettings = default;
        [SerializeField] ShaderResources shaderResources;

        public GeneralSettings GeneralSettings => generalSettings;
        public ShadowSettings ShadowSettings => shadowSettings;
        public LightingSettings LightingSettings => lightingSettings;
        public PostProcessingSettings PostProcessingSettings => postProcessingSettings;
        public ShaderResources ShaderResources => shaderResources;

        public bool UseSRPBatcher => generalSettings.useSRPBatcher;

        protected override RenderPipeline CreatePipeline()
        {
            return new OpenWorldRenderPipeline(this);
        }
    }
}
