using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GrassPainter
{
    public class GrassPainterDefine
    {
        public static string toolPath = "Assets/Scripts/Tools/World/Grass/";
        public static string dataPath = "Assets/EditorRes/Config/World/Grass/";
    }

    public class GrassPainterHelper
    {
        public static bool PreventCustomUserHotkey(EventType type, EventModifiers codeModifier, KeyCode hotkey)
        {
            Event currentevent = Event.current;
            if (currentevent.type == type && currentevent.modifiers == codeModifier && currentevent.keyCode == hotkey)
            {
                currentevent.Use();
                return true;
            }

            return false;
        }

        public static string GetAutoCreateGrassSOPath(string key)
        {
            string path = GrassPainterDefine.dataPath + "AutoCrateGrassSO_" + key + ".asset";
            return path;
        }
    }

}
