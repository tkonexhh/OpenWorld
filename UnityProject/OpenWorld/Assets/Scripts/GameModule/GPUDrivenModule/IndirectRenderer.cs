using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Mathematics;


namespace XHH
{
    /// <summary>
    /// 处理草的LOD 以及 剔除
    /// 然后再下发给下层的InstanceGroup
    /// InstanceGroup 就直接渲染就行了
    /// </summary>
    public class IndirectRenderer
    {
        public string name;//key
        //一种草的全部数据
        private InstanceTRSData[] m_AllTRS = new InstanceTRSData[MAX_COUNT];


        private int m_TRSCount;
        private const int MAX_COUNT = 5000000;
        private IndirectRenderingMesh indirectRenderingMesh;

        //Compute Shader
        private ComputeShader m_CullComputeShader;
        private ComputeShader copyInstanceDataCS;



        //Compute Buffers
        private ComputeBuffer m_InstancesArgsBuffer;
        private ComputeBuffer m_AllInstancesTRSBuffer;//全部数据
        private ComputeBuffer m_VisibleInfoBuffer;//ID lod infos
        private ComputeBuffer m_InstancesIsVisibleBuffer;//可见性
        private ComputeBuffer m_OutputDataBuffer;//最终的输出数据
        private ComputeBuffer m_InsertCountBuffer;


        private ComputeBuffer m_LOD0Buffer;
        private ComputeBuffer m_LOD1Buffer;
        private ComputeBuffer m_LOD2Buffer;


        //other
        private uint[] m_Args;
        private uint[] m_InsertCount = new uint[NUMBER_OF_LOD] { 0, 0, 0 };

        private float m_ShowDistance = 150;//最远距离


        private float m_MinX, m_MinZ, m_MinY, m_MaxY, m_MaxX, m_MaxZ;
        private float m_Expand = 20;
        private Bounds m_RenderBounds;

        private const int KERNAL_CalcCullAndLOD = 0;
        private const int MESH_INDEX = 0;


        // Constants
        private const int NUMBER_OF_LOD = 3; // (LOD00 + LOD01 + LOD02)
        private const int NUMBER_OF_ARGS_PER_DRAW = 5; // (indexCount, instanceCount, startIndex, baseVertex, startInstance)
        private const int NUMBER_OF_ARGS_PER_INSTANCE_TYPE = NUMBER_OF_LOD * NUMBER_OF_ARGS_PER_DRAW; // 3draws * 5args = 15args
        private const int ARGS_BYTE_SIZE_PER_DRAW_CALL = NUMBER_OF_ARGS_PER_DRAW * sizeof(uint); // 5args * 4bytes = 20 bytes


        public IndirectRenderer(string name, IndirectInstanceData instanceData)
        {
            this.name = name;
            indirectRenderingMesh = new IndirectRenderingMesh(instanceData);

            if (m_CullComputeShader == null)
                m_CullComputeShader = Resources.Load("ComputeShader/Grass/HMK_Grass_CalcLODCS") as ComputeShader;
            m_CullComputeShader.SetVector(ShaderConstants.LODDistancePID, new Vector3(m_ShowDistance * 0.25f, m_ShowDistance * 0.5f, m_ShowDistance));


            if (copyInstanceDataCS == null)
                copyInstanceDataCS = Resources.Load("ComputeShader/Grass/HMk_Grass_CopyInstanceDataCS") as ComputeShader;
            copyInstanceDataCS.SetInt("_NumOfDrawcalls", NUMBER_OF_LOD);

        }

        public void AddRangeInstance(List<InstanceTRSData> trs)
        {
            int addCount = trs.Count;

            if (addCount + m_TRSCount >= MAX_COUNT)
            {
                addCount = MAX_COUNT - m_TRSCount;
            }

            if (addCount <= 0)
            {
                return;
            }

            for (int i = 0; i < addCount; ++i)
            {
                m_AllTRS[m_TRSCount++] = trs[i];
            }
        }



        private void InitBuffer()
        {
            if (m_AllInstancesTRSBuffer == null)
                m_AllInstancesTRSBuffer = new ComputeBuffer(MAX_COUNT, sizeof(float) * 5);

            if (m_VisibleInfoBuffer == null)
                m_VisibleInfoBuffer = new ComputeBuffer(MAX_COUNT, sizeof(uint) * 2, ComputeBufferType.Append);

            if (m_InstancesIsVisibleBuffer == null)
                m_InstancesIsVisibleBuffer = new ComputeBuffer(MAX_COUNT, sizeof(uint), ComputeBufferType.Append);


            if (m_InsertCountBuffer == null)
                m_InsertCountBuffer = new ComputeBuffer(NUMBER_OF_LOD, sizeof(uint));


            if (m_OutputDataBuffer == null)
                m_OutputDataBuffer = new ComputeBuffer(MAX_COUNT, sizeof(uint), ComputeBufferType.Append);


            if (m_LOD0Buffer == null)
            {
                m_LOD0Buffer = new ComputeBuffer(MAX_COUNT, sizeof(uint), ComputeBufferType.Append);
                m_LOD1Buffer = new ComputeBuffer(MAX_COUNT, sizeof(uint), ComputeBufferType.Append);
                m_LOD2Buffer = new ComputeBuffer(MAX_COUNT, sizeof(uint), ComputeBufferType.Append);
            }


            if (m_Args == null)
            {
                m_Args = new uint[NUMBER_OF_ARGS_PER_INSTANCE_TYPE];
                int argsIndex = 0;

                // 0 - index count per instance, 
                // 1 - instance count 
                // 2 - start index location
                // 3 - base vertex location
                // 4 - start instance location

                // LOD0
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 0] = indirectRenderingMesh.numOfIndicesLod0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 2] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 4] = 0;

                //LOD1
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 0] = indirectRenderingMesh.numOfIndicesLod1;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 2] = m_Args[argsIndex] + m_Args[argsIndex + 2];
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 4] = 0;

                //LOD2
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 0] = indirectRenderingMesh.numOfIndicesLod2;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 2] = m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1] + m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 2];
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 4] = 0;

                // 0 1 2 3 4
                //其中 argsIndex + 1  argsIndex + 6 argsIndex + 11 需要传入CS中计算最终数量
                //其中 argsIndex + 4  argsIndex + 9 argsIndex + 14 需要传入Draw中计算起始下标 


                m_InstancesArgsBuffer = new ComputeBuffer(NUMBER_OF_ARGS_PER_INSTANCE_TYPE, sizeof(uint), ComputeBufferType.IndirectArguments);
                m_InstancesArgsBuffer.SetData(m_Args);

                indirectRenderingMesh.lod0MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
                indirectRenderingMesh.lod1MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
                indirectRenderingMesh.lod2MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);

                indirectRenderingMesh.lod0MatPropBlock.SetBuffer(ShaderConstants.AllInstancesTransformBuffer, m_AllInstancesTRSBuffer);
                indirectRenderingMesh.lod1MatPropBlock.SetBuffer(ShaderConstants.AllInstancesTransformBuffer, m_AllInstancesTRSBuffer);
                indirectRenderingMesh.lod2MatPropBlock.SetBuffer(ShaderConstants.AllInstancesTransformBuffer, m_AllInstancesTRSBuffer);

                indirectRenderingMesh.lod0MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 4);
                indirectRenderingMesh.lod1MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 4);
                indirectRenderingMesh.lod2MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 4);

            }

        }

        public void CalcCullAndLOD()
        {
            if (m_TRSCount <= 0)
                return;


            InitBuffer();
            //计算包围盒
            CalculateRenderbound();
            //计算可见性
            CalculateVisibleInstances();
        }

        private void CalculateRenderbound()
        {
            m_MinX = float.MaxValue;
            m_MinY = float.MaxValue;
            m_MinZ = float.MaxValue;
            m_MaxX = float.MinValue;
            m_MaxY = float.MinValue;
            m_MaxZ = float.MinValue;

            for (int i = 0; i < m_TRSCount; i++)
            {
                Vector3 target = m_AllTRS[i].position;
                m_MinX = Mathf.Min(target.x, m_MinX);
                m_MinY = Mathf.Min(target.y, m_MinY);
                m_MinZ = Mathf.Min(target.z, m_MinZ);
                m_MaxX = Mathf.Max(target.x, m_MaxX);
                m_MaxY = Mathf.Max(target.y, m_MaxY);
                m_MaxZ = Mathf.Max(target.z, m_MaxZ);
            }

            if (m_RenderBounds == null)
                m_RenderBounds = new Bounds();

            m_RenderBounds.SetMinMax(new Vector3(m_MinX - m_Expand, m_MinY - m_Expand, m_MinZ - m_Expand), new Vector3(m_MaxX + m_Expand, m_MaxY + m_Expand, m_MaxZ + m_Expand));

        }

        private void CalculateVisibleInstances()
        {
            Camera camera = Camera.main;

            // 获取摄像机参数
            Matrix4x4 v = camera.worldToCameraMatrix;
            Matrix4x4 p = camera.projectionMatrix;
            Matrix4x4 vp = p * v;

            m_CullComputeShader.SetMatrix(ShaderConstants.VPMatrixPID, vp);
            m_CullComputeShader.SetVector(ShaderConstants.CenterPosWSPID, camera.transform.position);
            m_CullComputeShader.SetVector(ShaderConstants.LODDistancePID, new Vector3(m_ShowDistance * 0.25f, m_ShowDistance * 0.5f, m_ShowDistance));


            m_VisibleInfoBuffer.SetCounterValue(0);


            m_AllInstancesTRSBuffer.SetData(m_AllTRS, 0, 0, m_TRSCount);

            m_InstancesArgsBuffer.SetData(m_Args);

            m_CullComputeShader.SetMatrix(ShaderConstants.VPMatrixPID, vp);
            m_CullComputeShader.SetBuffer(KERNAL_CalcCullAndLOD, ShaderConstants.AllInstancesTransformBuffer, m_AllInstancesTRSBuffer);
            m_CullComputeShader.SetBuffer(KERNAL_CalcCullAndLOD, ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
            m_CullComputeShader.SetBuffer(KERNAL_CalcCullAndLOD, "_VisibleInfoBuffer", m_VisibleInfoBuffer);
            m_CullComputeShader.SetBuffer(KERNAL_CalcCullAndLOD, "_IsVisibleBuffer", m_InstancesIsVisibleBuffer);

            // int sliceCount = 2000;//TODO 数量待验证
            // int dispatchCount = m_TRSCount / sliceCount;
            // for (int i = 0; i < dispatchCount; i++)
            // {
            //     m_ComputeShader.SetInt(ShaderConstants.StartOffsetPID, sliceCount * i);
            //     m_ComputeShader.Dispatch(KERNAL_CalcCullAndLOD, Mathf.CeilToInt(sliceCount / 64f), 1, 1);
            // }

            int cullGroupX = Mathf.Max(1, Mathf.CeilToInt(m_TRSCount / 64f));
            // int cullGroupX = Mathf.Min(60000, (int)m_TRSCount);
            m_CullComputeShader.Dispatch(KERNAL_CalcCullAndLOD, cullGroupX, 1, 1);



        }


        public void Render()
        {

            //20 =>5*size(uint); 单个args
            Graphics.DrawMeshInstancedIndirect(indirectRenderingMesh.combineMesh, MESH_INDEX, indirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 0, indirectRenderingMesh.lod0MatPropBlock, ShadowCastingMode.Off);
            Graphics.DrawMeshInstancedIndirect(indirectRenderingMesh.combineMesh, MESH_INDEX, indirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 1, indirectRenderingMesh.lod1MatPropBlock, ShadowCastingMode.Off);
            Graphics.DrawMeshInstancedIndirect(indirectRenderingMesh.combineMesh, MESH_INDEX, indirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 2, indirectRenderingMesh.lod2MatPropBlock, ShadowCastingMode.Off);

        }


        public void Destroy()
        {
            ReleaseComputeBuffer();

        }

        private void ReleaseComputeBuffer()
        {
            ReleaseComputeBuffer(ref m_AllInstancesTRSBuffer);
        }

        private static void ReleaseComputeBuffer(ref ComputeBuffer _buffer)
        {
            if (_buffer == null)
            {
                return;
            }

            _buffer.Release();
            _buffer = null;
        }


        private class ShaderConstants
        {
            public static readonly int AllInstancesTransformBuffer = Shader.PropertyToID("_AllInstancesTransformBuffer");
            public static readonly int VisibleInstanceOnlyTransformIDBuffer = Shader.PropertyToID("_VisibleInstanceOnlyTransformIDBuffer");

            public static readonly int LODDistancePID = Shader.PropertyToID("_LODDistance");
            public static readonly int CenterPosWSPID = Shader.PropertyToID("_CenterPos");
            public static readonly int VPMatrixPID = Shader.PropertyToID("_VPMatrix");
            public static readonly int StartOffsetPID = Shader.PropertyToID("_StartOffset");

            public static readonly int ArgsBufferPID = Shader.PropertyToID("_ArgsBuffer");

            //copyInstance
            public static readonly int s = Shader.PropertyToID("");


            //shader
            public static readonly int ArgsOffsetPID = Shader.PropertyToID("_ArgsOffset");


        }

        public struct VisibleInfo
        {
            public uint id;
            public uint lod;
        }

    }

}