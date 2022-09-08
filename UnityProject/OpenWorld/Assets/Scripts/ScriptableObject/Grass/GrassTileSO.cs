using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Unity.Mathematics;

namespace OpenWorld
{
    [CreateAssetMenu(menuName = "ScriptableObject/GrassTileSO", fileName = "GrassTileSO_")]
    public class GrassTileSO : SerializedScriptableObject
    {
        public GrassTileData tileData;

#if UNITY_EDITOR
        [Button("Clear")]
        public void Clear()
        {
            tileData.groupDatas = null;
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
    public struct GrassTileData
    {
        public int2 tileID;
        public float3 center;
        public GrassGroupData[] groupDatas;
    }

    [System.Serializable]
    public struct GrassGroupData
    {
        public byte type;//类型
        public GrassInstanceData[] instanceDatas;
    }

    [System.Serializable]
    public struct GrassInstanceData
    {
        public float3 position;//half暂时序列化不出来
        public byte rotation;
        public float scale;


        public static GrassInstanceData CreateGrassInstanceData(Transform grass, Transform root)
        {
            GrassInstanceData data = new GrassInstanceData();

            Vector3 scale = grass.localScale;
            data.scale = Mathf.Max(scale.x, Mathf.Max(scale.y, scale.z));
            data.rotation = (byte)(grass.rotation.eulerAngles.y / 255);
            Vector3 deltaPos = grass.position - root.position;
            data.position = new float3(deltaPos.x, deltaPos.y, deltaPos.z);

            return data;
        }

    }





}