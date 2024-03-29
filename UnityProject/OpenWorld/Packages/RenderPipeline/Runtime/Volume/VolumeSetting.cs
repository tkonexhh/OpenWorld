using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    [Serializable]
    public abstract class VolumeSetting : VolumeComponent, IPostProcessComponent
    {
        public abstract bool IsActive();
        public virtual bool IsTileCompatible() => false;
        //面板上打钩是回复到默认值的意思 
        //需要默认就关闭效果 强度为0
    }
}
