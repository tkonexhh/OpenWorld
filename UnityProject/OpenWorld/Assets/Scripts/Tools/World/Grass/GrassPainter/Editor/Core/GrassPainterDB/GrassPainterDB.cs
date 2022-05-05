using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassPainterDB : TSingleton<GrassPainterDB>
    {
        protected override void OnSingletonInit()
        {
            base.OnSingletonInit();
            LoadDB();
        }

        private static string DBPath = GrassPainterDefine.dataPath + "GrassPainterDBSO.asset";
        public GrassPainterDBSO grassPainterDBSO;


        public void Init()
        {

        }

        private void LoadDB()
        {
            grassPainterDBSO = AssetDatabase.LoadAssetAtPath<GrassPainterDBSO>(DBPath);
            if (grassPainterDBSO == null)
            {
                var so = ScriptableObject.CreateInstance<GrassPainterDBSO>();
                IOHelper.CreatePath(DBPath);
                AssetDatabase.CreateAsset(so, DBPath);
                grassPainterDBSO = so;
            }
        }

        public void AddPrefab(GrassPainterPrefabArgs args)
        {
            grassPainterDBSO.AddPrefab(args);
        }

        public void RemovePrefab(int index)
        {
            grassPainterDBSO.RemovePrefab(index);
        }

        public GrassPainterPrefab GetGrassPainterPrefab(string key)
        {
            for (int i = 0; i < grassPainterDBSO.prefabs.Count; i++)
            {
                if (grassPainterDBSO.prefabs[i].GetName().Equals(key))
                {
                    return grassPainterDBSO.prefabs[i];
                }
            }

            return null;
        }

        public void Destroy()
        {
            for (int i = 0; i < grassPainterDBSO.prefabs.Count; i++)
            {
                if (grassPainterDBSO.prefabs[i].prefab != null)
                    GameObject.DestroyImmediate(grassPainterDBSO.prefabs[i].prefab);
            }
        }

    }

    public struct GrassPainterPrefabArgs
    {
        public Mesh mesh;
        public Material material;
        public Material indirectMaterial;
    }
}
