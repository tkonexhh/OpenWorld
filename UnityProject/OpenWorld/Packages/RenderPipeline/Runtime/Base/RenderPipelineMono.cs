using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace OpenWorld.RenderPipelines.Runtime
{
    [ExecuteInEditMode]
    public class RenderPipelineMono : MonoBehaviour
    {
        private const string OBJ_NAME = "[RenderPipelineMono]";
        private static RenderPipelineMono m_Instance;
        public static RenderPipelineMono S
        {
            get
            {
                if (m_Instance == null)
                {
                    GameObject obj = null;

                    obj = GameObject.Find(OBJ_NAME);
                    if (obj == null)
                        obj = new GameObject(OBJ_NAME);

                    if (Application.isPlaying)
                    {
                        DontDestroyOnLoad(obj);
                    }

                    RenderPipelineMono com = obj.GetComponent<RenderPipelineMono>();
                    if (com == null)
                    {
                        m_Instance = obj.AddComponent<RenderPipelineMono>();
                    }
                    else
                    {
                        m_Instance = com;
                    }

                }
                return m_Instance;
            }
        }

        private void OnDrawGizmos()
        {
            if (RenderPipelineManager.currentPipeline == null)
                return;

            if (RenderPipelineManager.currentPipeline is not OpenWorldRenderPipeline pipeline)
                return;

            pipeline.OnDrawGizmos();
        }
    }
}
