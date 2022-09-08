using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;


public static class ColorExtension
{
    public static float Lumiance(this Color color)
    {
        Vector3 rgb = new Vector3(color.r, color.g, color.b);
        return Vector3.Dot(rgb, new Vector3(0.2126f, 0.7152f, 0.0722f));
    }

    // static 

    public static Color HexToColor(string hex)
    {
        Color color;
        if (!hex.StartsWith("#"))
            hex = "#" + hex;

        if (ColorUtility.TryParseHtmlString(hex, out color))
        {
            return color;
        }

        throw new Exception();
    }

    public static Vector3 ToVector3(this Color color)
    {
        return new Vector3(color.r, color.g, color.b);
    }
}

