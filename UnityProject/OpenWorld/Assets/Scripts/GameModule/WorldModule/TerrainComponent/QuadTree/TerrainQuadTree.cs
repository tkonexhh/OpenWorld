using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH.World
{
    public class TerrainQuadTree
    {
        private TerrainQuadNode root;
        public TerrainQuadTree()
        {

        }
    }

    public class TerrainQuadNode
    {
        public Bounds Bounds;
        public Vector2 UVMin;
        public Vector2 UVMax;
        public TerrainQuadNode[] children;

        public TerrainQuadNode(int depth, Vector3 min, Vector3 max, Vector2 uvmin, Vector2 uvmax)
        {
            Vector3 center = 0.5f * (min + max);
            Vector3 size = max - min;
            this.Bounds = new Bounds(center, size);
            this.UVMin = uvmin;
            this.UVMax = uvmax;

            Vector2 uvcenter = 0.5f * (uvmin + uvmax);
            Vector2 uvsize = uvmax - uvmin;

            if (depth > 0)
            {
                children = new TerrainQuadNode[4];
                Vector3 subMin = new Vector3(center.x - 0.5f * size.x, min.y, center.z - 0.5f * size.z);
                Vector3 subMax = new Vector3(center.x, max.y, center.z);
                Vector2 uvsubMin = new Vector2(uvcenter.x - 0.5f * uvsize.x, uvcenter.y - 0.5f * uvsize.y);
                Vector2 uvsubMax = new Vector2(uvcenter.x, uvcenter.y);
                children[0] = CreateSubNode(depth - 1, subMin, subMax, uvsubMin, uvsubMax);

                subMin = new Vector3(center.x, min.y, center.z - 0.5f * size.z);
                subMax = new Vector3(center.x + 0.5f * size.x, max.y, center.z);
                uvsubMin = new Vector2(uvcenter.x, uvcenter.y - 0.5f * uvsize.y);
                uvsubMax = new Vector2(uvcenter.x + 0.5f * uvsize.x, uvcenter.y);
                children[1] = CreateSubNode(depth - 1, subMin, subMax, uvsubMin, uvsubMax);

                subMin = new Vector3(center.x - 0.5f * size.x, min.y, center.z);
                subMax = new Vector3(center.x, max.y, center.z + 0.5f * size.z);
                uvsubMin = new Vector2(uvcenter.x - 0.5f * uvsize.x, uvcenter.y);
                uvsubMax = new Vector2(uvcenter.x, uvcenter.y + 0.5f * uvsize.y);
                children[2] = CreateSubNode(depth - 1, subMin, subMax, uvsubMin, uvsubMax);

                subMin = new Vector3(center.x, min.y, center.z);
                subMax = new Vector3(center.x + 0.5f * size.x, max.y, center.z + 0.5f * size.z);
                uvsubMin = new Vector2(uvcenter.x, uvcenter.y);
                uvsubMax = new Vector2(uvcenter.x + 0.5f * uvsize.x, uvcenter.y + 0.5f * uvsize.y);
                children[3] = CreateSubNode(depth - 1, subMin, subMax, uvsubMin, uvsubMax);
            }
        }

        private TerrainQuadNode CreateSubNode(int depth, Vector3 min, Vector3 max, Vector2 uvmin, Vector2 uvmax)
        {
            return new TerrainQuadNode(depth, min, max, uvmin, uvmax);
        }
    }
}

