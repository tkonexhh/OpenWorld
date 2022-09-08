using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

namespace OpenWorld
{
    [InlineEditor]
    [CreateAssetMenu(menuName = "ScriptableObject/WorldTerrainChunkSO", fileName = "WorldTerrainChunkSO")]
    public class WorldTerrainChunkSO : SerializedScriptableObject
    {
        public TerrainData terrainData;


        [Button]
        public void Slice(int sliceCount, Vector3 terrainChunkSize)
        {
            sliceCount = 4;
            terrainChunkSize = new Vector3(2048, 500, 2048);
            if (terrainData == null)
                return;

            int curSliceCount = Mathf.NextPowerOfTwo(sliceCount);
            int quadTreeDepth = Mathf.FloorToInt(Mathf.Log(curSliceCount, 2));

            // Debug.LogError(curSliceCount + "--" + quadTreeDepth);

            float max_sub_grids = sliceCount * (1 << 4);

            float min_edge_len = terrainChunkSize.x / max_sub_grids;
            float minArea = min_edge_len * min_edge_len / 8f;
            // Debug.LogError(min_edge_len);
            var bounds = new Bounds(terrainData.bounds.center + Vector3.zero, terrainData.bounds.size);
            Debug.LogError(terrainData.bounds);
        }
    }

}