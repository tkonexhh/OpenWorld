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
        [SerializeField] bool useSRPBatcher = true;

        public ShadowSettings ShadowSettings => shadowSettings;
        public bool UseSRPBatcher => useSRPBatcher;

        protected override RenderPipeline CreatePipeline()
        {
            return new OpenWorldRenderPipeline(this);
        }
    }
}
