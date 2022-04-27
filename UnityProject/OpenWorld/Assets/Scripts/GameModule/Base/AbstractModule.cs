using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public abstract class AbstractModule : MonoBehaviour, IModule
    {
        public virtual void OnInit() { }
        public virtual void OnLateUpdate() { }
        public virtual void OnUpdate() { }

        protected List<IModuleComponent> m_ComponentList = new List<IModuleComponent>();

        protected IModuleComponent AddComponent(IModuleComponent component)
        {
            if (component == null)
            {
                return null;
            }

            if (m_ComponentList.Contains(component))
            {
                return component;
            }

            m_ComponentList.Add(component);
            return component;
        }


        private void Start()
        {
            OnInit();
        }

        private void Update()
        {
            OnUpdate();

            for (int i = 0; i < m_ComponentList.Count; i++)
            {
                m_ComponentList[i].OnUpdate();
            }
        }

        private void LateUpdate()
        {
            OnLateUpdate();

            for (int i = 0; i < m_ComponentList.Count; i++)
            {
                m_ComponentList[i].OnLateUpdate();
            }
        }
    }

}