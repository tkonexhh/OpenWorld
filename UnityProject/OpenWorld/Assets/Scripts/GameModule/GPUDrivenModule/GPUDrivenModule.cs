// using System.Collections;
// using System.Collections.Generic;
// using UnityEngine;
// using UnityEngine.Rendering;
// namespace OpenWorld
// {
//     public class GPUDrivenModule : MonoBehaviour
//     {
//         private GrassComponent m_GrassComponent;
//         public bool draw;

//         void Start()
//         {
//             m_GrassComponent = new GrassComponent();
//             m_GrassComponent.Init();
//         }


//         void Update()
//         {
//             m_GrassComponent.Update();
//         }

//         private void LateUpdate()
//         {
//             if (draw)
//                 m_GrassComponent.LateUpdate();
//         }


//         private void OnDrawGizmos()
//         {
//             m_GrassComponent?.DrawGizmos();
//         }


//         private void OnDestroy()
//         {
//             m_GrassComponent.Destroy();
//         }
//     }
// }
