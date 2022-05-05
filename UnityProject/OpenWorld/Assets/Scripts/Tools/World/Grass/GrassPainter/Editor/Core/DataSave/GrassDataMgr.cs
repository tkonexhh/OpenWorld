using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassDataMgr : TSingleton<GrassDataMgr>
    {
        protected override void OnSingletonInit()
        {
            base.OnSingletonInit();
            LoadDB();
        }

        private static string DBPath = GrassPainterDefine.dataPath + "GrassDataSO.asset";
        public GrassDataSO grassDataSO;


        public void Init()
        {

        }

        private void LoadDB()
        {
            grassDataSO = AssetDatabase.LoadAssetAtPath<GrassDataSO>(DBPath);
            if (grassDataSO == null)
            {
                var so = ScriptableObject.CreateInstance<GrassDataSO>();
                AssetDatabase.CreateAsset(so, DBPath);
                grassDataSO = so;
            }
        }

        public void SaveData()
        {
            grassDataSO.Save();
        }
    }
}
