using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Mathematics;

namespace XHH
{

    // Preferrably want to have all buffer structs in power of 2...
    // 6 * 4 bytes = 24 bytes
    [System.Serializable]
    public struct IndirectInstanceCSInput
    {
        public Vector3 boundsCenter;       // 3
        public Vector3 boundsExtents;      // 6
    };


    public struct InstanceTRS
    {
        public float3 position;
        public float3 rotation;
        public float3 scale;
    }


    /// <summary>
    /// 处理草的LOD 以及 剔除
    /// 然后再下发给下层的InstanceGroup
    /// InstanceGroup 就直接渲染就行了
    /// </summary>
    public class IndirectRenderer
    {
        public string name;//key

        ///----------------------
        ///数据
        ///----------------------
        private List<IndirectInstanceCSInput> instancesInputData = new List<IndirectInstanceCSInput>();
        private List<InstanceTRS> instancesInputTRS = new List<InstanceTRS>();



        private IndirectRenderingMesh m_IndirectRenderingMesh;


        ///----------------------
        /// ComputeShader
        ///----------------------
        private ComputeShader m_CullCS;
        private ComputeShader m_CalcIndexOffsetCS;


        ///----------------------
        /// Compute Buffer
        ///----------------------

        //Cull
        private ComputeBuffer m_InstanceDataBuffer;
        private ComputeBuffer m_InstancesArgsBuffer;
        private ComputeBuffer m_VisibleInfoBuffer;//可见ID LOD
        //CalcIndexOffset
        private ComputeBuffer m_InsertCountBuffer;//已经插入的数量
        private ComputeBuffer m_OutputDataBuffer;//最终的输出数据

        private ComputeBuffer m_InstanceTRSBuffer;//全部数据



        //other
        private int m_InstancesCount = 0;
        private uint[] m_Args;

        private float m_ShowDistance = 10;//最远距离

        private Bounds m_RenderBounds;

        private int KERNAL_CalcCullAndLOD;//m_CullComputeShader
        private int KERNAL_CalcIndexOffset;
        private int m_CullingGroupX;



        private Matrix4x4 m_VPMatrix;

        // Constants
        private const int NUMBER_OF_LOD = 3; // (LOD00 + LOD01 + LOD02)
        private const int NUMBER_OF_ARGS_PER_DRAW = 5; // (indexCount, instanceCount, startIndex, baseVertex, startInstance)
        private const int NUMBER_OF_ARGS_PER_INSTANCE_TYPE = NUMBER_OF_LOD * NUMBER_OF_ARGS_PER_DRAW; // 3draws * 5args = 15args
        private const int ARGS_BYTE_SIZE_PER_DRAW_CALL = NUMBER_OF_ARGS_PER_DRAW * sizeof(uint); // 5args * 4bytes = 20 bytes
        private const int MESH_INDEX = 0;


        public IndirectRenderer(string name, GrassIndirectInstanceData instanceData)
        {
            this.name = name;

            if (m_CullCS == null)
                m_CullCS = Resources.Load("Shader/ComputeShader/XHH_GPUDriven_Culling") as ComputeShader;
            Vector4 lodDistance = new Vector3(m_ShowDistance * 0.25f, m_ShowDistance * 0.5f, m_ShowDistance);
            // Debug.LogError("lodDistance" + lodDistance);
            m_CullCS.SetVector(ShaderConstants.LODDistancePID, lodDistance);

            m_CalcIndexOffsetCS = Resources.Load("Shader/ComputeShader/XHH_GPUDriven_CalcIndexOffsetCS") as ComputeShader;

            InitBuffer(instanceData);
        }


        private bool TryGetKernels()
        {
            return TryGetKernel("CSMain", ref m_CullCS, ref KERNAL_CalcCullAndLOD) &&
                    TryGetKernel("CalcIndexOffsetCS", ref m_CalcIndexOffsetCS, ref KERNAL_CalcIndexOffset);

        }

        private void InitBuffer(GrassIndirectInstanceData instanceData)
        {
            if (!TryGetKernels())
            {
                return;
            }

            m_IndirectRenderingMesh = new IndirectRenderingMesh(instanceData);

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
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 0] = m_IndirectRenderingMesh.numOfIndicesLod0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 2] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 4] = 0;

                //LOD1
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 0] = m_IndirectRenderingMesh.numOfIndicesLod1;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 2] = m_Args[argsIndex] + m_Args[argsIndex + 2];
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 4] = 0;

                //LOD2
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 0] = m_IndirectRenderingMesh.numOfIndicesLod2;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 1] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 2] = m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1] + m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 2];
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 3] = 0;
                m_Args[argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 4] = 0;

                // 0 1 2 3 4
                //其中 argsIndex + 1  argsIndex + 6 argsIndex + 11 需要传入CS中计算最终数量
                //其中 argsIndex + 4  argsIndex + 9 argsIndex + 14 需要传入Draw中计算起始下标 


                Bounds originalBounds = m_IndirectRenderingMesh.bounds;

                for (int i = 0; i < instanceData.itemsTRS.Length; i++)
                {
                    Vector3 position = instanceData.itemsTRS[i].position;
                    Vector3 scale = new float3(instanceData.itemsTRS[i].scale, instanceData.itemsTRS[i].scale, instanceData.itemsTRS[i].scale);
                    Vector3 rotation = new float3(0, instanceData.itemsTRS[i].rotation / 360.0f, 0);

                    Bounds b = new Bounds();
                    b.center = position;
                    Vector3 s = originalBounds.size;
                    s.Scale(scale);
                    b.size = s;

                    //这个还没有考虑旋转对包围盒的影响
                    instancesInputData.Add(new IndirectInstanceCSInput()
                    {
                        boundsCenter = b.center,
                        boundsExtents = b.extents
                    });


                    instancesInputTRS.Add(new InstanceTRS()
                    {
                        position = position,
                        rotation = rotation,
                        scale = scale
                    });

                    m_InstancesCount++;
                }

                OnInstancesCountChange();

                m_InstancesArgsBuffer = new ComputeBuffer(NUMBER_OF_ARGS_PER_INSTANCE_TYPE, sizeof(uint), ComputeBufferType.IndirectArguments);
                m_InstancesArgsBuffer.SetData(m_Args);


                m_InsertCountBuffer = new ComputeBuffer(NUMBER_OF_LOD, sizeof(uint));

                m_IndirectRenderingMesh.lod0MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
                m_IndirectRenderingMesh.lod1MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
                m_IndirectRenderingMesh.lod2MatPropBlock.SetBuffer(ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);

                m_IndirectRenderingMesh.lod0MatPropBlock.SetBuffer(ShaderConstants.InstanceTRSBufferPID, m_InstanceTRSBuffer);
                m_IndirectRenderingMesh.lod1MatPropBlock.SetBuffer(ShaderConstants.InstanceTRSBufferPID, m_InstanceTRSBuffer);
                m_IndirectRenderingMesh.lod2MatPropBlock.SetBuffer(ShaderConstants.InstanceTRSBufferPID, m_InstanceTRSBuffer);

                m_IndirectRenderingMesh.lod0MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 0 + 4);
                m_IndirectRenderingMesh.lod1MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 1 + 4);
                m_IndirectRenderingMesh.lod2MatPropBlock.SetInt(ShaderConstants.ArgsOffsetPID, argsIndex + NUMBER_OF_ARGS_PER_DRAW * 2 + 4);

                m_IndirectRenderingMesh.lod0MatPropBlock.SetBuffer("_OutputDataBuffer", m_OutputDataBuffer);
                m_IndirectRenderingMesh.lod1MatPropBlock.SetBuffer("_OutputDataBuffer", m_OutputDataBuffer);
                m_IndirectRenderingMesh.lod2MatPropBlock.SetBuffer("_OutputDataBuffer", m_OutputDataBuffer);


                m_CullCS.SetInt(ShaderConstants.ShouldFrustumCullPID, 1);
            }
        }

        private void OnInstancesCountChange()
        {
            m_InstanceDataBuffer = new ComputeBuffer(m_InstancesCount, sizeof(float) * 6);
            m_VisibleInfoBuffer = new ComputeBuffer(m_InstancesCount, sizeof(uint) * 2, ComputeBufferType.Append);


            m_OutputDataBuffer = new ComputeBuffer(m_InstancesCount, sizeof(uint), ComputeBufferType.Append);
            m_InstanceTRSBuffer = new ComputeBuffer(m_InstancesCount, sizeof(float) * 9);
            m_InstanceTRSBuffer.SetData(instancesInputTRS, 0, 0, m_InstancesCount);

            m_CullingGroupX = Mathf.Max(1, Mathf.CeilToInt(m_InstancesCount / 64f));

        }

        public void CalcCullAndLOD()
        {
            if (m_InstancesCount <= 0)
                return;
            Debug.LogError("Update");

            // 计算可见性
            CalculateVisibleInstances();
            //根据Offset count 重整
            CalculateIndexOffset();
        }


        private void CalculateVisibleInstances()
        {
            Camera camera = Camera.main;

            // 获取摄像机参数
            Matrix4x4 v = camera.worldToCameraMatrix;
            Matrix4x4 p = camera.projectionMatrix;
            m_VPMatrix = p * v;

            //////////////////////////////////////////////////////
            // Reset the arguments buffer
            //////////////////////////////////////////////////////
            m_InstancesArgsBuffer.SetData(m_Args);

            //////////////////////////////////////////////////////
            // Culling
            //////////////////////////////////////////////////////
            m_CullCS.SetMatrix(ShaderConstants.VPMatrixPID, m_VPMatrix);
            m_CullCS.SetVector(ShaderConstants.CenterPosWSPID, camera.transform.position);
            m_CullCS.SetInt("_InstanceCount", m_InstancesCount);

            m_VisibleInfoBuffer.SetCounterValue(0);
            m_InstanceDataBuffer.SetData(instancesInputData, 0, 0, m_InstancesCount);

            m_CullCS.SetBuffer(KERNAL_CalcCullAndLOD, ShaderConstants.InstanceDataBufferPID, m_InstanceDataBuffer);
            m_CullCS.SetBuffer(KERNAL_CalcCullAndLOD, ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
            m_CullCS.SetBuffer(KERNAL_CalcCullAndLOD, "_VisibleInfoBuffer", m_VisibleInfoBuffer);

            m_CullCS.Dispatch(KERNAL_CalcCullAndLOD, m_CullingGroupX, 1, 1);

        }

        private void CalculateIndexOffset()
        {
            uint[] insertCount = new uint[NUMBER_OF_LOD];
            m_InsertCountBuffer.SetData(insertCount);
            m_CalcIndexOffsetCS.SetInt("_NumOfDrawcalls", NUMBER_OF_LOD);
            m_CalcIndexOffsetCS.SetBuffer(KERNAL_CalcIndexOffset, ShaderConstants.ArgsBufferPID, m_InstancesArgsBuffer);
            m_CalcIndexOffsetCS.SetBuffer(KERNAL_CalcIndexOffset, "_OutputDataBuffer", m_OutputDataBuffer);
            m_CalcIndexOffsetCS.SetBuffer(KERNAL_CalcIndexOffset, "_VisibleInfoBuffer", m_VisibleInfoBuffer);
            m_CalcIndexOffsetCS.SetBuffer(KERNAL_CalcIndexOffset, "_InsertCountBuffer", m_InsertCountBuffer);


            m_CalcIndexOffsetCS.Dispatch(KERNAL_CalcIndexOffset, m_CullingGroupX, 1, 1);

            // m_InsertCountBuffer.GetData(insertCount);
            // Debug.LogError("InsertCount:" + insertCount[0] + "-" + insertCount[1] + "-" + insertCount[2]);

            // // 获取可见性
            // uint[] visibleCount = new uint[NUMBER_OF_ARGS_PER_INSTANCE_TYPE];
            // m_InstancesArgsBuffer.GetData(visibleCount);
            // uint totalCount = visibleCount[1] + visibleCount[NUMBER_OF_ARGS_PER_DRAW + 1] + visibleCount[NUMBER_OF_ARGS_PER_DRAW * 2 + 1];
            // Debug.LogError(m_InstancesCount + "---" + totalCount + "==count" + "0===>" + visibleCount[1] + ":1===>" + visibleCount[NUMBER_OF_ARGS_PER_DRAW + 1] + ":2===>" + visibleCount[NUMBER_OF_ARGS_PER_DRAW * 2 + 1]);
        }


        public void Render()
        {
            if (m_InstancesArgsBuffer == null)
                return;

            m_RenderBounds = new Bounds(Vector3.zero, Vector3.one * 1000);
            //20 =>5*size(uint); 单个args
            Graphics.DrawMeshInstancedIndirect(m_IndirectRenderingMesh.combineMesh, MESH_INDEX, m_IndirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 0, m_IndirectRenderingMesh.lod0MatPropBlock, ShadowCastingMode.Off);
            Graphics.DrawMeshInstancedIndirect(m_IndirectRenderingMesh.combineMesh, MESH_INDEX, m_IndirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 1, m_IndirectRenderingMesh.lod1MatPropBlock, ShadowCastingMode.Off);
            Graphics.DrawMeshInstancedIndirect(m_IndirectRenderingMesh.combineMesh, MESH_INDEX, m_IndirectRenderingMesh.indirectMaterial, m_RenderBounds, m_InstancesArgsBuffer, ARGS_BYTE_SIZE_PER_DRAW_CALL * 2, m_IndirectRenderingMesh.lod2MatPropBlock, ShadowCastingMode.Off);

        }


        public void Destroy()
        {
            ReleaseComputeBuffer();
        }

        private void ReleaseComputeBuffer()
        {
            ReleaseComputeBuffer(ref m_InstanceDataBuffer);
            ReleaseComputeBuffer(ref m_InstanceTRSBuffer);
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

        private static bool TryGetKernel(string kernelName, ref ComputeShader computeShader, ref int kernelID)
        {
            if (!computeShader.HasKernel(kernelName))
            {
                Debug.LogError(kernelName + " kernel not found in " + computeShader.name + "!");
                return false;
            }

            kernelID = computeShader.FindKernel(kernelName);
            return true;
        }

        public void DrawGizmos()
        {

        }


        private class ShaderConstants
        {
            public static readonly int InstanceDataBufferPID = Shader.PropertyToID("_InstanceDataBuffer");
            public static readonly int InstanceTRSBufferPID = Shader.PropertyToID("_InstanceTRSBuffer");
            public static readonly int VisibleInstanceOnlyTransformIDBuffer = Shader.PropertyToID("_VisibleInstanceOnlyTransformIDBuffer");

            public static readonly int LODDistancePID = Shader.PropertyToID("_LODDistance");
            public static readonly int CenterPosWSPID = Shader.PropertyToID("_CenterPos");
            public static readonly int VPMatrixPID = Shader.PropertyToID("_VPMatrix");
            public static readonly int StartOffsetPID = Shader.PropertyToID("_StartOffset");

            public static readonly int ArgsBufferPID = Shader.PropertyToID("_ArgsBuffer");



            //shader
            public static readonly int ArgsOffsetPID = Shader.PropertyToID("_ArgsOffset");

            //Culling CS
            public static readonly int ShouldFrustumCullPID = Shader.PropertyToID("_ShouldFrustumCull");


        }


    }

}