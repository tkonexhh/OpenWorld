using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace OpenWorld.RenderPipelines.Runtime.PostProcessing
{
    public interface IPostProcessComponent
    {
        bool IsActive();
        bool IsTileCompatible();
    }
}
