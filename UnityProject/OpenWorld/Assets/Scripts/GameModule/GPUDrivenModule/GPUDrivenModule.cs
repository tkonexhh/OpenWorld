using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace XHH
{
    public class GPUDrivenModule : MonoBehaviour
    {
        private GrassComponent m_GrassComponent;

        void Start()
        {
            m_GrassComponent = new GrassComponent();
            m_GrassComponent.Init();
        }


        void Update()
        {
            m_GrassComponent.Update();
        }
    }
}
