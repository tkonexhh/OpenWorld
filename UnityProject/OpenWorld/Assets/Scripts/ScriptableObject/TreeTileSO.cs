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
        public TreeTileData treeTileData;
    }





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
        public half3 position;
        public float3 rotation;
        public float scale;
    }

}