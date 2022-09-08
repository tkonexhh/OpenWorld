using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class EventHelper
{
    public static bool CustomUserHotkey(EventType type, EventModifiers codeModifier, KeyCode hotkey)
    {
        Event currentevent = Event.current;
        if (currentevent.type == type && currentevent.modifiers == codeModifier && currentevent.keyCode == hotkey)
        {
            currentevent.Use();
            return true;
        }

        return false;
    }
}
