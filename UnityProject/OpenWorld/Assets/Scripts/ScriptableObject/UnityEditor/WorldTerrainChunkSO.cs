using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

namespace XHH
{
    [InlineEditor]
    [CreateAssetMenu(menuName = "ScriptableObject/WorldTerrainChunkSO", fileName = "WorldTerrainChunkSO")]
    public class WorldTerrainChunkSO : SerializedScriptableObject
    {
        public TerrainData terrainData;
    }

}