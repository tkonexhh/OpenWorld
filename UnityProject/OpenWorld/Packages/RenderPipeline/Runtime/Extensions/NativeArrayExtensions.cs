using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;

namespace OpenWorld.RenderPipelines.Runtime
{
    static class NativeArrayExtensions
    {
        public static unsafe ref readonly T UnsafeElementAt<T>(this NativeArray<T> array, int index) where T : struct
        {
            return ref UnsafeUtility.ArrayElementAsRef<T>(array.GetUnsafeReadOnlyPtr(), index);
        }

        public static unsafe ref T UnsafeElementAtMutable<T>(this NativeArray<T> array, int index) where T : struct
        {
            return ref UnsafeUtility.ArrayElementAsRef<T>(array.GetUnsafePtr(), index);
        }
    }
}
