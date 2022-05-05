using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Unity.Mathematics;
using GrassPainter;

// [CreateAssetMenu(menuName = "GrassPainter/GrassBlockDataSO", fileName = "GrassBlockDataSO")]
public class GrassBlockDataSO : SerializedScriptableObject
{
    public uint2 pos;
    public GrassBlockData grassBlockData;
}

[System.Serializable]
public struct GrassBlockData
{
    public GrassClusterData[] clusterDatas;
}

[System.Serializable]
public struct GrassClusterData
{
    public string key;

    public string meshName;
    public string matName;
    public string indirectMatName;

    public GrassTRS[] instanceDatas;
}

//TODO等待删除 替换为
[System.Serializable]
public struct GrassTRS
{
    public Vector3 position;
    public float rotateY;
    public float scale;

    public float GetRotationY()
    {
        return rotateY;
        // return ((float)rotateY / (float)byte.MaxValue) * 360f;
    }
}