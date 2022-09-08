using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public abstract class AbstractModule : IModule
    {

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
            component.OnInit();
            OnAddComponment(component);
            return component;
        }

        protected virtual void OnAddComponment(IModuleComponent component) { }

        public virtual void OnInit()
        {
            foreach (var component in m_ComponentList)
            {
                component.OnInit();
            }
        }

        public virtual void OnLateUpdate()
        {
            foreach (var component in m_ComponentList)
            {
                component.OnLateUpdate();
            }
        }

        public virtual void OnUpdate()
        {
            foreach (var component in m_ComponentList)
            {
                component.OnUpdate();
            }
        }

        public virtual void OnGizmos()
        {
            foreach (var component in m_ComponentList)
            {
                component.OnGizmos();
            }
        }
    }

}