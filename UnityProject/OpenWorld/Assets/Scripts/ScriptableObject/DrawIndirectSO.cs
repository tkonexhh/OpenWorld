using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

[CreateAssetMenu(menuName = "ScriptableObject/DrawIndirectSO", fileName = "new DrawIndirectSO")]
public class DrawIndirectSO : SerializedScriptableObject
{
    public Mesh mesh;
    public Material material;
}


public struct InstanceTRSData
{
    public Vector3 position;
    public Vector3 rotation;
    public Vector3 scale;
}
