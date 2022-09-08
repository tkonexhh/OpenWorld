using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Unity.Mathematics;
using System.Runtime.InteropServices;


namespace OpenWorld
{
    public class ClusterBasedLightingRenderFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public float clusterGridBlockSize = 30;
            public ComputeShader computeShader;
        }

        private ClusterBasedLightingPaass m_Pass;
        public Settings settings = new Settings();

        public override void Create()
        {
            m_Pass = new ClusterBasedLightingPaass(settings);
            m_Pass.renderPassEvent = RenderPassEvent.BeforeRendering;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_Pass);
        }
    }


    public class ClusterBasedLightingPaass : ScriptableRenderPass
    {
        private DIM m_DimData;
        private ClusterBasedLightingRenderFeature.Settings m_Setting;


        private ComputeBuffer m_ClusterAABBsCB;
        private ComputeShader m_ClusterCS;
        private int KERNAL_Cluster;

        public ClusterBasedLightingPaass(ClusterBasedLightingRenderFeature.Settings settings)
        {
            m_Setting = settings;
            m_ClusterCS = settings.computeShader;

            TryGetKernels();

        }


        private bool TryGetKernels()
        {
            return ComputeShaderHelper.TryGetKernel("CSMain", ref m_ClusterCS, ref KERNAL_Cluster);

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            CalculateMDim(renderingData.cameraData.camera);

            if (m_ClusterAABBsCB != null)
                m_ClusterAABBsCB.Release();
            // Debug.LogError(m_DimData.clusterDimXYZ);
            m_ClusterAABBsCB = new ComputeBuffer(m_DimData.clusterDimXYZ, Marshal.SizeOf(typeof(AABB)));


            if (m_ClusterCS == null)
                return;

            int threadX = math.max(1, m_DimData.clusterDimXYZ / 1024);

            m_ClusterCS.SetBuffer(KERNAL_Cluster, "RWClusterAABBs", m_ClusterAABBsCB);
            // m_ClusterCS.Dispatch(KERNAL_Cluster, threadX, 0, 0);


        }


        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.Release();
        }

        void CalculateMDim(Camera cam)
        {
            // The half-angle of the field of view in the Y-direction.
            float fieldOfViewY = cam.fieldOfView * Mathf.Deg2Rad * 0.5f;//Degree 2 Radiance:  Param.CameraInfo.Property.Perspective.fFovAngleY * 0.5f;
            float zNear = cam.nearClipPlane;// Param.CameraInfo.Property.Perspective.fMinVisibleDistance;
            float zFar = cam.farClipPlane;// Param.CameraInfo.Property.Perspective.fMaxVisibleDistance;

            // Number of clusters in the screen X direction.
            int clusterDimX = Mathf.CeilToInt(Screen.width / m_Setting.clusterGridBlockSize);
            // Number of clusters in the screen Y direction.
            int clusterDimY = Mathf.CeilToInt(Screen.height / m_Setting.clusterGridBlockSize);

            // The depth of the cluster grid during clustered rendering is dependent on the 
            // number of clusters subdivisions in the screen Y direction.
            // Source: Clustered Deferred and Forward Shading (2012) (Ola Olsson, Markus Billeter, Ulf Assarsson).
            float sD = 2.0f * Mathf.Tan(fieldOfViewY) / (float)clusterDimY;
            float logDimY = 1.0f / Mathf.Log(1.0f + sD);

            float logDepth = Mathf.Log(zFar / zNear);
            int clusterDimZ = Mathf.FloorToInt(logDepth * logDimY);

            m_DimData.zNear = zNear;
            m_DimData.zFar = zFar;
            m_DimData.sD = sD;
            m_DimData.fieldOfViewY = fieldOfViewY;
            m_DimData.logDepth = logDepth;
            m_DimData.logDimY = logDimY;
            m_DimData.clusterDimX = clusterDimX;
            m_DimData.clusterDimY = clusterDimY;
            m_DimData.clusterDimZ = clusterDimZ;
            m_DimData.clusterDimXYZ = clusterDimX * clusterDimY * clusterDimZ;


        }


        public struct DIM
        {
            public float fieldOfViewY;//FOV
            public float zNear;//近裁平面
            public float zFar;//远裁平面

            public float sD;
            public float logDimY;
            public float logDepth;

            public int clusterDimX;//X方向数量
            public int clusterDimY;//Y
            public int clusterDimZ;//Z
            public int clusterDimXYZ;//总数量
        }

        public struct AABB
        {
            public float3 boundsCenter;         // 3
            public float3 boundsExtents;        // 6
        }
    }

}