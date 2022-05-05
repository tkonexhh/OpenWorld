using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class TSingleton<T> where T : TSingleton<T>, new()
    {
        private static T _Instance;
        public static T S
        {
            get
            {
                if (_Instance == null)
                {
                    _Instance = new T();
                    _Instance.OnSingletonInit();
                }

                return _Instance;
            }
        }

        protected virtual void OnSingletonInit()
        {
        }
    }
}
