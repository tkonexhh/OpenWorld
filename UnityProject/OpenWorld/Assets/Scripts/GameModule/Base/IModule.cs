using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    public interface IModule
    {
        void OnInit();
        void OnUpdate();
        void OnLateUpdate();
    }

}