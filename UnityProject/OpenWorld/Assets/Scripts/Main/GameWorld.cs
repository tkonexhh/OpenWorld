using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public class GameWorld
    {
        IModule[] m_Modules;

        public void Start(IModule[] modules)
        {
            m_Modules = modules;

            foreach (var module in m_Modules)
            {
                module.OnInit();
            }
        }

        public void Update()
        {
            foreach (var module in m_Modules)
            {
                module.OnUpdate();
            }
        }

        public void LateUpdate()
        {
            foreach (var module in m_Modules)
            {
                module.OnLateUpdate();
            }
        }

        public void OnGizmos()
        {
            foreach (var module in m_Modules)
            {
                module.OnGizmos();
            }
        }
    }

}