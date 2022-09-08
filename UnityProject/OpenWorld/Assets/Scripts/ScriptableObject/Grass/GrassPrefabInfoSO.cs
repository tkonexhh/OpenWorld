using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Unity.Mathematics;

namespace OpenWorld
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

        public void AddGrassPrefabInfo(byte id, GrassPrefabInfo grassPrefabInfo)
        {
            if (HasPrefabInfo(id))
            {
                prefabInfoMap[id] = grassPrefabInfo;
            }
            else
            {
                prefabInfoMap.Add(id, grassPrefabInfo);
            }
        }

        public bool HasPrefabInfo(byte id)
        {
            return prefabInfoMap.ContainsKey(id);
        }

        //=============
        private static GrassPrefabInfoSO s_Instance = null;
        private static GrassPrefabInfoSO LoadInstance()
        {
            Object obj = Resources.Load("ScriptableObject/Grass/GrassPrefabInfoSO");
            if (obj == null)
            {
                Debug.LogError("Not Found GrassPrefabInfoSO");
                return null;
            }

            s_Instance = obj as GrassPrefabInfoSO;
            return s_Instance;
        }

        public static GrassPrefabInfoSO S
        {
            get
            {
                if (s_Instance == null)
                    s_Instance = LoadInstance();

                return s_Instance;
            }
        }
        //=============
    }

    [System.Serializable]
    public struct GrassPrefabInfo
    {
        [LabelText("资源路径")] public string resPath;
        [LabelText("原始包围盒")] public Bounds bounds;
        public Mesh mesh;
        public Material instanceMaterial;
        public Material indirectMaterial;
    }
}