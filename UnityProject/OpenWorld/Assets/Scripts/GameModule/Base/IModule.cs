using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public interface IModule
    {
        void OnInit();
        void OnUpdate();
        void OnLateUpdate();
        void OnGizmos();
    }

}