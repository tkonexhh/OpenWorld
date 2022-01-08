using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawIndirect
{
    public Mesh mesh { get; private set; }
    public Material instanceMaterial { get; private set; }

    private ComputeBuffer argsBuffer;
    private ComputeBuffer allInstancesDataBuffer;
    private List<InstanceData> allInstaneDataList;

    private const int MESH_INDEX = 0;

    public int drawCount = 100;


    public DrawIndirect(Mesh mesh, Material material)
    {
        this.mesh = mesh;
        this.instanceMaterial = material;
        allInstaneDataList = new List<InstanceData>();
    }

    public void AddInstanceData(InstanceData instanceData)
    {
        allInstaneDataList.Add(instanceData);
        OnDrawNumChanged();
    }

    private void OnDrawNumChanged()
    {
        InitArgsBuffer();
        UpdateBuffer();
    }

    private void InitArgsBuffer()
    {
        if (argsBuffer != null)
        {
            argsBuffer.Release();
        }

        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        args[0] = (uint)mesh.GetIndexCount(MESH_INDEX);
        args[1] = (uint)allInstaneDataList.Count;
        args[2] = (uint)mesh.GetIndexStart(MESH_INDEX);
        args[3] = (uint)mesh.GetBaseVertex(0);
        args[4] = 0;

        argsBuffer.SetData(args);
    }


    private void UpdateBuffer()
    {
        if (instanceMaterial == null)
        {
            return;
        }

        if (allInstancesDataBuffer != null)
            allInstancesDataBuffer.Release();
        allInstancesDataBuffer = new ComputeBuffer(allInstaneDataList.Count, sizeof(float) * 9); //3 个Vector3

        InstanceData[] instanceDatas = new InstanceData[allInstaneDataList.Count];
        for (int i = 0; i < instanceDatas.Length; i++)
        {
            instanceDatas[i] = allInstaneDataList[i];
        }
        allInstancesDataBuffer.SetData(instanceDatas);

        instanceMaterial.SetBuffer(ShaderConstants._AllInstancesDataBufferPID, allInstancesDataBuffer);
    }

    public void Render()
    {
        if (instanceMaterial == null || mesh == null)
        {

            return;
        }

        Bounds renderBound = new Bounds();
        renderBound.SetMinMax(Vector3.one * -1000, Vector3.one * 1000);
        Graphics.DrawMeshInstancedIndirect(mesh, MESH_INDEX, instanceMaterial, renderBound, argsBuffer);
    }

    public void Destroy()
    {
        if (allInstancesDataBuffer != null)
            allInstancesDataBuffer.Release();
        allInstancesDataBuffer = null;

        if (argsBuffer != null)
            argsBuffer.Release();
        argsBuffer = null;
    }


    private class ShaderConstants
    {
        public static int _AllInstancesDataBufferPID = Shader.PropertyToID("_AllInstancesDataBuffer");
    }

}
