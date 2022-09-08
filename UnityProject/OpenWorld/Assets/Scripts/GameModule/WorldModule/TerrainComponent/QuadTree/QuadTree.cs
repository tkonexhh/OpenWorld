using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public class QuadTree : IQuadNode
    {
        private QuadNode root;

        public QuadTree(int maxDepth, Vector3 min, Vector3 max)
        {
            root = new QuadNode(maxDepth, min, max);
        }

        public void DrawBound()
        {
            root?.DrawBound();
        }

    }

}