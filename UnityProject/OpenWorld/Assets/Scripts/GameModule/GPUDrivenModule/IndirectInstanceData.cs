using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace OpenWorld
{
    [System.Serializable]
    public class IndirectInstanceData
    {
        public Mesh lod0Mesh;
        public Mesh lod1Mesh;
        public Mesh lod2Mesh;
        public Material indirectMaterial;
        public Bounds originBounds;
        public Vector3 positionOffset = Vector3.zero;//坐标偏移
    }

    [System.Serializable]
    public class GrassIndirectInstanceData : IndirectInstanceData
    {
        public byte id;
        public GrassInstanceData[] itemsTRS;
    }



    public class IndirectRenderingMesh
    {
        public Mesh combineMesh;
        public Material indirectMaterial;
        public Bounds bounds;
        public MaterialPropertyBlock lod0MatPropBlock;
        public MaterialPropertyBlock lod1MatPropBlock;
        public MaterialPropertyBlock lod2MatPropBlock;
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

            indirectMaterial = instanceData.indirectMaterial;

            lod0MatPropBlock = new MaterialPropertyBlock();
            lod1MatPropBlock = new MaterialPropertyBlock();
            lod2MatPropBlock = new MaterialPropertyBlock();
            bounds = instanceData.originBounds;
        }

    }


}