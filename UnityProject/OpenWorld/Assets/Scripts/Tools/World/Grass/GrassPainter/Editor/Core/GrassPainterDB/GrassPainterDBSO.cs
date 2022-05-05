using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Sirenix.OdinInspector;

namespace GrassPainter
{
    public class GrassPainterDBSO : SerializedScriptableObject
    {
        //TODO 判空
        public List<GrassPainterPrefab> prefabs;


        public void AddPrefab(GrassPainterPrefabArgs args)
        {
            GrassPainterPrefab prefabInfo = new GrassPainterPrefab();
            prefabInfo.mesh = args.mesh;
            prefabInfo.material = args.material;
            prefabInfo.indirectMaterial = args.indirectMaterial;
            prefabs.Add(prefabInfo);
            Save();
        }

        public void RemovePrefab(int index)
        {
            prefabs.RemoveAt(index);
            Save();
        }

        [Button("Save")]
        public void Save()
        {
            EditorUtility.SetDirty(this);
            AssetDatabase.SaveAssets();
        }


    }

    [System.Serializable]
    public class GrassPainterPrefab
    {

        public Mesh mesh;
        public Material material;
        public Material indirectMaterial;

        private GameObject m_Prefab;
        public GameObject prefab
        {
            get
            {
                if (m_Prefab == null)
                {
                    m_Prefab = new GameObject();
                    m_Prefab.AddComponent<MeshRenderer>().material = material;
                    m_Prefab.AddComponent<MeshFilter>().mesh = mesh;
                    m_Prefab.transform.position = Vector3.one * -5000;
                    m_Prefab.name = GetName();
                }
                return m_Prefab;
            }
        }


        public string GetName()
        {
            return mesh.name + "-" + material.name;
        }
    }
}