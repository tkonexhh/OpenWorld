using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace OpenWorld
{
    public class CameraModule : AbstractModule
    {
        public Camera camera { get; set; }

        CameraData m_CameraData;
        bool m_IsDirty = false;

        public delegate void OnCameraDirty();
        public event OnCameraDirty onCameraDirty;

        public override void OnInit()
        {
            base.OnInit();
            camera = Camera.main;
        }

        public override void OnLateUpdate()
        {
            base.OnLateUpdate();
            CheckCameraDirty();
        }

        void CheckCameraDirty()
        {
            if (m_IsDirty)
                return;

            do
            {
                var cameraPosition = camera.transform.position;
                if (m_CameraData.lastPosition != cameraPosition)
                {
                    m_CameraData.lastPosition = cameraPosition;
                    m_IsDirty = true;
                    break;
                }

                var cameraRotation = camera.transform.rotation;
                if (m_CameraData.lastRotation != cameraRotation)
                {
                    m_CameraData.lastRotation = cameraRotation;
                    m_IsDirty = true;
                    break;
                }

                if (m_CameraData.lastFOV != camera.fieldOfView)
                {
                    m_CameraData.lastFOV = camera.fieldOfView;
                    m_IsDirty = true;
                    break;
                }
            } while (false);

            if (m_IsDirty)
            {
                m_CameraData.lastPosition = camera.transform.position;
                m_CameraData.lastRotation = camera.transform.rotation;
                m_CameraData.lastFOV = camera.fieldOfView;

                onCameraDirty?.Invoke();
            }
        }
    }

}