using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using OpenWorld.World;

namespace OpenWorld
{
    public class WorldModule : AbstractModule
    {
        public TerrainComponent terrain;
        public override void OnInit()
        {
            base.OnInit();
            terrain = AddComponent(new TerrainComponent()) as TerrainComponent;
        }

        protected override void OnAddComponment(IModuleComponent component)
        {
            (component as AbstractWorldModuleComponent).worldModule = this;
        }
    }

}