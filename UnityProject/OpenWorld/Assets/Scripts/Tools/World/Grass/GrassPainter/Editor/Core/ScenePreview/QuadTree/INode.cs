using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public interface INode
    {
        Bounds bounds { get; }
        void DrawBound();
        void InsertObj(string key, GrassTRS item);
        void TriggerMove(Camera camera);
        void Clear();
    }
}
