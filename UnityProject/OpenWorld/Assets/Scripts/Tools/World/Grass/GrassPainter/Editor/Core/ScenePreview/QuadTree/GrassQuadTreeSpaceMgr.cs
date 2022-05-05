using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassQuadTreeSpaceMgr : TSingleton<GrassQuadTreeSpaceMgr>
    {
        private GrassQuadTree m_Tree;
        static Plane[] m_CullingPlanes = new Plane[6];
        private CameraCullData m_CullData = new CameraCullData();

        protected override void OnSingletonInit()
        {
            base.OnSingletonInit();
            var size = GrassPainterMgr.worldSize;
            m_Tree = new GrassQuadTree(new Bounds(new Vector3(size.x / 2, size.y / 2, size.z / 2), size));
        }

        public void Init()
        {

        }

        public void Update(bool force = false)
        {
            var cam = SceneView.lastActiveSceneView.camera;
            bool isDirty = false;
            if (m_CullData.lastCullTime == -1)
            {
                isDirty = true;
            }
            else if (m_CullData.lastRotation != cam.transform.rotation)
            {
                isDirty = true;
            }
            else if (m_CullData.lastCameraPosition != cam.transform.position)
            {
                isDirty = true;
            }

            m_CullData.lastCullTime = Time.realtimeSinceStartup;
            m_CullData.lastRotation = cam.transform.rotation;
            m_CullData.lastCameraPosition = cam.transform.position;



            if (isDirty || force)
            {
                GeometryUtility.CalculateFrustumPlanes(cam, m_CullingPlanes);
                m_Tree.TriggerMove(cam);
            }


        }

        public void Refesh()
        {

            m_Tree.Clear();

            foreach (var container in SceneGrassContainerMgr.S.containerMap)
            {

                for (int x = 0; x < container.Value.instanceDataArray.GetLength(0); x++)
                {
                    for (int y = 0; y < container.Value.instanceDataArray.GetLength(1); y++)
                    {
                        if (container.Value.instanceDataArray[x, y] == null)
                            continue;
                        for (int i = 0; i < container.Value.instanceDataArray[x, y].instanceDatas.Count; i++)
                        {
                            m_Tree.InsertObj(container.Key, container.Value.instanceDataArray[x, y].instanceDatas[i]);
                        }

                    }
                }
            }
            Update(true);
        }

        public void AddData(string key, GrassTRS data)
        {
            m_Tree.InsertObj(key, data);
        }

        public void DrawGizmos()
        {
            Handles.color = Color.green;
            m_Tree.DrawBound();
        }


        public static bool CheckBoundIsInCamera(Bounds bound, Camera camera)
        {
            if (camera == null)
                return false;

            return GeometryUtility.TestPlanesAABB(m_CullingPlanes, bound);
        }

        public void Destroy()
        {
            m_Tree.Clear();
            Update(true);
        }

    }
}
