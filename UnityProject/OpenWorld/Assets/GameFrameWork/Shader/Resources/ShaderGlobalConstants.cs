using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace HMK
{
    /// <summary>
    /// Shader 全局环境
    /// </summary>
    public class ShaderGlobalConstants
    {

        //Environment 环境相关
        //====植被交互相关
        public static readonly int InteractivesCount = Shader.PropertyToID("_InteractivesCount");
        public static readonly int Interactives = Shader.PropertyToID("_Interactives");

        //GI 全局光照相关
        public static readonly string GIVolumeTex0ID = "_GIVolumeTex0";
        public static readonly string GIVolumeTex1ID = "_GIVolumeTex1";
        public static readonly string GIVolumePosID = "_GIVolumePosition";
        public static readonly string GIVolumeWorldSizeID = "_GIVolumeWorldSize";


        //==== 全局阴影
        public static readonly string GlobalShadowColorID = "_GlobalShadowColor";

        //===
        public static readonly string PlayerPos = "_PlayerPosition";
    }

}