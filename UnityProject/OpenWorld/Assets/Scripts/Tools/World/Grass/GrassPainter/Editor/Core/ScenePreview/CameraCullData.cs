using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{

    public class CameraCullData
    {
        public float lastCullTime = -1;
        public Vector3 lastCameraPosition;
        public Quaternion lastRotation;

    }
}
