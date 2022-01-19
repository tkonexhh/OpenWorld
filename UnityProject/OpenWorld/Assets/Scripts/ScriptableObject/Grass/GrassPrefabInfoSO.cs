using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Unity.Mathematics;

namespace XHH
{
    [CreateAssetMenu(menuName = "ScriptableObject/GrassPrefabInfoSO", fileName = "GrassPrefabInfoSO")]
    public class GrassPrefabInfoSO : SerializedScriptableObject
    {
        public Dictionary<byte, GrassPrefabInfo> prefabInfoMap = new Dictionary<byte, GrassPrefabInfo>();

        public byte GetIdByPath(string resPath)
        {
            foreach (var item in prefabInfoMap)
            {
                if (item.Value.resPath.Equals(resPath))
                {
                    return item.Key;
                }
            }


            throw new System.NullReferenceException(resPath + " 不在GrassPrefabInfo");
        }


        public GrassPrefabInfo GetGrassPrefabInfo(byte id)
        {
            if (prefabInfoMap.ContainsKey(id))
            {
                return prefabInfoMap[id];
            }

            throw new System.NullReferenceException(id + "not find in GrassPrefabInfoSO");
        }
    }

    [System.Serializable]
    public struct GrassPrefabInfo
    {
        [LabelText("资源路径")] public string resPath;
        [LabelText("包围盒size")] public float3 extents;
        [LabelText("绘制信息")] public IndirectDrawSO indirectDrawSO;
    }
}