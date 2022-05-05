using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class PaintRootFinder
    {
        public string GRASSROOTNAME = "GrassRoot";
        private GameObject m_GrassRoot;

        public GameObject FindPaintRoot(string key, bool isCreate = true)
        {
            if (m_GrassRoot == null)
            {
                if (GameObject.Find(GRASSROOTNAME))
                    m_GrassRoot = GameObject.Find(GRASSROOTNAME);
                else
                    m_GrassRoot = new GameObject(GRASSROOTNAME);
            }

            GameObject paintRoot = null;
            if (GameObject.Find(key))
            {
                paintRoot = GameObject.Find(GRASSROOTNAME + "/" + key);
            }
            else if (isCreate)
            {
                paintRoot = new GameObject(key);

            }

            SceneGrassContainerMgr.S.CreateContainer(key);

            if (paintRoot)
                paintRoot.transform.SetParent(m_GrassRoot.transform);

            return paintRoot;
        }
    }
}
