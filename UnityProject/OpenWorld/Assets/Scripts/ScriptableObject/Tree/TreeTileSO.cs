using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Unity.Mathematics;


namespace XHH
{


    [CreateAssetMenu(menuName = "ScriptableObject/TreeTileSO", fileName = "TreeTileSO")]
    public class TreeTileSO : SerializedScriptableObject
    {
        public TreeTileData tileData;

#if UNITY_EDITOR
        [Button("Clear")]
        public void Clear()
        {
            tileData.treeInstanceDatas = null;
        }

        [Button("Save")]
        public void Save()
        {
            UnityEditor.EditorUtility.SetDirty(this);
            UnityEditor.AssetDatabase.SaveAssets();
            UnityEditor.AssetDatabase.Refresh();
        }

#endif
    }


    [System.Serializable]
    public struct TreeTileData
    {
        public int2 tileID;
        public float3 center;
        public TreeInstanceData[] treeInstanceDatas;
    }

    [System.Serializable]
    public struct TreeInstanceData
    {
        public byte type;//类型
        public float3 position;
        public float3 rotation;
        public float scale;

        public static TreeInstanceData CreateInstanceData(Transform tree)
        {
            TreeInstanceData data = new TreeInstanceData();

            Vector3 scale = tree.localScale;
            data.scale = Mathf.Max(scale.x, Mathf.Max(scale.y, scale.z));
            data.rotation = tree.rotation.eulerAngles;
            Vector3 deltaPos = tree.position;
            data.position = new float3(deltaPos.x, deltaPos.y, deltaPos.z);

            return data;
        }
    }

}