using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassQuadTree : INode
    {
        public Bounds bounds { get; set; }
        public static int maxDepth { get; private set; }
        private GrassQuadNode m_Root;

        public GrassQuadTree(Bounds bounds)
        {
            this.bounds = bounds;
            GrassQuadTree.maxDepth = 5;
            m_Root = new GrassQuadNode(bounds, 0, this);
        }

        public void DrawBound()
        {
            m_Root.DrawBound();

        }

        public void InsertObj(string key, GrassTRS item)
        {
            m_Root.InsertObj(key, item);
        }

        public void Clear()
        {
            m_Root.Clear();
        }

        public void TriggerMove(Camera camera)
        {
            GrassRendererGroupMgr.S.Clear();
            m_Root.TriggerMove(camera);
        }
    }
}
