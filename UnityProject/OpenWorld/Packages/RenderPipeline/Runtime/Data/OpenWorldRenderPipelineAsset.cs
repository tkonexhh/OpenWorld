using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime
{
    [CreateAssetMenu(menuName = "Rendering/OpenWorld Render Pipeline")]
    public class OpenWorldRenderPipelineAsset : RenderPipelineAsset
    {

        [SerializeField] ShadowSettings shadowSettings = default;
        [SerializeField] LightingSettings lightingSettings = default;
        [SerializeField] bool useSRPBatcher = true;

        [SerializeField] ShaderResources shaderResources;

        public ShadowSettings ShadowSettings => shadowSettings;
        public LightingSettings LightingSettings => lightingSettings;
        public ShaderResources ShaderResources => shaderResources;

        public bool UseSRPBatcher => useSRPBatcher;

        protected override RenderPipeline CreatePipeline()
        {
            return new OpenWorldRenderPipeline(this);
        }
    }
}
