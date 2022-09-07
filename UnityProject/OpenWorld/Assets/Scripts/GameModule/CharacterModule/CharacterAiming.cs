using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations.Rigging;

namespace XHH.Character
{
    public class CharacterAiming : MonoBehaviour
    {
        public float turnSpeed = 15.0f;
        public float animDuration = 0.3f;
        private Camera m_Camera;
        public Rig aimLayer;

        void Start()
        {
            m_Camera = Camera.main;
            Cursor.visible = false;
        }



        void FixedUpdate()
        {
            float yawCamera = m_Camera.transform.rotation.eulerAngles.y;
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.Euler(0, yawCamera, 0), turnSpeed * Time.fixedDeltaTime);
        }

        private void Update()
        {
            if (Input.GetMouseButton(0))
            {
                aimLayer.weight += Time.deltaTime / animDuration;
            }
            else
            {
                aimLayer.weight -= Time.deltaTime / animDuration;
            }
        }
    }

}