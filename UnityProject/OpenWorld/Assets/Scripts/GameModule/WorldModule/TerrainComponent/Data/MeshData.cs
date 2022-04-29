using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.IO;

namespace XHH.World
{
    public class MeshData
    {
        public class LOD
        {
            public Vector3[] vertices;
            public Vector3[] normals;
            public Vector2[] uvs;

            public Vector2 uvmin;
            public Vector2 uvmax;

            static void Serialize(Stream stream, LOD lod)
            {
                //vertices
                StreamHelper.WriteInt(stream, lod.vertices.Length);
                for (int i = 0; i < lod.vertices.Length; i++)
                {
                    StreamHelper.WriteVector3(stream, lod.vertices[i]);
                }

                //normal
                StreamHelper.WriteInt(stream, lod.normals.Length);
                for (int i = 0; i < lod.normals.Length; i++)
                {
                    StreamHelper.WriteVector3(stream, lod.normals[i]);
                }

                //uvs
                StreamHelper.WriteInt(stream, lod.uvs.Length);
                for (int i = 0; i < lod.uvs.Length; i++)
                {
                    StreamHelper.WriteVector3(stream, lod.uvs[i]);
                }

                //uvminmax
                StreamHelper.WriteVector2(stream, lod.uvmin);
                StreamHelper.WriteVector2(stream, lod.uvmax);
            }

            public static LOD Deserialize(Stream stream)
            {
                var lod = new LOD();

                //vertices
                int verticesLength = StreamHelper.ReadInt(stream);
                lod.vertices = new Vector3[verticesLength];
                for (int i = 0; i < verticesLength; i++)
                {
                    lod.vertices[i] = StreamHelper.ReadVector3(stream);
                }

                //normal
                int normalsLength = StreamHelper.ReadInt(stream);
                lod.normals = new Vector3[normalsLength];
                for (int i = 0; i < normalsLength; i++)
                {
                    lod.normals[i] = StreamHelper.ReadVector3(stream);
                }

                //uvs
                int uvsLength = StreamHelper.ReadInt(stream);
                lod.uvs = new Vector2[uvsLength];
                for (int i = 0; i < uvsLength; i++)
                {
                    lod.uvs[i] = StreamHelper.ReadVector2(stream);
                }

                lod.uvmin = StreamHelper.ReadVector2(stream);
                lod.uvmax = StreamHelper.ReadVector2(stream);

                return lod;
            }
        }

        public LOD[] lods;
        public Bounds Bounds { get; private set; }



    }

}