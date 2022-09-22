using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [VolumeComponentMenu(VolumeDefine.Environment + Bloom.title)]
    public class Bloom : VolumeSetting
    {
        public const string title = "泛光 (Bloom)";

        public Bloom()
        {
            this.displayName = title;
        }


        public override bool IsActive() => Intensity.value > 0;
        public MinFloatParameter Intensity = new MinFloatParameter(0f, 0f);
        public ClampedFloatParameter Threshold = new ClampedFloatParameter(0.2f, 0f, 10f);
    }
}
