using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld.World
{
    public class TerrainComponent : AbstractWorldModuleComponent
    {
        QuadTree m_QuadTree;

        public override void OnInit()
        {
            base.OnInit();

            m_QuadTree = new QuadTree(5, Vector3.zero, new Vector3(2000, 500, 2000));
        }

        public override void OnGizmos()
        {
            base.OnGizmos();

            m_QuadTree?.DrawBound();
        }
    }

}