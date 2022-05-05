using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassPaintSetting : TSingleton<GrassPaintSetting>
    {

        protected override void OnSingletonInit()
        {
            base.OnSingletonInit();
            LoadSO();
        }

        private static string DBPath = GrassPainterDefine.toolPath + "GrassPainter/Res/SO/GrassPaintSettingSO.asset";
        public GrassPaintSettingSO grassPainterSettingSO;

        public void Init()
        {

        }

        private void LoadSO()
        {
            grassPainterSettingSO = AssetDatabase.LoadAssetAtPath<GrassPaintSettingSO>(DBPath);
            if (grassPainterSettingSO == null)
            {
                var so = ScriptableObject.CreateInstance<GrassPaintSettingSO>();
                AssetDatabase.CreateAsset(so, DBPath);
                grassPainterSettingSO = so;
            }
        }


        public void SaveSetting()
        {
            if (grassPainterSettingSO != null)
            {
                grassPainterSettingSO.Save();
            }
        }
    }
}
