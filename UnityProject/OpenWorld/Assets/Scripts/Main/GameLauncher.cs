using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    public class GameLauncher : MonoBehaviour
    {
        static GameWorld m_GameWorld;
        static bool m_IsPlaying = true;


        public static bool isPlaying { get { return m_IsPlaying; } set { m_IsPlaying = value; } }

        private void Awake()
        {
            gameObject.DontDestroy();
            InitGameModule();
        }


        void InitGameModule()
        {
            IModule[] modules = new IModule[]
            {
                new WorldModule(),
                new CameraModule(),
            };

            m_GameWorld = new GameWorld();
            m_GameWorld.Start(modules);
        }


        private void Update()
        {
            if (m_IsPlaying)
            {
                m_GameWorld.Update();
            }
        }

        private void LateUpdate()
        {
            if (m_IsPlaying)
            {
                m_GameWorld.LateUpdate();
            }
        }

        private void OnDrawGizmos()
        {
            if (m_IsPlaying)
            {
                m_GameWorld?.OnGizmos();
            }
        }
    }

}