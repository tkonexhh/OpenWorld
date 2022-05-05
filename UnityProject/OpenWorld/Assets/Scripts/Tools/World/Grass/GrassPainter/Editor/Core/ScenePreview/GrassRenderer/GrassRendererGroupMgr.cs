using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class GrassRendererGroupMgr : TSingleton<GrassRendererGroupMgr>
    {

        private Dictionary<string, GrassRenderer> groupMap = new Dictionary<string, GrassRenderer>();


        public void AddData(string key, GrassTRS data)
        {
            if (!groupMap.ContainsKey(key))
            {
                var grassPainterPrefab = GrassPainterDB.S.GetGrassPainterPrefab(key);
                GrassRendererArgs args = new GrassRendererArgs();
                Material mat = null;
                if (!grassPainterPrefab.material.enableInstancing)
                {
                    mat = Material.Instantiate(grassPainterPrefab.material);
                    mat.enableInstancing = true;
                }
                else
                {
                    mat = grassPainterPrefab.material;
                }

                args.material = mat;
                args.mesh = grassPainterPrefab.mesh;
                GrassRenderer groupRenderer = new GrassRenderer(args);
                groupMap.Add(key, groupRenderer);
            }

            Matrix4x4 trs = Matrix4x4.TRS(data.position, Quaternion.Euler(0, data.GetRotationY(), 0), Vector3.one * data.scale);
            groupMap[key].AddDate(trs);
        }

        public void AddRangeData(string key, List<GrassTRS> datas)
        {
            for (int i = 0; i < datas.Count; i++)
            {
                AddData(key, datas[i]);
            }
        }


        public void Render()
        {
            foreach (var renderer in groupMap)
            {
                renderer.Value.Render();
            }
        }

        public void Clear()
        {
            foreach (var renderer in groupMap)
            {
                renderer.Value.Clear();
            }
        }
    }
}
