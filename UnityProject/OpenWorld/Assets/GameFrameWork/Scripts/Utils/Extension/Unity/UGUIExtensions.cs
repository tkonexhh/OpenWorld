using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public static class UGUIExtensions
{
    public static Button SetClickListener(this Button @this, UnityAction handle)
    {
        if (@this.onClick == null)
            return @this;

        @this.onClick.RemoveAllListeners();
        @this.onClick.AddListener(handle);
        return @this;
    }
}

