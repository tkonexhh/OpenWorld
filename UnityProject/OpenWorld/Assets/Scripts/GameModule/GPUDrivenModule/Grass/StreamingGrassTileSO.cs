using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public class StreamingGrassTileSO
    {
        public static void LoadAsset(Vector2Int gridPos, System.Action<GrassTileSO> callback)
        {
#if UNITY_EDITOR
            string path = string.Format("Assets/Res/InstanceConfig/World/Grass/GrassTileSO_{0}_{1}.asset", gridPos.x, gridPos.y);
            var grassTileSO = UnityEditor.AssetDatabase.LoadAssetAtPath<GrassTileSO>(path);
            if (grassTileSO != null)
            {
                callback(grassTileSO);
            }
#endif
        }
    }

}