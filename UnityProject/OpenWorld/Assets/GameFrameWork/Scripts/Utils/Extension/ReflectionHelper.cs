using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;


public class ReflectionHelper
{
    public static object GetPropertyValue(object src, string propName, BindingFlags bindingAttr)
    {
        if (src == null) return null;
        if (propName == null) return null;

        if (propName.Contains("."))//complex type nested
        {
            var temp = propName.Split(new char[] { '.' }, 2);
            return GetPropertyValue(GetPropertyValue(src, temp[0], bindingAttr), temp[1], bindingAttr);
        }
        else
        {
            var prop = src.GetType().GetProperty(propName, bindingAttr);
            return prop != null ? prop.GetValue(src, null) : null;
        }
    }

    public static PropertyInfo GetPropertyInfo(object src, string propName, BindingFlags bindingAttr)
    {
        if (src == null) return null;
        if (propName == null) return null;

        if (propName.Contains("."))//complex type nested
        {
            var temp = propName.Split(new char[] { '.' }, 2);
            return GetPropertyInfo(GetPropertyValue(src, temp[0], bindingAttr), temp[1], bindingAttr);
        }
        else
        {
            var prop = src.GetType().GetProperty(propName, bindingAttr);
            return prop;
        }
    }

    public static MethodInfo GetMethodInfo(object src, string methodName, BindingFlags bindingAttr)
    {
        if (src == null) return null;
        if (methodName == null) return null;

        var method = src.GetType().GetMethod(methodName, bindingAttr);
        return method;
    }
}

