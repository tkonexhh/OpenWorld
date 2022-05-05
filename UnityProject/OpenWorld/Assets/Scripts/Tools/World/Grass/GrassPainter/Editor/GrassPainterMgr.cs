using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace GrassPainter
{
    public class GrassPainterMgr : TSingleton<GrassPainterMgr>
    {
        public static Vector3 worldSize => new Vector3(4000, 400, 4000);

        protected override void OnSingletonInit()
        {
            base.OnSingletonInit();
        }

        public void Init()
        {
            GrassQuadTreeSpaceMgr.S.Init();
        }

        public void Update()
        {
            GrassQuadTreeSpaceMgr.S.Update();
        }

        public void OnSceneGUI(SceneView sceneView)
        {
            DrawGizmos();
            GrassRendererGroupMgr.S.Render();
        }

        private void DrawGizmos()
        {
            // GrassQuadTreeSpaceMgr.S.DrawGizmos();
            // Handles.color = Color.green;
            // int size = 20;
            // Vector3 blockSize = new Vector3(WorldConfig.S.worldSize.x / size, 100, WorldConfig.S.worldSize.z / size);
            // for (int x = 0; x < size; x++)
            // {
            //     for (int y = 0; y < size; y++)
            //     {
            //         Vector3 center = new Vector3(blockSize.x * (x + 0.5f), 0, blockSize.z * (y + 0.5f));
            //         Handles.DrawWireCube(center, blockSize);
            //     }
            // }
        }

        public void Destroy()
        {
            SceneGrassContainerMgr.S.Destroy();
            GrassPainterDB.S.Destroy();
            GrassQuadTreeSpaceMgr.S.Destroy();
        }



    }
}
