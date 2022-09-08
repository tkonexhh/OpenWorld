using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

namespace OpenWorld
{
    public class WorldTerrainBakeSO : SerializedScriptableObject
    {
        [LabelText("世界大小")][ReadOnly] public Vector3 worldSize = new Vector3(4000, 500, 4000);
        [LabelText("单块大小")] public Vector3 terrainChunkSize = new Vector3(2048, 500, 2048);
        [LabelText("单块切分数量")][Min(1)] public int sliceCount = 4;

        [OnValueChanged("OnSliceCountChange")]
        [LabelText("分切割层数(需要修改提前联系)")]
        [Range(1, 4)]
        public int chunkCount = 2;

        [TableMatrix(SquareCells = true, IsReadOnly = true, HideRowIndices = true, ResizableColumns = false)]

        public WorldTerrainChunkSO[,] terrainChunks;


        public WorldTerrainBakeSO()
        {
            OnSliceCountChange();
        }

        private void OnSliceCountChange()
        {
            terrainChunks = new WorldTerrainChunkSO[chunkCount, chunkCount];
            worldSize = new Vector3(terrainChunkSize.x * chunkCount, terrainChunkSize.y, terrainChunkSize.z * chunkCount);
        }

        [Button]
        public void Slice()
        {

            // Vector3 center = terrainChunk
            // var bounds = new Bounds(terrainTarget.transform.TransformPoint(terrainData.bounds.center), terrainData.bounds.size);
        }


        [Button]
        public void Save()
        {
            EditorHelper.SetDirty(this);
        }
    }

}