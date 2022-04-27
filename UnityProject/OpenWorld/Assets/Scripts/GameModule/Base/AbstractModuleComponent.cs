using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public abstract class AbstractModuleComponent : IModuleComponent
    {
        public virtual void OnInit() { }
        public virtual void OnLateUpdate() { }
        public virtual void OnUpdate() { }
    }

}