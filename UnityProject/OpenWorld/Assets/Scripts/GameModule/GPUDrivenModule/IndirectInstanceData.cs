using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace XHH
{
    [System.Serializable]
    public class IndirectInstanceData
    {
        //外部的
        public Mesh lod0Mesh;
        public Mesh lod1Mesh;
        public Mesh lod2Mesh;
        public Material indirectMaterial;


        public InstanceTRSData[] itemsTRS;
    }



    [System.Serializable]
    public class IndirectRenderingMesh
    {
        public Mesh combineMesh;
        public Material indirectMaterial;
        public MaterialPropertyBlock lod0MatPropBlock;
        public MaterialPropertyBlock lod1MatPropBlock;
        public MaterialPropertyBlock lod2MatPropBlock;
        public uint numOfVerticesLod0;
        public uint numOfVerticesLod1;
        public uint numOfVerticesLod2;
        public uint numOfIndicesLod0;
        public uint numOfIndicesLod1;
        public uint numOfIndicesLod2;


        public static int MESH_INDEX = 0;


        public IndirectRenderingMesh(IndirectInstanceData instanceData)
        {

            // Initialize Mesh
            combineMesh = new Mesh();
            // combineMesh.name = name;
            combineMesh.CombineMeshes(
                new CombineInstance[]{
                    new CombineInstance(){mesh=instanceData.lod0Mesh},
                    new CombineInstance(){mesh=instanceData.lod1Mesh},
                    new CombineInstance(){mesh=instanceData.lod2Mesh}
                },
                true,           // Merge Submeshes 
                false,          // Use Matrices
                false			// Has lightmap data
            );


            numOfIndicesLod0 = instanceData.lod0Mesh.GetIndexCount(MESH_INDEX);
            numOfIndicesLod1 = instanceData.lod1Mesh.GetIndexCount(MESH_INDEX);
            numOfIndicesLod2 = instanceData.lod2Mesh.GetIndexCount(MESH_INDEX);
            numOfVerticesLod0 = (uint)instanceData.lod0Mesh.vertexCount;
            numOfVerticesLod1 = (uint)instanceData.lod1Mesh.vertexCount;
            numOfVerticesLod2 = (uint)instanceData.lod2Mesh.vertexCount;

            indirectMaterial = instanceData.indirectMaterial;


            lod0MatPropBlock = new MaterialPropertyBlock();
            lod1MatPropBlock = new MaterialPropertyBlock();
            lod2MatPropBlock = new MaterialPropertyBlock();
        }

        public MaterialPropertyBlock this[int mpbIndex]
        {
            get
            {
                if (mpbIndex == 0) return lod0MatPropBlock;
                else if (mpbIndex == 1) return lod1MatPropBlock;
                else return lod2MatPropBlock;
                // if (mpbIndex == 0) return lod0MatPropBlock;
            }
        }
    }


}