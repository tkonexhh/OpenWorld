using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH.World
{
    public class WorldModule : AbstractModule
    {
        public override void OnInit()
        {
            base.OnInit();

            AddComponent(new TerrainComponent());
        }
    }

}