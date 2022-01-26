using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public class StreamingGrassTileSO
    {
        public static void LoadAsset(Vector2Int gridPos, System.Action<GrassTileSO> callback)
        {

            string path = string.Format("InstanceConfig/World/Grass/GrassTileSO_{0}_{1}", gridPos.x, gridPos.y);
            var grassTileSO = Resources.Load<GrassTileSO>(path);
            if (grassTileSO != null)
            {
                callback(grassTileSO);
            }

        }
    }

}