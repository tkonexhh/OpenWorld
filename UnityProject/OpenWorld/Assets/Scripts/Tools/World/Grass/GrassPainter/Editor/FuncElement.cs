using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

namespace GrassPainter
{
    public abstract class FuncElement : VisualElement
    {
        public abstract void Init();
        public abstract void OnDestroy();
    }
}
