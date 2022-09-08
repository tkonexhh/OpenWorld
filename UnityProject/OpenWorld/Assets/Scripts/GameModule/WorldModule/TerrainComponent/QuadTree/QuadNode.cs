using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public class QuadNode : IQuadNode
    {
        public int depth { get; private set; }
        public QuadNode[] children { get; private set; }
        public Bounds bounds;

        public QuadNode(int depth, Vector3 min, Vector3 max)
        {
            this.depth = depth;
            Vector3 center = 0.5f * (min + max);
            Vector3 size = max - min;
            this.bounds = new Bounds(center, size);

            if (depth > 0)
            {
                CreateChildNode();
            }
        }

        void CreateChildNode()
        {
            if (children != null)
                return;

            Vector3 center = bounds.center;
            Vector3 size = bounds.size;
            Vector3 min = bounds.min;
            Vector3 max = bounds.max;

            children = new QuadNode[4];
            // [2 3]
            // [0 1]

            Vector3 subMin = new Vector3(center.x - 0.5f * size.x, min.y, center.z - 0.5f * size.z);
            Vector3 subMax = new Vector3(center.x, max.y, center.z);
            children[0] = CreateSubNode(subMin, subMax);

            subMin = new Vector3(center.x, min.y, center.z - 0.5f * size.z);
            subMax = new Vector3(center.x + 0.5f * size.x, max.y, center.z);
            children[1] = CreateSubNode(subMin, subMax);

            subMin = new Vector3(center.x - 0.5f * size.x, min.y, center.z);
            subMax = new Vector3(center.x, max.y, center.z + 0.5f * size.z);
            children[2] = CreateSubNode(subMin, subMax);

            subMin = new Vector3(center.x, min.y, center.z);
            subMax = new Vector3(center.x + 0.5f * size.x, max.y, center.z + 0.5f * size.z);
            children[3] = CreateSubNode(subMin, subMax);

        }

        private QuadNode CreateSubNode(Vector3 min, Vector3 max)
        {
            return new QuadNode(this.depth - 1, min, max);
        }

        public void DrawBound()
        {
            Gizmos.DrawWireCube(bounds.center, bounds.size - Vector3.one * 5.5f);
            if (children != null)
            {
                foreach (var child in children)
                {
                    child.DrawBound();
                }
            }
        }
    }

}