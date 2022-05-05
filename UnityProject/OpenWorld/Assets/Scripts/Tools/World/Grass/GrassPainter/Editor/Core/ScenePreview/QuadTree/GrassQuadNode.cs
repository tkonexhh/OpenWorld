using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassQuadNode : INode
    {
        public Bounds bounds { get; set; }
        private GrassQuadTree m_Tree;
        private int m_Depth;

        private GrassQuadNode[] m_ChildNodes;
        private Dictionary<string, List<GrassTRS>> m_DataMap = new Dictionary<string, List<GrassTRS>>();

        public GrassQuadNode(Bounds bounds, int depth, GrassQuadTree belongTree)
        {
            this.bounds = bounds;
            m_Tree = belongTree;
            m_Depth = depth;
        }

        public void DrawBound()
        {
            Handles.DrawWireCube(bounds.center, bounds.size);
            if (m_ChildNodes != null)
            {
                for (int i = 0; i < m_ChildNodes.Length; i++)
                {
                    m_ChildNodes[i].DrawBound();
                }
            }
        }

        public void InsertObj(string key, GrassTRS item)
        {
            GrassQuadNode node = null;
            bool isChild = false;
            if (m_Depth < GrassQuadTree.maxDepth && m_ChildNodes == null)
            {
                CreateChild();
            }

            if (m_ChildNodes != null)
            {
                for (int i = 0; i < m_ChildNodes.Length; i++)
                {
                    GrassQuadNode child = m_ChildNodes[i];

                    if (child.bounds.Contains(item.position))
                    {
                        if (node != null)
                        {
                            isChild = false;
                            break;
                        }

                        node = child;
                        isChild = true;
                    }
                }
            }

            if (isChild)
            {
                node.InsertObj(key, item);
            }
            else
            {
                if (!m_DataMap.ContainsKey(key))
                {
                    List<GrassTRS> datas = new List<GrassTRS>();
                    m_DataMap.Add(key, datas);
                }
                m_DataMap[key].Add(item);
            }
        }


        private void CreateChild()
        {
            m_ChildNodes = new GrassQuadNode[4];
            int index = 0;
            Vector3 cSize = new Vector3(bounds.size.x / 2, bounds.size.y, bounds.size.z / 2);
            for (int i = -1; i <= 1; i += 2)
            {
                for (int j = -1; j <= 1; j += 2)
                {
                    Vector3 centerOffset = new Vector3(bounds.size.x / 4 * i, 0, bounds.size.z / 4 * j);
                    Bounds cBound = new Bounds(bounds.center + centerOffset, cSize);
                    m_ChildNodes[index++] = new GrassQuadNode(cBound, m_Depth + 1, m_Tree);
                }
            }
        }

        public void Clear()
        {
            m_DataMap.Clear();
            if (m_ChildNodes != null)
            {
                for (int i = 0; i < m_ChildNodes.Length; i++)
                {
                    m_ChildNodes[i].Clear();
                }
            }
        }

        public void TriggerMove(Camera camera)
        {
            // Debug.LogError("TriggerMove");
            //首先判断距离
            if (GrassQuadTreeSpaceMgr.CheckBoundIsInCamera(bounds, camera))
            {
                Vector3 pos = bounds.center;
                pos.y = camera.transform.position.y;
                // Debug.LogError(Vector3.Distance(camera.transform.position, pos));
                if (Vector3.Distance(camera.transform.position, pos) < 150)//显示距离
                {
                    OnShow();
                }


                if (m_ChildNodes != null)
                {
                    for (int i = 0; i < m_ChildNodes.Length; i++)
                    {
                        m_ChildNodes[i].TriggerMove(camera);
                    }
                }
            }
        }

        private void OnShow()
        {
            foreach (var data in m_DataMap)
            {
                GrassRendererGroupMgr.S.AddRangeData(data.Key, data.Value);
            }

        }
    }
}
