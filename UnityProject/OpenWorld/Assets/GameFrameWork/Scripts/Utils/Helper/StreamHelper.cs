using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;

public class StreamHelper
{
    //BinaryWriter
    public static void WriteVector3(Stream stream, Vector3 v)
    {
        byte[] sBuff = BitConverter.GetBytes(v.x);
        stream.Write(sBuff, 0, sBuff.Length);
        sBuff = BitConverter.GetBytes(v.y);
        stream.Write(sBuff, 0, sBuff.Length);
        sBuff = BitConverter.GetBytes(v.z);
        stream.Write(sBuff, 0, sBuff.Length);
    }

    public static Vector3 ReadVector3(Stream stream, ref byte[] sBuff)
    {
        Vector3 v = Vector3.zero;
        stream.Read(sBuff, 0, sizeof(float));
        v.x = BitConverter.ToSingle(sBuff, 0);
        stream.Read(sBuff, 0, sizeof(float));
        v.y = BitConverter.ToSingle(sBuff, 0);
        stream.Read(sBuff, 0, sizeof(float));
        v.z = BitConverter.ToSingle(sBuff, 0);
        return v;
    }


    public static void WriteVector2(Stream stream, Vector2 v)
    {
        byte[] sBuff = BitConverter.GetBytes(v.x);
        stream.Write(sBuff, 0, sBuff.Length);
        sBuff = BitConverter.GetBytes(v.y);
        stream.Write(sBuff, 0, sBuff.Length);
    }

    public static Vector2 ReadVector2(Stream stream, ref byte[] sBuff)
    {
        Vector2 v = Vector2.zero;
        stream.Read(sBuff, 0, sizeof(float));
        v.x = BitConverter.ToSingle(sBuff, 0);
        stream.Read(sBuff, 0, sizeof(float));
        v.y = BitConverter.ToSingle(sBuff, 0);
        return v;
    }

    public static void WriteFloat(Stream stream, float value)
    {
        byte[] sBuff = BitConverter.GetBytes(value);
        stream.Write(sBuff, 0, sizeof(float));
    }

    public static float ReadFloat(Stream stream, ref byte[] sBuff)
    {
        float value = 0;
        stream.Read(sBuff, 0, sizeof(float));
        value = BitConverter.ToSingle(sBuff, 0);
        return value;
    }

    /// <summary>
    /// 用byte代替int来存储数据
    /// 范围0-255
    /// </summary>
    /// <param name="stream"></param>
    /// <param name="value"></param>
    public static void WriteByte(Stream stream, byte value)
    {
        byte[] sBuff = BitConverter.GetBytes(value);
        stream.Write(sBuff, 0, sizeof(byte));
    }

    public static int ReadByte(Stream stream, ref byte[] sBuff)
    {
        int value = 0;
        stream.Read(sBuff, 0, sizeof(byte));
        value = (byte)BitConverter.ToUInt16(sBuff, 0);
        return value;
    }


    public static void WriteShort(Stream stream, short value)
    {
        byte[] sBuff = BitConverter.GetBytes(value);
        stream.Write(sBuff, 0, sizeof(short));
    }

    public static int ReadShort(Stream stream, ref byte[] sBuff)
    {
        short value = 0;
        stream.Read(sBuff, 0, sizeof(short));
        value = BitConverter.ToInt16(sBuff, 0);
        return value;
    }


    public static void WriteInt(Stream stream, int value)
    {
        byte[] sBuff = BitConverter.GetBytes(value);
        stream.Write(sBuff, 0, sizeof(int));
    }

    public static int ReadInt(Stream stream, ref byte[] sBuff)
    {
        int value = 0;
        stream.Read(sBuff, 0, sizeof(int));
        value = (int)BitConverter.ToUInt32(sBuff, 0);
        return value;
    }
}
