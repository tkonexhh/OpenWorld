using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH.Character
{
    public class CharacterLocomotion : MonoBehaviour
    {
        private Animator m_Animator;
        private Vector2 m_Input;

        // Start is called before the first frame update
        void Start()
        {
            m_Animator = GetComponent<Animator>();
        }

        // Update is called once per frame
        void Update()
        {
            m_Input.x = Input.GetAxis("Horizontal");
            m_Input.y = Input.GetAxis("Vertical");

            m_Animator.SetFloat("InputX", m_Input.x);
            m_Animator.SetFloat("InputY", m_Input.y);
        }
    }

}