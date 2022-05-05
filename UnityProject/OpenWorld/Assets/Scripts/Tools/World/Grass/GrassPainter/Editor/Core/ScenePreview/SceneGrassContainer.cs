using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class SceneGrassContainer
    {
        private static int SIZE = 20;
        public SceneGrassBlock[,] instanceDataArray = new SceneGrassBlock[SIZE, SIZE];

        public string key { get; private set; }

        public SceneGrassContainer(string key)
        {
            this.key = key;
        }

        public void AddInstanceData(GrassTRS instanceData)
        {
            var blockPos = GetBlockPos(instanceData.position);
            if (instanceDataArray[blockPos.x, blockPos.y] == null)
            {
                instanceDataArray[blockPos.x, blockPos.y] = new SceneGrassBlock();
            }
            instanceDataArray[blockPos.x, blockPos.y].instanceDatas.Add(instanceData);

            GrassQuadTreeSpaceMgr.S.AddData(key, instanceData);
        }

        public int GetCount()
        {
            int count = 0;
            for (int x = 0; x < instanceDataArray.GetLength(0); x++)
            {
                for (int y = 0; y < instanceDataArray.GetLength(1); y++)
                {
                    if (instanceDataArray[x, y] == null)
                        continue;
                    count += instanceDataArray[x, y].instanceDatas.Count;
                }
            }

            return count;
        }


        private Vector2Int GetBlockPos(Vector3 position)
        {
            Vector2 blockSize = new Vector2(GrassPainterMgr.worldSize.x / SIZE, GrassPainterMgr.worldSize.z / SIZE);
            Vector2Int blockPos = new Vector2Int((int)(position.x / blockSize.x), (int)(position.z / blockSize.y));
            return blockPos;
        }

        public void Erasing(Vector3 hitpoint, float brushSize)
        {
            Vector2 blockSize = new Vector2(GrassPainterMgr.worldSize.x / SIZE, GrassPainterMgr.worldSize.z / SIZE);
            //根据hitpoint得到BlockPos
            Vector2Int blockPos = GetBlockPos(hitpoint);
            Vector2 edge = new Vector2(blockSize.x / 2 + brushSize, blockSize.y / 2 + brushSize);
            for (int x = -1; x < 1; x++)
            {
                for (int y = -1; y < 1; y++)
                {
                    if (x < 0 || y < 0 || x >= SIZE || y >= SIZE)
                        continue;

                    int posX = x + blockPos.x;
                    int posY = y + blockPos.y;
                    if (instanceDataArray[posX, posY] == null || instanceDataArray[posX, posY].instanceDatas.Count <= 0)
                        continue;

                    Vector3 center = new Vector3(blockSize.x * (posX + 0.5f), hitpoint.y, blockSize.y * (posY + 0.5f));
                    float deltaX = Mathf.Abs(hitpoint.x - center.x);
                    float deltaY = Mathf.Abs(hitpoint.y - center.y);
                    if (deltaX <= edge.x && deltaY <= edge.y)
                    {
                        // Debug.LogError(posX + "---" + posY);
                        instanceDataArray[posX, posY].Erasing(hitpoint, brushSize);
                    }
                }
            }
        }
    }

    public class SceneGrassBlock
    {
        public List<GrassTRS> instanceDatas = new List<GrassTRS>();


        public void Erasing(Vector3 hitpoint, float brushSize)
        {
            for (int i = instanceDatas.Count - 1; i >= 0; i--)
            {
                if (Vector3.Distance(instanceDatas[i].position, hitpoint) < brushSize)
                {
                    RemoveInstanceData(i);
                }
            }

        }

        public void RemoveInstanceData(int index)
        {
            instanceDatas.RemoveAt(index);
        }
    }
}
