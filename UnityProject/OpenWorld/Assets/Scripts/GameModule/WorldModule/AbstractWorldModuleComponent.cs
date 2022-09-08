using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld.World
{
    public abstract class AbstractWorldModuleComponent : AbstractModuleComponent
    {
        public WorldModule worldModule { get; set; }
    }

}