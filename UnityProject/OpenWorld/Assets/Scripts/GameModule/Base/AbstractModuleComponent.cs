using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public abstract class AbstractModuleComponent : IModuleComponent
    {
        bool m_Inited = false;
        public virtual void OnInit()
        {
            if (m_Inited)
                return;

            m_Inited = true;
        }

        public virtual void OnLateUpdate() { }
        public virtual void OnUpdate() { }
        public virtual void OnGizmos() { }
    }

}