using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public struct BrushSetting
    {
        public float brushSize;
        public int brushDensity;
        public LayerMask paintMask;
        public LayerMask targetLayer;
        public bool randomRotate;
        public bool randomScale;
        public Vector2 scaleRange;
        public float mouseModeDelta;
    }
}
